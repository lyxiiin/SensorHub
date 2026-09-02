import 'dart:io';
import 'package:sensor_hub/data/dao/device_config_dao.dart';
import 'package:sensor_hub/data/dao/measurement_dao.dart';
import 'package:sensor_hub/data/models/measurement.dart';
import 'package:sensor_hub/data/services/http/api_service.dart';
import 'package:sensor_hub/data/services/http/api_config.dart';
import 'package:sensor_hub/utils/app_logger.dart';

class DeviceRepository {
  final ApiService _apiService = ApiService();
  final DeviceConfigDao _deviceConfigDao = DeviceConfigDao();
  final MeasurementDao _measurementDao = MeasurementDao();

  /// 快速检测服务器 TCP 连通性（5秒超时）
  Future<bool> _isServerReachable() async {
    try {
      final uri = Uri.parse(ApiConfig.development.baseUrl);
      final socket = await Socket.connect(
        uri.host,
        uri.port,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      logI('服务器连通性检测: ${uri.host}:${uri.port} 可达', tag: 'DeviceRepo');
      return true;
    } catch (e) {
      logW('服务器不可达: $e', tag: 'DeviceRepo');
      return false;
    }
  }

  Future<void> syncHistoryFromApi() async {
    if (!await _isServerReachable()) {
      logW('跳过 HTTP 同步：服务器不可达', tag: 'DeviceRepo');
      return;
    }

    final configs = await _deviceConfigDao.getAll();
    for(final config in configs){
      try {
        final latestMeasurements = await _measurementDao.queryLatest(config.configId!);
        final endTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        int startTime = 0;
        if (latestMeasurements.isNotEmpty) {
          startTime = latestMeasurements.values.first.timestamp + 1;
        }
        final result = await _apiService.getHistory(config.macAddress, startTime.toString(), endTime.toString(), "1000");
        if(!result.isSuccess || result.data == null) continue;
        final measurements = <Measurement>[];
        for(final record in result.data!){
          measurements.addAll(record.toMeasurements(config.configId!));
        }
        if(measurements.isNotEmpty){
          await _measurementDao.insertBatch(measurements);
        }

        logI('HTTP 历史数据同步完成,本次同步了${measurements.length}条数据', tag: 'DeviceVM');
      } catch(e){
        logE('HTTP 历史数据同步失败(设备: ${config.deviceName}): $e', tag: 'DeviceVM');
      }
    }
  }
}
