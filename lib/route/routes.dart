import 'package:flutter/material.dart';
import 'package:sensor_hub/ui/device/widgets/device_registration_form_page.dart';
import 'package:sensor_hub/ui/device_detail/widgets/device_detail_page.dart';
import 'package:sensor_hub/ui/profile/widgets/theme_selection_page.dart';
import 'package:sensor_hub/ui/profile/widgets/units_conversion_page.dart';
import 'package:sensor_hub/utils/app_logger.dart';

import '../ui/main/widgets/app_navigation_page.dart';
import '../ui/profile/widgets/language_selection_page.dart';

import 'package:provider/provider.dart';
import 'package:sensor_hub/ui/device_detail/device_detail_vm.dart';

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
      case RoutePath.unitsConversion:
        return pageRoute(UnitsConversionPage());
      case RoutePath.deviceRegistrationFrom:
        return pageRoute(DeviceRegistrationFormPage());
      case RoutePath.deviceDetail:
        final deviceId = setting.arguments as int;
        return pageRoute(
          ChangeNotifierProvider(
            create: (_) => DeviceDetailVm(),
            child: DeviceDetailPage(deviceId: deviceId),
          ),
          settings: setting,
        );
    }
    logW('未知路由: ${setting.name}', tag: 'Router');
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

  // 度数单位设置页
  static const String unitsConversion = "UnitsConversionPage";

  //
  static const String deviceRegistrationFrom = "DeviceRegistrationFromPage";

  // 设备详情页
  static const String deviceDetail = "DeviceDetailPage";
}