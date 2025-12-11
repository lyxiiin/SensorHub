import 'package:flutter/cupertino.dart';

import '../../../data/services/mqtt_service.dart';

class NotificationScreen extends StatefulWidget{
  const NotificationScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _NotificationScreenState();
  }

}

class _NotificationScreenState extends State<NotificationScreen>{
  late MqttService subscriber;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // subscriber = MqttService();
    // subscriber.connect();
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: SizedBox(child: Text("页面一"),)
    );
  }

}