import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/data/models/device_group.dart';
import 'package:sensor_hub/route/route_utils.dart';
import 'package:sensor_hub/ui/device/view_model/device_vm.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/ui/custom_app_bar.dart';

/// 分组管理页：新建 / 重命名 / 拖拽排序 / 删除。
///
/// 所有操作即时生效（无需"保存"），AppBar 的「完成」只是返回入口。
/// 数据全部走 DeviceVM：设备列表筛选菜单、注册表单下拉消费的是同一份
/// 状态，在这里改完返回后自动就是新的。
class GroupManagementPage extends StatefulWidget {
  const GroupManagementPage({super.key});

  @override
  State<StatefulWidget> createState() => _GroupManagementPageState();
}

class _GroupManagementPageState extends State<GroupManagementPage> {
  /// 排序快照：与设备列表页保持同一比较规则。
  ///
  /// DAO 已按 sortOrder 返回，但 VM.groups 在测试里可能被塞进乱序数据，
  /// 和 device_screen 一样显式排一次，不依赖上游顺序。
  List<DeviceGroup> _sortedGroups(DeviceVM vm) {
    return [...vm.groups]..sort((a, b) {
        final bySort = a.sortOrder.compareTo(b.sortOrder);
        if (bySort != 0) return bySort;
        return (a.groupId ?? 0).compareTo(b.groupId ?? 0);
      });
  }

  int _deviceCountIn(DeviceVM vm, int groupId) {
    return vm.deviceProfiles.values
        .where((profile) => profile.groupId == groupId)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: createAppBar(
        title: appText.group_manage_title,
        appText: appText,
        colorScheme: colorScheme,
        onBack: () => RouteUtils.pop(context),
        // 操作即时生效，「完成」就是返回
        onFinish: () => RouteUtils.pop(context),
      ),
      body: SafeArea(
        // 点空白收起键盘，行为与注册表单页一致
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Column(
            children: [
              Expanded(child: _groupList(colorScheme, appText)),
              _createButton(colorScheme, appText),
            ],
          ),
        ),
      ),
    );
  }

  Widget _groupList(ColorScheme colorScheme, AppLocalizations appText) {
    return Consumer<DeviceVM>(
      builder: (context, vm, child) {
        final groups = _sortedGroups(vm);

        if (groups.isEmpty) {
          return _emptyHint(colorScheme, appText);
        }

        return ReorderableListView.builder(
          // 底部留出新建按钮上方的一小段呼吸空间
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 8.h),
          itemCount: groups.length,
          buildDefaultDragHandles: false,
          onReorder: _onReorder,
          itemBuilder: (context, index) {
            final group = groups[index];
            return _groupRow(
              key: ValueKey('group-row-${group.groupId}'),
              index: index,
              group: group,
              deviceCount: _deviceCountIn(vm, group.groupId!),
              colorScheme: colorScheme,
              appText: appText,
            );
          },
        );
      },
    );
  }

  /// ReorderableListView 的官方下标修正：
  /// 拖到更靠后的位置时，目标下标包含被拖项自身，要减一。
  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final vm = context.read<DeviceVM>();
    final ordered = _sortedGroups(vm);
    if (oldIndex < 0 || oldIndex >= ordered.length) return;
    final item = ordered.removeAt(oldIndex);
    ordered.insert(newIndex.clamp(0, ordered.length), item);
    // VM 持久化成功后会 notifyListeners → Consumer 自动重建为新顺序
    vm.reorderGroups(ordered);
  }

  /// 单个分组行：拖拽手柄 + 名称 + 设备数 + 操作菜单
  Widget _groupRow({
    required Key key,
    required int index,
    required DeviceGroup group,
    required int deviceCount,
    required ColorScheme colorScheme,
    required AppLocalizations appText,
  }) {
    return Container(
      key: key,
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        // 与设备列表筛选按钮同一套观感（surfaceContainerLow + 圆角 + 轻阴影）
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12.r),
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
          // 拖拽手柄：显式包 ReorderableDragStartListener，
          // 避免长按整行触发拖拽与行内点击/菜单手势打架
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
              child: Icon(
                Icons.drag_handle,
                size: 24.r,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: Text(
                group.groupName,
                style: TextStyle(fontSize: 16.sp),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 4.w),
            child: Text(
              appText.group_manage_device_count(deviceCount),
              style: TextStyle(
                fontSize: 13.sp,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          PopupMenuButton<String>(
            key: ValueKey('group-row-menu-${group.groupId}'),
            icon: Icon(
              Icons.more_vert,
              size: 22.r,
              color: colorScheme.onSurfaceVariant,
            ),
            position: PopupMenuPosition.under,
            onSelected: (action) {
              if (action == 'rename') {
                _showRenameDialog(group);
              } else if (action == 'delete') {
                _showDeleteConfirm(group);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                key: ValueKey('group-row-rename-${group.groupId}'),
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.drive_file_rename_outline,
                        size: 20.r, color: colorScheme.onSurfaceVariant),
                    SizedBox(width: 8.w),
                    Text(appText.group_manage_rename,
                        style: TextStyle(fontSize: 15.sp)),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                key: ValueKey('group-row-delete-${group.groupId}'),
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        size: 20.r, color: colorScheme.error),
                    SizedBox(width: 8.w),
                    Text(appText.group_manage_delete,
                        style: TextStyle(
                            fontSize: 15.sp, color: colorScheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 底部「新建分组」主按钮
  Widget _createButton(ColorScheme colorScheme, AppLocalizations appText) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          key: const ValueKey('group-manage-add'),
          onPressed: _showCreateDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          icon: Icon(Icons.add, size: 22.r),
          label: Text(
            appText.group_manage_new_group,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _emptyHint(ColorScheme colorScheme, AppLocalizations appText) {
    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off_outlined,
            size: 48.r,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: 12.h),
          Text(
            appText.group_manage_empty,
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

  // ================= 对话框 =================

  /// 新建分组
  Future<void> _showCreateDialog() async {
    final appText = AppLocalizations.of(context);
    final name = await _showNameDialog(
      title: appText.group_manage_new_group,
      initialName: null,
    );
    if (name == null || !mounted) return;
    final ok = await context.read<DeviceVM>().addGroup(name);
    if (!ok && mounted) showToast(appText.group_manage_operation_failed);
  }

  /// 重命名分组
  Future<void> _showRenameDialog(DeviceGroup group) async {
    final appText = AppLocalizations.of(context);
    final name = await _showNameDialog(
      title: appText.group_manage_rename,
      initialName: group.groupName,
      excludeGroupId: group.groupId,
    );
    if (name == null || !mounted) return;
    final ok = await context.read<DeviceVM>().renameGroup(group, name);
    if (!ok && mounted) showToast(appText.group_manage_operation_failed);
  }

  /// 名称输入对话框（新建 / 重命名共用），返回 null 表示取消。
  ///
  /// 必须是独立的 StatefulWidget：controller 要跟着 dialog 的 State 走
  /// lifecycle，在 dispose() 里释放。若在 showDialog 的 await 之后立刻
  /// dispose，退场动画还没播完的 TextField 仍在引用它，会抛
  /// "used after being disposed"。
  Future<String?> _showNameDialog({
    required String title,
    String? initialName,
    int? excludeGroupId,
  }) async {
    final appText = AppLocalizations.of(context);
    final vm = context.read<DeviceVM>();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => _GroupNameDialog(
        title: title,
        initialName: initialName,
        hint: appText.group_manage_name_hint,
        confirmLabel: appText.device_detail_confirm,
        cancelLabel: appText.common_ui_cancel,
        emptyError: appText.group_manage_name_empty,
        duplicateError: appText.group_manage_name_duplicate,
        // 重命名时排除自身，否则旧名本身就会被判为重名
        existingNames: vm.groups
            .where((g) => g.groupId != excludeGroupId)
            .map((g) => g.groupName)
            .toSet(),
      ),
    );
  }

  /// 删除确认：明示组内设备数，告知设备将转为未分组
  Future<void> _showDeleteConfirm(DeviceGroup group) async {
    final appText = AppLocalizations.of(context);
    final vm = context.read<DeviceVM>();
    final count = _deviceCountIn(vm, group.groupId!);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(appText.group_manage_delete_title),
        content: Text(
          appText.group_manage_delete_message(group.groupName, count),
        ),
        actions: [
          TextButton(
            key: const ValueKey('group-delete-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(appText.common_ui_cancel),
          ),
          FilledButton(
            key: const ValueKey('group-delete-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor:
                  Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(appText.group_manage_delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final ok = await vm.deleteGroup(group.groupId!);
    if (!ok && mounted) showToast(appText.group_manage_operation_failed);
  }
}

/// 分组名称输入对话框（新建 / 重命名共用）。
///
/// 查重在对话框内完成（错误就地显示在输入框下方），
/// 不合法时「确定」不关对话框。文案与查重所需数据全部由调用方注入，
/// 组件自身不依赖 VM，保持可独立测试。
class _GroupNameDialog extends StatefulWidget {
  const _GroupNameDialog({
    required this.title,
    required this.hint,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.emptyError,
    required this.duplicateError,
    this.initialName,
    this.existingNames = const <String>{},
  });

  final String title;
  final String hint;
  final String confirmLabel;
  final String cancelLabel;
  final String emptyError;
  final String duplicateError;
  final String? initialName;
  final Set<String> existingNames;

  @override
  State<_GroupNameDialog> createState() => _GroupNameDialogState();
}

class _GroupNameDialogState extends State<_GroupNameDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    // controller 只能在这里释放：dialog 路由完全移除（含退场动画）后
    // State.dispose 才执行，此时 TextField 已不再引用它
    _controller.dispose();
    super.dispose();
  }

  String? _validate() {
    final value = _controller.text.trim();
    if (value.isEmpty) return widget.emptyError;
    if (widget.existingNames.contains(value)) return widget.duplicateError;
    return null;
  }

  void _submit() {
    final error = _validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const ValueKey('group-name-field'),
        controller: _controller,
        autofocus: true,
        maxLength: 20,
        decoration: InputDecoration(
          hintText: widget.hint,
          errorText: _error,
        ),
        // 输入即清错：不要让上一次的错误一直挂在框上
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          key: const ValueKey('group-dialog-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          key: const ValueKey('group-dialog-confirm'),
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
