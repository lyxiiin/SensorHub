import 'package:flutter/material.dart';
import 'package:sensor_hub/data/dao/device_config_dao.dart';
import 'package:sensor_hub/data/dao/measurement_dao.dart';
import 'package:sensor_hub/data/models/measurement.dart';
import 'package:sensor_hub/data/models/sensor_type.dart';
import 'package:sensor_hub/utils/app_logger.dart';

/// 设备详情页 ViewModel
///
/// 负责加载设备配置（名称 / MAC）、实时读数快照（history）与
/// 选定传感器在选定时间范围内的历史数据（chartData），
/// 并联动「传感器选择」与「时间范围」两个图表筛选条件。
class DeviceDetailVm extends ChangeNotifier {
  /// 可注入 DAO，便于测试；默认使用真实实现
  DeviceDetailVm({DeviceConfigDao? configDao, MeasurementDao? measurementDao})
    : _configDao = configDao ?? DeviceConfigDao(),
      _measurementDao = measurementDao ?? MeasurementDao();

  final DeviceConfigDao _configDao;
  final MeasurementDao _measurementDao;

  /// 超过该时长未收到数据即视为离线
  static const Duration offlineThreshold = Duration(minutes: 10);

  /// 支持的时间范围标签 → 时长
  static const Map<String, Duration> timeRangeOptions = {
    '1h': Duration(hours: 1),
    '6h': Duration(hours: 6),
    '24h': Duration(hours: 24),
    '7d': Duration(days: 7),
  };

  int? deviceId;

  // ── 设备信息 ────────────────────────────────────────────────────
  String deviceName = '';
  String macAddress = '';

  /// 设备在线状态（依据最近一次读数时间推断）
  bool get isOnline {
    if (history.isEmpty) return false;
    final last = history
        .map((m) => m.timestamp)
        .reduce((a, b) => a > b ? a : b);
    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(last * 1000),
    );
    return age <= offlineThreshold;
  }

  /// 最近一次读数时间（秒级时间戳），无数据时为 null
  int? get latestTimestamp {
    if (history.isEmpty) return null;
    return history.map((m) => m.timestamp).reduce((a, b) => a > b ? a : b);
  }

  // ── 实时数据 ────────────────────────────────────────────────────
  List<Measurement> history = [];

  // ── 图表相关 ────────────────────────────────────────────────────
  List<SensorType> availableSensors = [];
  SensorType? selectedType;
  String selectedRange = '24h';
  List<Measurement> chartData = [];

  bool isLoading = true;
  bool isChartLoading = false;

  /// 首次进入页面时加载全部数据
  Future<void> initData(int id) async {
    deviceId = id;
    isLoading = true;
    notifyListeners();
    try {
      await _loadDeviceInfo();
      await _loadLatest();
      if (availableSensors.isNotEmpty) {
        await _loadChartData();
      }
    } catch (e, stack) {
      logE('设备详情加载失败: $e', error: e, stack: stack, tag: 'DeviceDetailVm');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 下拉刷新：重新加载（不显示整页加载态）
  Future<void> refresh() async {
    if (deviceId == null) return;
    try {
      await _loadDeviceInfo();
      await _loadLatest();
      await _loadChartData();
    } catch (e, stack) {
      logE('设备详情刷新失败: $e', error: e, stack: stack, tag: 'DeviceDetailVm');
    }
  }

  /// 切换图表传感器
  void selectSensor(SensorType type) {
    if (type == selectedType) return;
    selectedType = type;
    _loadChartData();
  }

  /// 切换图表时间范围
  void selectRange(String range) {
    if (!timeRangeOptions.containsKey(range) || range == selectedRange) return;
    selectedRange = range;
    _loadChartData();
  }

  Future<void> _loadDeviceInfo() async {
    final config = await _configDao.getById(deviceId!);
    deviceName = config?.deviceName ?? '';
    macAddress = config?.macAddress ?? '';
  }

  /// 从 device_latest 快照表加载各传感器最新读数，
  /// 并按 SensorType 枚举顺序稳定排序，保证卡片顺序不跳动。
  Future<void> _loadLatest() async {
    final latest = await _measurementDao.queryLatest(deviceId!);
    history = SensorType.values
        .where(latest.containsKey)
        .map((type) => latest[type]!)
        .toList();
    availableSensors = history.map((m) => m.sensorType).toList();
    if (availableSensors.isEmpty) {
      chartData = [];
      return;
    }
    if (selectedType == null || !availableSensors.contains(selectedType)) {
      selectedType = availableSensors.first;
    }
  }

  /// 按「传感器 + 时间范围」查询历史数据
  Future<void> _loadChartData() async {
    if (deviceId == null || selectedType == null) {
      chartData = [];
      notifyListeners();
      return;
    }
    isChartLoading = true;
    notifyListeners();

    final now = DateTime.now();
    final range = timeRangeOptions[selectedRange] ?? const Duration(hours: 24);
    final startTime = now.subtract(range).millisecondsSinceEpoch ~/ 1000;

    try {
      chartData = await _measurementDao.queryHistory(
        configId: deviceId!,
        type: selectedType!,
        startTime: startTime,
      );
    } catch (e, stack) {
      logE('历史数据加载失败: $e', error: e, stack: stack, tag: 'DeviceDetailVm');
      chartData = [];
    } finally {
      isChartLoading = false;
      notifyListeners();
    }
  }
}
