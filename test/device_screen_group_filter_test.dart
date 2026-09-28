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
import 'package:sensor_hub/ui/device/widgets/device_info_card.dart';
import 'package:sensor_hub/ui/device/widgets/device_screen.dart';
import 'package:sensor_hub/ui/device/widgets/group_management_page.dart';

/// 设备列表页「按分组筛选」的组件测试。
///
/// 重点验证两件靠阅读代码不容易发现的事：
///
/// 1. 筛选真的作用在 `itemCount` 上 —— 筛完为空时走空态，
///    而不是渲染一个长度非 0、内容全是零高度占位的列表。
/// 2. 「全部设备」这一项真的能被选中 —— 它靠哨兵值 -1 实现。
///    如果把菜单项的 value 写成 null，PopupMenuButton 的 showButtonMenu()
///    会把它和"用户点空白关掉菜单"当成同一件事，只调用 onCanceled，
///    onSelected 永远不触发。最后一条用例就是守住这个行为的。
class _NoInitDeviceVM extends DeviceVM {
  /// 组件测试里不碰数据库 / MQTT：initData 会连 MQTT broker 并读写 SQLite。
  @override
  Future<void> initData() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _NoInitDeviceVM vm;

  DeviceGroup group(int id, String name) =>
      DeviceGroup(groupId: id, groupName: name, sortOrder: 0, createdAt: 0);

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
    vm = _NoInitDeviceVM();
    vm.groups = [group(1, '客厅'), group(2, '卧室')];
    addDevice(configId: 1, name: '客厅温度计', groupId: 1);
    addDevice(configId: 2, name: '卧室温度计', groupId: 2);
  });

  Widget wrap() {
    return ScreenUtilInit(
      designSize: const Size(393, 873),
      builder: (context, _) => ChangeNotifierProvider<DeviceVM>.value(
        value: vm,
        child: MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          // 「管理分组」入口会 pushNamed 到分组管理页：
          // Provider 必须挂在 MaterialApp 之上，push 出来的路由才能读到
          //（Provider 按 route 作用域隔离，藏在 home 里新路由拿不到）
          onGenerateRoute: (settings) => MaterialPageRoute(
            settings: settings,
            builder: (_) => const GroupManagementPage(),
          ),
          home: const Scaffold(
            body: DeviceScreen(),
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

  /// 点开筛选按钮，再点某个分组项。
  ///
  /// 用菜单项的 Key 定位而不是文案：菜单行里现在还有设备数这个 Text，
  /// 按文案找容易和卡片上的分组标签、按钮上的分组名撞车。
  Future<void> selectGroup(WidgetTester tester, String menuKey) async {
    await tester.tap(find.byType(PopupMenuButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey(menuKey)));
    await tester.pumpAndSettle();
  }

  Finder tagInCard(String text) => find.descendant(
        of: find.byType(DeviceInfoCard),
        matching: find.text(text),
      );

  testWidgets('默认展示「全部设备」，列出所有设备并标出各自分组', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.byType(PopupMenuButton<int>), findsOneWidget);
    expect(find.text('全部设备'), findsOneWidget);
    expect(find.byType(DeviceInfoCard), findsNWidgets(2));
    expect(find.text('客厅温度计'), findsOneWidget);
    expect(find.text('卧室温度计'), findsOneWidget);

    // 卡片上的分组标签
    expect(tagInCard('客厅'), findsOneWidget);
    expect(tagInCard('卧室'), findsOneWidget);
  });

  testWidgets('选中分组后只列出该分组的设备，按钮文案同步更新', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(wrap());
    await tester.pump();

    await selectGroup(tester, 'group-menu-1');

    expect(find.byType(DeviceInfoCard), findsOneWidget);
    expect(find.text('客厅温度计'), findsOneWidget);
    expect(find.text('卧室温度计'), findsNothing);
    // 按钮上换成当前分组名（要限定在按钮内，卡片标签也是"客厅"）
    expect(
      find.descendant(
        of: find.byType(PopupMenuButton<int>),
        matching: find.text('客厅'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('分组下没有设备时展示空态，而不是空白列表', (tester) async {
    usePhoneSurface(tester);
    vm.groups = [group(1, '客厅'), group(2, '卧室'), group(3, '书房')];
    await tester.pumpWidget(wrap());
    await tester.pump();

    await selectGroup(tester, 'group-menu-3');

    expect(find.byType(DeviceInfoCard), findsNothing);
    expect(find.text('该分组暂无设备'), findsOneWidget);
  });

  testWidgets('从分组切回「全部设备」能恢复完整列表', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(wrap());
    await tester.pump();

    await selectGroup(tester, 'group-menu-1');
    expect(find.byType(DeviceInfoCard), findsOneWidget);

    // 关键一步：这一项的 value 是哨兵 -1。
    // 若改成 null，点击不会有任何反应，下面的断言就会失败。
    await selectGroup(tester, 'group-menu-all');

    expect(find.byType(DeviceInfoCard), findsNWidgets(2));
    expect(find.text('卧室温度计'), findsOneWidget);
  });

  testWidgets('菜单按 groupId 升序展示、标注各分组设备数，并带管理分组入口', (tester) async {
    usePhoneSurface(tester);
    // 故意乱序塞进去：UI 必须自己按 groupId 排，不能依赖 vm.groups 的顺序
    vm.groups = [group(2, '卧室'), group(1, '客厅')];
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.byType(PopupMenuButton<int>));
    await tester.pumpAndSettle();

    final livingY = tester.getTopLeft(find.byKey(const ValueKey('group-menu-1'))).dy;
    final bedroomY =
        tester.getTopLeft(find.byKey(const ValueKey('group-menu-2'))).dy;
    expect(livingY, lessThan(bedroomY), reason: '分组应按 groupId 升序排列');

    // 设备数：全部 2 台，每个分组各 1 台
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('group-menu-all')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('group-menu-1')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    // 管理分组入口（点击后跳转分组管理页，导航行为在下方独立用例验证）
    expect(find.byKey(const ValueKey('group-menu-manage')), findsOneWidget);
    expect(find.text('管理分组'), findsOneWidget);
  });

  testWidgets('「管理分组」入口跳转到分组管理页', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(wrap());
    await tester.pump();

    await selectGroup(tester, 'group-menu-manage');

    expect(find.byType(GroupManagementPage), findsOneWidget);
    // 页面标题正确
    expect(find.text('分组管理'), findsOneWidget);
  });
}
