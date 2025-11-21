import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sensor_hub/domain/models/user_device_groups.dart';
import 'package:sensor_hub/route/route_utils.dart';

import '../../../l10n/app_localizations.dart';

class DeviceGroupSheetContent extends StatelessWidget{
  final List<UserDeviceGroups> deviceGroups;
  final GestureTapCallback onclick;
  const DeviceGroupSheetContent({
    super.key,
    required this.deviceGroups,
    required this.onclick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appText = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.all(12.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextButton(
                onPressed: (){
                  RouteUtils.pop(context);
                },
                child: Text(appText.common_ui_cancel,style: TextStyle(fontSize: 16.sp,color: colorScheme.primary),),
              ),
              Spacer(),
              TextButton(
                onPressed: (){
                  RouteUtils.pop(context);
                },
                child: Text(appText.common_ui_finish,style: TextStyle(fontSize: 16.sp,color: colorScheme.primary),),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: deviceGroups.length,
              itemBuilder: (context,index){
                return groupItem(
                  name: deviceGroups[index].deviceName,
                  deviceNum: "0",
                  onTap: onclick
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget groupItem({
    required String name,
    required String deviceNum,
    required GestureTapCallback onTap
  }){
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48.h,
        width: double.infinity,
        child: Row(
          children: [
            Icon(
              Icons.folder,
              size: 24.r,
            ),
            SizedBox(width: 8.w,),
            Text(
              name,
              style: TextStyle(
                fontSize: 18.sp,
              ),
            ),
            Spacer(),
            Text(
              deviceNum,
              style: TextStyle(
                fontSize: 18.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

}