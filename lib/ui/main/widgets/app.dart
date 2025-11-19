import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/l10n/app_localizations.dart';
import 'package:sensor_hub/route/routes.dart';
import 'package:sensor_hub/ui/core/themes/app_theme.dart';
import 'package:sensor_hub/ui/device/view_model/device_vm.dart';
import 'package:sensor_hub/ui/profile/view_model/profile_vm.dart';
import '../app_vm.dart';
import 'package:sensor_hub/data/repositories/user_config_repository_impl.dart';

class MyApp extends StatefulWidget{
  final UserConfigRepository userConfig;
  
  const MyApp({
    super.key,
    required this.userConfig,
  });

  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }

}
class _MyAppState extends State<MyApp>{
  late AppVM _appVM;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _appVM = AppVM();
    _appVM.initApp();
    _appVM.themeModelSelectedValue = widget.userConfig.theme;
  }
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => DeviceVM()),
        ChangeNotifierProvider(create: (context) => ProfileVM()),
        ChangeNotifierProvider.value(value: _appVM),
      ],
      child: OKToast(
        child: ScreenUtilInit(
          designSize: const Size(393, 873),
          builder: (context,child) {
            return Consumer<AppVM>(builder: (context,vm,child){
              return MaterialApp(
                key: ValueKey(vm.currentLocale),
                theme: AppThemes.lightTheme,
                darkTheme: AppThemes.darkTheme,
                themeMode: vm.themeModelSelectedValue,
                onGenerateRoute: Routes.generateRoute,
                initialRoute: RoutePath.main,
                locale: vm.currentLocale,
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