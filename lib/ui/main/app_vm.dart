import 'package:flutter/material.dart';

class AppVM extends ChangeNotifier{
  ThemeMode themeModelSelectedValue = ThemeMode.light;

  void changedThemeModelSelectedValue(ThemeMode? value){
    themeModelSelectedValue = value ?? ThemeMode.light;
    notifyListeners();
  }

}