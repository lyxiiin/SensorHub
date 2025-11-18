import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/route/route_utils.dart';
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
    return Scaffold(
      appBar: createAppBar(
          title: '外观',
          onBack: () {
            RouteUtils.pop(context);
          },
          colorScheme: colorScheme,
          onFinish: () {

          }
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(left: 12.w,right: 12.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _themeModelGroupCart(colorScheme: colorScheme),
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
  }){
    return Consumer<AppVM>(builder: (context,vm,child){
      return Container(
        height: 260.h,
        width: double.infinity,
        color: colorScheme.surface,
        child: RadioGroup<ThemeMode>(
          groupValue: vm.themeModelSelectedValue,
          onChanged: (ThemeMode? value) async {
            await vm.changedThemeModelSelectedValue(value);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _themeModelCardItem(
                colorScheme: colorScheme,
                value: ThemeMode.system,
                title: "跟随系统"
              ),
              _themeModelCardItem(
                  colorScheme: colorScheme,
                  value: ThemeMode.light,
                  title: "浅色模式"
              ),
              _themeModelCardItem(
                  colorScheme: colorScheme,
                  value: ThemeMode.dark,
                  title: "深色模式"
              )
            ],
          ),
        ),
      );
    });
  }
}