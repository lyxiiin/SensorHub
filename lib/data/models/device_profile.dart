import 'package:sensor_hub/data/models/sensor_channel.dart';
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
  final int? groupId;
  final List<SensorKey> sensors;
  final Map<SensorKey, ThresholdConfig> thresholds;
  final int payloadVersion;

  const DeviceProfile({
    required this.configId,
    required this.deviceName,
    required this.sensors,
    this.groupId,
    this.thresholds = const {},
    this.payloadVersion = 1,
  });

  /// 将 sensors 列表序列化为字符串（如 `[co2:primary, temperature:external]`）。
  ///
  /// 说明：当前没有调用点（DeviceProfile 由 device_latest 快照在内存中重建），
  /// 保留该序列化能力是为了将来落库/调试时格式统一。
  String sensorsToJson() {
    return sensors.map((s) => s.storageName).toList().toString();
  }

  /// 从 [sensorsToJson] 的格式反序列化。
  ///
  /// 兼容旧格式（如 `[temperature, humidity]`，无通道 → primary），
  /// 由 [SensorKey.fromStorageName] 兜底。
  static List<SensorKey> sensorsFromJson(String json) {
    // 简单处理：去除方括号和引号，按逗号分隔
    final cleaned = json
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .replaceAll(' ', '');
    if (cleaned.isEmpty) return [];
    return cleaned
        .split(',')
        .where((name) => name.isNotEmpty)
        .map(SensorKey.fromStorageName)
        .toList();
  }

  /// 检查某个 Measurement 是否超阈值
  bool isOverThreshold(Measurement measurement) {
    final threshold = thresholds[measurement.key];
    if (threshold == null) return false;
    return measurement.value > threshold.maxValue ||
           measurement.value < threshold.minValue;
  }
}