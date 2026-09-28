
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/data/models/device_group.dart';
import 'package:sensor_hub/route/route_utils.dart';
import 'package:sensor_hub/route/routes.dart';
import 'package:sensor_hub/ui/device/view_model/device_vm.dart';
import 'package:sensor_hub/ui/device/widgets/device_info_card.dart';

import '../../../l10n/app_localizations.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<StatefulWidget> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  /// 「全部设备」这一项的哨兵值。
  ///
  /// 不能拿 null 当"全部设备"的菜单值：PopupMenuButton 的 showButtonMenu()
  /// 里写死了 `if (newValue == null) { onCanceled(); return; }`，
  /// 会把"选中了值为 null 的项"和"用户点空白关掉了菜单"当成同一件事，
  /// 结果是 onSelected 永远不触发、点"全部设备"没反应。
  ///
  /// device_group.groupId 是 INTEGER PRIMARY KEY AUTOINCREMENT，从 1 起发号，
  /// 不可能出现负数，所以 -1 可以安全地当哨兵。
  static const int _allGroups = -1;

  /// 菜单里「管理分组」这一动作项的值。
  /// 它同样不能是 null（理由同上），也不能和任何真实分组 id 撞车，所以用 -2。
  static const int _manageGroups = -2;

  static const int _ungrouped = -3;

  late AppLocalizations appText;
  late DeviceVM viewModel;

  /// 当前筛选的分组；null = 全部设备。
  /// 哨兵只活在"菜单值"这一层，转到页面状态时立刻翻译回 null。
  int? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // final viewModel = Provider.of<DeviceVM>(context, listen: false);
      viewModel = context.read<DeviceVM>();
      await viewModel.initData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appText = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(left: 12.w,right: 12.w,bottom: 12.h),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
              ),
              child: Column(
                spacing: 8.h,
                children: [
                  _titleBar(colorScheme),
                  // 分组筛选。单独包一个 Consumer：
                  // 只需要 groups，不希望 MQTT 每次推数据都把整个页头重建一遍
                  Consumer<DeviceVM>(
                    builder: (context, vm, child) =>
                        _groupFilterButton(colorScheme, appText, vm),
                  ),
                  // deviceStateCards(colorScheme,appText)
                ],
              ),
            ),
            Expanded(
              child: deviceList(colorScheme,appText),
            ),
          ],
        ),
    );
  }

  Widget _titleBar(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      height: 52.h,
      color: colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            "assets/images/sensor_hub.png",
            height: 48.h,
          ),
          const Spacer(), // 更简洁的 Expanded(child: SizedBox())
          IconButton(
            icon: Icon(Icons.search, color: colorScheme.onSurface),
            iconSize: 28.h,
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.add, color: colorScheme.onSurface),
            iconSize: 28.h,
            onPressed: () {
              RouteUtils.pushForNamed(context, RoutePath.deviceRegistrationFrom);
            },
          ),
        ],
      ),
    );
  }

  /// 分组列表，按 sortOrder 优先、groupId 兜底升序。
  ///
  /// 这里显式排序，不依赖 DAO 的 orderBy：VM.groups 在组件测试里
  /// 可能被直接塞进乱序数据（注册表单下拉同理）。
  List<DeviceGroup> _sortedGroups(DeviceVM vm) {
    return [...vm.groups]..sort((a, b) {
        final bySort = a.sortOrder.compareTo(b.sortOrder);
        if (bySort != 0) return bySort;
        return (a.groupId ?? 0).compareTo(b.groupId ?? 0);
      });
  }

  /// 当前生效的筛选分组；null = 全部设备。
  ///
  /// 选中的分组在管理页被删除时，[_selectedGroupId] 会指向一个
  /// 不存在的 id，若不加保护会把设备列表筛成永久空态 ——
  /// 这里统一回落为 null（全部设备）。
  int? _effectiveGroupId(List<DeviceGroup> groups) {
    final id = _selectedGroupId;
    if (id == null) return null;
    if(id == _ungrouped) return _ungrouped;
    return groups.any((g) => g.groupId == id) ? id : null;
  }

  /// 某分组下的设备数；[groupId] 传 null 表示统计全部
  int _deviceCountInGroup(DeviceVM vm, int? groupId) {
    if (groupId == null) return vm.deviceProfiles.length;
    return vm.deviceProfiles.values
        .where((profile) => profile.groupId == groupId)
        .length;
  }

  int _ungroupCount(DeviceVM vm) =>
    vm.deviceProfiles.values.where((p) => p.groupId == null).length;

  /// 分组筛选按钮（替代原来那个 onPressed 为空的「全部设备」按钮）
  ///
  /// 用 PopupMenuButton 而不是 DropdownButtonFormField / DropdownMenu：
  /// - 这里没有 Form，用不上 validator；
  /// - DropdownMenu 是 M3 的"输入框 + 菜单"混合体，外观和这个全宽按钮对不上，
  ///   还必须显式给 width 否则会按最宽条目撑开；
  /// - PopupMenuButton 可以用 child 原样保留按钮外观，
  ///   而且菜单里能塞分隔线和「管理分组」这种动作项。
  ///
  /// 菜单"只弹半截宽"的问题不必换组件：PopupMenuButton 的 constraints
  /// 可以把菜单宽度锁成按钮宽度，配合 shape 让菜单上沿直角贴住按钮、
  /// 下沿收圆角，视觉上与按钮连为一体。
  Widget _groupFilterButton(
    ColorScheme colorScheme,
    AppLocalizations appText,
    DeviceVM vm,
  ) {
    final groups = _sortedGroups(vm);

    // PopupMenuButton 自己不做选中态展示，当前分组的名字要自己查；
    // 选中的分组被删除时 _effectiveGroupId 已经回落为 null → 显示「全部设备」
    final selectedId = _effectiveGroupId(groups);
    String label = appText.device_screen_all_devices;
    if(selectedId == _ungrouped){
      label = appText.device_screen_no_devices;
    }else if(selectedId != null) {
      for (final group in groups) {
        if (group.groupId == selectedId) {
          label = group.groupName;
          break;
        }
      }
    }

    // LayoutBuilder 取按钮的实际宽度（= 页面可用宽度），把菜单宽度锁成一致：
    // PopupMenuButton 默认按条目内容（IntrinsicWidth）自适应宽度，
    // 弹出的菜单只有按钮一半宽，和全宽按钮对不上。
    return LayoutBuilder(
      builder: (context, constraints) => PopupMenuButton<int>(
        // initialValue 只决定菜单弹出时高亮哪一项
        initialValue: selectedId ?? _allGroups,
        position: PopupMenuPosition.under,
        // 宽度下限保证菜单不窄于按钮；上限保证超长分组名
        // 也撑不破按钮宽度（配合行内省略号截断）
        constraints: BoxConstraints(
          minWidth: constraints.maxWidth,
          maxWidth: constraints.maxWidth,
        ),
        // 上沿直角贴住按钮下沿、下沿用与页头一致的 16 圆角：
        // 菜单像从按钮底下"接出来"，而不是一块悬浮的小方片
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16.r),
          ),
        ),
        onSelected: (value) {
          if (value == _manageGroups) {
            RouteUtils.pushForNamed(context, RoutePath.groupManagement);
            return;
          }
          setState(() {
            // 唯一的翻译点：菜单里的哨兵 → 页面状态里的 null
            _selectedGroupId = value == _allGroups ? null : value;
          });
        },
        itemBuilder: (context) => [
          PopupMenuItem<int>(
            key: const ValueKey('group-menu-all'),
            value: _allGroups,
            child: _groupMenuRow(
              colorScheme,
              appText.device_screen_all_devices,
              _deviceCountInGroup(vm, null),
            ),
          ),
          ...groups.map(
            (group) => PopupMenuItem<int>(
              key: ValueKey('group-menu-${group.groupId}'),
              value: group.groupId!,
              child: _groupMenuRow(
                colorScheme,
                group.groupName,
                _deviceCountInGroup(vm, group.groupId),
              ),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<int>(
            key: const ValueKey('group-menu-manage'),
            value: _manageGroups,
            child: Row(
              children: [
                Icon(Icons.tune, size: 20.r, color: colorScheme.onSurfaceVariant),
                SizedBox(width: 8.w),
                Text(
                  appText.device_screen_manage_groups,
                  style: TextStyle(fontSize: 15.sp),
                ),
              ],
            ),
          ),
        ],
        child: Container(
          width: double.infinity,
          height: 48.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            // 与 M3 ElevatedButton 的默认底色一致，保持原来那个按钮的观感
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24.r),
            // 原来的 ElevatedButton 有 1 级海拔阴影，换成 Container 后要自己补，
            // 参数与 deviceStateCardItem 保持一致
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.1),
                spreadRadius: 0.5,
                blurRadius: 3,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 16.sp),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                size: 32.r,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 菜单里的一行：分组名占剩余宽度（超长省略），设备数靠右。
  ///
  /// 以前菜单按内容自适应宽度（IntrinsicWidth），行宽不定，
  /// 只能用"ConstrainedBox 封顶 + mainAxisSize.min"的写法；
  /// 现在菜单宽度已锁定为按钮宽度，行拿到的是有界宽度，
  /// 改用 Expanded 让所有设备数统一右对齐，不受最长分组名影响。
  Widget _groupMenuRow(ColorScheme colorScheme, String name, int count) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: TextStyle(fontSize: 15.sp),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 13.sp,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget deviceStateCards(ColorScheme colorScheme, AppLocalizations appText){
    return Container(
      width: double.infinity,
      height: 120.h,
      color: colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          deviceStateCardItem(
            icon: "assets/icons/icon_over_limit.svg",
            title: appText.device_screen_overLimit,
            deviceCount: 0,
            colorScheme: colorScheme
          ),
          deviceStateCardItem(
              icon: "assets/icons/icon_low_battery.svg",
              title: appText.device_screen_lowBattery,
              deviceCount: 0,
              colorScheme: colorScheme
          ),
          deviceStateCardItem(
              icon: "assets/icons/icon_offline.svg",
              title: appText.device_screen_offline,
              deviceCount: 0,
              colorScheme: colorScheme
          ),
          deviceStateCardItem(
              icon: "assets/icons/icon_upgradeable.svg",
              title: appText.device_screen_upgradeable,
              deviceCount: 0,
              colorScheme: colorScheme
          ),
        ],
      ),
    );
  }
  Widget deviceStateCardItem({
    required String icon,
    required String title,
    required int deviceCount,
    required ColorScheme colorScheme
  }){
    return Container(
      width: 84.w,
      height: 120.h,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            spreadRadius: 0.5,
            blurRadius: 3,
          ),
        ],
        border: Border.all(
          width: 0.5.r,
          color: colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            icon,
            height: 32.h,
            colorFilter: ColorFilter.mode(colorScheme.onSurfaceVariant, BlendMode.srcIn),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              color: colorScheme.onSurfaceVariant
            ),
          ),
          Divider(
            height: 1.h,
            thickness: 1.h,
            indent: 16.w,
            endIndent: 16.w,
          ),
          Text(
            deviceCount.toString(),
            style: TextStyle(
              fontSize: 14.sp,
              color: colorScheme.onSurfaceVariant
            ),
          ),
        ],
      ),
    );
  }
  Widget deviceList(ColorScheme colorScheme, AppLocalizations appText) {
    return Consumer<DeviceVM>(builder: (context, vm, child) {
      // 一台设备都没有：保留原有的"添加第一台设备"引导页
      if (vm.latestReadings.isEmpty) {
        return _firstDevicePrompt(colorScheme, appText);
      }

      // ① 先算出「可见设备名」的快照列表。
      //    一次布局期间 builder 读的是同一个 List，不会因为 MQTT 恰好推来
      //    新数据（latestReadings 被改写或新增 key）导致下标与设备错位。
      //    筛选用 _effectiveGroupId：选中的分组被删除后自动回落到全部。
      final effectiveGroupId = _effectiveGroupId(_sortedGroups(vm));
      final visibleNames = <String>[];
      for (final deviceName in vm.latestReadings.keys) {
        final profile = vm.deviceProfiles[deviceName];
        // profile 尚未同步的设备直接不进列表：
        // 否则会渲染成一个零高度的空占位（原来的 SizedBox.shrink 就是这个毛病）
        if (profile == null) continue;
        if (effectiveGroupId == _ungrouped) {
          if (profile.groupId != null) continue; // 未分组：只留 groupId == null 的
        } else if (effectiveGroupId != null && profile.groupId != effectiveGroupId) {
          continue;
        }
        visibleNames.add(deviceName);
      }

      // ② 筛完为空要走空态。itemCount 的语义是"可见项数"，
      //    所以判断必须做在这里，而不是塞进 itemBuilder 里返回空盒子。
      if (visibleNames.isEmpty) {
        return _emptyHint(
          colorScheme,
          effectiveGroupId == null
              ? appText.device_screen_no_devices
              : effectiveGroupId == _ungrouped
              ? appText.device_screen_ungrouped_empty
              : appText.device_screen_group_empty,
        );
      }

      // 分组名查表：卡片上的分组标签用（同一份排序结果，保证与菜单一致）
      final groupNames = <int, String>{
        for (final group in _sortedGroups(vm))
          if (group.groupId != null) group.groupId!: group.groupName,
      };

      return RefreshIndicator(
        onRefresh: () async {
          await vm.refreshData();
        },
        child: ListView.builder(
          itemCount: visibleNames.length,
          itemBuilder: (context, index) {
            // 直接用下标取名字：List 是 O(1)，
            // 不像 Map.entries.elementAt(index) 那样每次都要从头遍历一遍
            final deviceName = visibleNames[index];
            final readings = vm.latestReadings[deviceName]!;
            final profile = vm.deviceProfiles[deviceName]!;
            final deviceId = profile.configId;
            // 取所有读数中最新的时间戳
            int latestTimestamp = 0;
            for (final m in readings.values) {
              if (m.timestamp > latestTimestamp) {
                latestTimestamp = m.timestamp;
              }
            }
            return Padding(
              padding: EdgeInsets.only(left: 12.w, right: 12.w, bottom: 12.w),
              child: DeviceInfoCard(
                colorScheme: colorScheme,
                name: deviceName,
                // 未分组时传 null，卡片不渲染标签
                groupName: groupNames[profile.groupId],
                time: latestTimestamp > 0
                    ? vm.getMinutesDifference(latestTimestamp).toString()
                    : "0",
                dateList: readings,
                onTap: () {
                  RouteUtils.pushForNamed(
                    context,
                    RoutePath.deviceDetail,
                    arguments: deviceId,
                  );
                },
              ),
            );
          },
        ),
      );
    });
  }

  /// 一台设备都没有时的引导页（从 deviceList 里搬出来，避免嵌套过深）
  Widget _firstDevicePrompt(ColorScheme colorScheme, AppLocalizations appText) {
    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 160.w,
            height: 120.h,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SvgPicture.asset(
                  "assets/icons/icon_device.svg",
                  width: 100.w,
                ),
                Positioned(
                  top: 36.h, // 垂直居中（基于容器高度）
                  left: 96.w, // 右边缘减去按钮半宽
                  child: IconButton(
                    iconSize: 48.w,
                    padding: EdgeInsets.zero, // 移除默认 padding 更精准
                    color: colorScheme.primary,
                    icon: Icon(Icons.add_circle_outline),
                    onPressed: () {
                      RouteUtils.pushForNamed(
                        context,
                        RoutePath.deviceRegistrationFrom,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Text(
            appText.device_screen_prompt,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// 筛选结果为空时的占位，与"一台设备都没有"区分开
  Widget _emptyHint(ColorScheme colorScheme, String message) {
    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_alt_off_outlined,
            size: 48.r,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: 12.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}