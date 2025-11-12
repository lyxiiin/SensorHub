import 'package:flutter/material.dart';

class AppColors {
  // ===== 浅色主题（基于 #07C160）=====
  static const light = ColorScheme(
    brightness: Brightness.light,     // 主题亮度：亮色

    primary: Color(0xFF07C160),       // 主色，通常用于主要按钮和互动元素
    onPrimary: Color(0xFFFFFFFF),     // 在主色上的文本或图标颜色（白色）
    primaryContainer: Color(0xFFBBF7D0), // 主色容器的颜色，适用于背景等
    onPrimaryContainer: Color(0xFF00210F), // 在主色容器上的文本或图标颜色

    secondary: Color(0xFF505A5F),     // 次级色，用于不太重要的组件
    onSecondary: Color(0xFFFFFFFF),   // 在次级色上的文本或图标颜色（白色）
    secondaryContainer: Color(0xFFD3E4E9), // 次级色容器的颜色
    onSecondaryContainer: Color(0xFF0C1B1F), // 在次级色容器上的文本或图标颜色

    tertiary: Color(0xFF6F577A),      // 第三种颜色，用于特殊组件
    onTertiary: Color(0xFFFFFFFF),    // 在第三种颜色上的文本或图标颜色（白色）
    tertiaryContainer: Color(0xFFF2DAFF), // 第三种颜色容器的颜色
    onTertiaryContainer: Color(0xFF281433), // 在第三种颜色容器上的文本或图标颜色

    error: Color(0xFFBA1A1A),         // 错误颜色，用于表示错误状态
    onError: Color(0xFFFFFFFF),       // 在错误颜色上的文本或图标颜色（白色）
    errorContainer: Color(0xFFFFDAD6), // 错误容器的颜色
    onErrorContainer: Color(0xFF410002), // 在错误容器上的文本或图标颜色

    surface: Color(0xFFFBFDFC),       // 表面颜色，用于卡片、对话框等
    onSurface: Color(0xFF191C1B),     // 在表面颜色上的文本或图标颜色

    surfaceContainerHighest: Color(0xFFDDE4E3), // 最高对比度的表面容器颜色

    onSurfaceVariant: Color(0xFF414948), // 在不同表面变体上的文本或图标颜色
    outline: Color(0xFF717978),       // 边框颜色
    shadow: Color(0xFF000000),        // 阴影颜色
    inverseSurface: Color(0xFF2E3130), // 反转表面颜色
    onInverseSurface: Color(0xFFEFF1F0), // 在反转表面上的文本或图标颜色
    inversePrimary: Color(0xFFA0F0B5), // 反转后的主色
  );

  // ===== 深色主题 =====
  static const dark = ColorScheme(
    brightness: Brightness.dark,      // 主题亮度：暗色

    primary: Color(0xFFA0F0B5),       // 主色，提亮版本用于暗色主题
    onPrimary: Color(0xFF00391C),     // 在主色上的文本或图标颜色（深色）
    primaryContainer: Color(0xFF00532B), // 主色容器的颜色，在暗色主题中更深
    onPrimaryContainer: Color(0xFFBBF7D0), // 在主色容器上的文本或图标颜色（浅色）

    secondary: Color(0xFFB7C8CD),     // 次级色，适用于暗色主题
    onSecondary: Color(0xFF223034),   // 在次级色上的文本或图标颜色（深色）
    secondaryContainer: Color(0xFF38474B), // 次级色容器的颜色，在暗色主题中更深
    onSecondaryContainer: Color(0xFFD3E4E9), // 在次级色容器上的文本或图标颜色（浅色）

    tertiary: Color(0xFFD8BEE6),      // 第三种颜色，适用于暗色主题
    onTertiary: Color(0xFF3E2948),    // 在第三种颜色上的文本或图标颜色（深色）
    tertiaryContainer: Color(0xFF553F5F), // 第三种颜色容器的颜色，在暗色主题中更深
    onTertiaryContainer: Color(0xFFF2DAFF), // 在第三种颜色容器上的文本或图标颜色（浅色）

    error: Color(0xFFFFB4AB),         // 错误颜色，在暗色主题中的版本
    onError: Color(0xFF690005),       // 在错误颜色上的文本或图标颜色（深色）
    errorContainer: Color(0xFF93000A), // 错误容器的颜色，在暗色主题中更暗
    onErrorContainer: Color(0xFFFFDAD6), // 在错误容器上的文本或图标颜色（浅色）

    surface: Color(0xFF191C1B),       // 表面颜色，用于卡片、对话框等在暗色主题中
    onSurface: Color(0xFFE0E3E2),     // 在表面颜色上的文本或图标颜色（浅色）

    surfaceContainerHighest: Color(0xFF414948), // 最高对比度的表面容器颜色在暗色主题中

    onSurfaceVariant: Color(0xFFC1C9C8), // 在不同表面变体上的文本或图标颜色（浅色）
    outline: Color(0xFF8B9392),       // 边框颜色在暗色主题中
    shadow: Color(0xFF000000),        // 阴影颜色
    inverseSurface: Color(0xFFE0E3E2), // 反转表面颜色在暗色主题中
    onInverseSurface: Color(0xFF2E3130), // 在反转表面上的文本或图标颜色（深色）
    inversePrimary: Color(0xFF07C160), // 反转后的主色，在暗色主题中使用原始的主色
  );
}