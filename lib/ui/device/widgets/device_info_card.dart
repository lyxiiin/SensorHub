import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../../l10n/app_localizations.dart';

final Map<String,String> labelMap = {
  'temp': "温度",
  'co2': "二氧化碳",
  'humidity': "湿度"
};
final Map<String,String> labelUnitMap = {
  'temp': "℃",
  'co2': "ppm",
  'humidity': "%"
};

class DeviceInfoCard extends StatelessWidget{
  final ColorScheme colorScheme;
  final String? icon;
  final String? name;
  final String? time;
  final Map<String,String> dateList;
  final GestureTapCallback? onTap;
  const DeviceInfoCard({
    super.key,
    required this.colorScheme,
    this.icon,
    this.name,
    this.time,
    required this.dateList,
    this.onTap
  });
  @override
  Widget build(BuildContext context) {
    final appText = AppLocalizations.of(context);
    final displayTime = (time?.trim().isNotEmpty == true) ? time! : "0";
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(left: 12.w, right: 12.w, top: 12.h, bottom: 12.h),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      icon?.isNotEmpty == true ? icon! : "assets/icons/icon_device.svg",
                      width: 16.w,
                      height: 16.w,
                      placeholderBuilder: (context) => const Icon(Icons.devices, size: 16),
                    ),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Text(
                        name ?? appText.device_screen_unknown_sensor,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  "$displayTime${appText.device_screen_minutes_ago}",
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
            Divider(
              height: 16.h,
              thickness: 1.h,
              color: colorScheme.outline.withOpacity(0.3),
            ),
            Wrap(
              spacing: 8.w,        // 水平间距
              runSpacing: 8.h,     // 垂直间距
              children: dateList.entries.map((entry) {
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 24.w - 16.w - 24.w) / 2, // 粗略估算每行两个
                  child: Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8.r,
                            height: 8.r,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                              labelMap[entry.key]!,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          Spacer(),
                          Text(
                              "${entry.value} ${labelUnitMap[entry.key]!}",
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

}
