import 'dart:typed_data';

import 'package:sensor_hub/data/dao/device_config_dao.dart';
import 'package:sensor_hub/data/services/sqlite_service.dart';
import '../decoders/qingping/qingping_co2_temperature_humidity_decoder.dart';
import '../models/device_config.dart';
import '../models/sensor_reading.dart';

class MqttRepository {
  static final MqttRepository _instance = MqttRepository.internal();
  factory MqttRepository() => _instance;
  MqttRepository.internal();

  SqliteService? _sqliteService;
  DeviceConfigDao? _configDao;
  
  // 初始化方法：由外部调用，传入依赖
  Future<void> init() async {
    _sqliteService = SqliteService();
    _configDao = DeviceConfigDao();

  }

  //插入一个新设备
  Future<int> insertDevice(DeviceConfig config) async {
    // 确保服务已初始化
    if (_sqliteService == null || _configDao == null) {
      await init();
    }
    
    await _configDao!.insert(config);
    final DeviceConfig? newConfig = await _configDao!.getByClientId(config.clientId);
    if(newConfig != null){
      await _sqliteService!.createDynamicTable(await _sqliteService!.database, "${newConfig.clientId}_${newConfig.configId}");
      return newConfig.configId!;
    }
    return -1;
  }

  //读取所有设备
  Future<List<DeviceConfig>> getLocalSavedDevices() async {
    final devices = await _configDao!.getAll();
    return devices;
  }

  Future<List<SensorReading>> decodeDate(DeviceConfig deviceConfig, Uint8List payload) async {
    final decode = QingPingCo2TemperatureHumidityDecoder();
    List<SensorReading> results = [];
    if (payload.length < 3) {
      return results;
    }
    final length = decode.combineLittleEndianAndToNum([payload[1], payload[2]]);

    switch (payload[0]) {
      case 0x41: // 实时数据报告
        // results.addAll(_decodeRealTimeReport(payload.sublist(3, 3 + length), deviceName, configId));
        break;
      case 0x42: // 统计数据报告
      // TODO: 实现统计数据解码
        break;
      case 0x43: // 历史数据报告
      // TODO: 实现历史数据解码
        break;
      case 0x44: // 事件数据报告
      // TODO: 实现事件数据解码
        break;
    }

    return results;
  }

}