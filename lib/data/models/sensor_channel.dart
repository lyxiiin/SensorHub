import 'package:sensor_hub/data/models/sensor_type.dart';

enum SensorChannel {
  primary,
  external,
  internal;

  static SensorChannel fromName(String? name) {
    return switch (name) {
      'external' => SensorChannel.external,
      'internal' => SensorChannel.internal,
      _ => SensorChannel.primary,
    };
  }

  int get sortOrder => switch(this){
    SensorChannel.primary => 0,
    SensorChannel.external => 1,
    SensorChannel.internal => 2,
  };
}

class SensorKey implements Comparable<SensorKey>{
  final SensorType type;
  final SensorChannel channel;

  const SensorKey(this.type,this.channel);

  String get storageName => '${type.name}:${channel.name}';

  /// 兼容旧 JSON（无冒号，如 'temperature'）→ primary
  static SensorKey fromStorageName(String raw) {
    final i = raw.indexOf(':');
    if (i < 0) return SensorKey(SensorTypeMeta.fromString(raw), SensorChannel.primary);
    return SensorKey(
      SensorTypeMeta.fromString(raw.substring(0, i)),
      SensorChannel.fromName(raw.substring(i + 1)),
    );
  }

  /// 从 DB 行构造（measurements / device_latest）
  static SensorKey fromMap(Map<String, dynamic> map) => SensorKey(
    SensorTypeMeta.fromString((map['sensor_type'] as String?) ?? ''),
    SensorChannel.fromName(map['sensor_channel'] as String?),
  );

  @override
  int compareTo(SensorKey other) {
    final c = type.index.compareTo(other.type.index);
    return c != 0 ? c : channel.sortOrder.compareTo(other.channel.sortOrder);
  }

  @override
  bool operator ==(Object other) =>
      other is SensorKey && other.type == type && other.channel == channel;

  @override
  int get hashCode => Object.hash(type, channel);

  @override
  String toString() => storageName; // 日志直接可读
}