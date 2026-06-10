import 'package:sensor_hub/data/models/sensor_type.dart';

// 窄表

class Measurement {
  final int? id;
  final int configId;
  final SensorType sensorType;
  final int value;
  final int timestamp;

  Measurement({
    this.id,
    required this.configId,
    required this.sensorType,
    required this.value,
    required this.timestamp,
  });

  // 格式化后的显示值，如 255 → "25.5"
  String get formattedValue => sensorType.formatValue(value);

  // 转为数据库Map,字段与measurements表一致
  Map<String, dynamic> toMap() => {
    'id': id,
    'configId': configId,
    'sensorType': sensorType.name,
    'value': value,
    'timestamp': timestamp,
  };

  /// 从数据库 Map 创建
  factory Measurement.fromMap(Map<String, dynamic> map) {
    return Measurement(
      id: map['id'] as int?,
      configId: (map['config_id'] as int?) ?? 0,
      sensorType: SensorTypeMeta.fromString(
        (map['sensor_type'] as String?) ?? '',
      ),
      value: (map['value'] as int?) ?? 0,
      timestamp: (map['timestamp'] as int?) ?? 0,
    );
  }

  /// 从 device_latest 快照表 Map 创建（该表没有 id 列）
  factory Measurement.fromLatestMap(Map<String, dynamic> map) {
    return Measurement(
      id: null,
      configId: (map['config_id'] as int?) ?? 0,
      sensorType: SensorTypeMeta.fromString(
        (map['sensor_type'] as String?) ?? '',
      ),
      value: (map['value'] as int?) ?? 0,
      timestamp: (map['timestamp'] as int?) ?? 0,
    );
  }
}
