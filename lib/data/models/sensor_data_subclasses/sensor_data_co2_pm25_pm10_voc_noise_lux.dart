import 'package:sensor_hub/data/models/sensor_data.dart';

class SensorDataCo2Pm25Pm10VocNoiseLux extends SensorData{
  final int co2;
  final int pm25;
  final int pm10;
  final int voc;
  final int noise;
  final int lux;
  SensorDataCo2Pm25Pm10VocNoiseLux({
    required super.configId,
    required super.datetime,
    required super.temperature,
    required super.humidity,
    required this.co2,
    required this.pm25,
    required this.pm10,
    required this.voc,
    required this.noise,
    required this.lux,
  });

  @override
  Map<String,dynamic> toMap() {
    return {
      'config_id': configId,
      'datetime': datetime,
      'temperature': temperature,
      'humidity': humidity,
      'co2': co2,
      'pm25': pm25,
      'pm10': pm10,
      'voc': voc,
      'noise': noise,
      'lux': lux,
    };
  }

  factory SensorDataCo2Pm25Pm10VocNoiseLux.fromMap(Map<String, dynamic> map) {
    return SensorDataCo2Pm25Pm10VocNoiseLux(
      configId: map['config_id'] is int ? map['config_id'] : 0,
      datetime: map['datetime'] is int ? map['datetime'] : 0,
      temperature: map['temperature'] is int ? map['temperature'] : 0,
      humidity: map['humidity'] is int ? map['humidity'] : 0,
      co2: map['co2'] is int? ? map['co2'] : 0,
      pm25: map['pm25'] is int? ? map['pm25'] : 0,
      pm10: map['pm10'] is int? ? map['pm10'] : 0,
      voc: map['voc'] is int? ? map['voc'] : 0,
      noise: map['noise'] is int? ? map['noise'] : 0,
      lux: map['lux'] is int? ? map['lux'] : 0,
    );
  }
}