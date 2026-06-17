import 'package:sensor_hub/data/dao/device_config_dao.dart';
import 'package:sensor_hub/data/services/sqlite_service.dart';
import 'package:sensor_hub/utils/app_logger.dart';
import '../models/device_config.dart';

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
      logI('插入设备成功: ${config.deviceName} (configId=${newConfig.configId})', tag: 'Repo');
      return newConfig.configId!;
    }
    logE('插入设备后未找到记录: ${config.deviceName}', tag: 'Repo');
    return -1;
  }

  ///删除设备
  Future<void> deleteDevice(String clientId, int? configId) async {
    // 确保服务已初始化
    if (_sqliteService == null || _configDao == null) {
      await init();
    }
    if(configId != null){
      await _configDao!.delete(configId);
      logI('删除设备: clientId=$clientId, configId=$configId', tag: 'Repo');
    }
  }

  //读取所有设备
  Future<List<DeviceConfig>> getLocalSavedDevices() async {
    final devices = await _configDao!.getAll();
    logD('读取本地设备列表: ${devices.length} 个', tag: 'Repo');
    return devices;
  }


}