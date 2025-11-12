import 'package:flutter/widgets.dart';

class DeviceVM extends ChangeNotifier{
  String selectedDevice = "全部设备";
  List<String> devices = ["全部设备"];
  int deviceCount = 0;
}