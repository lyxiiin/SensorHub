import 'package:sensor_hub/data/models/measurement.dart';
import 'package:sensor_hub/data/models/sensor_type.dart';

class SensorRecord{
  final int? id;
  final String deviceId;
  final int timestamp;
  final double? co2;
  final double? temperature;
  final double? humidity;
  final double? pm25;
  final double? pm10;
  final double? voc;
  final double? noise;
  final double? lux;
  final double? atmosPressure;
  final int? flags;

  SensorRecord({
    this.id,
    required this.deviceId,
    required this.timestamp,
    this.co2,
    this.temperature,
    this.humidity,
    this.pm25,
    this.pm10,
    this.voc,
    this.noise,
    this.lux,
    this.atmosPressure,
    this.flags,
  });
  factory SensorRecord.fromJson(Map<String,dynamic> json){
    return SensorRecord(
      id: json['id'] as int?,
      deviceId: (json['deviceId'] as String?) ?? '',
      timestamp: (json['timestamp'] as int?) ?? 0,
      co2: _toDouble(json['co2']),
      temperature: _toDouble(json['temperature']),
      humidity: _toDouble(json['humidity']),
      pm25: _toDouble(json['pm25']),
      pm10: _toDouble(json['pm10']),
      voc: _toDouble(json['voc']),
      noise: _toDouble(json['noise']),
      lux: _toDouble(json['lux']),
      atmosPressure: _toDouble(json['atmosPressure']),
      flags: json['flags'] as int?,
    );
  }

    /// 宽表 → 窄表：拆分为多个 Measurement
  List<Measurement> toMeasurements(int configId) {
    final map = {
      SensorType.co2: co2,
      SensorType.temperature: temperature,
      SensorType.humidity: humidity,
      SensorType.pm25: pm25,
      SensorType.pm10: pm10,
      SensorType.voc: voc,
      SensorType.noise: noise,
      SensorType.lux: lux,
      SensorType.atmosPressure: atmosPressure,
    };

    final results = <Measurement>[];
    for (final entry in map.entries) {
      final rawValue = entry.value;
      if (rawValue == null) continue;

      final sensorType = entry.key;
      final storedValue = (rawValue * sensorType.storageScale).round();

      results.add(Measurement(
        configId: configId,
        sensorType: sensorType,
        value: storedValue,
        timestamp: timestamp,
      ));
    }
    return results;
  }

    static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return null;
  }
}