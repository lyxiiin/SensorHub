import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/data/services/settings_service.dart';
import 'package:sensor_hub/data/services/sync_service.dart';
import 'package:sensor_hub/l10n/app_localizations.dart';
import 'package:sensor_hub/route/routes.dart';
import 'package:sensor_hub/ui/core/themes/app_theme.dart';
import 'package:sensor_hub/ui/device/view_model/device_vm.dart';
import 'package:sensor_hub/ui/profile/view_model/profile_vm.dart';
import 'package:sensor_hub/ui/core/responsive/app_breakpoints.dart';
import 'package:sensor_hub/ui/core/responsive/window_size_guard.dart';

class MyApp extends StatefulWidget{
  final SettingsService settingsService;
  const MyApp({
    super.key,
    required this.settingsService,
  });

  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }

}
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final SyncService _syncService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncService = SyncService();
    _syncService.start(interval: const Duration(minutes: 5));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncService.syncOnce();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncService.stop();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.settingsService),
        Provider<SyncService>.value(value: _syncService),
        ChangeNotifierProvider(create: (context) => DeviceVM()),
        ChangeNotifierProvider(create: (context) => ProfileVM()),
      ],
      child: OKToast(
        child: ScreenUtilInit(
          designSize: const Size(393, 873),
          enableScaleWH: () => !isDesktopPlatForm,
          enableScaleText: () => !isDesktopPlatForm,
          minTextAdapt: true,
          builder: (context,child) {
            return Consumer<SettingsService>(builder: (context,settings,child){
              return MaterialApp(
                key: ValueKey(settings.locale),
                theme: AppThemes.lightTheme,
                darkTheme: AppThemes.darkTheme,
                themeMode: settings.themeMode,
                onGenerateRoute: Routes.generateRoute,
                initialRoute: RoutePath.main,
                locale: settings.locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                // 全局兜底：窗口小于最小可用尺寸（手动拖小 / DPI 极限缩放）时
                // 整体替换为占位页，防止固定尺寸组件溢出
                builder: (context, child) => WindowSizeGuard(child: child),
              );
            });
          },
        ),
      ),
    );
  }
}