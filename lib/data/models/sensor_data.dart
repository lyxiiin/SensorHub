class SensorData {
  final int configId;
  final int datetime;
  final int temperature;
  final int humidity;

  SensorData({
    required this.configId,
    required this.datetime,
    required this.temperature,
    required this.humidity,
  });
  Map<String,dynamic> toMap() {
    return {
      'config_id': configId,
      'datetime': datetime,
      'temperature': temperature,
      'humidity': humidity,
    };
  }

  factory SensorData.fromMap(Map<String, dynamic> map) {
    return SensorData(
      configId: map['config_id'] is int ? map['config_id'] : 0,
      datetime: map['datetime'] is int ? map['datetime'] : 0,
      temperature: map['temperature'] is int ? map['temperature'] : 0,
      humidity: map['humidity'] is int ? map['humidity'] : 0,
    );
  }
}