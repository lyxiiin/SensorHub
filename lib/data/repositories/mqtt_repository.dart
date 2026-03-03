import 'package:sensor_hub/data/dao/device_config_dao.dart';
import 'package:sensor_hub/data/dao/qingping_sensor_state_dao.dart';
import 'package:sensor_hub/data/dao/sensor_data_co2_dao.dart';
import 'package:sensor_hub/data/services/sqlite_service.dart';
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
      final sensorDao = SensorDataCo2Dao();
      await sensorDao.createTable("${newConfig.clientId}_${newConfig.configId}");
      final sensorStateDao = QingPingSensorStateDao();
      await sensorStateDao.createTable("qingping_state_${newConfig.configId!}");
      return newConfig.configId!;
    }
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
      final sensorDao = SensorDataCo2Dao();
      sensorDao.deleteTable("${clientId}_$configId");
      final sensorStateDao = QingPingSensorStateDao();
      await sensorStateDao.deleteTable("qingping_state_$configId");
    }
  }

  //读取所有设备
  Future<List<DeviceConfig>> getLocalSavedDevices() async {
    final devices = await _configDao!.getAll();
    return devices;
  }


}