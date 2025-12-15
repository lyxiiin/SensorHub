import 'package:sensor_hub/data/models/sensor_data.dart';

class SensorDataCo2 extends SensorData{
  final int co2;
  SensorDataCo2({
    required super.configId,
    required super.datetime,
    required super.temperature,
    required super.humidity,
    required this.co2
  });

  @override
  Map<String,dynamic> toMap() {
    return {
      'config_id': configId,
      'datetime': datetime,
      'temperature': temperature,
      'humidity': humidity,
      'co2': co2,
    };
  }

  factory SensorDataCo2.fromMap(Map<String, dynamic> map) {
    return SensorDataCo2(
      configId: map['config_id'] is int ? map['config_id'] : 0,
      datetime: map['datetime'] is int ? map['datetime'] : 0,
      temperature: map['temperature'] is int ? map['temperature'] : 0,
      humidity: map['humidity'] is int ? map['humidity'] : 0,
      co2: map['co2'] is int? ? map['co2'] : 0,
    );
  }
}