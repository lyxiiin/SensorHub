import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensor_hub/data/services/http/api_config.dart';
import 'package:sensor_hub/data/services/http/api_service.dart';
import 'package:sensor_hub/data/services/settings_service.dart';
import 'package:sensor_hub/l10n/app_localizations.dart';
import 'package:sensor_hub/utils/app_logger.dart';
import 'ui/main/widgets/app.dart';
import 'data/services/shared_preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SPUtil.init();
    final settings = SettingsService();
    if(settings.checkFirstRun()){
      await settings.initializeConfig();
    }
    settings.load();

    // 设置状态栏系统
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    // 初始化服务
    ApiService(config: ApiConfig.development);
    logI('应用启动');
    runApp(MyApp(settingsService: settings));
  } catch (e) {
    // 即使初始化失败，也运行应用，但可以跳转到一个错误提示页面
    logE('应用初始化失败: $e', error: e);
    runApp(const _InitFailedApp());
  }
}

/// 初始化失败时的兜底页。
///
/// 自带 l10n 委托：错误文案也按系统语言解析，
/// 避免在极端场景下向用户暴露硬编码文案。
class _InitFailedApp extends StatelessWidget {
  const _InitFailedApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Builder(
          builder: (context) =>
              Center(child: Text(AppLocalizations.of(context).common_ui_init_failed)),
        ),
      ),
    );
  }
}