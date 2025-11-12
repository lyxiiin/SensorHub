import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // 状态栏透明
        statusBarBrightness: Brightness.dark, // 浅色背景使用深色文字
        statusBarIconBrightness: Brightness.dark, // 状态栏图标深色
      )
  );
  runApp(const MyApp());
}