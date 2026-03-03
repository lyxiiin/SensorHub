import 'dart:developer';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:sensor_hub/data/dao/qingping_sensor_state_dao.dart';
import 'package:sensor_hub/data/dao/sensor_data_atmos_pressure_dao.dart';
import 'package:sensor_hub/data/dao/sensor_data_co2_dao.dart';
import 'package:sensor_hub/data/dao/sensor_data_co2_pm25_pm10_voc_noise_lux_dao.dart';
import 'package:sensor_hub/data/dao/sensor_data_basic_dao.dart';
import 'package:sensor_hub/data/dao/sensor_data_external_co2_or_temp_dao.dart';
import 'package:sensor_hub/data/decoders/qingping/qingping_co2_temperature_humidity_decoder.dart';
import 'package:sensor_hub/data/models/sensor_data.dart';
import 'package:sensor_hub/data/repositories/mqtt_repository.dart';
import 'package:sensor_hub/data/dao/device_config_dao.dart';
import 'package:sensor_hub/data/models/device_config.dart';
import 'package:sensor_hub/data/services/mqtt_service.dart';

class DeviceVM with ChangeNotifier{
  late final MqttRepository _mqttRepository;
  late final DeviceConfigDao _configDao;
  int deviceCount = 0;
  final Map<String, MqttService> _services = {};
  final Map<String, List<SensorData>> sensorCard = {};
  bool isLoading = false;
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

  Future<void> publishMessage() async {
    final tt = getService("8.163.13.154", 1883);
    final temp = [0x43, 0x47, 0x3D, 0x05, 0x00, 0x42, 0x02, 0x00, 0x02, 0x00, 0x12, 0x01];
    await tt.publish(topic: "qingping/58:2D:34:70:E3:46/down", payload: temp);
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
    notifyListeners();
  }

  Future<void> connectAllSavedDevices() async {
    final devicesConfig = await _mqttRepository.getLocalSavedDevices();
    log("初始化：-读取到 ${devicesConfig.length} 个设备");
    
    // 先遍历所有设备，从数据库加载历史数据，初始化 sensorCard
    for (final deviceConfig in devicesConfig) {
      final sensorDao = SensorDataCo2Dao();
      if (deviceConfig.configId != null) {
        final String tableName = "${deviceConfig.clientId}_${deviceConfig.configId.toString()}";
        // 确保configId不为空时才创建表名并查询
        sensorCard[deviceConfig.deviceName] = await sensorDao.queryAll(tableName);
      } else {
        log('警告: 设备 ${deviceConfig.deviceName} 的 configId 为空，无法加载历史数据');
        // 即使 configId 为空，也初始化一个空列表，避免后续操作出现 null 错误
        sensorCard[deviceConfig.deviceName] = [];
      }
    }

    // 再遍历所有设备，建立 MQTT 连接
    for (final deviceConfig in devicesConfig) {
      await connectDeviceToMqtt(deviceConfig);
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

    // 检查是否已经存在对该主题的订阅，如果有则先取消
    if (broker1.isSubscribed(deviceConfig.upTopic)) {
      broker1.unsubscribe(deviceConfig.upTopic);
    }

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
    isLoading = true;
    notifyListeners();

    // 避免设备名重复：如果已存在，则追加 (1)
    String finalName = name;
    if (sensorCard.containsKey(name)) {
      finalName = "$name(1)";
    }
    try{
      final String clientId = "qingping_${mac.replaceAll(':', '_')}";
      final DeviceConfig deviceConfig = DeviceConfig(
        broker: broker,
        deviceName: finalName,
        port: port,
        clientId: clientId,
        upTopic: upTopic,
        downTopic: downTopic,
        username: username,
        password: password,
      );

      // 插入设备配置到数据库
      final newConfig = await _mqttRepository.insertDevice(deviceConfig);

      // 获取或创建 MQTT 服务实例
      final broker1 = getService(deviceConfig.broker, deviceConfig.port);

      // 尝试连接 MQTT
      await broker1.connect(
        host: deviceConfig.broker,
        port: deviceConfig.port,
        clientId: deviceConfig.clientId,
        username: deviceConfig.username,
        password: deviceConfig.password,
      );
      // 检查连接
      if (!broker1.isConnected) {
        log('MQTT 连接失败，无法添加设备: $finalName');
        await _mqttRepository.deleteDevice(deviceConfig.clientId, newConfig);
        return false;
      }
      sensorCard[finalName] = [];

      // 检查是否已经存在对该主题的订阅，如果有则先取消
      if (broker1.isSubscribed(deviceConfig.upTopic)) {
        broker1.unsubscribe(deviceConfig.upTopic);
      }

      broker1.subscribe(deviceConfig.upTopic, (topic, payload) async {
        log("收到消息: $payload");
        final newConfig = await _configDao.getByClientId(deviceConfig.clientId);
        if(newConfig != null){
          await _handleData(
            deviceConfig: newConfig,
            payload: Uint8List.fromList(payload),
          );
        }
      });

      // 创建 Completer 用于异步等待结果
      final completer = Completer<bool>();

      // 启动监听：如果 serviceCard 被更新，则视为成功
      void listener() {
        final dataList = sensorCard[finalName];
        if (dataList != null && dataList.isNotEmpty) {
          log('检测到 $finalName 收到有效数据，设备添加成功');
          isLoading = false;
          notifyListeners();
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        }
      }

      addListener(listener);
      // 超时机制
      Future.delayed(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          log('设备 $finalName 添加超时（10秒内未收到有效数据）');
          completer.complete(false);
        }
      });

      await publishMessage();

      final result = await completer.future;
      removeListener(listener);

      if(result == false){
        _mqttRepository.deleteDevice(deviceConfig.clientId, newConfig);
        sensorCard.remove(deviceConfig.deviceName);
        broker1.unsubscribe(deviceConfig.upTopic);
        broker1.disconnect();
      }
      return result;
    } catch (e, stack) {
      log('添加设备失败: $e\n$stack');
      return false;
    }finally{
      isLoading = false;
      notifyListeners();
    }
  }
  //二氧化碳与温湿度
  Future<void> _handleData({
    required DeviceConfig deviceConfig,
    required Uint8List payload,
  }) async {
    try{
      final decode = QingPingCo2TemperatureHumidityDecoder();
      if (payload.length < 5) {
        return;
      }
      final length = decode.combineLittleEndianAndToNum([payload[3], payload[4]]);
      log("开始解码   数据长度：${length.toString()}");
      switch (payload[2]) {
        case 0x35: // 时间设置
          decode.decodeDataBy0x35(length,payload);
          break;
        case 0x41 || 0x42 || 0x43: // 实时数据上报、历史数据上报、临时数据上报
          await decodeDateBy0x41And0x42And0x43(
            messageType: payload[2],
            len: length,
            payload: payload,
            deviceConfig: deviceConfig,
            callback: () {  },
          );
          break;
        case 0x44: // 报警信息上传
        // TODO: 实现事件数据解码
          break;
      }
    } catch (e) {
      log('解码传感器数据失败: $e');
    }
  }

  Future<void> decodeDateBy0x41And0x42And0x43({
    required int messageType,
    required int len,
    required Uint8List payload,
    required DeviceConfig deviceConfig,
    required void Function() callback,
  }) async {
    int index = 5;
    final decode = QingPingCo2TemperatureHumidityDecoder();
    while(index < len - 2){
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
              final data = decode.decode0x85BySensorData0x02(
                payload.sublist(index+8,index+3+len),
                deviceConfig.deviceName,
                deviceConfig.configId!, // 确保configId不为空
                datetime,
              );
              log("插入新数据 id:${data.configId} datetime: ${data.datetime} temp: ${data.temperature}");
              final sensorDataOnlyTempDao = SensorDataBasicDao();
              if(messageType == 0x43){
                sensorCard[deviceConfig.deviceName]?.add(data);
                log(sensorCard[deviceConfig.deviceName]?[-1].datetime.toString() ?? "0插入");
              }else if(messageType == 0x41){
                sensorCard[deviceConfig.deviceName]?[sensorCard[deviceConfig.deviceName]!.length - 1] = data;
                log("收到实时数据");
              }else{
                if(sensorCard[deviceConfig.deviceName]!.isNotEmpty){
                  final temp = sensorCard[deviceConfig.deviceName]?.removeLast();
                  sensorCard[deviceConfig.deviceName]?.add(data);
                  sensorCard[deviceConfig.deviceName]?.add(temp!);
                }
                if (deviceConfig.configId != null) {
                  await sensorDataOnlyTempDao.insert("${deviceConfig.clientId}_${deviceConfig.configId.toString()}",data);
                }
                log("收到历史数据");
              }
              break;
            case 0x03:
              final data = decode.decode0x85BySensorData0x03(
                payload.sublist(index+8,index+3+len),
                deviceConfig.deviceName,
                deviceConfig.configId!, // 确保configId不为空
                datetime,
              );
              log("插入新数据 id:${data.configId} datetime: ${data.datetime} atmosPressure:${data.atmosPressure} temp: ${data.temperature} humi:${data.humidity}");
              final sensorDataAtmosPressureDao = SensorDataAtmosPressureDao();
              if(messageType == 0x43){
                sensorCard[deviceConfig.deviceName]?.add(data);
              }else if(messageType == 0x41){
                sensorCard[deviceConfig.deviceName]?[sensorCard[deviceConfig.deviceName]!.length - 1] = data;
              }else{
                if(sensorCard[deviceConfig.deviceName]!.isNotEmpty){
                  final temp = sensorCard[deviceConfig.deviceName]?.removeLast();
                  sensorCard[deviceConfig.deviceName]?.add(data);
                  sensorCard[deviceConfig.deviceName]?.add(temp!);
                }
                if (deviceConfig.configId != null) {
                  await sensorDataAtmosPressureDao.insert("${deviceConfig.clientId}_${deviceConfig.configId.toString()}",data);
                }
              }
              break;
            case 0x04:
              final data = decode.decode0x85BySensorData0x04(
                payload.sublist(index+8,index+3+len),
                deviceConfig.deviceName,
                deviceConfig.configId!, // 确保configId不为空
                datetime,
              );
              log("插入新数据 id:${data.configId} datetime: ${data.datetime} co2:${data.co2} temp: ${data.temperature} humi:${data.humidity}");
              final sensorDataCo2Dao = SensorDataCo2Dao();
              if(messageType == 0x43){
                sensorCard[deviceConfig.deviceName]?.add(data);
                log(sensorCard[deviceConfig.deviceName]?.length.toString() ?? "0");
              }else if(messageType == 0x41){
                sensorCard[deviceConfig.deviceName]?[sensorCard[deviceConfig.deviceName]!.length - 1] = data;
              }else{
                if(sensorCard[deviceConfig.deviceName]!.isNotEmpty){
                  final temp = sensorCard[deviceConfig.deviceName]?.removeLast();
                  sensorCard[deviceConfig.deviceName]?.add(data);
                  sensorCard[deviceConfig.deviceName]?.add(temp!);
                }
                if (deviceConfig.configId != null) {
                  await sensorDataCo2Dao.insert("${deviceConfig.clientId}_${deviceConfig.configId.toString()}",data);
                }
              }
              break;
            case 0x06 || 0x09:
              final data = decode.decode0x85BySensorData0x06(
                payload.sublist(index+8,index+3+len),
                deviceConfig.deviceName,
                deviceConfig.configId!,
                datetime,
                sensorType,
              );
              log("插入新数据 id:${data.configId} datetime: ${data.datetime} externalCo2:${data.externalCo2} temp: ${data.temperature} humi: ${data.humidity} externalTemp: ${data.externalTemperature}");
              final sensorDataExternalCo2OrTempDao = SensorDataExternalCo2OrTempDao();
              if(messageType == 0x43){
                sensorCard[deviceConfig.deviceName]?.add(data);
              }else if(messageType == 0x41){
                sensorCard[deviceConfig.deviceName]?[sensorCard[deviceConfig.deviceName]!.length - 1] = data;
              }else{
                if(sensorCard[deviceConfig.deviceName]!.isNotEmpty){
                  final temp = sensorCard[deviceConfig.deviceName]?.removeLast();
                  sensorCard[deviceConfig.deviceName]?.add(data);
                  sensorCard[deviceConfig.deviceName]?.add(temp!);
                }
                if (deviceConfig.configId != null) {
                  await sensorDataExternalCo2OrTempDao.insert("${deviceConfig.clientId}_${deviceConfig.configId.toString()}",data);
                }
              }
              break;
            case 0x10:  //青萍室内环境检测仪
              final data = decode.decode0x85BySensorData0x10(
                payload.sublist(index+8,index+3+len),
                deviceConfig.deviceName,
                deviceConfig.configId!,
                datetime,
              );
              log("插入新数据 id:${data.configId} datetime: ${data.datetime} co2:${data.co2} temp: ${data.temperature} humi:${data.humidity}");
              final sensorDataCo2Pm25Pm10VocNoiseLuxDao = SensorDataCo2Pm25Pm10VocNoiseLuxDao();
              if(messageType == 0x43){
                sensorCard[deviceConfig.deviceName]?.add(data);
              }else if(messageType == 0x41){
                sensorCard[deviceConfig.deviceName]?[sensorCard[deviceConfig.deviceName]!.length - 1] = data;
              }else{
                if(sensorCard[deviceConfig.deviceName]!.isNotEmpty){
                  final temp = sensorCard[deviceConfig.deviceName]?.removeLast();
                  sensorCard[deviceConfig.deviceName]?.add(data);
                  sensorCard[deviceConfig.deviceName]?.add(temp!);
                }
                if (deviceConfig.configId != null) {
                  await sensorDataCo2Pm25Pm10VocNoiseLuxDao.insert("${deviceConfig.clientId}_${deviceConfig.configId.toString()}",data);
                }
              }
              break;
          }
          break;
        //   -----------------------------------------   //
        case 0x11:
          final code = String.fromCharCodes(payload.sublist(index+3,index+3+len));
          log("固件版本号: $code");
          break;
        case 0x1D:  // 断开设备连接
          log("断开设备连接?: ${payload[index+3] == 0 ? "还有数据未发送完" : "数据已发送完"}");
          break;
        case 0x2C:  // USB插入状态
          final usbState = payload[index+3];
          log("USB插入状态: ${usbState == 0 ? "拔出" : "插入"}");
          break;
        case 0x38:
          final id = decode.bytesToInt(payload.sublist(index+3,index+3+len));
          log("产品ID: $id");
          break;
        case 0x61:
          if(len == 0){
            log("PM模组: 未接入");
          }else{
            log("PM模组SN: ${payload.sublist(index+3,index+3+len)}");
          }
          break;
        case 0x64:
          final power = decode.bytesToInt(payload.sublist(index+3,index+3+len));
          log("当前电量： $power %");
          break;
        case 0x65:  // 信号强度
          final voltage = decode.toSignedInt8(decode.bytesToInt(payload.sublist(index+3,index+3+len)));
          log("信号强度： $voltage dBm");
          break;
        case 0x70:  // 系统运行时间
          final time = decode.bytesToInt(payload.sublist(index+3,index+3+len));
          log("系统运行时间: $time s");
          break;
        case 0x71:  // 模组当次搜网时间
          final time = decode.bytesToInt(payload.sublist(index+3,index+3+len));
          log("模组当次搜网时间: $time ms");
          break;
        case 0x74:  // 当前电压
          final double voltage = decode.bytesToInt(payload.sublist(index+3,index+3+len)) / 1000.0;
          log("当前电压： $voltage V");
          break;
        case 0x81:  // 设备基本信息
          final d0 = payload[index+3];
          final d1 = payload[index+4];
          final screen = ["无屏幕","墨水屏","段码屏","彩屏"];
          final power = [" AC 220V", "低压供电", "USB-C 供电", "电池"];
          final wifiType = ["不支持", "2.4G", "5G", "2.4G+5G"];
          final net = ["无", "NB-IoT", "Cat.1", "unknown", "LoRa"];
          log("设备基本信息 || 屏幕类型: ${screen[d0 & 3]} 供电类型: ${power[((d0>>3) & 7) - 1]} Wifi类型: ${wifiType[d1 & 3]} 其他网络: ${net[(d1 >> 2) & 7]} RS485: ${(d1 >> 5) & 1 == 0 ? "不支持" : "支持"}");
          break;
        case 0x82:  // 当天天气预报温度
          log("当天天气预报温度:");
          break;
        case 0x89:  // M0 mcu 固件版本
          log("M0 mcu 固件版本: ${String.fromCharCodes(payload.sublist(index+3,index+3+len))}");
          break;
        case 0x8A:  // M0 MCU 运行时间
          final time = decode.bytesToInt(payload.sublist(index+3,index+3+len));
          log("M0 MCU 运行时间: ${DateTime.fromMillisecondsSinceEpoch(time * 1000)};");
          break;
        case 0x8B:  // 本次上网使用的网络
          final network = payload[index+3];
          log("本次上网使用的网络: ${network == 1 ? "Wifi" : "cat1 模组"}");
          break;
        default:
          log("未识别命令: ${payload.sublist(index,index+3+len)}");
      }
      index += len+3;
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