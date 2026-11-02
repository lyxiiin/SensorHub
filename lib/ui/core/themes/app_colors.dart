import 'package:flutter/material.dart';

/// 品牌色与业务语义色的唯一来源。
///
/// 这里只保留 seed 和语义色。亮/暗两套完整色板交给
/// `ColorScheme.fromSeed` 生成——它产出的色板内部一致、对比度经过校验，
/// 并自带 M3 的 surfaceContainer* / outlineVariant 等新槽位。
///
/// 历史上这里手写过两套 ColorScheme，但从未被引用（死代码），
/// 且缺少上述槽位，因此删除。
class AppColors {
  /// 品牌主色。亮/暗主题共用同一个 seed，只切换 brightness。
  static const Color brandSeed = Color(0xFF07C160);

  /// 业务语义色：设备在线/数据正常。
  /// M3 的 ColorScheme 没有 success 槽位，这类业务语义色必须自己定义，
  /// 不能在各页面里散写 `Colors.green`（见 P5 备注）。
  static const Color success = Color(0xFF07C160);

  /// 暗色主题下的成功色。提亮以保证在深色表面上的对比度 >= 4.5:1。
  static const Color successDark = Color(0xFF3DDC84);
}
