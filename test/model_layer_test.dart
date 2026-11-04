import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_hub/data/models/device_profile.dart';
import 'package:sensor_hub/data/models/measurement.dart';
import 'package:sensor_hub/data/models/sensor_channel.dart';
import 'package:sensor_hub/data/models/sensor_record.dart';
import 'package:sensor_hub/data/models/sensor_type.dart';

/// 模型层回归测试（重构方案 §5）：
/// - HTTP 宽表 → 窄表时的通道归属；
/// - DeviceProfile 以 SensorKey 作为业务主键后的序列化与阈值匹配；
/// - SensorKey 的字符串/DB 行往返与排序契约。
void main() {
  group('SensorRecord.toMeasurements（HTTP 宽表 → 窄表）', () {
    test('温度/湿度归入 external，其余物理量归入 primary', () {
      final record = SensorRecord(
        deviceId: 'dev-1',
        timestamp: 1700000000,
        co2: 800,
        temperature: 18.3,
        humidity: 45.6,
        pm25: 12,
        atmosPressure: 1013.25,
      );

      final measurements = record.toMeasurements(7);
      final byKey = {for (final m in measurements) m.key: m};

      expect(measurements, hasLength(5));
      // 精度按 SensorType.storageScale 换算后落库（温度/湿度/压力 ×100）
      expect(
        byKey[SensorKey(SensorType.temperature, SensorChannel.external)]?.value,
        1830,
      );
      expect(
        byKey[SensorKey(SensorType.humidity, SensorChannel.external)]?.value,
        4560,
      );
      expect(
        byKey[SensorKey(SensorType.pressure, SensorChannel.primary)]?.value,
        101325,
      );
      expect(byKey[SensorKey(SensorType.carbon_dioxide, SensorChannel.primary)]?.value, 800);
      expect(byKey[SensorKey(SensorType.pm25, SensorChannel.primary)]?.value, 12);
      expect(measurements.every((m) => m.configId == 7), isTrue);
      expect(measurements.every((m) => m.timestamp == 1700000000), isTrue);
    });

    test('温度/湿度不再落 primary，与设备直采的 internal 通道区分开', () {
      final measurements = SensorRecord(
        deviceId: 'dev-1',
        timestamp: 1,
        temperature: 25.5,
        humidity: 50,
      ).toMeasurements(1);

      // 宽表没有来源信息 → 统一 external，不能写成 primary
      expect(
        measurements.any(
          (m) =>
              m.channel == SensorChannel.primary &&
              (m.sensorType == SensorType.temperature ||
                  m.sensorType == SensorType.humidity),
        ),
        isFalse,
      );

      // 同一物理量的外部/内部必须是两个不同的 key（回归「互相覆盖」问题）
      final externalTemp = measurements
          .firstWhere((m) => m.sensorType == SensorType.temperature)
          .key;
      const internalTemp = SensorKey(
        SensorType.temperature,
        SensorChannel.internal,
      );
      expect(externalTemp == internalTemp, isFalse);
      expect(externalTemp.compareTo(internalTemp), isNot(0));
    });

    test('空列跳过；全空记录返回空列表', () {
      expect(SensorRecord(deviceId: 'dev-1', timestamp: 1).toMeasurements(1),
          isEmpty);

      final partial =
          SensorRecord(deviceId: 'dev-1', timestamp: 1, co2: 400)
              .toMeasurements(1);
      expect(partial, hasLength(1));
      expect(partial.single.sensorType, SensorType.carbon_dioxide);
      expect(partial.single.channel, SensorChannel.primary);
    });
  });

  group('DeviceProfile（SensorKey 作为业务主键）', () {
    test('sensors 序列化/反序列化保留通道', () {
      const profile = DeviceProfile(
        configId: 1,
        deviceName: 'dev-1',
        sensors: [
          SensorKey(SensorType.carbon_dioxide, SensorChannel.primary),
          SensorKey(SensorType.temperature, SensorChannel.external),
          SensorKey(SensorType.temperature, SensorChannel.internal),
        ],
      );

      final json = profile.sensorsToJson();
      expect(json, contains('temperature:external'));
      expect(json, contains('temperature:internal'));

      final restored = DeviceProfile.sensorsFromJson(json);
      expect(restored, profile.sensors);
    });

    test('反序列化兼容旧格式（无通道 → primary）', () {
      expect(DeviceProfile.sensorsFromJson('[temperature, humidity]'), [
        const SensorKey(SensorType.temperature, SensorChannel.primary),
        const SensorKey(SensorType.humidity, SensorChannel.primary),
      ]);
      expect(DeviceProfile.sensorsFromJson('[]'), isEmpty);
      expect(DeviceProfile.sensorsFromJson(''), isEmpty);
    });

    test('阈值按 (物理量, 通道) 匹配，外部阈值不影响内部通道', () {
      final profile = DeviceProfile(
        configId: 1,
        deviceName: 'dev-1',
        sensors: const [
          SensorKey(SensorType.temperature, SensorChannel.external),
        ],
        // 注意：SensorKey 重写了 ==，不能做 const Map 的 key
        thresholds: {
          const SensorKey(SensorType.temperature, SensorChannel.external):
              const ThresholdConfig(minValue: 0, maxValue: 3000),
        },
      );

      Measurement reading(SensorChannel channel, int value) => Measurement(
            configId: 1,
            sensorType: SensorType.temperature,
            channel: channel,
            value: value,
            timestamp: 0,
          );

      expect(profile.isOverThreshold(reading(SensorChannel.external, 3500)),
          isTrue);
      expect(profile.isOverThreshold(reading(SensorChannel.external, 2500)),
          isFalse);
      // 同一个物理量的其它通道没有配置阈值 → 不告警
      expect(profile.isOverThreshold(reading(SensorChannel.internal, 3500)),
          isFalse);
      expect(profile.isOverThreshold(reading(SensorChannel.primary, 3500)),
          isFalse);
    });
  });

  group('SensorKey（模型层主键契约）', () {
    test('storageName 可往返，旧格式回落 primary', () {
      const key = SensorKey(SensorType.temperature, SensorChannel.external);
      expect(key.storageName, 'temperature:external');
      expect(SensorKey.fromStorageName(key.storageName), key);
      expect(
        SensorKey.fromStorageName('temperature'),
        const SensorKey(SensorType.temperature, SensorChannel.primary),
      );
    });

    test('fromMap 从 DB 行构造，缺列回落 primary', () {
      expect(
        SensorKey.fromMap(
            {'sensor_type': 'humidity', 'sensor_channel': 'internal'}),
        const SensorKey(SensorType.humidity, SensorChannel.internal),
      );
      expect(
        SensorKey.fromMap({'sensor_type': 'humidity'}),
        const SensorKey(SensorType.humidity, SensorChannel.primary),
      );
      expect(
        SensorKey.fromMap(
            {'sensor_type': 'humidity', 'sensor_channel': null}),
        const SensorKey(SensorType.humidity, SensorChannel.primary),
      );
    });

    test('compareTo 先物理量后通道，且与 == 保持一致', () {
      final keys = [
        const SensorKey(SensorType.temperature, SensorChannel.internal),
        const SensorKey(SensorType.humidity, SensorChannel.external),
        const SensorKey(SensorType.temperature, SensorChannel.external),
        const SensorKey(SensorType.temperature, SensorChannel.primary),
      ]..sort();

      expect(keys, [
        const SensorKey(SensorType.temperature, SensorChannel.primary),
        const SensorKey(SensorType.temperature, SensorChannel.external),
        const SensorKey(SensorType.temperature, SensorChannel.internal),
        const SensorKey(SensorType.humidity, SensorChannel.external),
      ]);

      const a = SensorKey(SensorType.carbon_dioxide, SensorChannel.primary);
      const b = SensorKey(SensorType.carbon_dioxide, SensorChannel.primary);
      expect(a.compareTo(b), 0);
      expect(a == b, isTrue);
    });
  });
}
