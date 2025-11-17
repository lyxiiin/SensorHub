import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/route/routes.dart';
import 'package:sensor_hub/ui/core/themes/app_theme.dart';
import 'package:sensor_hub/ui/device/view_model/device_vm.dart';
import 'package:sensor_hub/ui/profile/view_model/profile_vm.dart';
import '../app_vm.dart';

class MyApp extends StatelessWidget{
  const MyApp({super.key,});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => DeviceVM()),
        ChangeNotifierProvider(create: (context) => ProfileVM()),
        ChangeNotifierProvider(create: (context) => AppVM()),
      ],
      child: OKToast(
        child: ScreenUtilInit(
          designSize: const Size(393, 873),
          builder: (context,child) {
            return Consumer<AppVM>(builder: (context,vm,child){
              return MaterialApp(
                theme: AppThemes.lightTheme,
                darkTheme: AppThemes.darkTheme,
                themeMode: vm.themeModelSelectedValue,
                onGenerateRoute: Routes.generateRoute,
                initialRoute: RoutePath.main,
              );
            });
          },
        ),
      ),
    );
  }
}