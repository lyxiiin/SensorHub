import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/route/route_utils.dart';
import 'package:sensor_hub/ui/profile/view_model/profile_vm.dart';

import '../../core/ui/custom_app_bar.dart';

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
      backgroundColor: colorScheme.surface,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _themeModelCard(colorScheme: colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _themeModelCard({
    required ColorScheme colorScheme,
  }){
    return Consumer<ProfileVM>(builder: (context,vm,child){
      return Container(
        height: 260.h,
        width: double.infinity,
        color: colorScheme.surfaceContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _themeModelCardItem(
              colorScheme: colorScheme,
              selfValue: 0,
              selectedValue: vm.themeModelSelectedValue,
              title: "跟随系统",
              onChange: (value){
                vm.changedThemeModelSelectedValue(value);
              }
            ),
            _themeModelCardItem(
                colorScheme: colorScheme,
                selfValue: 1,
                selectedValue: vm.themeModelSelectedValue,
                title: "浅色模式",
                onChange: (value){
                  vm.changedThemeModelSelectedValue(value);
                }
            ),
            _themeModelCardItem(
                colorScheme: colorScheme,
                selfValue: 2,
                selectedValue: vm.themeModelSelectedValue,
                title: "深色模式",
                onChange: (value){
                  vm.changedThemeModelSelectedValue(value);
                }
            ),
          ],
        ),
      );
    });
  }
  Widget _themeModelCardItem({
    required ColorScheme colorScheme,
    required int selfValue,
    required int selectedValue,
    required ValueChanged onChange,
    required String title
  }){
    return Container(
      height: 180.h,
      width: 90.w,
      color: colorScheme.surfaceContainer,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 54.w,
            height: 96.h,
            color: Colors.green,
          ),
          Text(title,style: TextStyle(fontSize: 14.sp,color: colorScheme.onSurfaceVariant),),
          Radio<int>(
            activeColor: colorScheme.primary,
            value: selfValue,
            groupValue: selectedValue,
            onChanged: onChange,
          ),
        ],
      ),
    );
  }
}