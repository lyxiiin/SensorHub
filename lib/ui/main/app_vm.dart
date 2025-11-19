import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:sensor_hub/data/repositories/user_config_repository_impl.dart';

class AppVM extends ChangeNotifier{
  ThemeMode themeModelSelectedValue = ThemeMode.system;
  ThemeMode? tempSelectedValue;

  List<List<String>> languageList = UserConfigRepository.languageList;


  late String languageCode;     //当前语言——代码
  late String languageName; //当前语言——文本

  late Locale currentLocale;
  
  void initApp() {
    UserConfigRepository userConfig = UserConfigRepository();
    themeModelSelectedValue = userConfig.theme;
    tempSelectedValue = themeModelSelectedValue;

    languageCode = userConfig.language;
    for(var i=0;i<languageList.length;i++){
      if(languageList[i][1] == languageCode){
        languageName = languageList[i][0];
        break;
      }
    }
    if(languageCode == 'auto'){
      setAutoLanguage();
    }else{
      setCurrentLanguage(languageCode);
    }
    notifyListeners();
  }

  Future<void> changedThemeModelSelectedValue() async {
    if(tempSelectedValue != null && tempSelectedValue != themeModelSelectedValue){
      themeModelSelectedValue = tempSelectedValue!;
      await UserConfigRepository().saveTheme(newTheme: themeModelSelectedValue);
    }
    notifyListeners();
  }
  void changedTempSelectedValue(ThemeMode? value) {
    if(value != null){
      tempSelectedValue = value;
    }
    notifyListeners();
  }


  void changedTempLanguage(int value){
    languageName = languageList[value][0];
    notifyListeners();
  }

  Future<void> changedLanguage() async {
    if(languageName != languageCode){
      for(var i=0;i<languageList.length;i++){
        if(languageList[i][0] == languageName){
          languageCode = languageList[i][1];
          await UserConfigRepository().saveLanguage(newLanguage: languageCode);
          break;
        }
      }
    }
    if(languageCode == 'auto'){
      setAutoLanguage();
    }else{
      setCurrentLanguage(languageCode);
    }
    log("当前语言: $languageCode");
    notifyListeners();
  }

  void setAutoLanguage(){
    Locale systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    log("系统语言: ${systemLocale.languageCode}, 国家/地区: ${systemLocale.countryCode}");
    
    // 针对中文的特殊处理
    if(systemLocale.languageCode == 'zh'){
      if(systemLocale.countryCode == "TW"){
        setCurrentLanguage(languageList[2][1]); // 繁体中文
      } else {
        setCurrentLanguage(languageList[1][1]); // 简体中文（包括CN和其他情况）
      }
    } else {
      // 对于非中文语言，尝试匹配
      bool found = false;
      for(var i=0;i<languageList.length;i++){
        if(systemLocale.languageCode == languageList[i][1].split('_')[0]){
          setCurrentLanguage(languageList[i][1]);
          found = true;
          break;
        }
      }
      // 如果没有找到匹配的语言，默认使用英语
      if (!found) {
        setCurrentLanguage(languageList[3][1]); // English
      }
    }
  }
  
  void setCurrentLanguage(String language){
    if(language.length > 2){
      currentLocale =  Locale(language.substring(0,2),language.substring(3));
    }else{
      currentLocale =  Locale(language);
    }
    log("设置当前语言环境: $currentLocale");
  }
  
}