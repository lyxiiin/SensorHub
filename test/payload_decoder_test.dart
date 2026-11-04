import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_hub/data/decoders/payload_decoder.dart';
import 'package:sensor_hub/data/models/measurement.dart';
import 'package:sensor_hub/data/models/sensor_channel.dart';
import 'package:sensor_hub/data/models/sensor_type.dart';

/// SDTP 协议解码单元测试（重构方案 §10.1「解码器零单测」缺口）。
///
/// 帧结构（见 `lib/data/decoders/payload_decoder.dart` 文件头注释）：
/// ```
/// AA 55 | Timestamp(4B 大端) | TLV Count(1B) | Flags(1B) | TLV Records | CRC8(1B)
/// ```
/// TLV Record = `TypeId(1B) | Length(1B) | Value(Length B)`：
/// - `Length == 2` → uint16 大端，Value 是「物理量的整数形式」（如 CO2 = 800）；
/// - `Length == 4` → float32 IEEE 754 大端，Value 是「物理量的浮点形式」（如 25.5）。
/// 两种线格式统一按「物理量 × storageScale」落库，同一物理量口径一致。
///
/// CRC8：poly 0x07、init 0x00、不反射、xorout 0x00，覆盖 offset 2 → CRC 字节之前
/// （即 Timestamp / Count / Flags / TLV 区域，同步头不参与校验）。
///
/// 测试不依赖解码器的私有映射表，一律通过 `PayloadDecoder.decode(hex, configId:)`
/// 断言输出，映射表改动（§2.2 增删一行）只会让对应用例失败，而不是编译失败。
const int _configId = 7;

/// 2025-01-01 00:00:00 UTC，用于验证 Timestamp 原样透传。
const int _timestamp = 1735689600;

// ============================================================
// 测试侧编码工具（与解码器同算法，用来「造」合法帧）
// ============================================================

/// CRC-8/ATM：poly=0x07、init=0x00、不反射、xorout=0x00。
int _crc8(List<int> data, [int start = 0, int? end]) {
  int crc = 0x00;
  final stop = end ?? data.length;
  for (int i = start; i < stop; i++) {
    crc ^= data[i];
    for (int b = 0; b < 8; b++) {
      crc = (crc & 0x80) != 0 ? ((crc << 1) ^ 0x07) & 0xFF : (crc << 1) & 0xFF;
    }
  }
  return crc;
}

String _hex(List<int> bytes) => bytes
    .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    .join();

/// float32 大端字节（IEEE 754）。
List<int> _float32(double value) {
  final data = ByteData(4)..setFloat32(0, value, Endian.big);
  return data.buffer.asUint8List().toList();
}

/// uint16 大端字节。
List<int> _uint16(int value) => [(value >> 8) & 0xFF, value & 0xFF];

/// 单条 TLV：TypeId + Length + Value。
List<int> _tlv(int typeId, List<int> value) => [typeId, value.length, ...value];

/// 组帧并返回大写十六进制串。
///
/// [records] 中每个元素是「一条 TLV 的原始字节」，用 `_tlv(...)` 构造；
/// 需要构造畸形帧时也可以直接传裸字节（如 `[0x03, 0x40]` 表示声明 64 字节却没有数据）。
String _frame(
  List<List<int>> records, {
  int timestamp = _timestamp,
  int flags = 0,
  int? tlvCount,
  int? crcOverride,
}) {
  final frame = <int>[
    0xAA,
    0x55,
    (timestamp >> 24) & 0xFF,
    (timestamp >> 16) & 0xFF,
    (timestamp >> 8) & 0xFF,
    timestamp & 0xFF,
    tlvCount ?? records.length,
    flags,
    for (final record in records) ...record,
  ];
  // CRC 覆盖 offset 2 到末尾（即 CRC 字节之前）
  final crc = (crcOverride ?? _crc8(frame, 2, frame.length)) & 0xFF;
  return _hex([...frame, crc]);
}

/// 用真实 CRC 造一帧后把最后一字节取反，得到「合法结构 + 坏 CRC」的帧。
String _withBadCrc(String validHex) {
  final last = _byteCount(validHex) - 1;
  // 取反保证与真实 CRC 不同，避免恰好等于原值造成假阳性
  return _patchByte(validHex, last, _byteAt(validHex, last) ^ 0xFF);
}

/// 帧中的字节数（每 2 个 hex 字符 1 字节）。
int _byteCount(String hex) => hex.length ~/ 2;

/// 读取帧中第 [byteIndex] 个字节。
int _byteAt(String hex, int byteIndex) =>
    int.parse(hex.substring(byteIndex * 2, byteIndex * 2 + 2), radix: 16);

/// 把帧中第 [byteIndex] 个字节替换为 [value]，用于构造「结构合法但内容被篡改」的帧。
String _patchByte(String hex, int byteIndex, int value) {
  final start = byteIndex * 2;
  final byteHex = value.toRadixString(16).padLeft(2, '0').toUpperCase();
  return '${hex.substring(0, start)}$byteHex${hex.substring(start + 2)}';
}

List<Measurement> _decode(String hex, {int configId = _configId}) =>
    PayloadDecoder.decode(hex, configId: configId);

/// 按 (SensorType, SensorChannel) 建索引，便于断言「同物理量不同通道」。
Map<SensorKey, Measurement> _byKey(List<Measurement> list) =>
    {for (final m in list) m.key: m};

void main() {
  // ============================================================
  group('测试帧构造自检（CRC8 算法 / float32 大端）', () {
    test('CRC8 与协议一致：poly=0x07、init=0x00，标准校验值 0xF4', () {
      // CRC-8/ATM 标准 check：ASCII "123456789" → 0xF4
      expect(_crc8('123456789'.codeUnits), 0xF4);
      expect(_crc8([0x00]), 0x00);
      expect(_crc8([0x01]), 0x07);
    });

    test('float32 按大端编码：25.5 → 41CC0000、18.3 → 41926666', () {
      // 与解码器 _parseFloat32(..., Endian.big) 的假设一致；
      // 若解码器改成小端，这里的用例会因值不匹配而失败。
      expect(_hex(_float32(25.5)), '41CC0000');
      expect(_hex(_float32(18.3)), '41926666');
    });
  });

  // ============================================================
  group('TypeId → (SensorType, SensorChannel) 映射（§2.2）', () {
    test('0x02 内部温度：float 25.5 → (temperature, internal)，落库 2550', () {
      final hex = _frame([
        _tlv(0x02, _float32(25.5)),
      ]);

      final result = _decode(hex);

      expect(result, hasLength(1));
      final m = result.single;
      expect(m.sensorType, SensorType.temperature);
      expect(m.channel, SensorChannel.internal);
      expect(m.key, const SensorKey(SensorType.temperature, SensorChannel.internal));
      expect(m.value, 2550); // 25.5 × storageScale(100)
      expect(m.formattedValue, '25.50');
      expect(m.configId, _configId);
      expect(m.timestamp, _timestamp);
    });

    test('0x04 外部温度：float 18.3 → (temperature, external)，落库 1830', () {
      final hex = _frame([
        _tlv(0x04, _float32(18.3)),
      ]);

      final result = _decode(hex);

      expect(result, hasLength(1));
      final m = result.single;
      expect(m.sensorType, SensorType.temperature);
      expect(m.channel, SensorChannel.external);
      expect(
        m.key,
        const SensorKey(SensorType.temperature, SensorChannel.external),
      );
      // 18.3 的 float32 实际为 18.299999237…，×100 后 round() 仍应为 1830
      expect(m.value, 1830);
      expect(m.formattedValue, '18.30');
    });

    test('0x03 / 0x05 湿度分别落到 internal / external 通道', () {
      // 同一帧内两路湿度：数值不同，便于识别「映射互换」这类错误
      final hex = _frame([
        _tlv(0x03, _float32(45.6)),
        _tlv(0x05, _float32(62.5)),
      ]);

      final result = _decode(hex);
      final byKey = _byKey(result);

      expect(result, hasLength(2));
      expect(
        byKey[SensorKey(SensorType.humidity, SensorChannel.internal)]?.value,
        4560, // 45.6 × 100
      );
      expect(
        byKey[SensorKey(SensorType.humidity, SensorChannel.external)]?.value,
        6250, // 62.5 × 100
      );
      // 两路湿度是两条独立记录，key 必须不同
      expect(result.map((m) => m.key).toSet(), hasLength(2));
    });

    test('0x01 CO2：uint16 800 → (co2, primary)，物理量 × scale(1) = 800', () {
      final hex = _frame([
        _tlv(0x01, _uint16(800)), // 0x0320
      ]);

      final result = _decode(hex);

      expect(result, hasLength(1));
      final m = result.single;
      expect(m.sensorType, SensorType.carbon_dioxide);
      expect(m.channel, SensorChannel.primary);
      expect(m.key, const SensorKey(SensorType.carbon_dioxide, SensorChannel.primary));
      // co2 的 storageScale = 1：统一口径「物理量 × storageScale」下仍是 800
      expect(m.value, 800);
      expect(m.formattedValue, '800');
    });
  });

  // ============================================================
  group('线格式与缩放口径统一（TLV Value 恒为物理量）', () {
    test('2 字节 uint16 也按「物理量 × storageScale」落库：0x02 温度 25 → 2500', () {
      // 当前固件 0x02 走 float，但协议约定 Value 恒为物理量：
      // 若将来某一路温度改用 2 字节整数上报，25 ℃ 必须落库 2500（显示 25.00），
      // 而不是按原值存 25（会显示成 0.25 ℃）。
      final hex = _frame([
        _tlv(0x02, _uint16(25)),
      ]);

      final m = _decode(hex).single;
      expect(
        m.key,
        const SensorKey(SensorType.temperature, SensorChannel.internal),
      );
      expect(m.value, 2500);
      expect(m.formattedValue, '25.00');
    });

    test('同一物理量两种线格式落库一致：float 25.0 与 uint16 25 都是 2500', () {
      final viaFloat = _decode(_frame([_tlv(0x04, _float32(25.0))])).single;
      final viaUint16 = _decode(_frame([_tlv(0x04, _uint16(25))])).single;

      expect(
        viaFloat.key,
        const SensorKey(SensorType.temperature, SensorChannel.external),
      );
      expect(viaUint16.key, viaFloat.key);
      expect(viaFloat.value, 2500);
      expect(viaUint16.value, viaFloat.value);
      expect(viaUint16.formattedValue, viaFloat.formattedValue);
    });

    test('scale = 1 的整数物理量：2 字节 / 4 字节两种线格式都不缩放', () {
      final viaUint16 = _decode(_frame([_tlv(0x01, _uint16(800))])).single;
      final viaFloat = _decode(_frame([_tlv(0x01, _float32(800.0))])).single;

      expect(viaUint16.value, 800);
      expect(viaFloat.value, 800);
    });

    test('2 字节 uint16 上限 65535 按物理量处理（scale = 1）', () {
      final m = _decode(_frame([_tlv(0x01, _uint16(65535))])).single;
      expect(m.value, 65535);
    });

    test('负数物理量只能走 4 字节 float：-5.5 → -550', () {
      // uint16 无符号，协议约定负数必须用 float；这里锁定 float 分支的负值处理
      final m = _decode(_frame([_tlv(0x02, _float32(-5.5))])).single;
      expect(m.value, -550);
      expect(m.formattedValue, '-5.50');
    });
  });

  // ============================================================
  group('一帧多记录（回归「两路温度互相覆盖」问题）', () {
    test('一帧同时含 0x02 + 0x04 → 2 条 Measurement 且 key 不同', () {
      // 落库时 device_latest 以 (config_id, sensor_type, sensor_channel) 为键，
      // 若两路都映射成 temperature:primary，这里就会只剩一条。
      final hex = _frame([
        _tlv(0x02, _float32(25.5)),
        _tlv(0x04, _float32(18.3)),
      ]);

      final result = _decode(hex);
      final byKey = _byKey(result);

      expect(result, hasLength(2));
      expect(result.every((m) => m.sensorType == SensorType.temperature), isTrue);
      expect(result.map((m) => m.key).toSet(), hasLength(2));

      expect(
        byKey[const SensorKey(SensorType.temperature, SensorChannel.internal)]
            ?.value,
        2550,
      );
      expect(
        byKey[const SensorKey(SensorType.temperature, SensorChannel.external)]
            ?.value,
        1830,
      );
    });

    test('一帧含全部 5 类记录 → 按映射表输出 5 条，顺序与帧内一致', () {
      final hex = _frame([
        _tlv(0x01, _uint16(800)),
        _tlv(0x02, _float32(25.5)),
        _tlv(0x03, _float32(45.6)),
        _tlv(0x04, _float32(18.3)),
        _tlv(0x05, _float32(62.5)),
      ]);

      final result = _decode(hex);

      expect(result, hasLength(5));
      expect(
        result.map((m) => m.key).toList(),
        const [
          SensorKey(SensorType.carbon_dioxide, SensorChannel.primary),
          SensorKey(SensorType.temperature, SensorChannel.internal),
          SensorKey(SensorType.humidity, SensorChannel.internal),
          SensorKey(SensorType.temperature, SensorChannel.external),
          SensorKey(SensorType.humidity, SensorChannel.external),
        ],
      );
      expect(result.map((m) => m.value).toList(), [800, 2550, 4560, 1830, 6250]);
      // TLV Count 逐条推进 offset，不能丢也不能重复
      expect(result.map((m) => m.key).toSet(), hasLength(5));
    });

    test('configId 与 Timestamp（大端 uint32）原样透传', () {
      final hex = _frame(
        [
          _tlv(0x01, _uint16(1200)),
        ],
        timestamp: 1700000000,
      );

      final m = _decode(hex, configId: 42).single;

      expect(m.configId, 42);
      expect(m.timestamp, 1700000000);
    });
  });

  // ============================================================
  group('非法帧与边界：返回空列表或安全跳过', () {
    test('未知 TypeId 被跳过，已知记录仍然解析', () {
      final hex = _frame([
        _tlv(0x7F, _float32(1.0)), // 映射表里没有 → 跳过
        _tlv(0x04, _float32(18.3)),
        _tlv(0xFF, _uint16(999)), // 同样未知
      ]);

      final result = _decode(hex);

      expect(result, hasLength(1));
      expect(result.single.key,
          const SensorKey(SensorType.temperature, SensorChannel.external));
      expect(result.single.value, 1830);
    });

    test('帧内记录全部未知 TypeId 时返回空列表', () {
      final hex = _frame([
        _tlv(0x10, _float32(99.9)),
      ]);

      expect(_decode(hex), isEmpty);
    });

    test('坏 CRC 返回空列表', () {
      final valid = _frame([
        _tlv(0x04, _float32(18.3)),
      ]);

      // 先确认合法帧确实能解出来，避免「构造失败也返回空」的假阳性
      expect(_decode(valid), hasLength(1));

      expect(_decode(_withBadCrc(valid)), isEmpty);
    });

    test('CRC 覆盖 Timestamp 与 TLV 区域：篡改任一字节都被拒绝', () {
      final valid = _frame([
        _tlv(0x02, _float32(25.5)),
      ]);

      // 篡改 Timestamp 的低字节（offset 5）→ CRC 不再匹配
      expect(_decode(_patchByte(valid, 5, 0x00)), isEmpty);

      // 篡改 TLV 值的首字节（offset 10）→ CRC 同样不匹配
      expect(_decode(_patchByte(valid, 10, 0x00)), isEmpty);
    });

    test('短帧（< 9 字节）一律返回空列表', () {
      expect(_decode(''), isEmpty); // 空 payload
      expect(_decode('AA55'), isEmpty); // 只有同步头
      expect(_decode('AA550000000000'), isEmpty); // 8 字节：差 1 字节到最小合法帧

      // 自检：完整帧长度为 15 字节，可正常解析
      final valid = _frame([
        _tlv(0x04, _float32(18.3)),
      ]);
      expect(valid.length ~/ 2, greaterThanOrEqualTo(9));
      expect(_decode(valid), hasLength(1));

      // 同一帧被截断到 8 字节 → 长度校验拦下
      expect(_decode(valid.substring(0, 16)), isEmpty);
    });

    test('非法同步头返回空列表（CRC 覆盖范围不含同步头）', () {
      final valid = _frame([
        _tlv(0x04, _float32(18.3)),
      ]);

      // 只改同步头，CRC 依然「正确」，必须靠同步头校验拦下
      expect(_decode(_patchByte(valid, 0, 0xBB)), isEmpty);
      expect(_decode(_patchByte(valid, 1, 0x56)), isEmpty);
      expect(_decode(_patchByte(_patchByte(valid, 0, 0x00), 1, 0x00)), isEmpty);
      // 对照：原始帧可正常解析
      expect(_decode(valid), hasLength(1));
    });

    test('空 TLV（Count = 0）返回空列表', () {
      final hex = _frame([], timestamp: 1700000000);
      expect(_decode(hex), isEmpty);
    });

    test('非法十六进制串（奇数位 / 非 hex 字符）返回空列表', () {
      expect(_decode('AA5500000000000'), isEmpty); // 奇数长度
      expect(_decode('ZZ5500000000000000'), isEmpty); // 非 hex
    });

    test('不支持的 Value 长度（非 2/4）跳过该记录，不影响后续记录', () {
      final hex = _frame([
        _tlv(0x02, [0x01, 0x02, 0x03]), // 3 字节 → 不支持，跳过
        _tlv(0x01, _uint16(800)), // 后续记录照常解析
      ]);

      final result = _decode(hex);

      expect(result, hasLength(1));
      expect(result.single.key, const SensorKey(SensorType.carbon_dioxide, SensorChannel.primary));
      expect(result.single.value, 800);
    });

    test('TLV 声明长度越界时中断，但保留此前已解析的记录', () {
      final hex = _frame([
        _tlv(0x04, _float32(18.3)),
        [0x03, 0x40], // 声明 64 字节却没有数据
      ]);

      final result = _decode(hex);

      expect(result, hasLength(1));
      expect(result.single.channel, SensorChannel.external);
      expect(result.single.value, 1830);
    });

    test('TLV Count 大于实际记录数时安全退出，不抛异常', () {
      final hex = _frame(
        [
          _tlv(0x01, _uint16(800)),
        ],
        tlvCount: 3,
      );

      final result = _decode(hex);

      expect(result, hasLength(1));
      expect(result.single.value, 800);
    });
  });
}
