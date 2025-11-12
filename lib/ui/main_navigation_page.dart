
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sensor_hub/ui/device/widgets/device_screen.dart';
import 'package:sensor_hub/ui/navigation_bar_item.dart';
import 'package:sensor_hub/ui/notification/widgets/notification_screen.dart';
import 'package:sensor_hub/ui/profile/widgets/profile_screen.dart';

class MainNavigationPage extends StatefulWidget{
  const MainNavigationPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MainNavigationPageState();
  }

}

class _MainNavigationPageState extends State<MainNavigationPage >{
  int _currentIndex = 0;
  final List<Widget> tabItems = [];
  final List<String> tabLabels = ["设备","消息","我的"];
  final List<String> tabIcons = [
    "assets/icons/icon_device.svg",
    "assets/icons/icon_notifications.svg",
    "assets/icons/icon_profile.svg",
  ];
  // final List<String> tabActiveIcons = [
  //   "assets/icons/icon_device.png",
  //   "assets/icons/icon_notifications.png",
  //   "assets/icons/icon_profile.png",
  // ];
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
    return Scaffold(
      appBar: null,
      body: IndexedStack(index: _currentIndex,children: tabItems,),
      bottomNavigationBar: BottomNavigationBar(
        iconSize: 24.r,
        selectedFontSize: 14.sp,
        unselectedFontSize: 12.sp,
        selectedItemColor: Color(0xFF07C160),
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        items: _barItemList(),
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

  List<BottomNavigationBarItem> _barItemList(){
    List<BottomNavigationBarItem> items = [];
    for(var i = 0; i < tabItems.length;i++){
      items.add(
          BottomNavigationBarItem(
              activeIcon: NavigationBarItem(builder:(context){
                return SvgPicture.asset(
                  tabIcons[i],
                  width: 24.r,
                  height: 24.r,
                  colorFilter: ColorFilter.mode(Color(0xFF07C160), BlendMode.srcIn),
                );
              }),
              icon: SvgPicture.asset(
                tabIcons[i],
                width: 24.r,
                height: 24.r,
              ),
              label: tabLabels[i]
          )
      );
    }
    return items;
  }
}