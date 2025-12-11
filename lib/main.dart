import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/repositories/user_config_repository.dart';
import 'ui/main/widgets/app.dart';
import 'data/services/shared_preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SPUtil.init();
    UserConfigRepository userConfig = UserConfigRepository();
    if(userConfig.checkFirstRun()){
      await userConfig.initializeConfig();
    }
    userConfig.readUserConfig();

    // 设置状态栏系统
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    runApp(MyApp(userConfig: userConfig));
  } catch (e) {
    // 即使初始化失败，也运行应用，但可以跳转到一个错误提示页面
    log('SharedPreferences 初始化失败: $e');
    runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('初始化失败...')))));
  }
}