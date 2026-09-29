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
  String get device_screen_all_devices => 'すべてのデバイス';

  @override
  String get device_screen_group_empty => 'このグループにデバイスがありません';

  @override
  String get device_screen_ungrouped_empty => '未分類のデバイスはありません';

  @override
  String get device_screen_no_devices => 'デバイスがありません';

  @override
  String get device_screen_manage_groups => 'グループ管理';

  @override
  String get device_form_group => 'デバイスグループ';

  @override
  String get device_group_ungrouped => '未分類';

  @override
  String get group_manage_title => 'グループ管理';

  @override
  String get group_manage_new_group => '新規グループ';

  @override
  String get group_manage_rename => '名前を変更';

  @override
  String get group_manage_delete => '削除';

  @override
  String get group_manage_empty => 'グループがありません\n下のボタンから作成できます';

  @override
  String get group_manage_name_hint => 'グループ名を入力';

  @override
  String get group_manage_name_empty => 'グループ名を入力してください';

  @override
  String get group_manage_name_duplicate => 'このグループ名はすでに存在します';

  @override
  String get group_manage_delete_title => 'グループを削除';

  @override
  String group_manage_delete_message(String name, int count) {
    return '「$name」を削除しますか？$count 台のデバイスが未分類になります。';
  }

  @override
  String group_manage_device_count(int count) {
    return '$count 台';
  }

  @override
  String get group_manage_operation_failed => '操作に失敗しました。もう一度お試しください';

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

  @override
  String get common_ui_coming_soon => '開発中';

  @override
  String get common_ui_loading => '読み込み中…';

  @override
  String get device_detail_edit => '編集';

  @override
  String get device_detail_delete => '削除';

  @override
  String get device_detail_deleted => 'デバイスを削除しました';

  @override
  String get device_detail_sensor_data => 'リアルタイムデータ';

  @override
  String get device_detail_history => '履歴トレンド';

  @override
  String get device_detail_online => 'オンライン';

  @override
  String get device_detail_offline => 'オフライン';

  @override
  String get device_detail_mac => 'MACアドレス';

  @override
  String get device_detail_group => 'グループ';

  @override
  String get device_detail_last_update => '最終更新';

  @override
  String get device_detail_no_data => 'データなし';

  @override
  String get device_detail_no_data_hint => 'センサーデータがありません。下に引いて更新してください';

  @override
  String get device_detail_unknown_device => '不明なデバイス';

  @override
  String get device_detail_delete_title => 'デバイスを削除';

  @override
  String get device_detail_delete_message => 'このデバイスを削除しますか？この操作は元に戻せません。';

  @override
  String get device_detail_confirm => '確認';

  @override
  String get device_detail_chart_current => '現在値';

  @override
  String get device_detail_chart_max => '最大';

  @override
  String get device_detail_chart_min => '最小';

  @override
  String get device_detail_chart_avg => '平均';

  @override
  String get common_ui_other => 'その他';

  @override
  String get common_ui_init_failed => '初期化に失敗しました...';

  @override
  String get common_ui_operation_failed => '操作に失敗しました。もう一度お試しください';

  @override
  String route_not_defined(String name) {
    return '未定義のルート: $name';
  }

  @override
  String get units_page_title => '読み取り単位';

  @override
  String get device_form_title_edit => 'デバイスを編集';

  @override
  String get device_form_title_register => 'デバイスを登録';

  @override
  String get device_form_section_info => 'デバイス情報';

  @override
  String get device_form_name_label => '名称';

  @override
  String get device_form_name_hint => 'デバイス名を入力';

  @override
  String get device_form_name_required => 'デバイス名は必須です';

  @override
  String get device_form_broker_label => 'サーバーアドレス(Broker)';

  @override
  String get device_form_broker_hint => 'MQTTサーバーアドレスを入力';

  @override
  String get device_form_broker_required => 'サーバーアドレスは必須です';

  @override
  String get device_form_broker_invalid => '有効なサーバーアドレスを入力してください';

  @override
  String get device_form_port_label => 'ポート(Port)';

  @override
  String get device_form_port_hint => 'ポート番号を入力';

  @override
  String get device_form_port_required => 'ポート番号は必須です';

  @override
  String get device_form_port_invalid => '有効なポート番号を入力してください（1〜65535）';

  @override
  String get device_form_up_topic_label => '上りトピック(Topic)';

  @override
  String get device_form_up_topic_hint => '例：env_monitor/AABBCCDDEEFF/data';

  @override
  String get device_form_up_topic_required => '上りトピックは必須です';

  @override
  String get device_form_up_topic_invalid =>
      'トピックの形式が無効です。MACアドレス部分が必要です（例：env_monitor/AABBCCDDEEFF/data）';

  @override
  String get device_form_up_topic_mac_invalid =>
      'トピックの第2セグメントは12桁のMACアドレスである必要があります（例：AABBCCDDEEFF）';

  @override
  String get device_form_down_topic_label => '下りトピック(Topic)';

  @override
  String get device_form_down_topic_hint => 'MQTTトピックを入力';

  @override
  String get device_form_down_topic_required => 'トピックは必須です';

  @override
  String get device_form_username_label => 'ユーザー名';

  @override
  String get device_form_username_hint => 'ユーザー名を入力';

  @override
  String get device_form_username_required => 'ユーザー名は必須です';

  @override
  String get device_form_password_label => 'パスワード';

  @override
  String get device_form_password_hint => 'パスワードを入力';

  @override
  String get device_form_password_required => 'パスワードは必須です';

  @override
  String get device_form_password_too_short => 'パスワードは6文字以上で入力してください';

  @override
  String get device_form_advanced => '詳細設定';

  @override
  String get device_form_client_id_label => 'クライアントID (Client ID)';

  @override
  String get device_form_client_id_hint => '空欄の場合は自動生成されます';

  @override
  String get device_form_submit_save => '変更を保存';

  @override
  String get device_form_update_success => 'デバイス設定を更新しました';

  @override
  String get device_form_update_failed => 'デバイス設定の更新に失敗しました。もう一度お試しください';

  @override
  String get device_form_register_failed => 'デバイスの登録に失敗しました';

  @override
  String get sensor_type_temperature => '温度';

  @override
  String get sensor_type_humidity => '湿度';

  @override
  String get sensor_type_pressure => '気圧';

  @override
  String get sensor_type_co2 => '二酸化炭素';

  @override
  String get sensor_type_pm25 => 'PM2.5';

  @override
  String get sensor_type_pm10 => 'PM10';

  @override
  String get sensor_type_voc => 'VOC';

  @override
  String get sensor_type_noise => 'ノイズ';

  @override
  String get sensor_type_lux => '照度';

  @override
  String get notification_empty => 'メッセージはまだありません';

  @override
  String get notification_over_limit => '上限超過';

  @override
  String notification_sent_time(String time) {
    return '送信時間: $time';
  }

  @override
  String get notification_sensor_temperature => '温度';

  @override
  String get notification_sensor_humidity => '湿度';

  @override
  String get notification_sensor_pressure => '気圧';

  @override
  String get notification_sensor_hall => 'ホール';

  @override
  String get notification_sensor_human_activity => '人体検知';

  @override
  String get notification_sensor_light => '照度';

  @override
  String get notification_sensor_co2_percent => 'CO2（%）';

  @override
  String get notification_sensor_pm25 => 'PM2.5';

  @override
  String get notification_sensor_pm10 => 'PM10';

  @override
  String get notification_sensor_voc_index => 'VOC（index）';

  @override
  String get notification_sensor_noise => 'ノイズ';

  @override
  String get notification_sensor_battery_percent => '電池（%）';

  @override
  String get notification_sensor_co2_ppm => 'CO2（ppm）';

  @override
  String get notification_sensor_pm1 => 'PM1.0';

  @override
  String get notification_sensor_pm4 => 'PM4.0';

  @override
  String get notification_sensor_pm100 => 'PM100';

  @override
  String get notification_sensor_voc_density => 'VOC（µg/m³）';

  @override
  String get notification_sensor_battery_mv => '電池（mV）';

  @override
  String get notification_sensor_unknown => '不明';
}
