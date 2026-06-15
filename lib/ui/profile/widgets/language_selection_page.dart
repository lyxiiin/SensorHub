import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/data/services/settings_service.dart';

import '../../../l10n/app_localizations.dart';
import '../../../route/route_utils.dart';
import '../../core/ui/custom_app_bar.dart';
import '../view_model/profile_vm.dart';

class LanguageSelectionPage extends StatefulWidget{
  const LanguageSelectionPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _LanguageSelectionPageState();
  }

}

class _LanguageSelectionPageState extends State<LanguageSelectionPage>{
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileVM = Provider.of<ProfileVM>(context, listen: false);
      profileVM.resetLanguage();
    });
  }
  @override
  Widget build(BuildContext context) {
    final appText = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBody: true,
      backgroundColor: colorScheme.surface,
      appBar: createAppBar(
          title: appText.language,
          appText: appText,
          onBack: () {
            RouteUtils.pop(context);
          },
          colorScheme: colorScheme,
          onFinish: () {
            final profileVM = Provider.of<ProfileVM>(context, listen: false);
            final settings = Provider.of<SettingsService>(context,listen:false);
            profileVM.saveLanguage(settings);
            RouteUtils.pop(context);
          }
      ),
      body: SafeArea(
        child: Consumer2<ProfileVM, SettingsService>(builder: (context, profileVM, settings, child){
          // 初始化临时值
          if (profileVM.tempLanguageName.isEmpty) {
            profileVM.initFromSettings(settings);
          }
          
          return ListView.builder(
            itemCount: profileVM.languageList.length,
            itemBuilder: (context,index){
              return ListTile(
                title: profileVM.languageList[index][1] == "auto" ?
                Text(appText.profile_screen_follow_system,style: TextStyle(fontSize: 18.sp),) :
                Text(profileVM.languageList[index][0],style: TextStyle(fontSize: 18.sp),),
                trailing: (profileVM.tempLanguageName.isNotEmpty ? profileVM.tempLanguageName : settings.languageName) == profileVM.languageList[index][0] ?
                Icon(Icons.check,color: colorScheme.primary,) :
                null,
                shape: index+1 != profileVM.languageList.length ? Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1.0)) : null,
                tileColor: colorScheme.surface,
                onTap: (){
                  profileVM.changedTempLanguage(index);
                },
              );
            },
          );
        }),
      ),
    );
  }
}