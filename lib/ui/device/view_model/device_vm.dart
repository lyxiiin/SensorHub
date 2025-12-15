import 'dart:developer';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:sensor_hub/data/dao/sensor_data_co2_dao.dart';
import 'package:sensor_hub/data/decoders/qingping/qingping_co2_temperature_humidity_decoder.dart';
import 'package:sensor_hub/data/models/sensor_data.dart';
import 'package:sensor_hub/data/models/sensor_data_subclasses/sensor_data_co2.dart';
import 'package:sensor_hub/data/repositories/mqtt_repository.dart';
import 'package:sensor_hub/data/dao/device_config_dao.dart';
import 'package:sensor_hub/data/models/device_config.dart';
import 'package:sensor_hub/data/services/mqtt_service.dart';

class DeviceVM extends ChangeNotifier{
  late final MqttRepository _mqttRepository;
  late final DeviceConfigDao _configDao;
  int deviceCount = 0;
  final Map<String, MqttService> _services = {};
  final Map<String, List<SensorData>> serviceCard = {};
  bool _initEd = false;
  bool _initializing = false;

  Future<void> initData() async {
    // 防止重复初始化
    if (_initializing) return;
    _initializing = true;

    try {
      _mqttRepository = MqttRepository();
      _configDao = DeviceConfigDao();
      await _mqttRepository.init();

      // 设置5秒超时，避免阻塞界面
      await connectAllSavedDevices().timeout(
        Duration(seconds: 5),
        onTimeout: () {
          log('设备连接超时，将在后台继续连接');
          // 超时后在后台继续连接
          connectAllSavedDevices().catchError((e) {
            log('后台连接设备失败: $e');
          });
          return Future.value();
        },
      );
    } catch (e) {
      log('初始化过程中发生错误: $e');
    } finally {
      _initializing = false;
      if(_initEd){
        notifyListeners();
      }
    }
  }

  // 使用 host:port 作为唯一 key
  MqttService getService(String host, int port) {
    final key = '$host:$port';
    return _services.putIfAbsent(key, () => MqttService());
  }

  void removeService(String host, int port) {
    final key = '$host:$port';
    final service = _services.remove(key);
    service?.disconnect();
  }

  Future<void> connectAllSavedDevices() async {
    final devicesConfig = await _mqttRepository.getLocalSavedDevices();
    log("初始化：-读取到 ${devicesConfig.length} 个设备");
    for(var i=0;i<devicesConfig.length;i++){
      await connectDeviceToMqtt(devicesConfig[i]);
      final sensorDao = SensorDataCo2Dao();
      // 修复类型转换错误：确保configId不为空再转换为字符串
      if (devicesConfig[i].configId != null) {
        final String tableName = "${devicesConfig[i].clientId}_${devicesConfig[i].configId}";
        serviceCard[devicesConfig[i].deviceName] = await sensorDao.queryAll(tableName);
      } else {
        log('警告: 设备 ${devicesConfig[i].deviceName} 的 configId 为空');
      }
    }
    _initEd = true;
  }

  Future<void> connectDeviceToMqtt(DeviceConfig deviceConfig) async {
    final broker1 = getService(deviceConfig.broker, deviceConfig.port);
    await broker1.connect(
      host: deviceConfig.broker,
      port: deviceConfig.port,
      clientId: deviceConfig.clientId,
      username: deviceConfig.username,
      password: deviceConfig.password,
    );
    broker1.subscribe(deviceConfig.upTopic, (topic, payload) async {
      log("收到消息: $payload");
      final newConfig = await _configDao.getByClientId(deviceConfig.clientId);
      if(newConfig != null){
        await _handleData(
          deviceConfig: newConfig,
          payload: Uint8List.fromList(payload),
        );
      }
      notifyListeners();
    });
  }


  /// 添加设备
  Future<bool> addDevice({
    required String sensorType,
    required String name,
    required String broker,
    required int port,
    required String mac,
    required String upTopic,
    required String downTopic,
    required String username,
    required String password,
  }) async {
    try{
      final String clientId = "qingping_${mac.replaceAll(':', '_')}";
      final DeviceConfig deviceConfig = DeviceConfig(
        broker: broker,
        deviceName: name,
        port: port,
        clientId: clientId,
        upTopic: upTopic,
        downTopic: downTopic,
        username: username,
        password: password,
      );
      final configId = await _mqttRepository.insertDevice(deviceConfig);
      final broker1 = getService(deviceConfig.broker, deviceConfig.port);
      await broker1.connect(
        host: deviceConfig.broker,
        port: deviceConfig.port,
        clientId: deviceConfig.clientId,
        username: deviceConfig.username,
        password: deviceConfig.password,
      );
      serviceCard[deviceConfig.deviceName] = [];

      // 获取当前时间
      final now = DateTime.now();
      final timestampInSeconds = roundDownToHalfHour(now).millisecondsSinceEpoch ~/ 1000;

      // 根据传感器类型创建
      switch(sensorType){
        case "青萍二氧化碳和温湿度检测仪":
          final SensorDataCo2Dao sensorDataCo2Dao = SensorDataCo2Dao();
          await  sensorDataCo2Dao.insert(
            "${deviceConfig.clientId}_$configId",
            SensorDataCo2(configId: configId, datetime: timestampInSeconds, temperature: 255, humidity: 500, co2: 400),
          );
          serviceCard[deviceConfig.deviceName] = await sensorDataCo2Dao.queryAll("${deviceConfig.clientId}_${configId.toString()}");
          break;
      }

      broker1.subscribe(deviceConfig.upTopic, (topic, payload) async {
        final newConfig = await _configDao.getByClientId(deviceConfig.clientId);
        if(newConfig != null){
          await _handleData(
            deviceConfig: newConfig,
            payload: Uint8List.fromList(payload),
          );
        }
      });
      return true;
    } catch (e) {
      log('添加设备失败: $e');
      return false;
    }finally{
      notifyListeners();
    }
  }
  //二氧化碳与温湿度
  Future<void> _handleData({
    required DeviceConfig deviceConfig,
    required Uint8List payload,
  }) async {
    try{
      log("开始解码");
      final decode = QingPingCo2TemperatureHumidityDecoder();
      if (payload.length < 5) {
        return;
      }
      final length = decode.combineLittleEndianAndToNum([payload[3], payload[4]]);
      log("数据长度：${length.toString()}");
      int index = 5;
      switch (payload[2]) {
        case 0x41: // 实时数据报告
          while(index < length - 2){
            final dataType = payload[index];
            final len = decode.combineLittleEndianAndToNum([payload[index+1], payload[index+2]]);
            switch(dataType) {
              case 0x85:
                final datetime = decode.bytesToInt(payload.sublist(index+3,index+7));
                final sensorType = payload[index+7];
                switch(sensorType){
                  case 0x01:
                  // ToDO
                    break;
                  case 0x02:
                  // ToDO
                    break;
                  case 0x03:
                  // ToDO
                    break;
                  case 0x04:
                    final data = decode.decode0x85BySensorDataCo2(
                      payload.sublist(index+8,index+15),
                      deviceConfig.deviceName,
                      deviceConfig.configId!, // 确保configId不为空
                      datetime,
                    );
                    log("id:${data.configId} datetime: ${data.datetime} co2:${data.co2} temp: ${data.temperature} humi:${data.humidity}");
                    final sensorDataCo2Dao = SensorDataCo2Dao();
                    serviceCard[deviceConfig.deviceName]?.add(data);
                    // 确保configId不为空再转换为字符串
                    if (deviceConfig.configId != null) {
                      await sensorDataCo2Dao.insert("${deviceConfig.clientId}_${deviceConfig.configId.toString()}",data);
                    }
                }
            }
            index += len+3;
          }
          break;
        case 0x42: // 历史数据上报
        // TODO: 实现历史数据上报

          break;
        case 0x43: // 临时数据上报
        // TODO: 实现历史数据解码
          break;
        case 0x44: // 报警信息上传
        // TODO: 实现事件数据解码
          break;
      }
    } catch (e) {
      log('解码传感器数据失败: $e');
    }
  }

  /// 时间戳转换
  int getMinutesDifference(int timestampSec) {
    final past = DateTime.fromMillisecondsSinceEpoch(timestampSec * 1000);
    final now = DateTime.now();
    return now.difference(past).inMinutes;
  }


  /// 主动上发命令获取当前传感器数据
  Future<void> fetchDataFromServer({
    required String broker,
    required int port,
    required String downTopic,
    required String username,
    required String password,
  }) async {
    try{
      final String clientId = "qingping_down_port";
      final broker1 = getService(broker, port);
      await broker1.connect(
        host: broker,
        port: port,
        clientId: clientId,
        username: username,
        password: password,
      );
    }catch(e){
      log('发送命令失败: $e');
    } finally{

    }
  }

  /// 将时间转为上一个整半小时
  DateTime roundDownToHalfHour(DateTime dt) {
    final minutes = dt.minute;
    final targetMinutes = minutes >= 30 ? 30 : 0;
    return DateTime(
      dt.year,
      dt.month,
      dt.day,
      dt.hour,
      targetMinutes,
      0, // 秒
      0, // 毫秒
      0, // 微秒（Dart 中 DateTime 精度到毫秒，但构造函数保留此参数）
    );
  }

}