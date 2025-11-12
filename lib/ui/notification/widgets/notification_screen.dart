import 'package:flutter/cupertino.dart';

class NotificationScreen extends StatefulWidget{
  const NotificationScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _NotificationScreenState();
  }

}

class _NotificationScreenState extends State<NotificationScreen>{
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: SizedBox(child: Text("页面一"),)
    );
  }

}