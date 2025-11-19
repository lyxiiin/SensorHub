import 'package:flutter/material.dart';
import 'package:sensor_hub/ui/profile/widgets/theme_selection_page.dart';

import '../ui/main/widgets/app_navigation_page.dart';
import '../ui/profile/widgets/language_selection_page.dart';
class Routes{
  static Route<dynamic> generateRoute(RouteSettings setting) {
    switch(setting.name){
    // 首页
      case RoutePath.main:
        return pageRoute(AppNavigationPage(), settings: setting);
      case RoutePath.themeSelection:
        return pageRoute(ThemeSelectionPage());
      case RoutePath.languageSelection:
        return pageRoute(LanguageSelectionPage());
    }
    return pageRoute(
        Scaffold(
          body: SafeArea(
            child: Center(
              child: Text('No route defined for ${setting.name}'),
            ),
          ),));
  }

  static MaterialPageRoute pageRoute(
      Widget page, {
        RouteSettings? settings,
        bool? fullscreenDialog,
        bool? maintainState,
        bool? allowSnapshotting,
      }) {
    return MaterialPageRoute(
        builder: (context) => page,
        settings: settings,
        fullscreenDialog: fullscreenDialog ?? false,
        maintainState: maintainState ?? true,
        allowSnapshotting: allowSnapshotting ?? true);
  }
}

class RoutePath{
  // 首页
  static const String main = "/";

  // 主题设置页
  static const String themeSelection = "ThemeSelectionPage";

  // 语言设置页
  static const String languageSelection = "LanguageSelectionPage";
}