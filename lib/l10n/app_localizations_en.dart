// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'Language';

  @override
  String get tab_device => 'Device';

  @override
  String get tab_notifications => 'Notifications';

  @override
  String get tab_profile => 'Profile';

  @override
  String get automatic => 'Automatic';

  @override
  String get device_screen_overLimit => 'Over Limit';

  @override
  String get device_screen_lowBattery => 'Low Battery';

  @override
  String get device_screen_offline => 'Offline';

  @override
  String get device_screen_upgradeable => 'Upgradable';

  @override
  String get device_screen_prompt => 'Add your first device';

  @override
  String get device_screen_unknown_sensor => 'Unknown Sensor';

  @override
  String get device_screen_minutes_ago => 'minutes ago';

  @override
  String get device_screen_all_devices => 'All Devices';

  @override
  String get device_screen_group_empty => 'No devices in this group';

  @override
  String get device_screen_ungrouped_empty => 'No ungrouped devices';

  @override
  String get device_screen_no_devices => 'No devices';

  @override
  String get device_screen_manage_groups => 'Manage Groups';

  @override
  String get device_form_group => 'Device Group';

  @override
  String get device_group_ungrouped => 'Ungrouped';

  @override
  String get group_manage_title => 'Manage Groups';

  @override
  String get group_manage_new_group => 'New Group';

  @override
  String get group_manage_rename => 'Rename';

  @override
  String get group_manage_delete => 'Delete';

  @override
  String get group_manage_empty =>
      'No groups yet\nTap the button below to create one';

  @override
  String get group_manage_name_hint => 'Enter group name';

  @override
  String get group_manage_name_empty => 'Group name cannot be empty';

  @override
  String get group_manage_name_duplicate => 'This group name already exists';

  @override
  String get group_manage_delete_title => 'Delete Group';

  @override
  String group_manage_delete_message(String name, int count) {
    return 'Delete \"$name\"? $count device(s) in it will become ungrouped.';
  }

  @override
  String group_manage_device_count(int count) {
    return '$count devices';
  }

  @override
  String get group_manage_operation_failed => 'Operation failed, please retry';

  @override
  String get profile_screen_personal_info => 'Personal Info';

  @override
  String get profile_screen_notification_settings => 'Notification Settings';

  @override
  String get profile_screen_degree_unit => 'Degree Unit';

  @override
  String get profile_screen_language => 'Language';

  @override
  String get profile_screen_appearance => 'Appearance';

  @override
  String get profile_screen_light_mode => 'Light Mode';

  @override
  String get profile_screen_dark_mode => 'Dark Mode';

  @override
  String get profile_screen_follow_system => 'System';

  @override
  String get common_ui_cancel => 'Cancel';

  @override
  String get common_ui_finish => 'Finish';

  @override
  String get common_ui_coming_soon => 'Coming Soon';

  @override
  String get common_ui_loading => 'Loading…';

  @override
  String get device_detail_edit => 'Edit';

  @override
  String get device_detail_delete => 'Delete';

  @override
  String get device_detail_deleted => 'Device deleted';

  @override
  String get device_detail_sensor_data => 'Real-time Data';

  @override
  String get device_detail_history => 'History Trend';

  @override
  String get device_detail_online => 'Online';

  @override
  String get device_detail_offline => 'Offline';

  @override
  String get device_detail_mac => 'MAC Address';

  @override
  String get device_detail_group => 'Group';

  @override
  String get device_detail_last_update => 'Last Update';

  @override
  String get device_detail_no_data => 'No Data';

  @override
  String get device_detail_no_data_hint =>
      'No sensor data yet. Pull down to refresh';

  @override
  String get device_detail_unknown_device => 'Unknown Device';

  @override
  String get device_detail_delete_title => 'Delete Device';

  @override
  String get device_detail_delete_message =>
      'Delete this device? This action cannot be undone.';

  @override
  String get device_detail_confirm => 'Confirm';

  @override
  String get device_detail_chart_current => 'Current';

  @override
  String get device_detail_chart_max => 'Max';

  @override
  String get device_detail_chart_min => 'Min';

  @override
  String get device_detail_chart_avg => 'Avg';

  @override
  String get common_ui_other => 'Other';

  @override
  String get common_ui_init_failed => 'Initialization failed...';

  @override
  String get common_ui_operation_failed => 'Operation failed. Please try again';

  @override
  String route_not_defined(String name) {
    return 'Route not defined: $name';
  }

  @override
  String get units_page_title => 'Reading Units';

  @override
  String get device_form_title_edit => 'Edit Device';

  @override
  String get device_form_title_register => 'Register Device';

  @override
  String get device_form_section_info => 'Device Information';

  @override
  String get device_form_name_label => 'Name';

  @override
  String get device_form_name_hint => 'Enter device name';

  @override
  String get device_form_name_required => 'Device name is required';

  @override
  String get device_form_broker_label => 'Server Address (Broker)';

  @override
  String get device_form_broker_hint => 'Enter MQTT server address';

  @override
  String get device_form_broker_required => 'Server address is required';

  @override
  String get device_form_broker_invalid => 'Enter a valid server address';

  @override
  String get device_form_port_label => 'Port';

  @override
  String get device_form_port_hint => 'Enter port number';

  @override
  String get device_form_port_required => 'Port is required';

  @override
  String get device_form_port_invalid => 'Enter a valid port (1-65535)';

  @override
  String get device_form_up_topic_label => 'Upstream Topic';

  @override
  String get device_form_up_topic_hint => 'e.g. env_monitor/AABBCCDDEEFF/data';

  @override
  String get device_form_up_topic_required => 'Upstream topic is required';

  @override
  String get device_form_up_topic_invalid =>
      'Invalid topic format: a MAC address segment is required (e.g. env_monitor/AABBCCDDEEFF/data)';

  @override
  String get device_form_up_topic_mac_invalid =>
      'The second segment must be a 12-character MAC address (e.g. AABBCCDDEEFF)';

  @override
  String get device_form_down_topic_label => 'Downstream Topic';

  @override
  String get device_form_down_topic_hint => 'Enter MQTT topic';

  @override
  String get device_form_down_topic_required => 'Topic is required';

  @override
  String get device_form_username_label => 'Username';

  @override
  String get device_form_username_hint => 'Enter username';

  @override
  String get device_form_username_required => 'Username is required';

  @override
  String get device_form_password_label => 'Password';

  @override
  String get device_form_password_hint => 'Enter password';

  @override
  String get device_form_password_required => 'Password is required';

  @override
  String get device_form_password_too_short =>
      'Password must be at least 6 characters';

  @override
  String get device_form_advanced => 'Advanced Settings';

  @override
  String get device_form_client_id_label => 'Client ID';

  @override
  String get device_form_client_id_hint => 'Leave blank to auto-generate';

  @override
  String get device_form_submit_save => 'Save Changes';

  @override
  String get device_form_update_success => 'Device settings updated';

  @override
  String get device_form_update_failed =>
      'Failed to update device settings. Please try again';

  @override
  String get device_form_register_failed => 'Failed to register device';

  @override
  String get sensor_type_temperature => 'Temperature';

  @override
  String get sensor_type_humidity => 'Humidity';

  @override
  String get sensor_type_pressure => 'Pressure';

  @override
  String get sensor_type_co2 => 'CO2';

  @override
  String get sensor_type_pm25 => 'PM2.5';

  @override
  String get sensor_type_pm10 => 'PM10';

  @override
  String get sensor_type_voc => 'VOC';

  @override
  String get sensor_type_noise => 'Noise';

  @override
  String get sensor_type_lux => 'Light';

  @override
  String get notification_empty => 'No messages yet';

  @override
  String get notification_over_limit => 'Over Limit';

  @override
  String notification_sent_time(String time) {
    return 'Sent at $time';
  }

  @override
  String get notification_sensor_temperature => 'Temperature';

  @override
  String get notification_sensor_humidity => 'Humidity';

  @override
  String get notification_sensor_pressure => 'Pressure';

  @override
  String get notification_sensor_hall => 'Hall';

  @override
  String get notification_sensor_human_activity => 'Human Activity';

  @override
  String get notification_sensor_light => 'Light';

  @override
  String get notification_sensor_co2_percent => 'CO2 (%)';

  @override
  String get notification_sensor_pm25 => 'PM2.5';

  @override
  String get notification_sensor_pm10 => 'PM10';

  @override
  String get notification_sensor_voc_index => 'VOC (index)';

  @override
  String get notification_sensor_noise => 'Noise';

  @override
  String get notification_sensor_battery_percent => 'Battery (%)';

  @override
  String get notification_sensor_co2_ppm => 'CO2 (ppm)';

  @override
  String get notification_sensor_pm1 => 'PM1.0';

  @override
  String get notification_sensor_pm4 => 'PM4.0';

  @override
  String get notification_sensor_pm100 => 'PM100';

  @override
  String get notification_sensor_voc_density => 'VOC (µg/m³)';

  @override
  String get notification_sensor_battery_mv => 'Battery (mV)';

  @override
  String get notification_sensor_unknown => 'Unknown';
}
