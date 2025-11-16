import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TitleBar extends StatelessWidget{
  final String? title;
  final double? titleSize;
  final ColorScheme colorScheme;
  const TitleBar({
    super.key,
    this.title,
    this.titleSize,
    required this.colorScheme,
  });


  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52.h,
      color: colorScheme.surface, // 与父容器一致
      padding: EdgeInsets.only(left: 12.w,right: 12.w),
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