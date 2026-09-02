import 'dart:async';
import 'package:sensor_hub/data/repositories/device_repository.dart';
import 'package:sensor_hub/utils/app_logger.dart';

/// HTTP 历史数据周期同步服务
///
/// 职责：
/// - 管理 Timer.periodic 周期调用 DeviceRepository.syncHistoryFromApi()
/// - 提供手动触发同步接口（App 回前台时调用）
/// - 通过 _syncing 标志防止并发同步
class SyncService {
  Timer? _syncTimer;
  final DeviceRepository _deviceRepository = DeviceRepository();
  bool _syncing = false;

  /// 启动周期同步
  /// [interval] 同步间隔，默认 5 分钟
  void start({Duration interval = const Duration(minutes: 5)}) {
    _syncNow();
    _syncTimer = Timer.periodic(interval, (_) => _syncNow());
    logI('周期同步已启动，间隔: ${interval.inMinutes} 分钟', tag: 'SyncService');
  }

  /// 停止周期同步
  void stop() {
    _syncTimer?.cancel();
    _syncTimer = null;
    logI('周期同步已停止', tag: 'SyncService');
  }

  /// 手动触发一次同步（如 App 回前台时调用）
  Future<void> syncOnce() => _syncNow();

  Future<void> _syncNow() async {
    if (_syncing) {
      logD('同步正在进行中，跳过本次触发', tag: 'SyncService');
      return;
    }
    _syncing = true;
    try {
      await _deviceRepository.syncHistoryFromApi();
    } catch (e) {
      logE('周期同步异常: $e', error: e, tag: 'SyncService');
    } finally {
      _syncing = false;
    }
  }
}
