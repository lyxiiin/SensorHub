import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

abstract final class Breakpoints {
  static const double medium = 600;
  static const double expanded = 1024;

  static const double contentMaxWidth = 840;

  /// 窗口绝对最小可用尺寸（逻辑像素），低于该值由 [WindowSizeGuard] 接管。
  ///
  /// 触发场景有两类：
  /// - 用户手动把窗口拖到极小；
  /// - Windows 显示缩放（DPI）拉到 350%+：逻辑尺寸 = 物理尺寸 ÷ 缩放，
  ///   1080p 屏幕在 500% 下逻辑窗口只有 384×216，任何固定尺寸组件都放不下，
  ///   而窗口尺寸又被屏幕物理尺寸限死，min-width 在物理层面就救不回来。
  ///
  /// 数值依据（compact 布局仍可用为下限）：
  /// - 高度：主页头部约 132 + 底部导航约 80，还要剩一行列表内容；
  /// - 宽度：BottomNavigationBar 三等分后标签不裁字。
  static const double minUsableWidth = 320;
  static const double minUsableHeight = 280;
}

enum WindowSizeClass { compact, medium, expanded }

bool get isDesktopPlatForm =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux);

extension WindowSizeClassX on BuildContext {
  WindowSizeClass get windowSizeClass {
    final width = MediaQuery.sizeOf(this).width;
    if (width < Breakpoints.medium) return WindowSizeClass.compact;
    if (width < Breakpoints.expanded) return WindowSizeClass.medium;
    return WindowSizeClass.expanded;
  }

  bool get isCompactLayout => windowSizeClass == WindowSizeClass.compact;
}
