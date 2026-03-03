import 'package:flutter/cupertino.dart';
import 'package:sensor_hub/data/models/notification_message.dart';

class NotificationVM with ChangeNotifier{
  List<NotificationMessage> notificationMessages = [NotificationMessage(severity: 1, configId: 1,sensorName: "sensorName", sensorType: 1, value: 500, datetime: 1766476845)];
  
  void initData() {
    notificationMessages.add(
      NotificationMessage(severity: 1, sensorName: "sensorName", sensorType: 1, value: 500, datetime: 1766476845, configId: 1)
    );
    notifyListeners();
  }


}