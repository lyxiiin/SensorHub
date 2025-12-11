import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

typedef MqttMessageCallback = void Function(String topic, List<int> payload);
typedef MqttConnectionStatusCallback = void Function(bool connected);

class MqttService {
  late MqttServerClient _client;
  final Map<String, MqttMessageCallback> _topicCallbacks = {};
  final Set<String> _subscribedTopics = {};
  bool _autoReconnect = true;
  int _reconnectDelay = 5000; // 5秒重连
  Timer? _reconnectTimer;

  StreamController<bool>? _connectionStatusController;
  Stream<bool> get connectionStatusStream =>
      _connectionStatusController!.stream;

  // 初始化连接
  Future<void> connect({
    required String host,
    int port = 1883,
    String? clientId,
    String? username,
    String? password,
    bool autoReconnect = true,
    int keepAlive = 60,
    int reconnectDelay = 5000,
    bool logging = false,
  }) async {
    _autoReconnect = autoReconnect;
    _reconnectDelay = reconnectDelay;

    _client = MqttServerClient(host, clientId ?? 'flutter_client_${DateTime.now().millisecondsSinceEpoch}');
    _client.port = port;
    _client.logging(on: logging);
    _client.keepAlivePeriod = keepAlive;
    _client.onDisconnected = _onDisconnected;
    _client.onConnected = _onConnected;

    if (username != null && password != null) {
      _client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(_client.clientIdentifier)
          .startClean()
          .withWillTopic('will')
          .withWillMessage('Client disconnected unexpectedly')
          .withWillQos(MqttQos.atLeastOnce)
          .authenticateAs(username, password);
    }

    _connectionStatusController ??= StreamController<bool>.broadcast();
    await _doConnect();
  }

  Future<void> _doConnect() async {
    try {
      await _client.connect();
      if (_client.connectionStatus!.state == MqttConnectionState.connected) {
        _onConnected();
        // 重新订阅之前订阅的 topic（断线重连后需要）
        for (final topic in _subscribedTopics) {
          _client.subscribe(topic, MqttQos.atLeastOnce);
        }
      }
    } catch (e) {
      log('MQTT 连接失败: $e');
      _onDisconnected();
      if (_autoReconnect) {
        _scheduleReconnect();
      }
    }
  }

  void _onConnected() {
    log('MQTT 已连接');
    _connectionStatusController?.add(true);
    _listenToMessages();
  }

  void _onDisconnected() {
    log('MQTT 已断开');
    _connectionStatusController?.add(false);
    if (_autoReconnect) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: _reconnectDelay), () {
      log('尝试 MQTT 重连...');
      _doConnect();
    });
  }

  void _listenToMessages() {
    _client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final message = messages[0];
      final topic = message.topic;
      final publishMsg = message.payload as MqttPublishMessage;
      final payload = publishMsg.payload.message;

      // 查找是否有注册的回调
      final callback = _topicCallbacks[topic];
      if (callback != null) {
        callback(topic, payload);
      } else {
        // 兜底：未注册回调也打印（可选）
        log('收到未注册 topic 消息: $topic -> $payload');
      }
    }, onError: (error) {
      log('MQTT 消息监听错误: $error');
    });
  }

  // 订阅 topic 并注册回调
  void subscribe(String topic, MqttMessageCallback callback) {
    if (_client.connectionStatus?.state != MqttConnectionState.connected) {
      log('MQTT 未连接，无法订阅 $topic');
      return;
    }

    if (_subscribedTopics.contains(topic)) {
      // 已订阅，更新回调即可
      _topicCallbacks[topic] = callback;
      return;
    }

    try {
      _client.subscribe(topic, MqttQos.atLeastOnce);
      _subscribedTopics.add(topic);
      _topicCallbacks[topic] = callback;
      log('成功订阅: $topic');
    } catch (e) {
      log('订阅失败 $topic: $e');
    }
  }

  // 取消订阅
  void unsubscribe(String topic) {
    if (!_subscribedTopics.contains(topic)) return;

    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      _client.unsubscribe(topic);
    }

    _subscribedTopics.remove(topic);
    _topicCallbacks.remove(topic);
    log('已退订: $topic');
  }

  // 断开连接（停止自动重连）
  void disconnect() {
    _autoReconnect = false;
    _reconnectTimer?.cancel();
    _client.disconnect();
    _connectionStatusController?.close();
    _connectionStatusController = null;
    _topicCallbacks.clear();
    _subscribedTopics.clear();
    log('MQTT 已手动断开');
  }

  // 获取当前连接状态
  bool get isConnected =>
      _client.connectionStatus?.state == MqttConnectionState.connected;
}