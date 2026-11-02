// 跨平台适配的回归测试（对应 lib/doc/ui_cross_platform_patch.md 的 P6）。
//
// 锁住三件事：
// 1. 断点边界 600 / 1024 —— 导航形态、内容限宽都靠它；
// 2. 平台判定 isDesktopPlatForm —— 桌面分支/移动分支的总开关；
// 3. 桌面端停用等比缩放 —— 1280 宽窗口下 16.w / 16.sp 必须还是 16。
//
// 这些都是纯行为断言：不需要真实窗口、不需要 golden 基线图，
// 在 CI 和无显示器的机器上都能跑。
//
// 注意：文档 P6 里写的是 isDesktopPlatform，而本仓库真实符号是
// isDesktopPlatForm（大写 F）。测试引用的是真实符号。
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_hub/ui/core/responsive/app_breakpoints.dart';

/// 伪造一个指定尺寸的窗口，再读 [WindowSizeClassX.windowSizeClass]。
///
/// 窗口尺寸不能靠真实显示器，测试里用 `tester.view.physicalSize` 直接改；
/// devicePixelRatio 固定成 1.0，让「物理像素 = 逻辑像素」，换算不用心算。
Future<WindowSizeClass> _classAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  late WindowSizeClass result;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          result = context.windowSizeClass;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return result;
}

/// 在「指定平台 + 指定窗口尺寸」下，读出 16.w / 16.sp 的真实解析值。
///
/// 这里刻意复刻 `lib/ui/main/widgets/app.dart` 里 ScreenUtilInit 的参数：
/// 测试如果用的是「理想配置」而不是「线上真实配置」，锁住的就不是真实行为。
Future<(double, double)> _resolveAt(
  WidgetTester tester, {
  required TargetPlatform platform,
  required Size windowSize,
}) async {
  tester.view.physicalSize = windowSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  debugDefaultTargetPlatformOverride = platform;
  late double w;
  late double sp;
  try {
    await tester.pumpWidget(
      MaterialApp(
        home: ScreenUtilInit(
          designSize: const Size(393, 873),
          // 与 app.dart 必须保持一致，否则测的是另一套配置
          enableScaleWH: () => !isDesktopPlatForm,
          enableScaleText: () => !isDesktopPlatForm,
          minTextAdapt: true,
          builder: (context, child) => Builder(
            builder: (context) {
              w = 16.w;
              sp = 16.sp;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  } finally {
    // 必须在测试体结束前还原：flutter_test 会在 body 结束时检查
    // debugDefaultTargetPlatformOverride 是否已复位，addTearDown 太晚，
    // 会报 "The value of a foundation debug variable was changed by the test."
    debugDefaultTargetPlatformOverride = null;
  }
  return (w, sp);
}

void main() {
  group('窗口尺寸等级', () {
    testWidgets('按 600 / 1024 分三档，边界值归属正确', (tester) async {
      expect(
        await _classAt(tester, const Size(360, 640)),
        WindowSizeClass.compact,
        reason: '手机竖屏 360 宽应为 compact',
      );
      expect(
        await _classAt(tester, const Size(599, 800)),
        WindowSizeClass.compact,
        reason: '599 是 medium 的左边界外，仍应 compact',
      );
      expect(
        await _classAt(tester, const Size(600, 800)),
        WindowSizeClass.medium,
        reason: '600 是 medium 的下边界，应进入 medium',
      );
      expect(
        await _classAt(tester, const Size(1023, 800)),
        WindowSizeClass.medium,
        reason: '1023 是 expanded 的左边界外，仍应 medium',
      );
      expect(
        await _classAt(tester, const Size(1024, 800)),
        WindowSizeClass.expanded,
        reason: '1024 是 expanded 的下边界，应进入 expanded',
      );
      expect(
        await _classAt(tester, const Size(1920, 1080)),
        WindowSizeClass.expanded,
        reason: '桌面全屏应 expanded',
      );
    });
  });

  group('平台判定', () {
    test('桌面三平台为 true，移动端为 false', () {
      try {
        for (final p in const [
          TargetPlatform.windows,
          TargetPlatform.macOS,
          TargetPlatform.linux,
        ]) {
          debugDefaultTargetPlatformOverride = p;
          expect(isDesktopPlatForm, isTrue, reason: '$p 应判定为桌面');
        }
        for (final p in const [TargetPlatform.android, TargetPlatform.iOS]) {
          debugDefaultTargetPlatformOverride = p;
          expect(isDesktopPlatForm, isFalse, reason: '$p 应判定为非桌面');
        }
      } finally {
        // 全局调试变量用完必须还原，否则会污染后续用例
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });

  group('缩放开关', () {
    // 1280 宽窗口：设计宽 393，若未关缩放则系数为 1280/393 ≈ 3.257
    const Size wideWindow = Size(1280, 800);
    const double scaleIfEnabled = 1280 / 393;

    testWidgets('桌面端 .w/.sp 退化为原值', (tester) async {
      final (w, sp) = await _resolveAt(
        tester,
        platform: TargetPlatform.windows,
        windowSize: wideWindow,
      );
      expect(
        w,
        closeTo(16.0, 0.01),
        reason: '桌面 1280 宽下 16.w 必须是 16.0，否则窗口一拉大间距就会炸',
      );
      expect(sp, closeTo(16.0, 0.01), reason: '桌面 1280 宽下 16.sp 必须是 16.0');
    });

    testWidgets('移动端保留等比缩放（守住原有行为，防止 P1 误伤手机）', (tester) async {
      final (w, sp) = await _resolveAt(
        tester,
        platform: TargetPlatform.android,
        windowSize: wideWindow,
      );
      expect(w, closeTo(16 * scaleIfEnabled, 0.01), reason: '手机/平板的宽度缩放必须原样保留');
      expect(
        sp,
        closeTo(16 * scaleIfEnabled, 0.01),
        reason: '字号目前也按宽度缩放，原因见下一个用例',
      );
    });

    testWidgets('现状记录：minTextAdapt 被默认 fontSizeResolver 覆盖（已知偏差）', (
      tester,
    ) async {
      // 834x1112 平板：scaleWidth = 834/393 ≈ 2.122，scaleHeight = 1112/873 ≈ 1.274
      final (w, sp) = await _resolveAt(
        tester,
        platform: TargetPlatform.android,
        windowSize: const Size(834, 1112),
      );
      expect(w, closeTo(16 * (834 / 393), 0.01));

      // flutter_screenutil 5.9.3 中 ScreenUtilInit 的 fontSizeResolver 默认值是
      // FontSizeResolvers.width，而 setSp() 是
      //   fontSizeResolver?.call(...) ?? fontSize * scaleText
      // —— 优先走 resolver，于是 .sp 恒等于按宽度缩放，minTextAdapt 参数不生效。
      // 这不是期望设计，是当前事实；将来若改成 FontSizeResolvers.height，
      // 这条断言会失败，提醒我们同步更新预期（那正是我们要的提醒）。
      expect(
        sp,
        closeTo(16 * (834 / 393), 0.01),
        reason: '当前字号按宽度放大到约 33.95，而不是 minTextAdapt 期望的 20.38',
      );
    });
  });
}
