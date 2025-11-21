import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../l10n/app_localizations.dart';

AppBar createAppBar({
  required String title,
  required GestureTapCallback onBack,
  required ColorScheme colorScheme,
  required GestureTapCallback? onFinish,
  required AppLocalizations appText
}){
  return AppBar(
    centerTitle: true,
    backgroundColor: colorScheme.surfaceContainerHigh,
    iconTheme: IconThemeData(
      color: colorScheme.primary,
      size: 20.r,
    ),
    leading: IconButton(
      icon: Icon(Icons.arrow_back_ios_new_sharp),
      onPressed: onBack,
    ),
    title: Text(
      appText.profile_screen_appearance,
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