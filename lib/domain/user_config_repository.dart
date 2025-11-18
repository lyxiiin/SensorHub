
import 'package:flutter/material.dart';

abstract class UserConfigRepository {
  late ThemeMode theme;

  bool checkFirstRun();
  Future<void> initializeConfig();
  void readUserConfig();

  Future<void> saveTheme({required ThemeMode newTheme});
}