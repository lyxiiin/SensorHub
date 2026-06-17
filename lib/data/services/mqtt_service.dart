import 'dart:async';
import 'package:sensor_hub/utils/app_logger.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:typed_data';
typedef MqttMessageCallback = void Function(String topic, List<int> payload);
typedef MqttConnectionStatusCallback = void Function(bool connected);

class MqttService {
  late MqttServerClient _client;
  final Map<String, MqttMessageCallback> _topicCallbacks = {};
  final Set<String> _subscribedTopics = {};
  bool _autoReconnect = true;
  int _reconnectDelay = 5000; // 5秒重连
  Timer? _reconnectTimer;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _streamSubscription;

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

    // 如果已经连接或正在连接中，直接复用
    if (isConnected) {
      logD('复用现有连接', tag: 'MQTT');
      return;
    }
    if (_isConnecting) {
      logD('正在连接中，等待完成', tag: 'MQTT');
      return;
    }

    _client = MqttServerClient(host, clientId ?? 'flutter_client_${DateTime.now().millisecondsSinceEpoch}');
    _client.port = port;
    _client.setProtocolV311();
    _client.logging(on: false);
    _client.keepAlivePeriod = keepAlive;
    _client.onDisconnected = _onDisconnected;
    _client.onConnected = _onConnected;

    if (username != null && password != null) {
      _client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(_client.clientIdentifier)
          .authenticateAs(username, password)
          .withWillTopic('will')
          .withWillMessage('Client disconnected unexpectedly')
          .withWillQos(MqttQos.atLeastOnce)
          .startClean();
    }

    _connectionStatusController ??= StreamController<bool>.broadcast();
    await _doConnect();
  }

  bool _isConnecting = false;

  Future<void> _doConnect() async {
    // 防止重复连接：已连接或正在连接中时跳过
    if (isConnected) {
      return;
    }
    if (_isConnecting) {
      return;
    }
    _isConnecting = true;
    try {
      await _client.connect();
    } catch (e) {
      logE('连接失败: $e', error: e, tag: 'MQTT');
      _onDisconnected();
      if (_autoReconnect) {
        _scheduleReconnect();
      }
    } finally {
      _isConnecting = false;
    }
  }

  void _onConnected() {
    logI('已连接', tag: 'MQTT');
    _connectionStatusController?.add(true);
    _listenToMessages();
    // 断线重连后需要重新订阅已记录的 topic
    for (final topic in _subscribedTopics) {
      _client.subscribe(topic, MqttQos.atLeastOnce);
    }
  }

  void _onDisconnected() {
    logW('连接已断开', tag: 'MQTT');
    _connectionStatusController?.add(false);
    if (_autoReconnect) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: _reconnectDelay), () {
      logI('尝试重连...', tag: 'MQTT');
      _doConnect();
    });
  }

  void _listenToMessages() {
    logD('设置流监听器', tag: 'MQTT');
    // 取消现有的监听器（如果有的话）
    _streamSubscription?.cancel();
        
    _streamSubscription = _client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
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
        logW('未注册回调的 topic: $topic', tag: 'MQTT');
      }
    }, onError: (error) {
      logE('消息监听错误: $error', error: error, tag: 'MQTT');
    });
  }

  Future<void> publish({
    required String topic,
    required dynamic payload,
    MqttQos qos = MqttQos.atLeastOnce,
    bool retain = false,
  }) async {
    if(!isConnected){
      logW('未连接，无法发布到 $topic', tag: 'MQTT');
      return;
    }
    final builder = MqttClientPayloadBuilder();
    if(payload is String){
      builder.addString(payload);
    }else if(payload is List<int>){
      final temp = Uint8List.fromList(payload);
      for(final byte in temp){
        builder.addByte(byte);
      }
    }else{
      logE('不支持的 payload 类型 ${payload.runtimeType}', tag: 'MQTT');
      return;
    }
    try{
      _client.publishMessage(topic, qos, builder.payload!, retain: retain);
      logD('已发布到 $topic', tag: 'MQTT');
    } catch(e){
      logE('发布失败: $e', error: e, tag: 'MQTT');
    }
  }

  // 订阅 topic 并注册回调
  void subscribe(String topic, MqttMessageCallback callback) {
    if (_client.connectionStatus?.state != MqttConnectionState.connected) {
      logW('未连接，无法订阅 $topic', tag: 'MQTT');
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
      logI('已订阅: $topic', tag: 'MQTT');
    } catch (e) {
      logE('订阅失败 $topic: $e', error: e, tag: 'MQTT');
    }
  }

  // 检查是否已订阅指定主题
  bool isSubscribed(String topic) {
    return _subscribedTopics.contains(topic);
  }

  // 取消订阅
  void unsubscribe(String topic) {
    if (!_subscribedTopics.contains(topic)) return;

    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      _client.unsubscribe(topic);
    }

    _subscribedTopics.remove(topic);
    _topicCallbacks.remove(topic);
    logI('已退订: $topic', tag: 'MQTT');
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
    // 取消消息监听器
    _streamSubscription?.cancel();
    _streamSubscription = null;
    logI('已手动断开', tag: 'MQTT');
  }

  // 获取当前连接状态
  bool get isConnected {
    try {
      return _client.connectionStatus?.state == MqttConnectionState.connected;
    } catch (_) {
      return false; // _client 尚未初始化
    }
  }
}