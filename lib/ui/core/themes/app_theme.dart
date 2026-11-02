import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 全局主题。
///
/// 设计约束：**主题里不出现任何 ScreenUtil 缩放**（`.r` / `.sp`）。
///
/// 原因：lightTheme / darkTheme 是 static final，只在首次访问时求值一次
/// 并永久缓存。若主题内部使用 `.r` / `.sp`，主题尺寸就会冻结在
/// 首次访问时的窗口宽度上；而页面里其余的 `.r` 每次读取都会重算，
/// 于是桌面端拖动窗口后 AppBar 与页面其余部分会持续脱节。
/// 主题与缩放解耦之后，static final 缓存才是正确的。
class AppThemes {
  // 亮/暗共用同一个品牌 seed，只切换 brightness。
  static final lightTheme = _build(Brightness.light);
  static final darkTheme = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandSeed,
      brightness: brightness,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
    );

    return base.copyWith(
      // AppBar 的样式统一在这里定义：页面只写 AppBar(title: ...)。
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerHigh,
        // 固定逻辑像素：AppBar 图标不需要按设计稿缩放。
        iconTheme: IconThemeData(color: colorScheme.primary, size: 20),
        // 不指定 fontSize，直接沿用 M3 titleLarge 的字号与行高，
        // 只覆盖字重与颜色。
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}
