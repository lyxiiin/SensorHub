import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/data/models/notification_message.dart';
import 'package:sensor_hub/data/services/mqtt_service.dart';
import 'package:sensor_hub/l10n/app_localizations.dart';
import 'package:sensor_hub/ui/core/ui/title_bar.dart';
import 'package:sensor_hub/ui/notification/view_model/notification_vm.dart';

const Map<int, String> sensorType = {
  0x01: "🌡️ 温度",
  0x02: "💧 湿度",
  0x05: "🌬️ 气压",               // 或 📉（但🌬️更自然）
  0x06: "🧲 霍尔",               // 霍尔传感器常用于磁感应
  0x07: "🧍 人体活动",
  0x0A: "☀️ 光感",
  0x0B: "🫁 CO2(%)",             // 呼吸/空气质量相关
  0x0C: "🌫️ PM2.5",
  0x0D: "🌫️ PM10",
  0x12: "👃 VOC(index)",         // 挥发性有机物，嗅觉相关
  0x13: "🔇 噪声",               // 或 📢，但 🔇 更强调“检测噪声”而非发出声音
  0x14: "🔋 电量(%)",
  0x15: "🫁 CO2(ppm)",           // 与 CO2(%) 统一风格
  0x16: "🌫️ PM1.0",
  0x17: "🌫️ PM4.0",
  0x18: "🌫️ PM100",
  0x19: "👃 VOC(ug/m³)",         // 单位修正为标准格式 µg/m³，但保留原写法也可
  0x1A: "⚡️ 电量(mV)",           // 电压常用 ⚡，或 🔋 但已用于百分比
  0xFF: "❔ 未知"
};

const Map<int, String> sensorTypeUnit = {
  0x01: "℃",      // 温度
  0x02: "%",      // 湿度
  0x05: "kPa",    // 气压（修正拼写）
  0x06: "",       // 霍尔传感器通常输出开关信号或无量纲值，无标准单位
  0x07: "",       // 人体活动：通常为存在/活动状态，无单位
  0x0A: "lux",     // 光照强度单位：勒克斯（lux）
  0x0B: "%",      // CO2(%)
  0x0C: "µg/m³",  // PM2.5（微克每立方米）
  0x0D: "µg/m³",  // PM10
  0x12: "",       // VOC index 通常是无量纲指数
  0x13: "dB",     // 噪声（分贝）
  0x14: "%",      // 电量(%)
  0x15: "ppm",    // CO2(ppm)
  0x16: "µg/m³",  // PM1.0
  0x17: "µg/m³",  // PM4.0
  0x18: "µg/m³",  // PM100
  0x19: "µg/m³",  // VOC(µg/m³)
  0x1A: "mV",     // 电量(mV)
  0xFF: ""
};


class NotificationScreen extends StatelessWidget{
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NotificationVM>(
      create: (context) => NotificationVM(),
      child: const _NotificationScreenContext(),
    );
  }
}


class _NotificationScreenContext extends StatelessWidget{
  const _NotificationScreenContext({super.key});



  @override
  Widget build(BuildContext context) {
    final notificationVM = context.watch<NotificationVM>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appText = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TitleBar(
            title: appText.tab_notifications,
            colorScheme: colorScheme,
            paddingTop: MediaQuery.of(context).padding.top,
          ),
          SizedBox(height: 16.h,),
          Expanded(
            child: notificationList(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget notificationList(ColorScheme colorScheme){
    return Consumer<NotificationVM>(builder: (context,vm,child){
      if(vm.notificationMessages.isEmpty){
        return SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 8.h,
            children: [
              SvgPicture.asset(
                "assets/icons/notification.svg",
                width: 100.w,
                colorFilter: ColorFilter.mode(colorScheme.surfaceContainerHighest, BlendMode.srcIn),
              ),
              Text("暂未收到消息",style: TextStyle(fontSize: 16.sp),textAlign: TextAlign.center,)
            ],
          ),
        );
      }else{
        return ListView.builder(
          padding: EdgeInsets.only(left: 12.w, right: 12.w, top: 12.h, bottom: 12.h),
          itemCount: vm.notificationMessages.length,
          itemBuilder: (context,index){
            return notificationCard(item: vm.notificationMessages[index], colorScheme: colorScheme);
          },
        );
      }
    });
  }


  /// 警告消息卡片（UI 优化版）
  Widget notificationCard({
    required NotificationMessage item,
    required ColorScheme colorScheme,
  }) {
    // 根据 severity 映射颜色（可复用）
    Color indicatorColor = item.severity == 1
        ? const Color(0xFFFFCC00) // Warning yellow
        : const Color(0xFFED1C24); // Critical red

    return GestureDetector(
      onTap: (){

      },
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colorScheme.outline.withOpacity(0.12)),
          borderRadius: BorderRadius.circular(12.r), // 稍大圆角更现代
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 标题行：图标 + 状态标签 + 传感器名称 ---
              Row(
                children: [
                  Container(
                    width: 28.r,
                    height: 28.r,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: indicatorColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "⚠️",
                      style: TextStyle(fontSize: 16.sp),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "超限",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: indicatorColor,
                          ),
                        ),
                        WidgetSpan(child: SizedBox(width: 8.w)),
                        TextSpan(
                          text: item.sensorName,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  // 状态小圆点移到右上角，作为视觉锚点
                  Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // --- 分割线（更细更透明）---
              Divider(
                height: 1.h,
                thickness: 0.8.h,
                color: colorScheme.outline.withOpacity(0.12),
              ),

              SizedBox(height: 10.h),

              // --- 传感器数值行 ---
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "${sensorType[item.sensorType] ?? sensorType[0xFF]!}: "
                          "${restoreOriginalValue(item.sensorType, item.value)} "
                          "${sensorTypeUnit[item.sensorType] ?? sensorType[0xFF]!}",
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 小圆点已移到顶部，此处移除
                ],
              ),

              SizedBox(height: 6.h),

              // --- 时间（弱化显示）---
              Text(
                "发送时间: ${DateTime.fromMillisecondsSinceEpoch(item.datetime * 1000).toLocal()}",
                style: TextStyle(
                  fontSize: 12.sp,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String restoreOriginalValue(int key, dynamic value){
    if(value is int &&(key == 0x01 || key == 0x02)){
      return (value / 10.0).toString();
    }
    return value.toString();
  }

}