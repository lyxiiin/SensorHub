// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get language => '言語';

  @override
  String get tab_device => 'デバイス';

  @override
  String get tab_notifications => '通知';

  @override
  String get tab_profile => 'マイページ';

  @override
  String get automatic => 'システムに従う';

  @override
  String get device_screen_overLimit => '上限超過';

  @override
  String get device_screen_lowBattery => '電池切れ';

  @override
  String get device_screen_offline => 'オフライン';

  @override
  String get device_screen_upgradeable => '更新あり';

  @override
  String get device_screen_prompt => '最初のデバイスを追加してください';

  @override
  String get device_screen_unknown_sensor => '不明なセンサー';

  @override
  String get device_screen_minutes_ago => '分前';

  @override
  String get profile_screen_personal_info => '個人情報';

  @override
  String get profile_screen_notification_settings => '通知設定';

  @override
  String get profile_screen_degree_unit => '単位（度数）';

  @override
  String get profile_screen_language => '言語';

  @override
  String get profile_screen_appearance => '外観';

  @override
  String get profile_screen_light_mode => 'ライトモード';

  @override
  String get profile_screen_dark_mode => 'ダークモード';

  @override
  String get profile_screen_follow_system => '自動';

  @override
  String get common_ui_cancel => 'キャンセル';

  @override
  String get common_ui_finish => '完了';
}
