import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/data/repositories/user_config_repository.dart';
import '../../main/app_vm.dart';

class ProfileVM extends ChangeNotifier {
  ThemeMode? tempSelectedValue;

  List<List<String>> languageList = UserConfigRepository.languageList;

  String? _tempLanguageName;
  String get tempLanguageName => _tempLanguageName ?? '';

  // 从 AppVM 获取当前值进行初始化
  void initFromAppVM(AppVM appVM) {
    tempSelectedValue = appVM.themeModelSelectedValue;
    _tempLanguageName = appVM.languageName;
    notifyListeners();
  }

  void changedTempThemeValue(ThemeMode? value) {
    if (value != null) {
      tempSelectedValue = value;
    }
    notifyListeners();
  }

  void changedTempLanguage(int value) {
    _tempLanguageName = languageList[value][0];
    notifyListeners();
  }

  Future<void> saveTheme(AppVM appVM) async {
    if (tempSelectedValue != null && tempSelectedValue != appVM.themeModelSelectedValue) {
      appVM.themeModelSelectedValue = tempSelectedValue!;
      await UserConfigRepository().saveTheme(newTheme: appVM.themeModelSelectedValue);
    }
    notifyListeners();
  }

  Future<void> saveLanguage(AppVM appVM) async {
    if (_tempLanguageName != null && _tempLanguageName != appVM.languageName) {
      for (var i = 0; i < languageList.length; i++) {
        if (languageList[i][0] == _tempLanguageName) {
          appVM.languageCode = languageList[i][1];
          await UserConfigRepository().saveLanguage(newLanguage: appVM.languageCode);
          break;
        }
      }
      
      if (appVM.languageCode == 'auto') {
        appVM.setAutoLanguage();
      } else {
        appVM.setCurrentLanguage(appVM.languageCode);
      }
      log("当前语言: ${appVM.languageCode}");
    }
    notifyListeners();
  }
}