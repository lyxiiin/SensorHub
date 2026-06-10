import 'dart:developer';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:sensor_hub/data/repositories/mqtt_repository.dart';
import 'package:sensor_hub/data/dao/device_config_dao.dart';
import 'package:sensor_hub/data/models/device_config.dart';
import 'package:sensor_hub/data/services/mqtt_service.dart';

import 'package:sensor_hub/data/dao/measurement_dao.dart';
import 'package:sensor_hub/data/models/measurement.dart';
import 'package:sensor_hub/data/models/sensor_type.dart';
import 'package:sensor_hub/data/models/device_profile.dart';
import 'package:sensor_hub/data/decoders/payload_decoder.dart';


class DeviceVM with ChangeNotifier{
  late final MqttRepository _mqttRepository;
  late final DeviceConfigDao _configDao;
  int get deviceCount => latestReadings.length;
  final Map<String, MqttService> _services = {};
  final Map<String, DeviceProfile> deviceProfiles = {};               // 设备名 → 配置
  final Map<String, Map<SensorType, Measurement>> latestReadings = {}; // 设备名 → (传感器类型 → 最新读数)
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

  Future<void> publishMessage({required String topic, required List<int> payload}) async {
    // TODO: 由自定义传感器实现具体的发布逻辑
    log('发布消息到主题: $topic, payload长度: ${payload.length}');
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
  log("初始化：读取到 ${devicesConfig.length} 个设备");

  // 遍历所有设备，从数据库恢复最新读数快照，初始化内存缓存
  for (final deviceConfig in devicesConfig) {
    if (deviceConfig.configId != null) {
      // 从 device_latest 快照表恢复最新数据
      final dao = MeasurementDao();
      final latest = await dao.queryLatest(deviceConfig.configId!);
      latestReadings[deviceConfig.deviceName] = latest;

      // 根据已有数据自动构建 DeviceProfile
      if (latest.isNotEmpty) {
        deviceProfiles[deviceConfig.deviceName] = DeviceProfile(
          configId: deviceConfig.configId!,
          deviceName: deviceConfig.deviceName,
          sensors: latest.keys.toList(),
          payloadVersion: 1,
        );
      }
    } else {
      log('警告: 设备 ${deviceConfig.deviceName} 的 configId 为空，无法恢复数据');
      latestReadings[deviceConfig.deviceName] = {};
    }
  }

  // 建立 MQTT 连接（订阅数据），跳过 configId 为空的设备
  for (final deviceConfig in devicesConfig) {
    if (deviceConfig.configId == null) {
      log('跳过 configId 为空的设备: ${deviceConfig.deviceName}');
      continue;
    }
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
      // SDTP 协议：payload 是十六进制编码的字符串
      try {
        await _handleSdtpMessage(deviceConfig, payload);
      } catch (e) {
        log('数据处理失败: $e');
      }
    });
  }


  /// 添加设备
  Future<bool> addDevice({
    required String sensorType,
    required String name,
    required String broker,
    required int port,
    required String clientId,
    required String upTopic,
    required String downTopic,
    required String username,
    required String password,
  }) async {
    isLoading = true;
    notifyListeners();

    // 避免设备名重复：如果已存在，则追加 (1)
    String finalName = name;
    if (deviceProfiles.containsKey(name)) {
      finalName = "$name(1)";
    }
    try{
      // 插入设备配置到数据库（configId 由数据库自增生成）
      final configId = await _mqttRepository.insertDevice(DeviceConfig(
        broker: broker,
        deviceName: name,
        port: port,
        clientId: clientId,
        upTopic: upTopic,
        downTopic: downTopic,
        username: username,
        password: password,
      ));

      // 用数据库返回的 configId 构造完整的 DeviceConfig
      final deviceConfig = DeviceConfig(
        configId: configId,
        broker: broker,
        deviceName: name,
        port: port,
        clientId: clientId,
        upTopic: upTopic,
        downTopic: downTopic,
        username: username,
        password: password,
      );

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
        await _mqttRepository.deleteDevice(deviceConfig.clientId, configId);
        return false;
      }
      latestReadings[finalName] = {};

      // 检查是否已经存在对该主题的订阅，如果有则先取消
      if (broker1.isSubscribed(deviceConfig.upTopic)) {
        broker1.unsubscribe(deviceConfig.upTopic);
      }

      broker1.subscribe(deviceConfig.upTopic, (topic, payload) async {
        try {
          await _handleSdtpMessage(deviceConfig, payload);
        } catch (e) {
          log('数据处理失败: $e');
        }
      });

      // 创建 Completer 用于异步等待结果
      final completer = Completer<bool>();

      // 启动监听：收到第一次有效数据即视为成功
      void listener() {
        if (completer.isCompleted) return; // 已判定结果，不再重复处理
        final readings = latestReadings[finalName];
        if (readings != null && readings.isNotEmpty) {
          log('检测到 $finalName 收到有效数据，设备添加成功');
          isLoading = false;
          notifyListeners();
          completer.complete(true);
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

      final result = await completer.future;
      removeListener(listener);

      if(result == false){
        _mqttRepository.deleteDevice(deviceConfig.clientId, configId);
        deviceProfiles.remove(deviceConfig.deviceName);
        latestReadings.remove(deviceConfig.deviceName);
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

  /// MQTT 消息处理（SDTP 解码 → 存储 → 缓存更新）
  Future<void> _handleSdtpMessage(DeviceConfig config, dynamic payload) async {
    if (config.configId == null) {
      log('[错误] 设备 ${config.deviceName} 的 configId 为空，无法处理消息');
      return;
    }

    String hexStr;
    if (payload is String) {
      hexStr = payload;
    } else {
      hexStr = String.fromCharCodes(payload);
    }

    log('[诊断] 收到 ${config.deviceName} 消息: hex长度=${hexStr.length}, configId=${config.configId}');

    final measurements = PayloadDecoder.decode(
      hexStr,
      configId: config.configId!,
    );

    if (measurements.isEmpty) return;

    await MeasurementDao().insertBatch(measurements);

    final latest = latestReadings[config.deviceName] ?? {};
    for (final m in measurements) {
      latest[m.sensorType] = m;
    }
    latestReadings[config.deviceName] = latest;

    _autoDetectProfile(config, measurements);
    _checkThresholdsAndNotify(config, measurements);
    notifyListeners();
  }

  // TODO: 此处由自定义传感器解码器实现填充
  // 建议后续引入抽象的 PayloadDecoder 接口和解码器注册表模式

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
    required String clientId,
    required String downTopic,
    required String username,
    required String password,
  }) async {
    try{
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

  /// 根据收到的 Measurement 自动推断设备搭载的传感器类型
  /// 当探测到新的传感器类型组合时，自动更新 DeviceProfile
  void _autoDetectProfile(DeviceConfig config, List<Measurement> measurements) {
    final deviceName = config.deviceName;
    final existingProfile = deviceProfiles[deviceName];

    // 从新数据中提取传感器类型集合
    final detectedSensors = measurements.map((m) => m.sensorType).toSet();

    if (existingProfile == null) {
      // 首次收到数据，新建 profile
      deviceProfiles[deviceName] = DeviceProfile(
        configId: config.configId!,
        deviceName: deviceName,
        sensors: detectedSensors.toList(),
        payloadVersion: 1,
      );
      log('自动检测设备 $deviceName 传感器: $detectedSensors');
      return;
    }

    // 检查传感器组合是否发生变化（新增了传感器或移除了传感器）
    final existingSet = existingProfile.sensors.toSet();
    if (!_setEquals(existingSet, detectedSensors)) {
      final newSensors = detectedSensors.difference(existingSet);
      final removedSensors = existingSet.difference(detectedSensors);

      deviceProfiles[deviceName] = DeviceProfile(
        configId: config.configId!,
        deviceName: deviceName,
        sensors: detectedSensors.toList(),
        payloadVersion: existingProfile.payloadVersion,
        thresholds: existingProfile.thresholds,  // 保留已配置的阈值
      );

      if (newSensors.isNotEmpty) {
        log('设备 $deviceName 检测到新传感器: $newSensors');
      }
      if (removedSensors.isNotEmpty) {
        log('设备 $deviceName 传感器已移除: $removedSensors（可能暂时离线）');
      }
    }
  }

  /// 比较两个 SensorType 集合是否相同
  bool _setEquals(Set<SensorType> a, Set<SensorType> b) {
    return a.length == b.length && a.containsAll(b);
  }


  // 预留函数，后续接入notificationVM
  /// 检查 Measurement 是否超过阈值，生成通知
  void _checkThresholdsAndNotify(
    DeviceConfig config,
    List<Measurement> measurements,
  ) {
    final profile = deviceProfiles[config.deviceName];
    if (profile == null) return;

    for (final m in measurements) {
      final threshold = profile.thresholds[m.sensorType];
      if (threshold == null) continue;

      if (m.value > threshold.maxValue || m.value < threshold.minValue) {
        log('告警: ${config.deviceName} ${m.sensorType.displayName}=${m.formattedValue}'
            '${m.sensorType.unit} 超出阈值 [${threshold.minValue}~${threshold.maxValue}]');
        // TODO: 调用 NotificationMessageDao().insert(...) 写入通知表
        // TODO: 触发 NotificationVM 刷新
      }
    }
  }



}