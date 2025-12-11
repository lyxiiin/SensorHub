import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/route/route_utils.dart';
import 'package:sensor_hub/route/routes.dart';
import 'package:sensor_hub/ui/device/view_model/device_vm.dart';
import 'package:sensor_hub/ui/device/widgets/device_group_sheet_content.dart';
import 'package:sensor_hub/ui/device/widgets/device_info_card.dart';

import '../../../l10n/app_localizations.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<StatefulWidget> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  late AppLocalizations appText;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = Provider.of<DeviceVM>(context, listen: false);
      await viewModel.initData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appText = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(left: 12.w,right: 12.w,bottom: 12.h),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
              ),
              child: Column(
                spacing: 8.h,
                children: [
                  _titleBar(colorScheme),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(double.infinity, 48.h),
                    ),
                    onPressed: (){
                      // deviceGroupSheet(context: context);
                    },
                    child: Row(
                      children: [
                        Text(
                          "全部设备",
                          style: TextStyle(
                            fontSize: 16.sp
                          ),
                        ),
                        Spacer(),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 32.r,
                          // color: colorScheme.onSurface,
                        ),
                      ],
                    ),
                  ),
                  deviceStateCards(colorScheme,appText)
                ],
              ),
            ),
            Expanded(
              child: deviceList(colorScheme,appText),
            ),
          ],
        ),
    );
  }

  Widget _titleBar(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      height: 52.h,
      color: colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            "assets/images/sensor_hub.png",
            height: 48.h,
          ),
          const Spacer(), // 更简洁的 Expanded(child: SizedBox())
          IconButton(
            icon: Icon(Icons.search, color: colorScheme.onSurface),
            iconSize: 28.h,
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.add, color: colorScheme.onSurface),
            iconSize: 28.h,
            onPressed: () {
              RouteUtils.pushForNamed(context, RoutePath.deviceAdd);
            },
          ),
        ],
      ),
    );
  }
  Widget deviceStateCards(ColorScheme colorScheme, AppLocalizations appText){
    return Container(
      width: double.infinity,
      height: 120.h,
      color: colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          deviceStateCardItem(
            icon: "assets/icons/icon_over_limit.svg",
            title: appText.device_screen_overLimit,
            deviceCount: 0,
            colorScheme: colorScheme
          ),
          deviceStateCardItem(
              icon: "assets/icons/icon_low_battery.svg",
              title: appText.device_screen_lowBattery,
              deviceCount: 0,
              colorScheme: colorScheme
          ),
          deviceStateCardItem(
              icon: "assets/icons/icon_offline.svg",
              title: appText.device_screen_offline,
              deviceCount: 0,
              colorScheme: colorScheme
          ),
          deviceStateCardItem(
              icon: "assets/icons/icon_upgradeable.svg",
              title: appText.device_screen_upgradeable,
              deviceCount: 0,
              colorScheme: colorScheme
          ),
        ],
      ),
    );
  }
  Widget deviceStateCardItem({
    required String icon,
    required String title,
    required int deviceCount,
    required ColorScheme colorScheme
  }){
    return Container(
      width: 84.w,
      height: 120.h,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            spreadRadius: 0.5,
            blurRadius: 3,
          ),
        ],
        border: Border.all(
          width: 0.5.r,
          color: colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            icon,
            height: 32.h,
            colorFilter: ColorFilter.mode(colorScheme.onSurfaceVariant, BlendMode.srcIn),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              color: colorScheme.onSurfaceVariant
            ),
          ),
          Divider(
            height: 1.h,
            thickness: 1.h,
            indent: 16.w,
            endIndent: 16.w,
          ),
          Text(
            deviceCount.toString(),
            style: TextStyle(
              fontSize: 14.sp,
              color: colorScheme.onSurfaceVariant
            ),
          ),
        ],
      ),
    );
  }
  Widget deviceList(ColorScheme colorScheme,AppLocalizations appText){
    return Consumer<DeviceVM>(builder: (context,vm,child){
      if(vm.serviceCard.isEmpty){
        return SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 160.w,
                height: 120.h,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SvgPicture.asset(
                      "assets/icons/icon_device.svg",
                      width: 100.w,
                    ),
                    Positioned(
                      top: 36.h, // 垂直居中（基于容器高度）
                      left: 96.w, // 右边缘减去按钮半宽
                      child: IconButton(
                        iconSize: 48.w,
                        padding: EdgeInsets.zero, // 移除默认 padding 更精准
                        color: colorScheme.primary,
                        icon: Icon(Icons.add_circle_outline),
                        onPressed: () {
                          // your logic
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                appText.device_screen_prompt,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize:16.sp,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                ),
              ),
            ],
          ),
        );
      }else{
        return ListView.builder(
          itemCount: vm.serviceCard.length,
          itemBuilder: (context,index){
            final item = vm.serviceCard.entries.elementAt(index);
            // 添加对null值的检查
            if (item.value.isEmpty) {
              return Container(); // 返回空容器而不是崩溃
            }
            final lastItemIndex = item.value.length - 1;
            return Padding(
              padding: EdgeInsets.only(left: 12.w,right: 12.w,bottom: 12.w),
              child: DeviceInfoCard(
                colorScheme: colorScheme,
                name: item.key,
                time: lastItemIndex >= 0 ? vm.getMinutesDifference(item.value[lastItemIndex].datetime).toString() : "0",
                dateList: lastItemIndex >= 0 ? vm.dataToMap(item.value[lastItemIndex]) : {},
                onTap: (){

                },
              ),
            );
          },
        );
      }
    });
  }

  // Future<dynamic> deviceGroupSheet({required BuildContext context}){
  //   return showModalBottomSheet(
  //     constraints: BoxConstraints(
  //       maxHeight: 0.8.sh
  //     ),
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
  //     ),
  //     scrollControlDisabledMaxHeightRatio: 0.8,
  //     showDragHandle: true,
  //     context: context,
  //     builder: (context){
  //       return Consumer<DeviceVM>(builder: (context,vm,child){
  //         return SizedBox(
  //           height: 0.8.sh,
  //           child: DeviceGroupSheetContent(deviceGroups: vm.userDeviceGroups, onclick: () {  },),
  //         );
  //       });
  //     }
  //   );
  // }

}