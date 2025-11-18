import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:sensor_hub/data/services/shared_preferences_service.dart';
import 'package:sensor_hub/domain/user_config_repository.dart';

class UserConfigRepositoryImpl implements UserConfigRepository{
  static final UserConfigRepositoryImpl _instance = UserConfigRepositoryImpl.internal();
  factory UserConfigRepositoryImpl() => _instance;
  UserConfigRepositoryImpl.internal();

  @override
  late ThemeMode theme;

  @override
  bool checkFirstRun() {
    if(SPUtil().getBool("is_first_run",defaultValue: true) == true){
      return true;
    }
    return false;
  }

  @override
  Future<void> initializeConfig() async {
    await SPUtil().setString("theme", "light");
    await SPUtil().setBool('is_first_run', false);
  }

  @override
  void readUserConfig() {
    try{
      final themeStr = SPUtil().getString("theme",defaultValue: "system");
      switch(themeStr){
        case 'light':
          theme = ThemeMode.light;
          break;
        case 'dark':
          theme = ThemeMode.dark;
          break;
        default:
          theme = ThemeMode.system;
          break;
      }
    } catch (e){
      log("读取错误$e");
    }
  }

  @override
  Future<void> saveTheme({required ThemeMode newTheme}) async {
    switch(newTheme){
      case ThemeMode.light:
        await SPUtil().setString("theme", "light");
        break;
      case ThemeMode.dark:
        await SPUtil().setString("theme", "dark");
        break;
      default:
        await SPUtil().setString("theme", "system");
        break;
    }
  }
}