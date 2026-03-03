import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/route/route_utils.dart';
import 'package:sensor_hub/ui/profile/view_model/profile_vm.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/ui/custom_app_bar.dart';
import '../../main/app_vm.dart';

class ThemeSelectionPage extends StatefulWidget{
  const ThemeSelectionPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _ThemeSelectionPageState();
  }
}

class _ThemeSelectionPageState extends State<ThemeSelectionPage>{
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appText = AppLocalizations.of(context);
    return Scaffold(
      extendBody: true,
      backgroundColor: colorScheme.surface,
      appBar: createAppBar(
          title: appText.profile_screen_appearance,
          appText: appText,
          onBack: () {
            RouteUtils.pop(context);
          },
          colorScheme: colorScheme,
          onFinish: () {
            final appVM = Provider.of<AppVM>(context, listen: false);
            final profileVM = Provider.of<ProfileVM>(context, listen: false);
            profileVM.saveTheme(appVM);
            RouteUtils.pop(context);
          }
      ),
      body: SafeArea(
        child: Container(
            color: colorScheme.surfaceContainer,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _themeModelGroupCart(colorScheme: colorScheme,appText: appText),
              ],
            ),
          ),
        ),
    );
  }
  Widget _themeModelCardItem({
    required ColorScheme colorScheme,
    required ThemeMode value,
    required String title
  }){
    return Container(
      height: 180.h,
      width: 90.w,
      color: colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              Container(
                width: 54.w,
                height: 96.h,
                decoration: value == ThemeMode.system ? BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFE8E8E8),
                      Color(0xCC000000)
                    ]
                  ),
                  borderRadius: BorderRadius.circular(4.r),
                ) :BoxDecoration(
                  color: value == ThemeMode.dark ? Color(0xCC000000) : Color(0xFFE8E8E8),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              Positioned(
                top: 18.h,
                left: 2.w,
                right: 2.w,
                child: Container(
                  width: double.infinity,
                  height: 28.h,
                  decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(4.r)
                  ),
                ),
              )
            ],
          ),
          Text(
            title,
            style: TextStyle(
                color: value == themeModelSelectedValue ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontSize: 14.sp,
                fontWeight: value == themeModelSelectedValue ? FontWeight.bold : FontWeight.normal
            ),
          )
        ],
      ),
    );
  }

  Widget _themeModelGroupCart({
    required ColorScheme colorScheme,
    required AppLocalizations appText,
  }){
    final List<List<String>> themeModelList = [
      [appText.profile_screen_light_mode,"Icons.wb_sunny_outlined",ThemeMode.light.toString()],
      [appText.profile_screen_dark_mode,"Icons.wb_moon_outlined",ThemeMode.dark.toString()],
      [appText.profile_screen_follow_system,"Icons.contrast_outlined",ThemeMode.system.toString()],
    ];
    return Consumer2<ProfileVM, AppVM>(builder: (context, profileVM, appVM, child){
      // 初始化临时值
      if (profileVM.tempSelectedValue == null) {
        profileVM.initFromAppVM(appVM);
      }
      
      themeModelSelectedValue = profileVM.tempSelectedValue ?? appVM.themeModelSelectedValue;
      return Column(
        children: List.generate(
            themeModelList.length, (index) {
          ThemeMode value = ThemeMode.values[index];
          return RadioListTile<ThemeMode>(
            title: Text(
              themeModelList[index][0],
              style: TextStyle(
                fontSize: 16.sp,
              ),
            ),
            value: value,
            groupValue: themeModelSelectedValue,
            onChanged: (ThemeMode? value) {
              profileVM.changedTempThemeValue(value);
            },
          );
        }).toList(),
      );
    });
  }
  late ThemeMode themeModelSelectedValue;
}

