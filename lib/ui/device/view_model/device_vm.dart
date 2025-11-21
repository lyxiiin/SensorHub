import 'package:flutter/widgets.dart';
import 'package:sensor_hub/domain/models/user_device_groups.dart';

class DeviceVM extends ChangeNotifier{
  String selectedDevice = "全部设备";
  List<UserDeviceGroups> userDeviceGroups = [
    UserDeviceGroups(deviceId: "001", deviceName: "分组1"),
    UserDeviceGroups(deviceId: "002", deviceName: "分组2"),
    UserDeviceGroups(deviceId: "003", deviceName: "分组3"),
    UserDeviceGroups(deviceId: "004", deviceName: "分组4"),
  ];
  List<String> devices = ["全部设备","1","1","1","1","1","1","1","1","1","1","1",];
  List<String> currentDevice = [];
  int deviceCount = 0;
}