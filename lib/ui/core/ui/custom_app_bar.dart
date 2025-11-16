import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

AppBar createAppBar({
  required String title,
  required GestureTapCallback onBack,
  required ColorScheme colorScheme,
  required GestureTapCallback onFinish
}){
  return AppBar(
    centerTitle: true,
    iconTheme: IconThemeData(color: colorScheme.primary,size: 20.r),
    leading: IconButton(
      icon: Icon(Icons.arrow_back_ios_new_sharp),
      onPressed: onBack,
    ),
    title: Text(
      "外观",
      style: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
    ),
    actions: [
      TextButton(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: TextStyle(fontSize: 18.sp),
        ),
        onPressed: onFinish,
        child: Text('完成'),
      )
    ],
  );
}