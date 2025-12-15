import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sensor_hub/route/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../route/route_utils.dart';
import '../../core/ui/custom_app_bar.dart';



const Map<String,List<String>> deviceTypeList = {
  "青萍": [
    "青萍二氧化碳和温湿度检测仪",
    "青萍商用温湿度（气压）计（S）",
    "青萍商用温湿度计 E",
    "青萍商用多功能检测仪",
    "青萍墙壁插座式温湿度计",
    "青萍墙壁开关式温湿度计",
    "青萍室内环境检测仪",
    "青萍空气检测仪",
    "青萍空气检测仪 2",
    "青萍空气检测仪 Lite",
  ],
};
final keysList = deviceTypeList.keys.toList(growable: false);
class DeviceAddPage extends StatelessWidget{
  const DeviceAddPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      extendBody: true,
      backgroundColor: colorScheme.surface,
      appBar: createAppBar(
        title: '添加设备',
        appText: appText,
        onBack: () {
          RouteUtils.pop(context);
        },
        colorScheme: colorScheme,
        onFinish: () {
          RouteUtils.pop(context);
        },
      ),
      body: SafeArea(
        child: ListView.builder(
          itemCount: deviceTypeList.length,
          itemBuilder: (context,index){
            final key = keysList[index];
            final values = deviceTypeList[key]!;
            return Container(
              width: double.infinity,
              padding: EdgeInsets.only(left: 12.w,right: 12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 24.h,),
                  Text(key,style: TextStyle(fontSize: 14.sp),),
                  ...values.map((sensor) => ListTile(
                    contentPadding: EdgeInsets.only(left: 0,right: 0),
                    title: Text(sensor,style: TextStyle(fontSize: 18.sp),maxLines: 1,),
                    trailing: Icon(Icons.keyboard_arrow_right),
                    onTap: (){
                      log(sensor);
                      RouteUtils.pushForNamed(context, RoutePath.deviceRegistrationFrom,arguments: sensor);
                    },
                  )),
                  Divider(height: 50.h,thickness: 1.r,)
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}