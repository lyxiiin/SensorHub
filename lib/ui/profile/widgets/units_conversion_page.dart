import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/ui/core/ui/setting_item.dart';
import 'package:sensor_hub/ui/main/app_vm.dart';

import '../../../l10n/app_localizations.dart';
import '../../../route/route_utils.dart';
import '../../core/ui/custom_app_bar.dart';

class UnitsConversionPage extends StatefulWidget{
  const UnitsConversionPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _UnitsConversionPageState();
  }

}

class _UnitsConversionPageState extends State<UnitsConversionPage>{
  @override
  Widget build(BuildContext context) {
    final appText = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      extendBody: true,
      backgroundColor: colorScheme.surface,
      appBar: createAppBar(
        title: '读数单位',
        colorScheme: colorScheme,
        appText: appText,
        onBack: () {
          RouteUtils.pop(context);
        },
        onFinish: () {

        },
      ),
      body: SafeArea(
        child:SingleChildScrollView(
          child: Column(

          ),
        ),
      ),
    );
  }
  //
  // Widget unitsConversionItem({required List<String> unitsList,}){
  //   final ColorScheme colorScheme = Theme.of(context).colorScheme;
  //   return Consumer<AppVM>(builder: (context,vm,child){
  //     return ListView.builder(
  //       itemCount: unitsList.length,
  //       itemBuilder: (context,index){
  //         return ListTile(
  //           title: Text(unitsList[index]),
  //           trailing: ,
  //         );
  //       },
  //     );
  //   });
  // }


}