import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_hub/l10n/app_localizations.dart';
import 'package:sensor_hub/ui/core/responsive/window_size_guard.dart';

/// WindowSizeGuard 的组件测试。
///
/// 守卫是全部页面的最终保险，两个行为必须锁死：
/// 1. 视口任一维度低于最小可用尺寸 → 整体替换为占位页，
///    真实内容不参与布局（极小尺寸下固定尺寸组件才不会溢出）；
/// 2. 视口恢复到最小可用尺寸之上 → 原样透传真实内容。
///
/// 用 SizedBox 直接压 LayoutBuilder 的约束，不依赖 setSurfaceSize：
/// 守卫只看 constraints，测试也不需要真实窗口。
void main() {
  Widget host(Size viewport, Widget child) {
    return MaterialApp(
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: SizedBox(
          width: viewport.width,
          height: viewport.height,
          child: WindowSizeGuard(child: child),
        ),
      ),
    );
  }

  testWidgets('视口过小时显示占位页，真实内容不渲染', (tester) async {
    await tester.pumpWidget(
      host(const Size(300, 250), const Text('REAL_CONTENT')),
    );

    expect(find.text('窗口过小'), findsOneWidget);
    expect(find.text('REAL_CONTENT'), findsNothing);
  });

  testWidgets('仅高度不足同样触发守卫（DPI 极限缩放的典型形态）', (tester) async {
    // 500% 缩放下 1080p 屏幕的逻辑窗口约 384×216：
    // 宽度尚可、高度不足，是「缩放到极限」最常见的触发形态
    await tester.pumpWidget(
      host(const Size(384, 216), const Text('REAL_CONTENT')),
    );

    expect(find.text('窗口过小'), findsOneWidget);
    expect(find.text('REAL_CONTENT'), findsNothing);
  });

  testWidgets('视口恢复后透传真实内容', (tester) async {
    await tester.pumpWidget(
      host(const Size(800, 600), const Text('REAL_CONTENT')),
    );

    expect(find.text('REAL_CONTENT'), findsOneWidget);
    expect(find.text('窗口过小'), findsNothing);
  });
}
