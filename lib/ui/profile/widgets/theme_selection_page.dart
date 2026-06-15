import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/data/services/settings_service.dart';
import 'package:sensor_hub/route/route_utils.dart';
import 'package:sensor_hub/ui/profile/view_model/profile_vm.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/ui/custom_app_bar.dart';

class ThemeSelectionPage extends StatefulWidget{
  const ThemeSelectionPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _ThemeSelectionPageState();
  }
}

class _ThemeSelectionPageState extends State<ThemeSelectionPage>{
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileVM = Provider.of<ProfileVM>(context, listen: false);
      profileVM.resetTheme();
    });
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appText = AppLocalizations.of(context);
    return Scaffold(
      extendBody: true,
      backgroundColor: colorScheme.surface,
      appBar: createAppBar(
          title: appText.profile_screen_appearance,
          appText: appText,
          onBack: () {
            RouteUtils.pop(context);
          },
          colorScheme: colorScheme,
          onFinish: () {
            final settings = Provider.of<SettingsService>(context, listen: false);
            final profileVM = Provider.of<ProfileVM>(context, listen: false);
            profileVM.saveTheme(settings);
            RouteUtils.pop(context);
          }
      ),
      body: SafeArea(
        child: Container(
            color: colorScheme.surfaceContainer,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _themeModelGroupCart(colorScheme: colorScheme,appText: appText),
              ],
            ),
          ),
        ),
    );
  }

  Widget _themeModelGroupCart({
    required ColorScheme colorScheme,
    required AppLocalizations appText,
  }){
    final List<ThemeMode> themeModes = [
      ThemeMode.light,
      ThemeMode.dark,
      ThemeMode.system,
    ];
    final List<String> themeLabels = [
      appText.profile_screen_light_mode,
      appText.profile_screen_dark_mode,
      appText.profile_screen_follow_system,
    ];
    return Consumer2<ProfileVM, SettingsService>(builder: (context, profileVM, settings, child){
      // 初始化临时值
      if (profileVM.tempSelectedValue == null) {
        profileVM.initFromSettings(settings);
      }
      
      themeModelSelectedValue = profileVM.tempSelectedValue ?? settings.themeMode;
      return Column(
        children: List.generate(themeModes.length, (index) {
          return RadioListTile<ThemeMode>(
            title: Text(
              themeLabels[index],
              style: TextStyle(
                fontSize: 16.sp,
              ),
            ),
            value: themeModes[index],
            groupValue: themeModelSelectedValue,
            onChanged: (ThemeMode? value) {
              profileVM.changedTempThemeValue(value);
            },
          );
        }).toList(),
      );
    });
  }
  late ThemeMode themeModelSelectedValue;
}

