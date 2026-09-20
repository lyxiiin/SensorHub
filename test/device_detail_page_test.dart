import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sensor_hub/data/dao/device_config_dao.dart';
import 'package:sensor_hub/data/dao/measurement_dao.dart';
import 'package:sensor_hub/data/models/device_config.dart';
import 'package:sensor_hub/data/models/measurement.dart';
import 'package:sensor_hub/data/models/sensor_type.dart';
import 'package:sensor_hub/l10n/app_localizations.dart';
import 'package:sensor_hub/ui/device/view_model/device_vm.dart';
import 'package:sensor_hub/ui/device/widgets/device_registration_form_page.dart';
import 'package:sensor_hub/ui/device_detail/device_detail_vm.dart';
import 'package:sensor_hub/ui/device_detail/widgets/device_detail_page.dart';
import 'package:sensor_hub/ui/device_detail/widgets/device_info_section.dart';
import 'package:sensor_hub/ui/device_detail/widgets/sensor_chart_card.dart';

/// 设备详情页相关组件的 Widget 测试
///
/// 覆盖：传感器卡片渲染、图表卡片（有数据 / 空态 / 加载态）、
/// 时间范围与传感器切换回调，以及整个详情页的布局（含空态）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(393, 873),
      builder: (context, _) => MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: child),
      ),
    );
  }

  void usePhoneSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(393, 873);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  List<Measurement> temperatureHistory() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return [
      Measurement(
        configId: 1,
        sensorType: SensorType.temperature,
        value: 2550, // 25.5℃
        timestamp: now - 3600,
      ),
      Measurement(
        configId: 1,
        sensorType: SensorType.temperature,
        value: 3100, // 31.0℃
        timestamp: now,
      ),
    ];
  }

  group('DeviceInfoSection', () {
    testWidgets('渲染传感器名称、格式化数值与单位', (tester) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(
        wrap(
          DeviceInfoSection(
            item: Measurement(
              configId: 1,
              sensorType: SensorType.temperature,
              value: 2550,
              timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            ),
          ),
        ),
      );

      expect(find.text('温度'), findsOneWidget);
      expect(find.text('25.50'), findsOneWidget);
      expect(find.text('℃'), findsOneWidget);
    });
  });

  group('SensorChartCard', () {
    testWidgets('有数据时渲染折线图与统计摘要', (tester) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(
        wrap(
          SensorChartCard(
            availableSensors: const [
              SensorType.temperature,
              SensorType.humidity,
            ],
            chartData: temperatureHistory(),
            selectedType: SensorType.temperature,
            selectedRange: '24h',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 工具栏
      expect(find.text('温度 (℃)'), findsOneWidget);
      expect(find.text('1d'), findsOneWidget);
      expect(find.text('7d'), findsOneWidget);
      // 统计摘要（温度保留 2 位小数；Text.rich 需用 textContaining 匹配）
      expect(find.text('当前'), findsOneWidget);
      expect(find.text('最高'), findsOneWidget);
      expect(find.text('最低'), findsOneWidget);
      expect(find.text('平均'), findsOneWidget);
      expect(find.textContaining('31.00'), findsWidgets);
      expect(find.textContaining('25.50'), findsWidgets);
      expect(find.textContaining('28.25'), findsOneWidget);
    });

    testWidgets('无数据时展示空态', (tester) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(
        wrap(
          const SensorChartCard(
            availableSensors: [SensorType.temperature],
            chartData: [],
            selectedType: SensorType.temperature,
            selectedRange: '1d',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('暂无数据'), findsOneWidget);
    });

    testWidgets('加载中展示进度占位', (tester) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(
        wrap(
          const SensorChartCard(
            availableSensors: [SensorType.temperature],
            chartData: [],
            selectedType: SensorType.temperature,
            selectedRange: '1d',
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('加载中…'), findsOneWidget);
    });

    testWidgets('点击时间范围按钮上报回调', (tester) async {
      usePhoneSurface(tester);
      String? changed;
      await tester.pumpWidget(
        wrap(
          SensorChartCard(
            availableSensors: const [SensorType.temperature],
            chartData: temperatureHistory(),
            selectedType: SensorType.temperature,
            selectedRange: '1d',
            onTimeRangeChanged: (range) => changed = range,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('1d'));
      expect(changed, '1d');
    });

    testWidgets('切换传感器下拉上报回调', (tester) async {
      usePhoneSurface(tester);
      SensorType? changed;
      await tester.pumpWidget(
        wrap(
          SensorChartCard(
            availableSensors: const [
              SensorType.temperature,
              SensorType.humidity,
            ],
            chartData: temperatureHistory(),
            selectedType: SensorType.temperature,
            selectedRange: '1d',
            onSensorTypeChanged: (type) => changed = type,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('温度 (℃)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('湿度 (%)').last);
      await tester.pumpAndSettle();

      expect(changed, SensorType.humidity);
    });
  });

  group('DeviceDetailPage', () {
    testWidgets('渲染概览卡、分区与空态（无溢出异常）', (tester) async {
      usePhoneSurface(tester);
      // 使用空数据 Fake DAO，避免测试环境依赖数据库插件
      final vm = DeviceDetailVm(
        configDao: _FakeConfigDao(),
        measurementDao: _FakeMeasurementDao(),
      );
      await tester.pumpWidget(
        wrap(
          ChangeNotifierProvider.value(
            value: vm,
            child: const DeviceDetailPage(deviceId: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // AppBar 标题（未知设备兜底）
      expect(find.text('未知设备'), findsWidgets);
      // 分区标题
      expect(find.text('实时数据'), findsOneWidget);
      expect(find.text('历史趋势'), findsOneWidget);
      // 空态（实时数据区 + 图表区各一处）
      expect(find.text('暂无数据'), findsNWidgets(2));
      // 历史趋势卡片仍在（图表显示空态而非崩溃）
      expect(find.byType(SensorChartCard), findsOneWidget);
      // 无布局溢出异常（若有 overflow，测试会直接失败）
    });

    testWidgets('有传感器数据时渲染双列卡片与图表', (tester) async {
      usePhoneSurface(tester);
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final vm = DeviceDetailVm(
        configDao: _FakeConfigDao(
          config: DeviceConfig(
            configId: 1,
            deviceName: '环境监测站',
            broker: '127.0.0.1',
            port: 1883,
            clientId: 'c1',
            upTopic: 'env/AA/data',
            downTopic: 'env/AA/cmd',
            username: 'u',
            password: 'p',
            macAddress: 'AABBCCDDEEFF',
          ),
        ),
        measurementDao: _FakeMeasurementDao(
          latest: {
            SensorType.temperature: Measurement(
              configId: 1,
              sensorType: SensorType.temperature,
              value: 2550,
              timestamp: now,
            ),
            SensorType.humidity: Measurement(
              configId: 1,
              sensorType: SensorType.humidity,
              value: 6500,
              timestamp: now,
            ),
            SensorType.co2: Measurement(
              configId: 1,
              sensorType: SensorType.co2,
              value: 800,
              timestamp: now,
            ),
          },
          history: [
            Measurement(
              configId: 1,
              sensorType: SensorType.temperature,
              value: 2550,
              timestamp: now - 3600,
            ),
            Measurement(
              configId: 1,
              sensorType: SensorType.temperature,
              value: 3100,
              timestamp: now,
            ),
          ],
        ),
      );
      await tester.pumpWidget(
        wrap(
          ChangeNotifierProvider.value(
            value: vm,
            child: const DeviceDetailPage(deviceId: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 概览卡：设备名 + MAC + 在线状态
      expect(find.text('环境监测站'), findsNWidgets(2)); // AppBar + 概览卡
      expect(find.textContaining('AABBCCDDEEFF'), findsOneWidget);
      expect(find.text('在线'), findsOneWidget);
      // 传感器卡片
      expect(find.text('温度'), findsOneWidget);
      expect(find.text('湿度'), findsOneWidget);
      expect(find.text('二氧化碳'), findsOneWidget);
      // 图表统计摘要（温度数据）
      expect(find.textContaining('31.00'), findsWidgets);
    });

    testWidgets('详情页编辑：表单页能收到 DeviceConfig 路由参数并预填', (tester) async {
      usePhoneSurface(tester);
      final config = DeviceConfig(
        configId: 7,
        deviceName: '环境监测站',
        broker: '192.168.1.10',
        port: 1883,
        clientId: 'c7',
        upTopic: 'env_monitor/AABBCCDDEEFF/data',
        downTopic: 'env_monitor/AABBCCDDEEFF/cmd',
        username: 'mqtt_user',
        password: 'secret123',
        macAddress: 'AABBCCDDEEFF',
      );

      // 模拟 RouteUtils.pushForNamed(..., arguments: config) 之后的页面栈
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(393, 873),
          builder: (context, _) => MultiProvider(
            providers: [ChangeNotifierProvider(create: (_) => DeviceVM())],
            child: MaterialApp(
              navigatorKey: navKey,
              locale: const Locale('zh'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              // 等价于 Routes.generateRoute：
              // 关键是 settings 原样透传给页面，arguments 才能被 ModalRoute 读到
              onGenerateRoute: (settings) => MaterialPageRoute(
                settings: settings,
                builder: (_) => const DeviceRegistrationFormPage(),
              ),
            ),
          ),
        ),
      );
      navKey.currentState!.pushNamed(
        'DeviceRegistrationFromPage',
        arguments: config,
      );
      await tester.pumpAndSettle();

      // 路由参数被正确解析：以编辑态呈现
      expect(find.text('编辑设备'), findsOneWidget);
      expect(find.text('保存修改'), findsOneWidget);
      // 表单字段按 DeviceConfig 预填
      expect(
        tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, '名称'),
        ).controller!.text,
        '环境监测站',
      );
      expect(
        tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, '服务器地址(Broker)'),
        ).controller!.text,
        '192.168.1.10',
      );
      expect(
        tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, '端口(Port)'),
        ).controller!.text,
        '1883',
      );
      expect(
        tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, '上行主题(Topic)'),
        ).controller!.text,
        'env_monitor/AABBCCDDEEFF/data',
      );
      // 已有 clientId → 高级设置自动展开并回填
      expect(
        tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, '客户端ID (Client ID)'),
        ).controller!.text,
        'c7',
      );
    });

    testWidgets('无路由参数进入表单页时保持注册态（不加参数即新增）', (tester) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(
        wrap(
          ChangeNotifierProvider(
            create: (_) => DeviceVM(),
            child: const DeviceRegistrationFormPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('注册设备'), findsWidgets);
      expect(find.text('编辑设备'), findsNothing);
    });
  });
}

/// 空数据 Fake：查询不到任何设备 / 读数
class _FakeConfigDao implements DeviceConfigDao {
  _FakeConfigDao({this.config});

  final DeviceConfig? config;

  @override
  Future<Database> get db async => throw UnimplementedError();

  @override
  Future<int> insert(DeviceConfig config) async => 1;

  @override
  Future<int> update(DeviceConfig config) async => 1;

  @override
  Future<int> updateByClientId(DeviceConfig config) async => 1;

  @override
  Future<int> delete(int id) async => 1;

  @override
  Future<List<DeviceConfig>> getAll() async => config == null ? [] : [config!];

  @override
  Future<DeviceConfig?> getById(int id) async => config;

  @override
  Future<DeviceConfig?> getByClientId(String clientId) async => config;

  @override
  Future<DeviceConfig?> getByMacAddress(String mac) async => config;
}

class _FakeMeasurementDao implements MeasurementDao {
  _FakeMeasurementDao({this.latest = const {}, this.history = const []});

  final Map<SensorType, Measurement> latest;
  final List<Measurement> history;

  @override
  Future<Database> get db async => throw UnimplementedError();

  @override
  Future insertBatch(List<Measurement> measurements) async {}

  @override
  Future<List<Measurement>> queryHistory({
    required int configId,
    required SensorType type,
    int? startTime,
    int? endTime,
  }) async => history;

  @override
  Future<Map<SensorType, Measurement>> queryLatest(int configId) async =>
      latest;

  @override
  Future<List<Measurement>> queryByThreshold({
    required int configId,
    required SensorType type,
    int? maxValue,
    int? minValue,
  }) async => [];
}
