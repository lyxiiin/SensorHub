import 'dart:developer';
import 'dart:typed_data';

import 'package:sensor_hub/data/models/sensor_data_subclasses/sensor_data_co2.dart';
import 'package:sensor_hub/data/models/sensor_data_subclasses/sensor_data_co2_pm25_pm10_voc_noise_lux.dart';
import 'package:sensor_hub/data/models/sensor_data_subclasses/sensor_data_basic.dart';
import 'package:sensor_hub/data/models/sensor_data_subclasses/sensor_data_external_co2_or_temp.dart';

import '../../models/sensor_data_subclasses/sensor_data_atmos_pressure.dart';

class QingPingCo2TemperatureHumidityDecoder {
  static final QingPingCo2TemperatureHumidityDecoder _instance = QingPingCo2TemperatureHumidityDecoder.internal();
  factory QingPingCo2TemperatureHumidityDecoder() => _instance;
  QingPingCo2TemperatureHumidityDecoder.internal();


  Future<void> decodeDataBy0x44({
    required int length,
    required Uint8List payload,
    required deviceName
  }) async {
    String logText = "0x44-- ";
    int index = 5;
    while(index < length - 2){
      final dataType = payload[index];
      final len = bytesToInt([payload[index+1],payload[index+2]]);
      switch(dataType){
        case 0x69:
          final sensorType = payload[index + 5];
          final alertValue = bytesToInt(payload.sublist(index+15,index+19));
          break;
        case 0x85:
          final datetime = bytesToInt(payload.sublist(index+3,index+7));
          int value = 0;
          switch(payload[index+8]){
            case 0x02:
              final data = decode0x85BySensorData0x02(payload.sublist(index+8,index+3+len), deviceName, 1, datetime);
              break;
          }
          break;
      }
      index += len+2;
    }
  }

  void decodeDataBy0x35(int length, Uint8List payload){
    String logText = "0x35-- ";
    int index = 5;
    while(length < length-2){
      final dataType = payload[index];
      final len = bytesToInt([payload[index+1], payload[index+2]]);
      switch(dataType) {
        case 0x15:  // 时间戳
          final time = bytesToInt(payload.sublist(index+3,index+3+len));
          // log("$dataType-时间戳: $time  时间：${DateTime.fromMillisecondsSinceEpoch(time * 1000)}");
          logText += "  $dataType-时间戳: $time  时间：${DateTime.fromMillisecondsSinceEpoch(time * 1000)}";
        case 0x1D:  // 断开设备连接
        // log("断开设备连接?: ${payload[index+3] == 0 ? "还有数据未发送完" : "数据已发送完"}");
          logText += "  断开设备连接?: ${payload[index+3] == 0 ? "还有数据未发送完" : "数据已发送完"}";
          break;
        case 0x38:  // 产品ID
          final id = bytesToInt(payload.sublist(index+3,index+3+len));
          // log("$dataType-产品ID: $id");
          logText += "  产品ID: $id";
          break;
      }
      index += 3+len;
    }
    log(logText);
  }

  /// 解码 0x85 类型数据（温度）
  SensorDataBasic decode0x85BySensorData0x02(List<int> value, String deviceName, int configId,int datetime) {
    final temp = bytesToInt(value.sublist(0, 2)); // 温度值（放大10倍）

    return SensorDataBasic(
      configId: configId,
      datetime: datetime,
      temperature: temp,
      humidity: -1,
    );
  }

  /// 解码 0x85 类型数据（CO2、温度、湿度）
  SensorDataCo2 decode0x85BySensorData0x04(List<int> value, String deviceName, int configId,int datetime) {
    final temp = bytesToInt(value.sublist(0, 2)); // 温度值（放大10倍）
    final humidity = bytesToInt(value.sublist(2, 4)); // 湿度值（放大10倍）
    final co2 = bytesToInt(value.sublist(4, 6)); // CO2值
    
    return SensorDataCo2(
      configId: configId,
      datetime: datetime,
      temperature: temp,
      humidity: humidity,
      co2: co2,
    );
  }
  /// 解码 0x85 类型数据（气压、温度、湿度）
  SensorDataAtmosPressure decode0x85BySensorData0x03(List<int> value, String deviceName, int configId,int datetime) {
    final temp = bytesToInt(value.sublist(0, 2)); // 温度值（放大10倍）
    final humidity = bytesToInt(value.sublist(2, 4)); // 湿度值（放大10倍）
    final atmosPressure = bytesToInt(value.sublist(4, 6)); // 气压值（放大10倍）

    return SensorDataAtmosPressure(
      configId: configId,
      datetime: datetime,
      temperature: temp,
      humidity: humidity,
      atmosPressure: atmosPressure,
    );
  }
  /// 解码 0x85 类型数据（温度、湿度、外接温度或二氧化碳）
  SensorDataExternalCo2OrTemp decode0x85BySensorData0x06(List<int> value, String deviceName, int configId,int datetime, int dataType) {
    final temp = bytesToInt(value.sublist(0, 2)); // 温度值（放大10倍）
    final humidity = bytesToInt(value.sublist(2, 4)); // 湿度值（放大10倍）
    final external = bytesToInt(value.sublist(4, 6));
    if(dataType == 0x06){
      return SensorDataExternalCo2OrTemp(
        configId: configId,
        datetime: datetime,
        temperature: temp,
        humidity: humidity,
        externalCo2: -1,
        externalTemperature: external,
      );
    }
    return SensorDataExternalCo2OrTemp(
      configId: configId,
      datetime: datetime,
      temperature: temp,
      humidity: humidity,
      externalCo2: external,
      externalTemperature: -1,
    );
  }


  /// 解码 0x85 类型数据（CO2、温度、湿度）
  SensorDataCo2Pm25Pm10VocNoiseLux decode0x85BySensorData0x10(List<int> value, String deviceName, int configId,int datetime) {
    final temp = toSignedInt16(value.sublist(0, 2)); // 温度值（放大10倍）
    final humidity = bytesToInt(value.sublist(2, 4)); // 湿度值（放大10倍）
    final co2 = bytesToInt(value.sublist(4, 6));
    final pm25 = bytesToInt(value.sublist(6, 8));
    final pm10 = bytesToInt(value.sublist(8, 10));
    final voc = bytesToInt(value.sublist(10, 12));
    final noise = bytesToInt(value.sublist(12, 14));
    final lux = bytesToInt(value.sublist(14));

    return SensorDataCo2Pm25Pm10VocNoiseLux(
      configId: configId,
      datetime: datetime,
      temperature: temp,
      humidity: humidity,
      co2: co2,
      pm25: pm25,
      pm10: pm10,
      voc: voc,
      noise: noise,
      lux: lux,
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

  ///有符号数转换
  int toSignedInt8(int byte) {
    if (byte < 0 || byte > 255) {
      throw ArgumentError('Byte must be in range 0..255');
    }
    // 如果最高位（bit 7）为 1，说明是负数
    if (byte >= 128) {
      return byte - 256; // 或者 return (byte << 24) >> 24;
    }
    return byte;
  }

  int toSignedInt16(List<int> data){
    Uint8List bytes = Uint8List.fromList(data);
    int value = ByteData.sublistView(bytes).getInt16(0, Endian.little);
    return value;
  }

}