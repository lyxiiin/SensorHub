import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class ProfileVM extends ChangeNotifier{
  int themeModelSelectedValue = 0;

  void changedThemeModelSelectedValue(int value){
    themeModelSelectedValue = value;
  }
}