import 'dart:developer';

import 'package:flutter/material.dart';
import 'data/repositories/user_config_repository_impl.dart';
import 'ui/main/widgets/app.dart';
import 'data/services/shared_preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SPUtil.init();
    UserConfigRepositoryImpl userConfig = UserConfigRepositoryImpl();
    if(userConfig.checkFirstRun()){
      await userConfig.initializeConfig();
    }
    userConfig.readUserConfig(); 
    runApp(MyApp(userConfig: userConfig));
  } catch (e) {
    // 即使初始化失败，也运行应用，但可以跳转到一个错误提示页面
    log('SharedPreferences 初始化失败: $e');
    runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('初始化失败...')))));
  }
}