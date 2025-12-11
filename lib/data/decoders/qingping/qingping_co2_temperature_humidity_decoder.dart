import 'dart:typed_data';

import '../../models/sensor_reading.dart';

class QingPingCo2TemperatureHumidityDecoder {
  /// 解码青萍传感器数据

  /// 解码 0x85 类型数据（CO2、温度、湿度）
  SensorReading decode0x85Data(List<int> value, String deviceName, String configId) {
    final datetime = _bytesToInt(value.sublist(0, 4));
    final temp = _bytesToInt(value.sublist(5, 7)); // 温度值（放大100倍）
    final humidity = _bytesToInt(value.sublist(7, 9)); // 湿度值（放大100倍）
    final co2 = _bytesToInt(value.sublist(9, 11)); // CO2值
    
    return SensorReading(
      configId: configId,
      name: deviceName,
      datetime: datetime,
      temp: temp,
      humidity: humidity,
      co2: co2,
    );
  }

  /// 将小端序字节数组转换为整数
  int combineLittleEndianAndToNum(List<int> bytes) {
    int result = 0;
    for (var i = bytes.length - 1; i >= 0; i--) {
      result = (result << 8) | (bytes[i] & 0xFF);
    }
    return result;
  }

  /// 将字节数组转换为整数（小端序）
  int _bytesToInt(List<int> bytes) {
    int result = 0;
    for (var i = bytes.length - 1; i >= 0; i--) {
      result = (result << 8) | (bytes[i] & 0xFF);
    }
    return result;
  }
}