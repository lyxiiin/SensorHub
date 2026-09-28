import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/data/models/device_config.dart';
import 'package:sensor_hub/data/models/device_group.dart';
import 'package:sensor_hub/l10n/app_localizations.dart';
import 'package:sensor_hub/ui/device/view_model/device_vm.dart';
import 'package:sensor_hub/ui/device/widgets/device_registration_form_page.dart';

/// 注册 / 编辑页「设备分组」下拉框的 UI 测试。
///
/// 只覆盖 UI 层：下拉框画出来了、选项按 groupId 升序、编辑态能按
/// DeviceConfig.groupId 回填、label 与选中值不重叠。
/// 选中值目前还没有落到数据库（保存链路尚未接入），所以这里不断言持久化。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DeviceVM vm;

  DeviceGroup group(int id, String name) =>
      DeviceGroup(groupId: id, groupName: name, sortOrder: 0, createdAt: 0);

  setUp(() {
    vm = DeviceVM();
    // 故意乱序塞进去：UI 必须自己按 groupId 排
    vm.groups = [group(2, '卧室'), group(1, '客厅')];
  });

  void usePhoneSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(393, 873);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// 模拟 RouteUtils.pushForNamed(..., arguments: ...) 之后的页面栈，
  /// settings 必须原样透传，arguments 才能被 ModalRoute 读到。
  Future<void> pumpForm(WidgetTester tester, {DeviceConfig? argument}) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 873),
        builder: (context, _) => ChangeNotifierProvider<DeviceVM>.value(
          value: vm,
          child: MaterialApp(
            navigatorKey: navKey,
            locale: const Locale('zh'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            onGenerateRoute: (settings) => MaterialPageRoute(
              settings: settings,
              builder: (_) => const DeviceRegistrationFormPage(),
            ),
          ),
        ),
      ),
    );
    navKey.currentState!.pushNamed('DeviceRegistrationFromPage',
        arguments: argument);
    await tester.pumpAndSettle();
  }

  DeviceConfig config({int? groupId, String mac = 'AABBCCDDEEFF'}) => DeviceConfig(
        configId: 7,
        groupId: groupId,
        deviceName: '环境监测站',
        broker: '192.168.1.10',
        port: 1883,
        clientId: 'c7',
        upTopic: 'env_monitor/$mac/data',
        downTopic: 'env_monitor/$mac/cmd',
        username: 'mqtt_user',
        password: 'secret123',
        macAddress: mac,
      );

  /// 读出下拉框内部 IndexedStack 的 index。
  ///
  /// DropdownButton 用 `IndexedStack(index: _selectedIndex ?? hintIndex)` 决定
  /// 按钮上显示哪一项。items 排成 [未分组(0), 客厅(1), 卧室(2)]，
  /// 所以 index 0 = 未分组、1 = 客厅、2 = 卧室。
  ///
  /// 这同时验证了选项顺序：vm.groups 传进去是乱序的 [卧室, 客厅]，
  /// 若 UI 没按 groupId 排序，groupId=1 就不会落在 index 1 上。
  int dropdownIndex(WidgetTester tester) {
    final stack = tester.widget<IndexedStack>(
      find.descendant(
        of: find.byType(DropdownButtonFormField<int?>),
        matching: find.byType(IndexedStack),
      ),
    );
    return stack.index!;
  }

  testWidgets('注册态：分组下拉框渲染出来，默认选中「未分组」', (tester) async {
    usePhoneSurface(tester);
    await pumpForm(tester);

    expect(find.text('设备分组'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int?>), findsOneWidget);
    // 未分组是一个真实的 value: null 选项，占用 items[0]
    expect(dropdownIndex(tester), 0);
    expect(find.text('未分组'), findsOneWidget);
  });

  testWidgets('label 上浮到边框上，不与选中值重叠', (tester) async {
    usePhoneSurface(tester);
    await pumpForm(tester);

    final labelRect = tester.getRect(find.text('设备分组'));
    final valueRect = tester.getRect(find.text('未分组'));
    expect(
      labelRect.bottom,
      lessThanOrEqualTo(valueRect.top),
      reason: 'InputDecorator 的 isEmpty 若为 true，label 会留在内容区并与选中值重叠',
    );
  });

  testWidgets('编辑态：按 DeviceConfig.groupId 回填选中项', (tester) async {
    usePhoneSurface(tester);
    await pumpForm(tester, argument: config(groupId: 1));

    expect(find.text('编辑设备'), findsOneWidget);
    // items 排成 [未分组, 客厅(1), 卧室(2)]，groupId=1 → index 1
    expect(dropdownIndex(tester), 1);
  });

  testWidgets('编辑态：未分组的设备回填为「未分组」', (tester) async {
    usePhoneSurface(tester);
    await pumpForm(tester, argument: config());

    expect(dropdownIndex(tester), 0);
  });

  testWidgets('编辑态：groupId 在选项里找不到时回退到「未分组」而不崩', (tester) async {
    usePhoneSurface(tester);
    // 99 不在 vm.groups 里：DropdownButton 内部有
    // assert(items.where((i) => i.value == value).length == 1)，
    // 直接把悬空 id 传下去会在 debug 断言失败，所以实现里做了兜底
    await pumpForm(tester, argument: config(groupId: 99));

    expect(dropdownIndex(tester), 0);
    expect(tester.takeException(), isNull);
  });
}
