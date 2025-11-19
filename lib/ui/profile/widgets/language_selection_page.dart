import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../route/route_utils.dart';
import '../../core/ui/custom_app_bar.dart';
import '../../main/app_vm.dart';

class LanguageSelectionPage extends StatefulWidget{
  const LanguageSelectionPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _LanguageSelectionPageState();
  }

}

class _LanguageSelectionPageState extends State<LanguageSelectionPage>{
  @override
  Widget build(BuildContext context) {
    final appText = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: createAppBar(
          title: appText.language,
          appText: appText,
          onBack: () {
            RouteUtils.pop(context);
          },
          colorScheme: colorScheme,
          onFinish: () {
            final appVM = Provider.of<AppVM>(context, listen: false);
            appVM.changedLanguage();
            RouteUtils.pop(context);
          }
      ),
      body: Consumer<AppVM>(builder: (context,vm,child){
        return ListView.builder(
          itemCount: vm.languageList.length,
          itemBuilder: (context,index){
            return ListTile(
              title: vm.languageList[index][1] == "auto" ? Text(appText.profile_screen_follow_system) : Text(vm.languageList[index][0]),
              trailing: vm.languageName == vm.languageList[index][0] ? Icon(Icons.check,color: colorScheme.primary,) : null,
              shape: index+1 != vm.languageList.length ? Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1.0)) : null,
              tileColor: colorScheme.surface,
              onTap: (){
                vm.changedTempLanguage(index);
              },
            );
          },
        );
      }),
    );
  }

}