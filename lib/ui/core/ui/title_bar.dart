import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TitleBar extends StatelessWidget{
  final String? title;
  final double? titleSize;
  final ColorScheme colorScheme;
  final double paddingTop;
  const TitleBar({
    super.key,
    this.title,
    this.titleSize,
    required this.colorScheme,
    required this.paddingTop,
  });


  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: paddingTop + 52.h,
      color: colorScheme.surfaceContainerHighest,
      padding: EdgeInsets.only(top: paddingTop,left: 12.w,right: 12.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title ?? "其他",
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: titleSize ?? 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

}