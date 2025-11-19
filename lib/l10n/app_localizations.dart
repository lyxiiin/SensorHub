import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @tab_device.
  ///
  /// In zh, this message translates to:
  /// **'设备'**
  String get tab_device;

  /// No description provided for @tab_notifications.
  ///
  /// In zh, this message translates to:
  /// **'通知'**
  String get tab_notifications;

  /// No description provided for @tab_profile.
  ///
  /// In zh, this message translates to:
  /// **'我'**
  String get tab_profile;

  /// No description provided for @automatic.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get automatic;

  /// No description provided for @device_screen_overLimit.
  ///
  /// In zh, this message translates to:
  /// **'超限'**
  String get device_screen_overLimit;

  /// No description provided for @device_screen_lowBattery.
  ///
  /// In zh, this message translates to:
  /// **'低电'**
  String get device_screen_lowBattery;

  /// No description provided for @device_screen_offline.
  ///
  /// In zh, this message translates to:
  /// **'离线'**
  String get device_screen_offline;

  /// No description provided for @device_screen_upgradeable.
  ///
  /// In zh, this message translates to:
  /// **'待升级'**
  String get device_screen_upgradeable;

  /// No description provided for @device_screen_prompt.
  ///
  /// In zh, this message translates to:
  /// **'添加你的第一台设备'**
  String get device_screen_prompt;

  /// No description provided for @device_screen_unknown_sensor.
  ///
  /// In zh, this message translates to:
  /// **'未知传感器'**
  String get device_screen_unknown_sensor;

  /// No description provided for @device_screen_minutes_ago.
  ///
  /// In zh, this message translates to:
  /// **'分钟前'**
  String get device_screen_minutes_ago;

  /// No description provided for @profile_screen_personal_info.
  ///
  /// In zh, this message translates to:
  /// **'个人资料'**
  String get profile_screen_personal_info;

  /// No description provided for @profile_screen_notification_settings.
  ///
  /// In zh, this message translates to:
  /// **'通知设置'**
  String get profile_screen_notification_settings;

  /// No description provided for @profile_screen_degree_unit.
  ///
  /// In zh, this message translates to:
  /// **'度数单位'**
  String get profile_screen_degree_unit;

  /// No description provided for @profile_screen_language.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get profile_screen_language;

  /// No description provided for @profile_screen_appearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get profile_screen_appearance;

  /// No description provided for @profile_screen_light_mode.
  ///
  /// In zh, this message translates to:
  /// **'浅色模式'**
  String get profile_screen_light_mode;

  /// No description provided for @profile_screen_dark_mode.
  ///
  /// In zh, this message translates to:
  /// **'深色模式'**
  String get profile_screen_dark_mode;

  /// No description provided for @profile_screen_follow_system.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get profile_screen_follow_system;

  /// No description provided for @common_ui_finish.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get common_ui_finish;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
