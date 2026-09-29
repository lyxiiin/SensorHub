import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/data/models/sensor_type.dart';
import 'package:sensor_hub/route/route_utils.dart';
import 'package:sensor_hub/route/routes.dart';
import 'package:sensor_hub/ui/core/ui/confirm_dialog.dart';
import 'package:sensor_hub/ui/device/view_model/device_vm.dart';
import 'package:sensor_hub/utils/app_logger.dart';

import '../../../l10n/app_localizations.dart';

final Map<String,String> labelMap = {
  'temperature': "温度",
  'co2': "二氧化碳",
  'humidity': "湿度",
  'atmosPressure':"大气压强",
  'pm25': "细颗粒物",
  'pm10': "可吸入颗粒物",
  'voc': "挥发性有机化合物",
  'noise': "噪音",
  'lux': "照度",
  "externalCo2": "二氧化碳(外接)",
  "externalTemperature": "温度(外接)",
};
final Map<String,String> labelUnitMap = {
  'temperature': "℃",
  'co2': "ppm",
  'humidity': "%",
  'atmosPressure':"kPa",
  'pm25': "µg/m³",
  'pm10': "µg/m³",
  'voc': "mg/m³",
  'noise': "dB",
  'lux': "Lux",
  "externalCo2": "%",
  "externalTemperature": "℃",
};

class DeviceInfoCard extends StatelessWidget{
  final ColorScheme colorScheme;
  final String? icon;
  final String? name;
  final String? time;
  final int? configId;

  /// 设备所属分组名；为空表示未分组，不渲染标签
  final String? groupName;
  final Map<SensorType,dynamic> dateList;
  final GestureTapCallback? onTap;
  const DeviceInfoCard({
    super.key,
    required this.colorScheme,
    this.icon,
    this.name,
    this.time,
    this.groupName,
    required this.dateList,
    this.onTap,
    this.configId,
  });
  @override
  Widget build(BuildContext context) {
    final appText = AppLocalizations.of(context);
    final displayTime = (time?.trim().isNotEmpty == true) ? time! : "0";
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPressStart: (details) => _showMenu(context, details,configId),
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
                    if (groupName != null && groupName!.isNotEmpty) ...[
                      SizedBox(width: 6.w),
                      // 分组标签。宽度封顶 + 省略号：设备名是 Flexible，
                      // 长名字会先让位，标签不会把整行撑破
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 84.w),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            groupName!,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: colorScheme.onSecondaryContainer,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  "$displayTime${appText.device_screen_minutes_ago}",
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
            Divider(
              height: 16.h,
              thickness: 1.h,
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
            Wrap(
              spacing: 8.w,        // 水平间距
              runSpacing: 8.h,     // 垂直间距
              children: dateList.entries
                  .where((entry) => (entry.value != null))
                  .map((entry) {
                    return SizedBox(
                      width: (MediaQuery.of(context).size.width - 24.w - 16.w - 24.w) / 2, // 粗略估算每行两个
                      child: Card(
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
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
                                  entry.key.displayName,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Spacer(),
                              Text(
                                  "${entry.value.formattedValue} ${entry.key.unit}",
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

  String restoreOriginalValue(String key, dynamic value){
    if(value is int &&(key == "temperature" || key == "humidity")){
      return (value / 10.0).toString();
    }
    return value.toString();
  }

  Future<void> _showMenu(
      BuildContext context,
      LongPressStartDetails details,
      int? configId,
      ) async {
    if(configId == null)  return;
    // Overlay 定位只依赖 details 和 context，不依赖查库结果：
    // 放在 await 之前的同步区，context 随便用，不存在跨 async gap 问题
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromLTRB(
      details.globalPosition.dx,
      details.globalPosition.dy,
      overlay.size.width - details.globalPosition.dx,
      overlay.size.height - details.globalPosition.dy,
    );
    final config = await context.read<DeviceVM>().configForEdit(configId);

    if (config == null) return;
    if (!context.mounted) return;
    final result = await showMenu<String>(
      context: context,
      position: position,
      items: const [
        PopupMenuItem(value: 'edit',child: Text("编辑")),
        PopupMenuItem(value: 'delete',child: Text("删除")),
      ],
    );

    if(!context.mounted) return;
    if(result == 'edit'){
      RouteUtils.pushForNamed(context,
          RoutePath.deviceRegistrationFrom,
          arguments: config
      );
    }else if(result == 'delete'){
      final l10n = AppLocalizations.of(context);
      final confirmed = await showConfirmDialog(context,
          title: l10n.device_detail_delete_title,
          message: l10n.device_detail_delete_message,
          confirmLabel: l10n.device_detail_confirm,
      );
      if(confirmed != true || !context.mounted) return;
      try{
        await context.read<DeviceVM>().removeDevice(configId);
        if(!context.mounted){
          return;
        }
        showToast(l10n.device_detail_deleted);
        // 注意：这里不能像详情页那样 popOfData——卡片长在设备列表（主导航 tab）里，
        // pop 会把整个主界面关掉。removeDevice -> notifyListeners 后
        // Consumer 会自动刷新列表，无需任何导航。

      }catch(e){
        logE('删除设备失败： $e', error: e, tag:'DeviceDetailPage');
        if (context.mounted) showToast('$e');
      }
    }
  }


}
