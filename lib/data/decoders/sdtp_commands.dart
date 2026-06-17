import 'dart:typed_data';
import 'package:sensor_hub/utils/app_logger.dart';

/// SDTP 下行命令类型
enum SdtpCommandType {
  /// 获取当前传感器数据
  fetchData(cmdId: 0x01),

  /// 重启设备
  restart(cmdId: 0x02),

  /// OTA 升级
  startOta(cmdId: 0x03),

  /// 设置数据上报间隔（秒）
  setReportInterval(cmdId: 0x10),

  /// 设置设备名称
  setDeviceName(cmdId: 0x11);

  const SdtpCommandType({required this.cmdId});

  /// 命令标识字节
  final int cmdId;
}

/// SDTP 下行帧编码器
///
/// 帧结构: [0xAA 0x55] [cmdId] [params...] [CRC8]
class SdtpFrame {
  SdtpFrame._();

  static const int _syncHi = 0xAA;
  static const int _syncLo = 0x55;

  // ============================================================
  // 无参命令 —— 直接传枚举即可
  // ============================================================

  /// 获取当前传感器数据
  static List<int> fetchData() =>
      _build(SdtpCommandType.fetchData, const []);

  /// 重启设备
  static List<int> restart() =>
      _build(SdtpCommandType.restart, const []);

  /// OTA 升级
  static List<int> startOta() =>
      _build(SdtpCommandType.startOta, const []);

  // ============================================================
  // 带参命令 —— 传入枚举 + 具体参数
  // ============================================================

  /// 设置数据上报间隔
  ///
  /// [intervalSec] 上报间隔，单位：秒（uint16，范围 1~65535）
  static List<int> setReportInterval(int intervalSec) {
    final params = ByteData(2)..setUint16(0, intervalSec, Endian.big);
    return _build(SdtpCommandType.setReportInterval, params.buffer.asUint8List());
  }

  /// 设置设备名称
  ///
  /// [name] 设备名称，最长 32 字节
  static List<int> setDeviceName(String name) {
    final bytes = name.codeUnits;
    if (bytes.length > 32) {
      logW('设备名称超过 32 字节限制: ${bytes.length} 字节', tag: 'SDTP');
      throw ArgumentError('设备名称不能超过 32 字节');
    }
    return _build(SdtpCommandType.setDeviceName, <int>[bytes.length, ...bytes]);
  }

  // ============================================================
  // 通用帧构建
  // ============================================================

  /// 构建完整下行帧: [AA 55] [cmdId] [params...] [CRC8]
  static List<int> _build(SdtpCommandType type, List<int> params) {
    final frame = <int>[_syncHi, _syncLo, type.cmdId, ...params];
    frame.add(_crc8(frame, 2, frame.length));
    return frame;
  }

  /// CRC-8 校验（多项式 0x07，初始值 0x00）
  static int _crc8(List<int> data, int start, int end) {
    int crc = 0x00;
    for (int i = start; i < end; i++) {
      crc ^= data[i];
      for (int b = 0; b < 8; b++) {
        crc = (crc & 0x80) != 0 ? ((crc << 1) ^ 0x07) & 0xFF : (crc << 1) & 0xFF;
      }
    }
    return crc;
  }
}
