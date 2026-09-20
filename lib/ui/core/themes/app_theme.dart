import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppThemes {
  /// 注意：主题里用到了 ScreenUtil 的 `.r` / `.sp` 缩放，
  /// 必须在 ScreenUtilInit 初始化完成之后再取值。
  /// app.dart 中 MaterialApp 建在 ScreenUtilInit 的 builder 内，
  /// 主题第一次被访问就在这里，因此是安全的；不要在 main() 里提前引用。
  static final lightTheme = _build(
    seedColor: const Color(0xFF6750A4),
    brightness: Brightness.light,
  );

  static final darkTheme = _build(
    seedColor: const Color(0xFFD0BCFF),
    brightness: Brightness.dark,
  );

  static ThemeData _build({
    required Color seedColor,
    required Brightness brightness,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
    );

    return base.copyWith(
      // AppBar 的样式统一在这里定义：页面只写 AppBar(title: ...)。
      // titleTextStyle 由 titleLarge 派生，保证行高/字距与 M3 默认一致。
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerHigh,
        iconTheme: IconThemeData(color: colorScheme.primary, size: 20.r),
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}
