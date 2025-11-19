import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../l10n/app_localizations.dart';

class DeviceInfoCard extends StatelessWidget{
  final ColorScheme colorScheme;
  final String? icon;
  final String? name;
  final String? time;
  final List<Map<String,String>> dateList;
  final GestureTapCallback? onTap;
  const DeviceInfoCard({
    super.key,
    required this.colorScheme,
    this.icon,
    this.name,
    this.time,
    required this.dateList, this.onTap
  });

  @override
  Widget build(BuildContext context) {
    final appText = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90.h,
        width: double.infinity,
        padding: EdgeInsets.only(left: 12.w,right: 12.w,top: 12.h,bottom: 12.h),
        decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12.r)
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(
                  icon ?? "assets/icons/icon_device",
                  width: 16.w,
                  height: 16.w,
                ),
                SizedBox(width: 8.w,),
                Text(
                  name ?? appText.device_screen_unknown_sensor,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: colorScheme.onSurfaceVariant
                  ),
                ),
                SizedBox.expand(),
                Text(
                  "${time ?? "0"}${appText.device_screen_minutes_ago}",
                  style: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),fontSize: 12.sp),
                )
              ],
            ),
            Divider(
              height: 2.h,
              thickness: 1.h,
              indent: 0,
              endIndent: 0,
            ),
          ],
        ),
      ),
    );
  }

}
