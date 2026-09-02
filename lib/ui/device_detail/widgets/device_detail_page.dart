import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/data/models/measurement.dart';
import 'package:sensor_hub/data/models/sensor_type.dart';
import 'package:sensor_hub/l10n/app_localizations.dart';
import 'package:sensor_hub/route/route_utils.dart';
import 'package:sensor_hub/ui/device/view_model/device_vm.dart';
import 'package:sensor_hub/ui/device_detail/device_detail_vm.dart';
import 'package:sensor_hub/ui/device_detail/widgets/device_info_section.dart';
import 'package:sensor_hub/ui/device_detail/widgets/sensor_chart_card.dart';
import 'package:sensor_hub/utils/app_logger.dart';

/// 设备详情页
///
/// 自上而下分为三个区域：
/// 1. 设备概览卡（名称 / 在线状态 / MAC 地址 / 最近更新）；
/// 2. 实时数据（各传感器最新读数的双列卡片网格，点击卡片可联动图表）；
/// 3. 历史趋势（传感器 + 时间范围筛选的折线图卡片）。
class DeviceDetailPage extends StatefulWidget {
  final int deviceId;
  const DeviceDetailPage({super.key, required this.deviceId});

  @override
  State<StatefulWidget> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  final GlobalKey _chartSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceDetailVm>().initData(widget.deviceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceDetailVm>(
      builder: (context, vm, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: _buildAppBar(context, vm),
          body: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: vm.refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(bottom: 32.h),
                    children: [
                      _buildOverviewCard(context, vm),
                      _buildSectionHeader(
                        context,
                        AppLocalizations.of(context).device_detail_sensor_data,
                      ),
                      if (vm.history.isEmpty)
                        _buildEmptyState(context)
                      else
                        _twoColumnGrid(vm.history),
                      _buildSectionHeader(
                        context,
                        AppLocalizations.of(context).device_detail_history,
                        key: _chartSectionKey,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: SensorChartCard(
                          availableSensors: vm.availableSensors,
                          chartData: vm.chartData,
                          selectedType: vm.selectedType,
                          selectedRange: vm.selectedRange,
                          isLoading: vm.isChartLoading,
                          onSensorTypeChanged: vm.selectSensor,
                          onTimeRangeChanged: vm.selectRange,
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  // ── AppBar：返回 + 设备名 + 刷新 + 更多操作 ─────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context, DeviceDetailVm vm) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final title = vm.deviceName.isEmpty
        ? l10n.device_detail_unknown_device
        : vm.deviceName;

    return AppBar(
      centerTitle: true,
      backgroundColor: colorScheme.surfaceContainerHigh,
      iconTheme: IconThemeData(color: colorScheme.primary, size: 20.r),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_sharp),
        onPressed: () => RouteUtils.pop(context),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: colorScheme.onSurface),
          iconSize: 22.r,
          onPressed: vm.refresh,
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
          onSelected: _onMenuSelected,
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text(l10n.device_detail_edit)),
            PopupMenuItem(
              value: 'delete',
              child: Text(
                l10n.device_detail_delete,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _onMenuSelected(String value) async {
    final l10n = AppLocalizations.of(context);
    switch (value) {
      case 'edit':
        // TODO: 跳转到编辑页（预填设备配置）
        showToast(l10n.common_ui_coming_soon);
        break;
      case 'delete':
        await _confirmDelete();
        break;
    }
  }

  /// 删除确认 → 移除设备 → 返回列表
  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.device_detail_delete_title),
        content: Text(l10n.device_detail_delete_message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.common_ui_cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.device_detail_confirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<DeviceVM>().removeDevice(widget.deviceId);
      if (!mounted) return;
      showToast(l10n.device_detail_deleted);
      RouteUtils.popOfData(context, data: true);
    } catch (e) {
      logE('删除设备失败: $e', error: e, tag: 'DeviceDetailPage');
      if (mounted) showToast('$e');
    }
  }

  // ── 设备概览卡 ──────────────────────────────────────────────────
  Widget _buildOverviewCard(BuildContext context, DeviceDetailVm vm) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final mutedColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    final title = vm.deviceName.isEmpty
        ? l10n.device_detail_unknown_device
        : vm.deviceName;
    final minutesAgo = vm.latestTimestamp == null
        ? null
        : ((DateTime.now().millisecondsSinceEpoch ~/ 1000 -
                      vm.latestTimestamp!) /
                  60)
              .toInt()
              .clamp(0, 9999);

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.w, 16.w, 0),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48.r,
                height: 48.r,
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: SvgPicture.asset(
                  'assets/icons/icon_device.svg',
                  colorFilter: ColorFilter.mode(
                    colorScheme.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    _StatusChip(online: vm.isOnline),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Divider(
            height: 1.h,
            thickness: 1.h,
            color: colorScheme.outline.withValues(alpha: 0.15),
          ),
          SizedBox(height: 12.h),
          // MAC 地址
          Row(
            children: [
              Icon(Icons.lan_outlined, size: 14.r, color: mutedColor),
              SizedBox(width: 6.w),
              Text(
                '${l10n.device_detail_mac}: ${vm.macAddress.isEmpty ? '--' : vm.macAddress}',
                style: TextStyle(fontSize: 12.sp, color: mutedColor),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // 最近更新
          Row(
            children: [
              Icon(Icons.schedule, size: 14.r, color: mutedColor),
              SizedBox(width: 6.w),
              Text(
                l10n.device_detail_last_update,
                style: TextStyle(fontSize: 12.sp, color: mutedColor),
              ),
              const Spacer(),
              Text(
                minutesAgo == null
                    ? '--'
                    : '$minutesAgo ${l10n.device_screen_minutes_ago}',
                style: TextStyle(fontSize: 12.sp, color: mutedColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 分区标题 ────────────────────────────────────────────────────
  Widget _buildSectionHeader(BuildContext context, String title, {Key? key}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      key: key,
      padding: EdgeInsets.fromLTRB(16.w, 20.w, 16.w, 10.w),
      child: Row(
        children: [
          Container(
            width: 3.w,
            height: 14.h,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ── 无传感器数据空态 ────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        height: 180.h,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sensors_off_rounded,
              size: 36.r,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.device_detail_no_data,
              style: TextStyle(
                fontSize: 13.sp,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              l10n.device_detail_no_data_hint,
              style: TextStyle(
                fontSize: 11.sp,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 实时数据：双列卡片网格 ──────────────────────────────────────
  Widget _twoColumnGrid(List<Measurement> items) {
    const double spacing = 8.0;
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      final left = Expanded(
        child: DeviceInfoSection(item: items[i], onTap: _onSensorCardTap),
      );
      final right = i + 1 < items.length
          ? Expanded(
              child: DeviceInfoSection(
                item: items[i + 1],
                onTap: _onSensorCardTap,
              ),
            )
          : const Expanded(child: SizedBox.shrink());
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            left,
            SizedBox(width: spacing),
            right,
          ],
        ),
      );
      if (i + 2 < items.length) {
        rows.add(SizedBox(height: spacing));
      }
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(children: rows),
    );
  }

  /// 点击传感器卡片：联动选择图表中的传感器，并滚动到图表区域
  void _onSensorCardTap(SensorType type) {
    context.read<DeviceDetailVm>().selectSensor(type);
    final chartContext = _chartSectionKey.currentContext;
    if (chartContext != null) {
      Scrollable.ensureVisible(
        chartContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    }
  }
}

/// 在线 / 离线状态徽标
class _StatusChip extends StatelessWidget {
  final bool online;

  const _StatusChip({required this.online});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final color = online ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.r,
            height: 6.r,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 4.w),
          Text(
            online ? l10n.device_detail_online : l10n.device_detail_offline,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
