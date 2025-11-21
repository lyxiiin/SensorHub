import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/route/route_utils.dart';
import 'package:sensor_hub/route/routes.dart';
import 'package:sensor_hub/ui/core/ui/setting_item.dart';
import 'package:sensor_hub/ui/core/ui/title_bar.dart';
import 'package:sensor_hub/ui/main/app_vm.dart';

import '../../../l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget{
  const ProfileScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _ProfileScreenState();
  }

}

class _ProfileScreenState extends State<ProfileScreen>{
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appText = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TitleBar(
              title: appText.profile_screen_personal_info,
              colorScheme: colorScheme,
              paddingTop: MediaQuery.of(context).padding.top,
            ),
            SizedBox(height: 16.h,),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Container(
                padding: EdgeInsets.only(left:12.w,right:12.w,),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  children: [
                    SettingItem(
                      icon: "assets/icons/icon_device.svg",
                      colorScheme: colorScheme,
                      title: appText.profile_screen_notification_settings,
                    ),
                    SettingItem(
                      icon: "assets/icons/icon_device.svg",
                      colorScheme: colorScheme,
                      title: appText.profile_screen_degree_unit,
                    ),
                    Consumer<AppVM>(builder: (context,vm,child){
                      return settingItemState(
                        icon: 'assets/icons/icon_device.svg',
                        colorScheme: colorScheme,
                        title: appText.profile_screen_language,
                        showCurrentValue: true,
                        currentValue: vm.languageName,
                        onClick: (){
                          RouteUtils.pushForNamed(context, RoutePath.languageSelection);
                        },
                      );
                    }),
                    Consumer<AppVM>(builder: (context,vm,child){
                      return settingItemState(
                        icon: "assets/icons/icon_device.svg",
                        colorScheme: colorScheme,
                        title: appText.profile_screen_appearance,
                        showBottomLine: false,
                        showCurrentValue: true,
                        currentValue: vm.themeModelSelectedValue == ThemeMode.light ? appText.profile_screen_light_mode
                            : vm.themeModelSelectedValue == ThemeMode.dark ? appText.profile_screen_dark_mode
                            : appText.profile_screen_follow_system,
                        onClick: (){
                          RouteUtils.pushForNamed(context, RoutePath.themeSelection);
                        },
                      );
                    }),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
  Widget settingItemState({
    required String icon,
    required ColorScheme colorScheme,
    required String title,
    bool? showBottomLine,
    bool? showCurrentValue,
    String? currentValue,
    required GestureTapCallback onClick
  }){
    return SettingItem(
      icon: icon,
      colorScheme: colorScheme,
      title: title,
      showBottomLine: showBottomLine ?? true,
      showCurrentValue: showCurrentValue ?? false,
      currentValue: currentValue,
      onClick: onClick
    );
  }
}