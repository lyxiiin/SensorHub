import 'dart:typed_data';
import 'package:sensor_hub/data/models/measurement.dart';
import 'package:sensor_hub/data/models/sensor_type.dart';
import 'package:sensor_hub/utils/app_logger.dart';

/// SDTP — 传感器数据传输协议解码器
///
/// 帧结构:
// ┌──────────┬──────────┬───────────┬───────────┬───────┬──────────────────┬──────┐
// │  SYNC_HI │ SYNC_LO  │ Timestamp │ TLV Count │ Flags │   TLV Records    │ CRC8 │
// │  0xAA    │  0x55    │  4 bytes  │  1 byte   │ 1 B   │    variable      │1 byte│
// └──────────┴──────────┴───────────┴───────────┴───────┴──────────────────┴──────┘
///
/// 输入: MQTT 收到的十六进制字符串，如 "AA550000000103010002..."
/// 输出: List<Measurement>
abstract class PayloadDecoder {
  // ============================================================
  // SDTP Type ID → SensorType 映射表
  // 新增传感器：在此 Map 中添加一行即可
  // ============================================================
  static final Map<int, SensorType> _typeIdToSensorType = {
    0x01: SensorType.co2,         // SCD41 CO2 (uint16)
    0x02: SensorType.temperature, // SCD41 温度 (float)
    0x03: SensorType.humidity,    // SCD41 湿度 (float)
    0x04: SensorType.temperature, // SHT40 温度 (float)
    0x05: SensorType.humidity,    // SHT40 湿度 (float)
  };

  // ============================================================
  // 公开接口：解码十六进制字符串 → List<Measurement>
  // ============================================================
  static List<Measurement> decode(
    String hexPayload, {
    required int configId,
  }) {
    // 步骤1: 十六进制字符串 → 字节数组
    final bytes = _hexToBytes(hexPayload);
    if (bytes.length < 9) {
      logW('帧长度不足 (${bytes.length} < 9)', tag: 'SDTP');
      return [];
    }

    // 步骤2: 验证同步头
    if (bytes[0] != 0xAA || bytes[1] != 0x55) {
      logW('同步头校验失败 (期望 AA55, 实际 '
          '${bytes[0].toRadixString(16).padLeft(2, '0').toUpperCase()}'
          '${bytes[1].toRadixString(16).padLeft(2, '0').toUpperCase()})', tag: 'SDTP');
      return [];
    }

    // 步骤3: 读取 Timestamp（大端序 uint32）
    final timestamp = (bytes[2] << 24) |
        (bytes[3] << 16) |
        (bytes[4] << 8) |
        bytes[5];

    // 步骤4: 读取 TLV Count
    final tlvCount = bytes[6];

    // bytes[7] = Flags: Bit0=HIST(历史数据), Bit1=FIRST(首帧)，当前不存储

    // 步骤5: CRC8 校验（覆盖范围：offset 2 到 CRC 字节之前）
    final expectedCrc = bytes[bytes.length - 1];
    final actualCrc = _crc8(bytes, 2, bytes.length - 1);
    if (expectedCrc != actualCrc) {
      logW('CRC8 校验失败 (期望 '
          '${expectedCrc.toRadixString(16).padLeft(2, '0')}, '
          '实际 ${actualCrc.toRadixString(16).padLeft(2, '0')})', tag: 'SDTP');
      return [];
    }

    // 步骤6: 解析 TLV 记录
    final results = <Measurement>[];
    int offset = 8; // TLV 区域起始位置

    for (int i = 0; i < tlvCount; i++) {
      if (offset + 2 > bytes.length - 1) break; // 至少需要 Type + Length

      final typeId = bytes[offset];
      final valueLen = bytes[offset + 1];
      offset += 2;

      if (offset + valueLen > bytes.length - 1) {
        logW('TLV 记录 $i Value 越界 (offset=$offset, len=$valueLen, '
            'available=${bytes.length - 1 - offset})', tag: 'SDTP');
        break;
      }

      final sensorType = _typeIdToSensorType[typeId];
      if (sensorType == null) {
        logD('未知传感器类型 ID=0x${typeId.toRadixString(16)} (length=$valueLen)，跳过', tag: 'SDTP');
        offset += valueLen;
        continue;
      }

      // 步骤7: 根据 Value 长度解析
      final int storedValue;
      if (valueLen == 2) {
        // uint16 大端序（CO2 等整数类型）
        storedValue = (bytes[offset] << 8) | bytes[offset + 1];
      } else if (valueLen == 4) {
        // float IEEE 754 大端序（温度、湿度等浮点类型）
        final double floatValue = _parseFloat32(bytes, offset);
        storedValue = (floatValue * sensorType.storageScale).round();
      } else {
        logW('不支持的 Value 长度 $valueLen (typeId=0x${typeId.toRadixString(16)})，跳过', tag: 'SDTP');
        offset += valueLen;
        continue;
      }

      results.add(Measurement(
        configId: configId,
        sensorType: sensorType,
        value: storedValue,
        timestamp: timestamp,
      ));

      offset += valueLen;
    }

    return results;
  }

  // ============================================================
  // 内部工具函数
  // ============================================================

  /// 十六进制字符串 → 字节列表
  /// "AA550000..." → [0xAA, 0x55, 0x00, 0x00, ...]
  static List<int> _hexToBytes(String hex) {
    if (hex.length % 2 != 0) return [];
    final result = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      final byte = int.tryParse(hex.substring(i, i + 2), radix: 16);
      if (byte == null) return [];
      result.add(byte);
    }
    return result;
  }

  /// CRC-8 校验
  /// 多项式: 0x07 (x⁸ + x² + x¹ + 1)
  /// 初始值: 0x00
  /// [start]: 校验起始偏移（含）
  /// [end]: 校验结束偏移（不含）
  static int _crc8(List<int> data, int start, int end) {
    int crc = 0x00;
    for (int i = start; i < end; i++) {
      crc ^= data[i];
      for (int b = 0; b < 8; b++) {
        if ((crc & 0x80) != 0) {
          crc = ((crc << 1) ^ 0x07) & 0xFF;
        } else {
          crc = (crc << 1) & 0xFF;
        }
      }
    }
    return crc;
  }

  /// 将 4 字节大端序 IEEE 754 单精度浮点数转为 double
  static double _parseFloat32(List<int> bytes, int offset) {
    final byteData = ByteData(4);
    for (int i = 0; i < 4; i++) {
      byteData.setUint8(i, bytes[offset + i]);
    }
    return byteData.getFloat32(0, Endian.big);
  }
}