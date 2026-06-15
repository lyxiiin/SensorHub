import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensor_hub/data/services/settings_service.dart';
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

    runApp(MyApp(settingsService: settings));
  } catch (e) {
    // 即使初始化失败，也运行应用，但可以跳转到一个错误提示页面
    log('SharedPreferences 初始化失败: $e');
    runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('初始化失败...')))));
  }
}