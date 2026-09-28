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

  /// 在途连接的共享 Future（单飞）：并发调用 connect() 时，
  /// 后来者等待同一次连接完成，而不是立即返回假装成功。
  Future<void>? _connectingFuture;

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

    // 如果已经连接，直接复用
    if (isConnected) {
      return;
    }
    // 单飞：在途连接返回同一个 Future，让后来者真正等待完成
    // （注意：连接参数以首次发起的调用为准）
    final pending = _connectingFuture;
    if (pending != null) {
      logD('正在连接中，等待完成', tag: 'MQTT');
      return pending;
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

  Future<void> _doConnect() {
    // 防止重复连接：已连接或正在连接中时，复用同一个 Future
    if (isConnected) {
      return Future.value();
    }
    final pending = _connectingFuture;
    if (pending != null) {
      return pending;
    }

    // 用 Completer 实现“单飞”：无论入口是 connect() 还是重连定时器，
    // 同一时刻只有一次真实连接，所有等待者共享同一个 Future。
    final completer = Completer<void>();
    _connectingFuture = completer.future;
    () async {
      try {
        await _client.connect();
        completer.complete();
      } catch (e) {
        logE('连接失败: $e', error: e, tag: 'MQTT');
        _onDisconnected();
        if (_autoReconnect) {
          _scheduleReconnect();
        }
        // 吞掉异常：调用方统一通过 isConnected 判断连接结果（保持原有语义）
        completer.complete();
      } finally {
        _connectingFuture = null;
      }
    }();
    return completer.future;
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
    // 回调永远先登记（同 topic 重复订阅 = 替换回调，不叠加）
    _topicCallbacks[topic] = callback;

    if (_subscribedTopics.contains(topic)) return;

    if (_isClientConnected) {
      try {
        _client.subscribe(topic, MqttQos.atLeastOnce);
        logI('已订阅: $topic', tag: 'MQTT');
      } catch (e) {
        logE('订阅失败 $topic: $e', error: e, tag: 'MQTT');
      }
    } else {
      // 未连接：只登记意图，连接建立后由 _onConnected 的补订循环生效
      logI('已登记订阅: $topic (连接建立后生效)', tag: 'MQTT');
    }
    _subscribedTopics.add(topic);
  }

  // 检查是否已订阅指定主题
  bool isSubscribed(String topic) {
    return _subscribedTopics.contains(topic);
  }

  // 取消订阅
  void unsubscribe(String topic) {
    if (!_subscribedTopics.contains(topic)) return;

    if (_isClientConnected) {
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

  // 安全的连接状态判断：_client 未初始化（late 字段）时返回 false 而不抛异常
  bool get _isClientConnected {
    try {
      return _client.connectionStatus?.state == MqttConnectionState.connected;
    } catch (_) {
      return false; // _client 尚未初始化
    }
  }

  // 获取当前连接状态
  bool get isConnected => _isClientConnected;
}