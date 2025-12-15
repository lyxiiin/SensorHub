import 'package:sensor_hub/data/models/sensor_data_subclasses/sensor_data_co2.dart';

class QingPingCo2TemperatureHumidityDecoder {
  /// 解码青萍传感器数据

  /// 解码 0x85 类型数据（CO2、温度、湿度）
  SensorDataCo2 decode0x85BySensorDataCo2(List<int> value, String deviceName, int configId,int datetime) {
    final temp = bytesToInt(value.sublist(0, 2)); // 温度值（放大100倍）
    final humidity = bytesToInt(value.sublist(2, 4)); // 湿度值（放大100倍）
    final co2 = bytesToInt(value.sublist(4, 6)); // CO2值
    
    return SensorDataCo2(
      configId: configId,
      datetime: datetime,
      temperature: temp,
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
  int bytesToInt(List<int> bytes) {
    int result = 0;
    for (var i = bytes.length - 1; i >= 0; i--) {
      result = (result << 8) | (bytes[i] & 0xFF);
    }
    return result;
  }
}