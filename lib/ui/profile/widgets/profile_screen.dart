import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sensor_hub/route/route_utils.dart';
import 'package:sensor_hub/route/routes.dart';
import 'package:sensor_hub/ui/core/ui/setting_item.dart';
import 'package:sensor_hub/ui/core/ui/title_bar.dart';

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
    return SafeArea(
        child: Column(
          children: [
            TitleBar(colorScheme: colorScheme),
            SizedBox(height: 16.h,),
            Padding(
              padding: EdgeInsets.only(left: 12.w,right: 12.w),
              child: Container(
                width: double.infinity,
                height: 212.h,
                padding: EdgeInsets.only(left:12.w,right:12.w,),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SettingItem(
                      icon: "assets/icons/icon_device.svg",
                      colorScheme: colorScheme,
                      title: "通知设置",
                    ),
                    SettingItem(
                      icon: "assets/icons/icon_device.svg",
                      colorScheme: colorScheme,
                      title: "度数单位",
                    ),
                    SettingItem(
                      icon: "assets/icons/icon_device.svg",
                      colorScheme: colorScheme,
                      title: "语言",
                      showCurrentValue: true,
                      currentValue: "简体中文",
                    ),
                    SettingItem(
                      icon: "assets/icons/icon_device.svg",
                      colorScheme: colorScheme,
                      title: "外观",
                      showBottomLine: false,
                      showCurrentValue: true,
                      currentValue: "跟随系统",
                      onClick: (){
                        RouteUtils.pushForNamed(context, RoutePath.themeSelection);
                      },
                    ),
                  ],
                ),
              ),
            )
          ],
        )
    );
  }

}