import 'package:sensor_hub/data/models/sensor_data.dart';

class SensorDataBasic extends SensorData{
  SensorDataBasic({
    required super.configId,
    required super.datetime,
    required super.temperature,
    required super.humidity,
  });

  @override
  Map<String,dynamic> toMap() {
    return {
      'config_id': configId,
      'datetime': datetime,
      'temperature': temperature,
      'humidity': humidity,
    };
  }

  factory SensorDataBasic.fromMap(Map<String, dynamic> map) {
    return SensorDataBasic(
      configId: map['config_id'] is int ? map['config_id'] : 0,
      datetime: map['datetime'] is int ? map['datetime'] : 0,
      temperature: map['temperature'] is int ? map['temperature'] : 0,
      humidity: map['humidity'] is int ? map['humidity'] : 0,
    );
  }
}