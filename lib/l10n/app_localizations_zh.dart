// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get language => '语言';

  @override
  String get tab_device => '设备';

  @override
  String get tab_notifications => '通知';

  @override
  String get tab_profile => '我';

  @override
  String get automatic => '跟随系统';

  @override
  String get device_screen_overLimit => '超限';

  @override
  String get device_screen_lowBattery => '低电';

  @override
  String get device_screen_offline => '离线';

  @override
  String get device_screen_upgradeable => '待升级';

  @override
  String get device_screen_prompt => '添加你的第一台设备';

  @override
  String get device_screen_unknown_sensor => '未知传感器';

  @override
  String get device_screen_minutes_ago => '分钟前';

  @override
  String get device_screen_all_devices => '全部设备';

  @override
  String get device_screen_group_empty => '该分组暂无设备';

  @override
  String get device_screen_ungrouped_empty => '暂无未分组设备';

  @override
  String get device_screen_no_devices => '暂无设备';

  @override
  String get device_screen_manage_groups => '管理分组';

  @override
  String get device_form_group => '设备分组';

  @override
  String get device_group_ungrouped => '未分组';

  @override
  String get group_manage_title => '分组管理';

  @override
  String get group_manage_new_group => '新建分组';

  @override
  String get group_manage_rename => '重命名';

  @override
  String get group_manage_delete => '删除';

  @override
  String get group_manage_empty => '还没有分组\n点击下方按钮新建一个吧';

  @override
  String get group_manage_name_hint => '请输入分组名称';

  @override
  String get group_manage_name_empty => '分组名称不能为空';

  @override
  String get group_manage_name_duplicate => '该分组名称已存在';

  @override
  String get group_manage_delete_title => '删除分组';

  @override
  String group_manage_delete_message(String name, int count) {
    return '确定要删除「$name」吗？组内 $count 台设备将变为未分组。';
  }

  @override
  String group_manage_device_count(int count) {
    return '$count 台设备';
  }

  @override
  String get group_manage_operation_failed => '操作失败，请重试';

  @override
  String get profile_screen_personal_info => '个人资料';

  @override
  String get profile_screen_notification_settings => '通知设置';

  @override
  String get profile_screen_degree_unit => '度数单位';

  @override
  String get profile_screen_language => '语言';

  @override
  String get profile_screen_appearance => '外观';

  @override
  String get profile_screen_light_mode => '浅色模式';

  @override
  String get profile_screen_dark_mode => '深色模式';

  @override
  String get profile_screen_follow_system => '跟随系统';

  @override
  String get common_ui_cancel => '取消';

  @override
  String get common_ui_finish => '完成';

  @override
  String get common_ui_coming_soon => '功能开发中';

  @override
  String get common_ui_loading => '加载中…';

  @override
  String get device_detail_edit => '编辑';

  @override
  String get device_detail_delete => '删除';

  @override
  String get device_detail_deleted => '设备已删除';

  @override
  String get device_detail_sensor_data => '实时数据';

  @override
  String get device_detail_history => '历史趋势';

  @override
  String get device_detail_online => '在线';

  @override
  String get device_detail_offline => '离线';

  @override
  String get device_detail_mac => 'MAC 地址';

  @override
  String get device_detail_group => '分组';

  @override
  String get device_detail_last_update => '最近更新';

  @override
  String get device_detail_no_data => '暂无数据';

  @override
  String get device_detail_no_data_hint => '暂无传感器数据，请下拉刷新';

  @override
  String get device_detail_unknown_device => '未知设备';

  @override
  String get device_detail_delete_title => '删除设备';

  @override
  String get device_detail_delete_message => '确定要删除该设备吗？此操作不可撤销。';

  @override
  String get device_detail_confirm => '确定';

  @override
  String get device_detail_chart_current => '当前';

  @override
  String get device_detail_chart_max => '最高';

  @override
  String get device_detail_chart_min => '最低';

  @override
  String get device_detail_chart_avg => '平均';

  @override
  String get common_ui_other => '其他';

  @override
  String get common_ui_init_failed => '初始化失败...';

  @override
  String get common_ui_operation_failed => '操作失败，请重试';

  @override
  String route_not_defined(String name) {
    return '未定义的路由: $name';
  }

  @override
  String get units_page_title => '读数单位';

  @override
  String get device_form_title_edit => '编辑设备';

  @override
  String get device_form_title_register => '注册设备';

  @override
  String get device_form_section_info => '设备信息';

  @override
  String get device_form_name_label => '名称';

  @override
  String get device_form_name_hint => '请输入设备名称';

  @override
  String get device_form_name_required => '设备名称不能为空';

  @override
  String get device_form_broker_label => '服务器地址(Broker)';

  @override
  String get device_form_broker_hint => '请输入MQTT服务器地址';

  @override
  String get device_form_broker_required => '服务器地址不能为空';

  @override
  String get device_form_broker_invalid => '请输入有效的服务器地址';

  @override
  String get device_form_port_label => '端口(Port)';

  @override
  String get device_form_port_hint => '请输入端口号';

  @override
  String get device_form_port_required => '端口号不能为空';

  @override
  String get device_form_port_invalid => '请输入有效的端口号(1-65535)';

  @override
  String get device_form_up_topic_label => '上行主题(Topic)';

  @override
  String get device_form_up_topic_hint => '例如 env_monitor/AABBCCDDEEFF/data';

  @override
  String get device_form_up_topic_required => '上行主题不能为空';

  @override
  String get device_form_up_topic_invalid =>
      '主题格式无效，需包含 MAC 地址段（如 env_monitor/AABBCCDDEEFF/data）';

  @override
  String get device_form_up_topic_mac_invalid =>
      '主题第二段须为12位MAC地址（如 AABBCCDDEEFF）';

  @override
  String get device_form_down_topic_label => '下行主题(Topic)';

  @override
  String get device_form_down_topic_hint => '请输入MQTT主题';

  @override
  String get device_form_down_topic_required => '主题不能为空';

  @override
  String get device_form_username_label => '用户名称';

  @override
  String get device_form_username_hint => '请输入用户名';

  @override
  String get device_form_username_required => '用户名不能为空';

  @override
  String get device_form_password_label => '密码';

  @override
  String get device_form_password_hint => '请输入密码';

  @override
  String get device_form_password_required => '密码不能为空';

  @override
  String get device_form_password_too_short => '密码长度至少6位';

  @override
  String get device_form_advanced => '高级设置';

  @override
  String get device_form_client_id_label => '客户端ID (Client ID)';

  @override
  String get device_form_client_id_hint => '留空则自动生成';

  @override
  String get device_form_submit_save => '保存修改';

  @override
  String get device_form_update_success => '设备配置已更新';

  @override
  String get device_form_update_failed => '设备配置更新失败，请重试';

  @override
  String get device_form_register_failed => '注册设备失败';

  @override
  String get sensor_type_temperature => '温度';

  @override
  String get sensor_type_humidity => '湿度';

  @override
  String get sensor_type_pressure => '压力';

  @override
  String get sensor_type_co2 => '二氧化碳';

  @override
  String get sensor_type_pm25 => 'PM2.5';

  @override
  String get sensor_type_pm10 => 'PM10';

  @override
  String get sensor_type_voc => 'VOC';

  @override
  String get sensor_type_noise => '噪声';

  @override
  String get sensor_type_lux => '光';

  @override
  String get notification_empty => '暂未收到消息';

  @override
  String get notification_over_limit => '超限';

  @override
  String notification_sent_time(String time) {
    return '发送时间: $time';
  }

  @override
  String get notification_sensor_temperature => '温度';

  @override
  String get notification_sensor_humidity => '湿度';

  @override
  String get notification_sensor_pressure => '气压';

  @override
  String get notification_sensor_hall => '霍尔';

  @override
  String get notification_sensor_human_activity => '人体活动';

  @override
  String get notification_sensor_light => '光感';

  @override
  String get notification_sensor_co2_percent => 'CO2(%)';

  @override
  String get notification_sensor_pm25 => 'PM2.5';

  @override
  String get notification_sensor_pm10 => 'PM10';

  @override
  String get notification_sensor_voc_index => 'VOC(index)';

  @override
  String get notification_sensor_noise => '噪声';

  @override
  String get notification_sensor_battery_percent => '电量(%)';

  @override
  String get notification_sensor_co2_ppm => 'CO2(ppm)';

  @override
  String get notification_sensor_pm1 => 'PM1.0';

  @override
  String get notification_sensor_pm4 => 'PM4.0';

  @override
  String get notification_sensor_pm100 => 'PM100';

  @override
  String get notification_sensor_voc_density => 'VOC(µg/m³)';

  @override
  String get notification_sensor_battery_mv => '电量(mV)';

  @override
  String get notification_sensor_unknown => '未知';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get language => '語言';

  @override
  String get tab_device => '設備';

  @override
  String get tab_notifications => '通知';

  @override
  String get tab_profile => '我';

  @override
  String get automatic => '跟随系统';

  @override
  String get device_screen_overLimit => '超限';

  @override
  String get device_screen_lowBattery => '低電';

  @override
  String get device_screen_offline => '離線';

  @override
  String get device_screen_upgradeable => '待升級';

  @override
  String get device_screen_prompt => '新增您的第一台裝置';

  @override
  String get device_screen_unknown_sensor => '未知感測器';

  @override
  String get device_screen_minutes_ago => '分鐘前';

  @override
  String get device_screen_all_devices => '全部裝置';

  @override
  String get device_screen_group_empty => '該分組暫無裝置';

  @override
  String get device_screen_ungrouped_empty => '暫無未分組裝置';

  @override
  String get device_screen_no_devices => '暫無裝置';

  @override
  String get device_screen_manage_groups => '管理分組';

  @override
  String get device_form_group => '裝置分組';

  @override
  String get device_group_ungrouped => '未分組';

  @override
  String get group_manage_title => '管理分組';

  @override
  String get group_manage_new_group => '新增分組';

  @override
  String get group_manage_rename => '重新命名';

  @override
  String get group_manage_delete => '刪除';

  @override
  String get group_manage_empty => '還沒有分組\n點擊下方按鈕新建一個吧';

  @override
  String get group_manage_name_hint => '請輸入分組名稱';

  @override
  String get group_manage_name_empty => '分組名稱不能為空';

  @override
  String get group_manage_name_duplicate => '該分組名稱已存在';

  @override
  String get group_manage_delete_title => '刪除分組';

  @override
  String group_manage_delete_message(String name, int count) {
    return '確定要刪除「$name」嗎？組內 $count 台裝置將變為未分組。';
  }

  @override
  String group_manage_device_count(int count) {
    return '$count 台裝置';
  }

  @override
  String get group_manage_operation_failed => '操作失敗，請重試';

  @override
  String get profile_screen_personal_info => '個人資料';

  @override
  String get profile_screen_notification_settings => '通知設定';

  @override
  String get profile_screen_degree_unit => '度數單位';

  @override
  String get profile_screen_language => '語言';

  @override
  String get profile_screen_appearance => '外觀';

  @override
  String get profile_screen_light_mode => '淺色模式';

  @override
  String get profile_screen_dark_mode => '深色模式';

  @override
  String get profile_screen_follow_system => '跟隨系統';

  @override
  String get common_ui_cancel => '取消';

  @override
  String get common_ui_finish => '完成';

  @override
  String get common_ui_coming_soon => '功能開發中';

  @override
  String get common_ui_loading => '載入中…';

  @override
  String get device_detail_edit => '編輯';

  @override
  String get device_detail_delete => '刪除';

  @override
  String get device_detail_deleted => '裝置已刪除';

  @override
  String get device_detail_sensor_data => '即時數據';

  @override
  String get device_detail_history => '歷史趨勢';

  @override
  String get device_detail_online => '在線';

  @override
  String get device_detail_offline => '離線';

  @override
  String get device_detail_mac => 'MAC 位址';

  @override
  String get device_detail_group => '分組';

  @override
  String get device_detail_last_update => '最近更新';

  @override
  String get device_detail_no_data => '暫無數據';

  @override
  String get device_detail_no_data_hint => '暫無感測器數據，請下拉刷新';

  @override
  String get device_detail_unknown_device => '未知裝置';

  @override
  String get device_detail_delete_title => '刪除裝置';

  @override
  String get device_detail_delete_message => '確定要刪除該裝置嗎？此操作無法復原。';

  @override
  String get device_detail_confirm => '確定';

  @override
  String get device_detail_chart_current => '當前';

  @override
  String get device_detail_chart_max => '最高';

  @override
  String get device_detail_chart_min => '最低';

  @override
  String get device_detail_chart_avg => '平均';

  @override
  String get common_ui_other => '其他';

  @override
  String get common_ui_init_failed => '初始化失敗...';

  @override
  String get common_ui_operation_failed => '操作失敗，請重試';

  @override
  String route_not_defined(String name) {
    return '未定義的路由: $name';
  }

  @override
  String get units_page_title => '讀數單位';

  @override
  String get device_form_title_edit => '編輯裝置';

  @override
  String get device_form_title_register => '註冊裝置';

  @override
  String get device_form_section_info => '裝置資訊';

  @override
  String get device_form_name_label => '名稱';

  @override
  String get device_form_name_hint => '請輸入裝置名稱';

  @override
  String get device_form_name_required => '裝置名稱不能為空';

  @override
  String get device_form_broker_label => '伺服器位址(Broker)';

  @override
  String get device_form_broker_hint => '請輸入MQTT伺服器位址';

  @override
  String get device_form_broker_required => '伺服器位址不能為空';

  @override
  String get device_form_broker_invalid => '請輸入有效的伺服器位址';

  @override
  String get device_form_port_label => '連接埠(Port)';

  @override
  String get device_form_port_hint => '請輸入連接埠號';

  @override
  String get device_form_port_required => '連接埠號不能為空';

  @override
  String get device_form_port_invalid => '請輸入有效的連接埠號(1-65535)';

  @override
  String get device_form_up_topic_label => '上行主題(Topic)';

  @override
  String get device_form_up_topic_hint => '例如 env_monitor/AABBCCDDEEFF/data';

  @override
  String get device_form_up_topic_required => '上行主題不能為空';

  @override
  String get device_form_up_topic_invalid =>
      '主題格式無效，需包含 MAC 位址段（如 env_monitor/AABBCCDDEEFF/data）';

  @override
  String get device_form_up_topic_mac_invalid =>
      '主題第二段須為12位MAC位址（如 AABBCCDDEEFF）';

  @override
  String get device_form_down_topic_label => '下行主題(Topic)';

  @override
  String get device_form_down_topic_hint => '請輸入MQTT主題';

  @override
  String get device_form_down_topic_required => '主題不能為空';

  @override
  String get device_form_username_label => '使用者名稱';

  @override
  String get device_form_username_hint => '請輸入使用者名稱';

  @override
  String get device_form_username_required => '使用者名稱不能為空';

  @override
  String get device_form_password_label => '密碼';

  @override
  String get device_form_password_hint => '請輸入密碼';

  @override
  String get device_form_password_required => '密碼不能為空';

  @override
  String get device_form_password_too_short => '密碼長度至少6位';

  @override
  String get device_form_advanced => '進階設定';

  @override
  String get device_form_client_id_label => '用戶端ID (Client ID)';

  @override
  String get device_form_client_id_hint => '留空則自動生成';

  @override
  String get device_form_submit_save => '儲存修改';

  @override
  String get device_form_update_success => '裝置設定已更新';

  @override
  String get device_form_update_failed => '裝置設定更新失敗，請重試';

  @override
  String get device_form_register_failed => '註冊裝置失敗';

  @override
  String get sensor_type_temperature => '溫度';

  @override
  String get sensor_type_humidity => '濕度';

  @override
  String get sensor_type_pressure => '氣壓';

  @override
  String get sensor_type_co2 => '二氧化碳';

  @override
  String get sensor_type_pm25 => 'PM2.5';

  @override
  String get sensor_type_pm10 => 'PM10';

  @override
  String get sensor_type_voc => 'VOC';

  @override
  String get sensor_type_noise => '噪音';

  @override
  String get sensor_type_lux => '光';

  @override
  String get notification_empty => '尚未收到訊息';

  @override
  String get notification_over_limit => '超限';

  @override
  String notification_sent_time(String time) {
    return '發送時間: $time';
  }

  @override
  String get notification_sensor_temperature => '溫度';

  @override
  String get notification_sensor_humidity => '濕度';

  @override
  String get notification_sensor_pressure => '氣壓';

  @override
  String get notification_sensor_hall => '霍爾';

  @override
  String get notification_sensor_human_activity => '人體活動';

  @override
  String get notification_sensor_light => '光感';

  @override
  String get notification_sensor_co2_percent => 'CO2(%)';

  @override
  String get notification_sensor_pm25 => 'PM2.5';

  @override
  String get notification_sensor_pm10 => 'PM10';

  @override
  String get notification_sensor_voc_index => 'VOC(index)';

  @override
  String get notification_sensor_noise => '噪音';

  @override
  String get notification_sensor_battery_percent => '電量(%)';

  @override
  String get notification_sensor_co2_ppm => 'CO2(ppm)';

  @override
  String get notification_sensor_pm1 => 'PM1.0';

  @override
  String get notification_sensor_pm4 => 'PM4.0';

  @override
  String get notification_sensor_pm100 => 'PM100';

  @override
  String get notification_sensor_voc_density => 'VOC(µg/m³)';

  @override
  String get notification_sensor_battery_mv => '電量(mV)';

  @override
  String get notification_sensor_unknown => '未知';
}
