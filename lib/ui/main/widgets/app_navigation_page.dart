import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sensor_hub/ui/core/responsive/app_breakpoints.dart';
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
  void _onTap(int index){
    if(_currentIndex == index){
      return;
    }
    setState(() {
      _currentIndex =index;
    });
  }
  Widget _tabIcon(int i, Color color){
    return SvgPicture.asset(
      tabIcons[i],
      width: 24.r,
      height: 24.r,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
  @override
  Widget build(BuildContext context) {
    final appText = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    tabLabels
      ..clear()
      ..add(appText.tab_device)
      ..add(appText.tab_notifications)
      ..add(appText.tab_profile);
    final bool useRail = !context.isCompactLayout;

    return Scaffold(
      appBar: null,
      // primary: false, //顶部延申
      backgroundColor: colorScheme.surface,
      body: useRail
        ? Row(
        children: [
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTap,
            labelType: NavigationRailLabelType.all,
            backgroundColor: colorScheme.surfaceContainerHigh,
            destinations: [
              for(var i = 0;i < tabItems.length; i++)
                NavigationRailDestination(
                  icon: _tabIcon(i, colorScheme.onSurfaceVariant),
                  selectedIcon: _tabIcon(i, colorScheme.primary),
                  label: Text(tabLabels[i]),
                ),
            ],
          ),
          const VerticalDivider(width: 1,thickness: 1,),
          Expanded(child: _tabBody()),
        ],
      )
          : _tabBody(),
      bottomNavigationBar: useRail ? null : _bottomBar(colorScheme),
    );
  }
  Widget _tabBody() {
    return IndexedStack(index: _currentIndex, children: tabItems);
  }

  Widget _bottomBar(ColorScheme colorScheme) {
    return BottomNavigationBar(
      backgroundColor: colorScheme.surfaceContainerHigh,
      iconSize: 24.r,
      selectedFontSize: 14.sp,
      unselectedFontSize: 12.sp,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      items: _barItemList(colorScheme),
      onTap: _onTap,
    );
  }
  List<BottomNavigationBarItem> _barItemList(ColorScheme colorScheme){
    return [
      for (var i = 0; i < tabItems.length; i++)
        BottomNavigationBarItem(
          activeIcon: NavigationBarItem(
            builder: (context) => _tabIcon(i, colorScheme.primary),
          ),
          icon: _tabIcon(i, colorScheme.onSurfaceVariant),
          label: tabLabels[i],
        ),
    ];
  }
}