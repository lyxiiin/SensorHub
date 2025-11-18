import 'package:flutter/material.dart';
import 'package:sensor_hub/data/repositories/user_config_repository_impl.dart';

class AppVM extends ChangeNotifier{
  ThemeMode themeModelSelectedValue = ThemeMode.system;

  void initApp() {
    UserConfigRepositoryImpl userConfig = UserConfigRepositoryImpl();
    themeModelSelectedValue = userConfig.theme;
    notifyListeners();
  }

  Future<void> changedThemeModelSelectedValue(ThemeMode? value) async {
    if(value != null){
      themeModelSelectedValue = value;
      await UserConfigRepositoryImpl().saveTheme(newTheme: value);
    }
    notifyListeners();
  }

}