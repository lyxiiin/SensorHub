import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sensor_hub/ui/device/widgets/device_screen.dart';
import 'package:sensor_hub/ui/notification/widgets/notification_screen.dart';
import 'package:sensor_hub/ui/profile/widgets/profile_screen.dart';

import '../../../l10n/app_localizations.dart';
import 'navigation_bar_item.dart';

class AppNavigationPage extends StatefulWidget{
  const AppNavigationPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AppNavigationPageState();
  }

}

class _AppNavigationPageState extends State<AppNavigationPage >{
  int _currentIndex = 0;
  final List<Widget> tabItems = [];
  final List<String> tabLabels = [];
  final List<String> tabIcons = [
    "assets/icons/icon_device.svg",
    "assets/icons/icon_notifications.svg",
    "assets/icons/icon_profile.svg",
  ];
  @override
  void initState() {
    super.initState();
    initTabPage();
  }
  void initTabPage(){
    tabItems.add(DeviceScreen());
    tabItems.add(NotificationScreen());
    tabItems.add(ProfileScreen());
  }
  @override
  Widget build(BuildContext context) {
    final appText = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    tabLabels.add(appText.tab_device);
    tabLabels.add(appText.tab_notifications);
    tabLabels.add(appText.tab_profile);


    return Scaffold(
      appBar: null,
      // primary: false, //顶部延申
      backgroundColor: colorScheme.surface,
      body: IndexedStack(index: _currentIndex,children: tabItems,),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: colorScheme.surface,
        iconSize: 24.r,
        selectedFontSize: 14.sp,
        unselectedFontSize: 12.sp,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        items: _barItemList(colorScheme),
        onTap: (index){
          if(_currentIndex == index){
            return;
          }
          _currentIndex = index;
          setState(() {});
        },
      ),
    );
  }
  List<BottomNavigationBarItem> _barItemList(ColorScheme colorScheme){
    List<BottomNavigationBarItem> items = [];
    for(var i = 0; i < tabItems.length;i++){
      items.add(
          BottomNavigationBarItem(
              activeIcon: NavigationBarItem(builder:(context){
                return SvgPicture.asset(
                  tabIcons[i],
                  width: 24.r,
                  height: 24.r,
                  colorFilter: ColorFilter.mode(colorScheme.primary, BlendMode.srcIn),
                );
              }),
              icon: SvgPicture.asset(
                tabIcons[i],
                width: 24.r,
                height: 24.r,
                colorFilter: ColorFilter.mode(colorScheme.onSurfaceVariant, BlendMode.srcIn),
              ),
              label: tabLabels[i]
          )
      );
    }
    return items;
  }
}