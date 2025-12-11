import 'dart:developer';
import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sensor_hub/data/decoders/qingping/qingping_co2_temperature_humidity_decoder.dart';
import 'package:sensor_hub/data/models/sensor_reading.dart';
import 'package:sensor_hub/data/repositories/mqtt_repository.dart';
import 'package:sensor_hub/data/dao/sensor_reading_dao.dart';

import '../../../data/dao/device_config_dao.dart';
import '../../../data/models/device_config.dart';
import '../../../data/services/mqtt_service.dart';

class DeviceVM extends ChangeNotifier{
  late final MqttRepository _mqttRepository;
  late final SensorReadingDao _sensorReadingDao;
  late final DeviceConfigDao _configDao;
  int deviceCount = 0;
  final Map<String, MqttService> _services = {};
  Map<String, List<SensorReading>> serviceCard = {};
  final QingPingCo2TemperatureHumidityDecoder _decoder = QingPingCo2TemperatureHumidityDecoder();
  bool _initEd = false;
  bool _initializing = false;

  Future<void> initData() async {
    // 防止重复初始化
    if (_initializing) return;
    _initializing = true;

    try {
      _mqttRepository = MqttRepository();
      _sensorReadingDao = SensorReadingDao();
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
    for(var i=0;i<devicesConfig.length;i++){
      await connectDeviceToMqtt(devicesConfig[i]);
      serviceCard[devicesConfig[i].deviceName] = await _sensorReadingDao.queryAll("${devicesConfig[i].clientId}_${devicesConfig[i].configId}");
      log("serviceCard $i :${serviceCard[devicesConfig[i].deviceName]?.length}");
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
    broker1.subscribe(deviceConfig.topic, (topic, payload) async {
      log("收到消息: $payload");
      final newConfig = await _configDao.getByClientId(deviceConfig.clientId);
      if(newConfig != null){
        final data = await _handleCo2AndTempHumidityData(newConfig, Uint8List.fromList(payload));
        if(data.isNotEmpty){
          serviceCard[newConfig.deviceName]?.addAll(data);
        }
      }
      final len = serviceCard[newConfig?.deviceName]?.length;
      log("CurrentData: $len");
      notifyListeners();
    });
  }



  Future<bool> addDevice({
    required String sensorType,
    required String name,
    required String broker,
    required int port,
    required String mac,
    required String topic,
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
        topic: topic,
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

      broker1.subscribe(deviceConfig.topic, (topic, payload) async {
        log("收到消息: $payload");
        final newConfig = await _configDao.getByClientId(deviceConfig.clientId);
        if(newConfig != null){
          final data = await _handleCo2AndTempHumidityData(newConfig, Uint8List.fromList(payload));
          if(data.isNotEmpty){
            serviceCard[newConfig.deviceName]?.addAll(data);
          }
        }
        notifyListeners();
      });
      return true;
    } catch (e) {
      log('添加设备失败: $e');
      return false;
    }
  }
  //二氧化碳与温湿度
  Future<List<SensorReading>> _handleCo2AndTempHumidityData(DeviceConfig deviceConfig, Uint8List payload) async {
    try{
      log("开始解码");
      log("收到消息: $payload");
      final decode = QingPingCo2TemperatureHumidityDecoder();
      List<SensorReading> results = [];
      if (payload.length < 5) {
        return [];
      }
      final length = decode.combineLittleEndianAndToNum([payload[3], payload[4]]);
      log("数据长度：${length.toString()}");
      switch (payload[2]) {
        case 0x41: // 实时数据报告
          int index = 5;
          while(index < length - 2){
            if(index + 2 >= length){
              break;
            }
            final dataType = payload[index];
            final len = decode.combineLittleEndianAndToNum([payload[index + 1], payload[index + 2]]);
            if(len <= 0 || index + 3 + len > length){
              break;
            }
            switch(dataType) {
              case 0x85:
                final data = decode.decode0x85Data(payload.sublist(index+3,index+3+len), deviceConfig.deviceName, deviceConfig.configId.toString());
                log("co2 == ${data.co2}   temp == ${data.temp}  humidity == ${data.humidity}");
                results.add(data);
                await _sensorReadingDao.insert("${deviceConfig.clientId}_${deviceConfig.configId}", data);
                break;
            }
            index += (len + 3);
          }
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

    } catch (e) {
      log('解码传感器数据失败: $e');
      return [];
    }
  }

  //时间戳转换
  int getMinutesDifference(int timestampSec) {
    final past = DateTime.fromMillisecondsSinceEpoch(timestampSec * 1000);
    final now = DateTime.now();
    return now.difference(past).inMinutes;
  }


  Map<String,String> dataToMap(SensorReading data) {
    Map<String,String> res = {};
    res['temp'] = (data.temp / 10).toString();
    res['humidity'] = (data.humidity / 10).toString();
    res['co2'] = data.co2.toString();
    return res;
  }

}