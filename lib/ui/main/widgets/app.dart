import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/data/services/settings_service.dart';
import 'package:sensor_hub/l10n/app_localizations.dart';
import 'package:sensor_hub/route/routes.dart';
import 'package:sensor_hub/ui/core/themes/app_theme.dart';
import 'package:sensor_hub/ui/device/view_model/device_vm.dart';
import 'package:sensor_hub/ui/profile/view_model/profile_vm.dart';
import '../app_vm.dart';

class MyApp extends StatefulWidget{
  final SettingsService settingsService;
  const MyApp({
    super.key,
    required this.settingsService,
  });

  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }

}
class _MyAppState extends State<MyApp>{
  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.settingsService),
        ChangeNotifierProvider(create: (context) => DeviceVM()),
        ChangeNotifierProvider(create: (context) => ProfileVM()),
      ],
      child: OKToast(
        child: ScreenUtilInit(
          designSize: const Size(393, 873),
          builder: (context,child) {
            return Consumer<SettingsService>(builder: (context,settings,child){
              return MaterialApp(
                key: ValueKey(settings.locale),
                theme: AppThemes.lightTheme,
                darkTheme: AppThemes.darkTheme,
                themeMode: settings.themeMode,
                onGenerateRoute: Routes.generateRoute,
                initialRoute: RoutePath.main,
                locale: settings.locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
              );
            });
          },
        ),
      ),
    );
  }
}