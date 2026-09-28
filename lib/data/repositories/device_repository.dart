import 'dart:io';
import 'package:sensor_hub/data/dao/device_config_dao.dart';
import 'package:sensor_hub/data/dao/device_group_dao.dart';
import 'package:sensor_hub/data/dao/measurement_dao.dart';
import 'package:sensor_hub/data/models/device_group.dart';
import 'package:sensor_hub/data/models/measurement.dart';
import 'package:sensor_hub/data/services/http/api_service.dart';
import 'package:sensor_hub/data/services/http/api_config.dart';
import 'package:sensor_hub/utils/app_logger.dart';

class DeviceRepository {
  final ApiService _apiService = ApiService();
  final DeviceConfigDao _deviceConfigDao = DeviceConfigDao();
  final DeviceGroupDao _deviceGroupDao = DeviceGroupDao();
  final MeasurementDao _measurementDao = MeasurementDao();

  /// 查询所有设备分组
  Future<List<DeviceGroup>> getAllGroups() async {
    final groups = await _deviceGroupDao.getAll();
    logD('读取所有设备分组: ${groups.length} 个', tag: 'DeviceRepo');
    return groups;
  }

  /// 新建分组：sortOrder 排到当前最后，名称唯一性由 UNIQUE 约束兜底
  Future<DeviceGroup> addGroup(String groupName) async {
    final existing = await _deviceGroupDao.getAll();
    final maxSortOrder = existing.fold<int>(
      -1,
      (max, g) => g.sortOrder > max ? g.sortOrder : max,
    );
    final group = DeviceGroup(
      groupName: groupName,
      sortOrder: maxSortOrder + 1,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    final id = await _deviceGroupDao.insert(group);
    logI('新建分组: $groupName (id=$id)', tag: 'DeviceRepo');
    return group.copyWith(groupId: id);
  }

  /// 重命名分组
  Future<void> renameGroup(DeviceGroup group, String newName) async {
    await _deviceGroupDao.update(group.copyWith(groupName: newName));
    logI('重命名分组: ${group.groupName} -> $newName', tag: 'DeviceRepo');
  }

  /// 持久化拖拽后的新顺序（下标即 sortOrder）
  Future<void> reorderGroups(List<DeviceGroup> orderedGroups) async {
    await _deviceGroupDao.updateSortOrders(
      orderedGroups.map((g) => g.groupId!).toList(),
    );
    logI('分组重排完成: ${orderedGroups.map((g) => g.groupName).join(' > ')}',
        tag: 'DeviceRepo');
  }

  /// 删除分组：device_configs.groupId 外键 ON DELETE SET NULL，
  /// 组内设备在数据库侧自动变为未分组
  Future<void> deleteGroup(int groupId) async {
    await _deviceGroupDao.delete(groupId);
    logI('删除分组: id=$groupId（组内设备已转为未分组）', tag: 'DeviceRepo');
  }

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
