import 'package:sensor_hub/data/models/sensor_data.dart';

class SensorDataExternalCo2OrTemp extends SensorData{
  final int externalCo2;
  final int externalTemperature;
  SensorDataExternalCo2OrTemp({
    required super.configId,
    required super.datetime,
    required super.temperature,
    required super.humidity,
    required this.externalCo2,
    required this.externalTemperature
  });

  @override
  Map<String,dynamic> toMap() {
    return {
      'config_id': configId,
      'datetime': datetime,
      'temperature': temperature,
      'humidity': humidity,
      'externalCo2': externalCo2,
      'externalTemperature': externalTemperature,
    };
  }

  factory SensorDataExternalCo2OrTemp.fromMap(Map<String, dynamic> map) {
    return SensorDataExternalCo2OrTemp(
      configId: map['config_id'] is int ? map['config_id'] : 0,
      datetime: map['datetime'] is int ? map['datetime'] : 0,
      temperature: map['temperature'] is int ? map['temperature'] : 0,
      humidity: map['humidity'] is int ? map['humidity'] : 0,
      externalCo2: map['externalCo2'] is int? ? map['externalCo2'] : 0,
      externalTemperature: map['externalTemperature'] is int? ? map['externalTemperature'] : 0,
    );
  }
}