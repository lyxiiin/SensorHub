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
}
