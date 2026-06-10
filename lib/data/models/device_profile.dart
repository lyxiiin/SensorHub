import 'package:sensor_hub/data/models/sensor_type.dart';
import 'package:sensor_hub/data/models/measurement.dart';

class ThresholdConfig {
  final int minValue;
  final int maxValue;
  final int severity; //告警级别 （1：警告，2：严重）

  const ThresholdConfig({
    required this.minValue,
    required this.maxValue,
    this.severity = 1,
  });

  Map<String, dynamic> toMap() => {
        'minValue': minValue,
        'maxValue': maxValue,
        'severity': severity,
  };

  factory ThresholdConfig.fromMap(Map<String, dynamic> map) => ThresholdConfig(
        minValue: map['minValue'],
        maxValue: map['maxValue'],
        severity: map['severity'],
  );
}

class DeviceProfile {
  final int configId;
  final String deviceName;
  final List<SensorType> sensors;
  final Map<SensorType, ThresholdConfig> thresholds;
  final int payloadVersion;

  const DeviceProfile({
    required this.configId,
    required this.deviceName,
    required this.sensors,
    this.thresholds = const {},
    this.payloadVersion = 1,
  });

  /// 将 sensors 列表序列化为 JSON 字符串（存入 device_configs 表）
  String sensorsToJson() {
    return sensors.map((s) => s.name).toList().toString();
  }

  /// 从 JSON 字符串反序列化 sensors 列表
  static List<SensorType> sensorsFromJson(String json) {
    // 简单处理：去除方括号和引号，按逗号分隔
    final cleaned = json.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').replaceAll(' ', '');
    if (cleaned.isEmpty) return [];
    return cleaned.split(',').map((name) => SensorTypeMeta.fromString(name)).toList();
  }

  /// 检查某个 Measurement 是否超阈值
  bool isOverThreshold(Measurement measurement) {
    final threshold = thresholds[measurement.sensorType];
    if (threshold == null) return false;
    return measurement.value > threshold.maxValue ||
           measurement.value < threshold.minValue;
  }
}