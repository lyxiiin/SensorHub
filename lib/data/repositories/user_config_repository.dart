import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:sensor_hub/data/services/shared_preferences_service.dart';

class UserConfigRepository{
  static final UserConfigRepository _instance = UserConfigRepository.internal();
  factory UserConfigRepository() => _instance;
  UserConfigRepository.internal();
  late ThemeMode theme;

  late String language;
  static const List<List<String>> languageList = [
    ["跟随系统", "auto"],
    ["简体中文", "zh_CN"],
    ["繁体中文", "zh_TW"],
    ["English", "en"],
    ["日本語", "ja"],
  ];

  bool checkFirstRun() {
    if(SPUtil().getBool("is_first_run",defaultValue: true) == true){
      return true;
    }
    return false;
  }

  Future<void> initializeConfig() async {
    await SPUtil().setString("theme", "light");
    await SPUtil().setString("language", languageList[1][1]);
    await SPUtil().setBool('is_first_run', false);
    log("首选项设置：OK");
  }

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
      language = SPUtil().getString("language",defaultValue: languageList[1][1]);
      log("当前语言： $language");
    } catch (e){
      log("读取错误$e");
    }
  }

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

  Future<void> saveLanguage({required String newLanguage}) async {
    await SPUtil().setString("language", newLanguage);
  }


}