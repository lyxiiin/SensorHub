class DeviceConfig {
  final int? configId; // UUID
  final String deviceName;
  final String broker;
  final int port;
  final String clientId;
  final String topic;
  final String username;
  final String password;

  DeviceConfig({
    this.configId,
    required this.broker,
    required this.port,
    required this.clientId,
    required this.topic,
    required this.username,
    required this.password,
    required this.deviceName
  });
  // 从数据库行（Map<String, dynamic>）创建对象
  factory DeviceConfig.fromMap(Map<String, dynamic> map) {
    return DeviceConfig(
      configId: map['configId'],
      broker: map['broker'],
      port: map['port'],
      clientId: map['clientId'],
      topic: map['topic'],
      username: map['username'],
      password: map['password'],
      deviceName: map['deviceName'],
    );
  }

  // 转换为数据库可存储的 Map
  Map<String, dynamic> toMap() {
    return {
      'configId': configId,
      'broker': broker,
      'port': port,
      'clientId': clientId,
      'topic': topic,
      'username': username,
      'password': password,
      'deviceName':deviceName
    };
  }
}