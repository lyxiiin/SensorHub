import 'package:flutter/material.dart';

class AppThemes {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4), // Material 3 推荐的主色（紫色）
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 2,
    ),
    scaffoldBackgroundColor: Colors.white,
    textTheme: Typography.material2021().englishLike, // 可选：保持一致字体风格
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFD0BCFF), // 深色模式下更亮的种子色
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.grey,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    scaffoldBackgroundColor: const Color(0xFF1C1B1F), // Material 3 深色背景
    textTheme: Typography.material2021().englishLike,
  );
}