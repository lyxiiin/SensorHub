import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/data/services/settings_service.dart';
import 'package:sensor_hub/utils/app_logger.dart';

class ProfileVM extends ChangeNotifier {
  ThemeMode? tempSelectedValue;

  List<List<String>> languageList = SettingsService.languageList;

  String? _tempLanguageName;
  String get tempLanguageName => _tempLanguageName ?? '';

  // 从 SettingsService 获取当前值进行初始化
  void initFromSettings(SettingsService settings) {
    tempSelectedValue = settings.themeMode;
    _tempLanguageName = settings.languageName;
    notifyListeners();
  }

  void resetTheme() {
    tempSelectedValue = null;
  }

  void resetLanguage() {
    _tempLanguageName = null;
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

  Future<void> saveTheme(SettingsService settings) async {
    if (tempSelectedValue != null && tempSelectedValue != settings.themeMode) {
      await settings.setTheme(tempSelectedValue!);
    }
    notifyListeners();
  }

  Future<void> saveLanguage(SettingsService settings) async {
    if (_tempLanguageName != null && _tempLanguageName != settings.languageName) {
      for (var i = 0; i < languageList.length; i++) {
        if (languageList[i][0] == _tempLanguageName) {
          await settings.setLanguage(languageList[i][1]);
          break;
        }
      }
      logD('语言已切换为: ${settings.languageCode}', tag: 'Profile');
      notifyListeners();
    }
  }
}