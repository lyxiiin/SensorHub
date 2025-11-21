import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/route/route_utils.dart';
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
            appVM.changedThemeModelSelectedValue();
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
                  width: 48.w,
                  height: 18.h,
                  decoration: BoxDecoration(
                    color: value == ThemeMode.dark ? Color(0x33FFFFFF) : value == ThemeMode.system ? Color(0xCC000000) : Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              Positioned(
                top: 40.h,
                left: 2.w,
                right: 2.w,
                child: Container(
                  width: 48.w,
                  height: 18.h,
                  decoration: BoxDecoration(
                    color: value == ThemeMode.dark ? Color(0x33FFFFFF) : Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
            ],
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          Radio<ThemeMode>(value: value,)
        ],
      ),
    );
  }
  Widget _themeModelGroupCart({
    required ColorScheme colorScheme,
    required AppLocalizations appText
  }){
    return Consumer<AppVM>(builder: (context,vm,child){
      return Container(
        height: 260.h,
        width: double.infinity,
        color: colorScheme.surface,
        child: RadioGroup<ThemeMode>(
          groupValue: vm.tempSelectedValue,
          onChanged: (ThemeMode? value) {
            vm.changedTempSelectedValue(value);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _themeModelCardItem(
                colorScheme: colorScheme,
                value: ThemeMode.system,
                title: appText.profile_screen_follow_system
              ),
              _themeModelCardItem(
                  colorScheme: colorScheme,
                  value: ThemeMode.light,
                  title: appText.profile_screen_light_mode
              ),
              _themeModelCardItem(
                  colorScheme: colorScheme,
                  value: ThemeMode.dark,
                  title: appText.profile_screen_dark_mode
              )
            ],
          ),
        ),
      );
    });
  }
}