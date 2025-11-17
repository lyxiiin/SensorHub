import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/route/routes.dart';
import 'package:sensor_hub/ui/core/themes/app_theme.dart';
import 'package:sensor_hub/ui/device/view_model/device_vm.dart';
import 'package:sensor_hub/ui/profile/view_model/profile_vm.dart';

class MyApp extends StatelessWidget{
  final String theme;
  const MyApp({
    super.key,
    required this.theme
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => DeviceVM()),
        ChangeNotifierProvider(create: (context) => ProfileVM()),
      ],
      child: OKToast(
        child: ScreenUtilInit(
          designSize: const Size(393, 873),
          builder: (context,child) {
            return MaterialApp(
              theme: AppThemes.lightTheme,
              darkTheme: AppThemes.darkTheme,
              themeMode: theme == "light" ? ThemeMode.light : theme == "dart" ? ThemeMode.dark : ThemeMode.system,
              onGenerateRoute: Routes.generateRoute,
              initialRoute: RoutePath.main,
            );
          },
        ),
      ),
    );
  }
}