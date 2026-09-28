import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/data/models/device_group.dart';
import 'package:sensor_hub/data/models/device_profile.dart';
import 'package:sensor_hub/data/models/measurement.dart';
import 'package:sensor_hub/data/models/sensor_type.dart';
import 'package:sensor_hub/l10n/app_localizations.dart';
import 'package:sensor_hub/ui/device/view_model/device_vm.dart';
import 'package:sensor_hub/ui/device/widgets/group_management_page.dart';

/// 分组管理页的组件测试：新建 / 重命名 / 删除 / 拖拽排序。
///
/// 用 [_FakeGroupVM] 把四个 CRUD 方法换成纯内存实现：
/// 组件测试不碰 SQLite（那套链路由迁移测试与真机验证覆盖），
/// 这里只验证 UI 交互与 VM 状态的契约 —— 输入校验、确认流程、
/// 删除后设备回落未分组、重排后的顺序持久化到 VM。
class _FakeGroupVM extends DeviceVM {
  int _nextId = 100;

  @override
  Future<void> initData() async {}

  @override
  Future<bool> addGroup(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    if (groups.any((g) => g.groupName == trimmed)) return false;
    groups = [
      ...groups,
      DeviceGroup(
        groupId: _nextId++,
        groupName: trimmed,
        sortOrder: groups.length,
        createdAt: 0,
      ),
    ];
    notifyListeners();
    return true;
  }

  @override
  Future<bool> renameGroup(DeviceGroup group, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return false;
    if (groups.any(
      (g) => g.groupId != group.groupId && g.groupName == trimmed,
    )) {
      return false;
    }
    groups = groups
        .map((g) =>
            g.groupId == group.groupId ? g.copyWith(groupName: trimmed) : g)
        .toList();
    notifyListeners();
    return true;
  }

  @override
  Future<bool> reorderGroups(List<DeviceGroup> orderedGroups) async {
    groups = [
      for (int i = 0; i < orderedGroups.length; i++)
        orderedGroups[i].copyWith(sortOrder: i),
    ];
    notifyListeners();
    return true;
  }

  @override
  Future<bool> deleteGroup(int groupId) async {
    groups = groups.where((g) => g.groupId != groupId).toList();
    // 与真实 VM 同步语义一致：组内设备回落未分组
    for (final key in deviceProfiles.keys.toList()) {
      final p = deviceProfiles[key]!;
      if (p.groupId == groupId) {
        deviceProfiles[key] = DeviceProfile(
          configId: p.configId,
          deviceName: p.deviceName,
          sensors: p.sensors,
          thresholds: p.thresholds,
          payloadVersion: p.payloadVersion,
          groupId: null,
        );
      }
    }
    notifyListeners();
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeGroupVM vm;

  DeviceGroup group(int id, String name, {int sortOrder = 0}) =>
      DeviceGroup(groupId: id, groupName: name, sortOrder: sortOrder, createdAt: 0);

  void addDevice({
    required int configId,
    required String name,
    int? groupId,
  }) {
    vm.latestReadings[name] = {
      SensorType.temperature: Measurement(
        configId: configId,
        sensorType: SensorType.temperature,
        value: 2550,
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
    };
    vm.deviceProfiles[name] = DeviceProfile(
      configId: configId,
      deviceName: name,
      sensors: const [SensorType.temperature],
      groupId: groupId,
    );
  }

  setUp(() {
    vm = _FakeGroupVM();
    vm.groups = [group(1, '客厅', sortOrder: 0), group(2, '卧室', sortOrder: 1)];
    addDevice(configId: 1, name: '客厅温度计', groupId: 1);
  });

  Widget wrap() {
    return ScreenUtilInit(
      designSize: const Size(393, 873),
      builder: (context, _) => MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: ChangeNotifierProvider<DeviceVM>.value(
            value: vm,
            child: const GroupManagementPage(),
          ),
        ),
      ),
    );
  }

  void usePhoneSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(393, 873);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// 打开名称对话框 → 输入 → 点「确定」
  Future<void> submitName(WidgetTester tester, String name) async {
    await tester.enterText(find.byKey(const ValueKey('group-name-field')), name);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('group-dialog-confirm')));
    await tester.pumpAndSettle();
  }

  testWidgets('空分组时展示空态与新建按钮', (tester) async {
    usePhoneSurface(tester);
    vm.groups = [];
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('还没有分组\n点击下方按钮新建一个吧'), findsOneWidget);
    expect(find.byKey(const ValueKey('group-manage-add')), findsOneWidget);
  });

  testWidgets('列表展示分组名与组内设备数', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.byKey(const ValueKey('group-row-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('group-row-2')), findsOneWidget);
    expect(find.text('客厅'), findsOneWidget);
    expect(find.text('卧室'), findsOneWidget);
    // 客厅 1 台、卧室 0 台
    expect(find.text('1 台设备'), findsOneWidget);
    expect(find.text('0 台设备'), findsOneWidget);
  });

  testWidgets('新建分组：输入名称确认后列表出现新行', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('group-manage-add')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await submitName(tester, '书房');

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('书房'), findsOneWidget);
    expect(vm.groups.map((g) => g.groupName), contains('书房'));
  });

  testWidgets('新建分组：重名被拦截，对话框不关闭', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('group-manage-add')));
    await tester.pumpAndSettle();

    await submitName(tester, '客厅');

    // 对话框还在，且错误文案可见；VM 没有新增
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('该分组名称已存在'), findsOneWidget);
    expect(vm.groups.length, 2);

    // 取消退出
    await tester.tap(find.byKey(const ValueKey('group-dialog-cancel')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('重命名：预填旧名，确认后列表与 VM 更新', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('group-row-menu-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('group-row-rename-2')));
    await tester.pumpAndSettle();

    // 预填旧名
    expect(
      tester.widget<TextField>(
        find.byKey(const ValueKey('group-name-field')),
      ).controller!.text,
      '卧室',
    );

    await submitName(tester, '主卧');

    expect(find.text('主卧'), findsOneWidget);
    expect(find.text('卧室'), findsNothing);
    expect(
      vm.groups.firstWhere((g) => g.groupId == 2).groupName,
      '主卧',
    );
  });

  testWidgets('删除：确认框明示设备数，确认后行消失且设备回落未分组', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('group-row-menu-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('group-row-delete-1')));
    await tester.pumpAndSettle();

    // 确认文案包含分组名与受影响设备数
    //（页面上的行文本也是「客厅」，用整句前缀把匹配限定在对话框里）
    expect(find.textContaining('确定要删除「客厅」'), findsOneWidget);
    expect(find.textContaining('1 台设备将变为未分组'), findsOneWidget);

    // 先取消：不应删除
    await tester.tap(find.byKey(const ValueKey('group-delete-cancel')));
    await tester.pumpAndSettle();
    expect(vm.groups.length, 2);

    // 再走一遍并确认
    await tester.tap(find.byKey(const ValueKey('group-row-menu-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('group-row-delete-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('group-delete-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('group-row-1')), findsNothing);
    expect(vm.groups.map((g) => g.groupId), [2]);
    // 组内设备回落未分组
    expect(vm.deviceProfiles['客厅温度计']!.groupId, isNull);
  });

  testWidgets('拖拽排序：把手拖动后 VM 中的顺序翻转', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(vm.groups.map((g) => g.groupId), [1, 2]);

    // 拖第一行的把手往下移过第二行
    // （buildDefaultDragHandles 关闭后只有把手能发起拖拽）
    final handle = find.descendant(
      of: find.byKey(const ValueKey('group-row-1')),
      matching: find.byIcon(Icons.drag_handle),
    );
    await tester.drag(handle, const Offset(0, 150));
    await tester.pumpAndSettle();

    expect(vm.groups.map((g) => g.groupId), [2, 1]);
    // 新的 sortOrder 已按新顺序重写
    expect(vm.groups.first.sortOrder, 0);
    expect(vm.groups.last.sortOrder, 1);
  });
}
