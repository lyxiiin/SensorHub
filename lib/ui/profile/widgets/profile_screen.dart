import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/data/services/settings_service.dart';
import 'package:sensor_hub/route/route_utils.dart';
import 'package:sensor_hub/route/routes.dart';
import 'package:sensor_hub/ui/core/responsive/app_breakpoints.dart';
import 'package:sensor_hub/ui/core/ui/setting_item.dart';
import 'package:sensor_hub/ui/core/ui/title_bar.dart';

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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          TitleBar(
            title: appText.profile_screen_personal_info,
            colorScheme: colorScheme,
            paddingTop: MediaQuery.of(context).padding.top,
          ),
          SizedBox(height: 16.h,),
          Expanded(
            // 顶部对齐：仅保留水平居中（配合 maxWidth），
            // 避免 Center 把选项列表垂直居中导致 titlebar 下方出现大段空白
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Breakpoints.contentMaxWidth,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
                    child: Container(
                      padding: EdgeInsets.only(left:12.w,right:12.w,),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Column(
                        children: [
                          SettingItem(
                            icon: "assets/icons/icon_bell.svg",
                            colorScheme: colorScheme,
                            title: appText.profile_screen_notification_settings,
                          ),
                          SettingItem(
                            icon: "assets/icons/icon_unit.svg",
                            colorScheme: colorScheme,
                            title: appText.profile_screen_degree_unit,
                            onClick: (){
                              RouteUtils.pushForNamed(context, RoutePath.unitsConversion);
                            },
                          ),
                          SettingItem(
                            icon: "assets/icons/icon_group.svg",
                            colorScheme: colorScheme,
                            title: appText.group_manage_title,
                            onClick: (){
                              RouteUtils.pushForNamed(context, RoutePath.groupManagement);
                            },
                          ),
                          Consumer<SettingsService>(builder: (context,settings,child){
                            return settingItemState(
                              icon: 'assets/icons/icon_language.svg',
                              colorScheme: colorScheme,
                              title: appText.profile_screen_language,
                              showCurrentValue: true,
                              // auto 档的存储名是中文占位，展示时按当前语言解析
                              currentValue: settings.languageCode == 'auto'
                                  ? appText.automatic
                                  : settings.languageName,
                              onClick: (){
                                RouteUtils.pushForNamed(context, RoutePath.languageSelection);
                              },
                            );
                          }),
                          Consumer<SettingsService>(builder: (context,settings,child){
                            return settingItemState(
                              icon: "assets/icons/icon_appearance.svg",
                              colorScheme: colorScheme,
                              title: appText.profile_screen_appearance,
                              showBottomLine: false,
                              showCurrentValue: true,
                              currentValue: settings.themeMode == ThemeMode.light ? appText.profile_screen_light_mode
                                  : settings.themeMode == ThemeMode.dark ? appText.profile_screen_dark_mode
                                  : appText.profile_screen_follow_system,
                              onClick: (){
                                RouteUtils.pushForNamed(context, RoutePath.themeSelection);
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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