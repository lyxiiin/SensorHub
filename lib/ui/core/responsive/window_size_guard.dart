import 'package:flutter/material.dart';
import 'package:sensor_hub/l10n/app_localizations.dart';
import 'package:sensor_hub/ui/core/responsive/app_breakpoints.dart';

/// 全局「窗口过小」守卫：桌面 UI 的最终保险（Visual Studio 同款做法）。
///
/// 挂在 MaterialApp.builder 上，当视口小于
/// [Breakpoints.minUsableWidth] × [Breakpoints.minUsableHeight]（逻辑像素）时，
/// 用占位页整体替换页面内容，避免固定尺寸组件在极端窗口尺寸 /
/// DPI 极限缩放下溢出（RenderFlex overflow）。
///
/// 尺寸恢复后自动切回真实页面。注意：切换会导致 Navigator 重建，
/// 路由状态回到首页；数据都在 MaterialApp 之上的 Provider 层，不受影响。
///
/// 用 LayoutBuilder 而不是 MediaQuery：builder 拿到的 constraints
/// 就是应用视口的实际约束，且不依赖更上层的 MediaQuery 语义。
class WindowSizeGuard extends StatelessWidget {
  final Widget? child;

  const WindowSizeGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool tooSmall =
            constraints.maxWidth < Breakpoints.minUsableWidth ||
            constraints.maxHeight < Breakpoints.minUsableHeight;
        if (!tooSmall) return child ?? const SizedBox.shrink();
        return const _WindowTooSmallView();
      },
    );
  }
}

/// 占位页本身必须永远不会溢出：
/// 只用 Center + Column(mainAxisSize.min) + 可换行文本，不用 Scaffold，
/// 避免在极小视口下引入额外固定尺寸。
class _WindowTooSmallView extends StatelessWidget {
  const _WindowTooSmallView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appText = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.open_in_full_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                appText.common_ui_window_too_small_title,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                appText.common_ui_window_too_small_hint,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
