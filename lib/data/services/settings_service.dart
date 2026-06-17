import 'package:flutter/material.dart';
import 'package:sensor_hub/data/services/shared_preferences_service.dart';
import 'package:sensor_hub/utils/app_logger.dart';

class SettingsService extends ChangeNotifier{

  //主题
  ThemeMode themeMode = ThemeMode.system;

  // 语言
  late String languageCode;
  late String languageName;
  late Locale locale;

  // 单位
  late String unit;

  // ── 语言列表（静态常量，全局共享）──
  static const List<List<String>> languageList = [
    ["跟随系统", "auto"],
    ["简体中文", "zh_CN"],
    ["繁体中文", "zh_TW"],
    ["English", "en"],
    ["日本語", "ja"],
  ];

  Future<void> initializeConfig() async {
    await SPUtil().setString("theme", "light");
    await SPUtil().setString("language", languageList[1][1]);
    await SPUtil().setBool('is_first_run', false);
    logI('首次运行，已写入默认配置', tag: 'Settings');
  }
  void load() {
    try{
      final themeStr = SPUtil().getString("theme",defaultValue: "system");
      switch(themeStr){
        case 'light':
          themeMode = ThemeMode.light;
          break;
        case 'dark':
          themeMode = ThemeMode.dark;
          break;
        default:
          themeMode = ThemeMode.system;
          break;
      }
      languageCode = SPUtil().getString("language",defaultValue: languageList[1][1]);
      languageName = _findLanguageName(languageCode);
      _applyLocale(languageCode);


      logI('加载完成: theme=$themeMode, lang=$languageCode', tag: 'Settings');
    } catch (e){
      logE('加载配置失败: $e', error: e, tag: 'Settings');
    }
  }
  bool checkFirstRun() {
    if(SPUtil().getBool("is_first_run",defaultValue: true) == true){
      return true;
    }
    return false;
  }

  // ────────── 主题操作 ──────────
  Future<void> setTheme(ThemeMode mode) async {
    if (themeMode == mode) return;
    themeMode = mode;
    notifyListeners();
    final String value;
    switch(mode){
      case ThemeMode.light:
        value = "light";
        break;
      case ThemeMode.dark:
        value = "dark";
        break;
      default:
        value = "system";
        break;
    }
    await SPUtil().setString("theme", value);
  }

  // ────────── 语言操作 ──────────

  Future<void> setLanguage(String code) async {
    if (languageCode == code) return;
    languageCode = code;
    languageName = _findLanguageName(code);
    _applyLocale(code);
    notifyListeners();
    await SPUtil().setString("language", code);
  }


   String _findLanguageName(String languageCode){
    return languageList.firstWhere((element) => element[1] == languageCode)[0];
   }

  void _applyLocale(String code){
    if(code == 'auto'){
      _resolveSystemLocale();
    }else if(code.length > 2){
      locale = Locale(code.substring(0,2), code.substring(3));
    }else{
      locale = Locale(code);
    }
  }

  void _resolveSystemLocale(){
    final system = WidgetsBinding.instance.platformDispatcher.locale;
    if(system.languageCode == 'zh'){
      final code = system.countryCode == "TW" ? languageList[2][1] : languageList[1][1];
      locale = _codeToLocale(code);
      return;
    }
      for (var entry in languageList) {
        if (entry[1] == 'auto') continue;
        if (system.languageCode == entry[1].split('_')[0]) {
          locale = _codeToLocale(entry[1]);
          return;
      }
    }

    // fallback: English
    locale = _codeToLocale(languageList[3][1]);
  }

  static Locale _codeToLocale(String code) {
    if (code.length > 2) {
      return Locale(code.substring(0, 2), code.substring(3));
    }
    return Locale(code);
  }
}