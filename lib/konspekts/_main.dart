import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core/konspekts/base_konspekt_widget.dart';
import 'package:harcapp_core/konspekts/data.dart';
import 'package:harcapp_core/konspekts/konspekt.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:harcapp_web/konspekts/table_of_content_widget.dart';
import 'package:harcapp_web/main.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class KonspektsPage extends StatefulWidget{

  static const double defPaddingVal = 32.0;

  const KonspektsPage();

  @override
  State<StatefulWidget> createState() => KonspektsPageState();

}

class KonspektsPageState extends State<KonspektsPage>{

  Konspekt? selectedKonspekt;
  
  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints){

        bool workspaceAlwaysVisible = constraints.maxWidth>920;

        return BaseScaffold(
          backgroundColor: background_(context),
          drawer: workspaceAlwaysVisible?
          null:
          Drawer(
            backgroundColor: background_(context),
            child: TableOfContentWidget(
              selectedKonspekt: selectedKonspekt,
              padding: const EdgeInsets.all(Dimen.defMarg),
              onItemTap: (index){
                setState(() => selectedKonspekt = allKonspekts[index]);
                Navigator.pop(context);
              },
            ),
            width: drawerWidth,
          ),
          body: Row(
            children: [

              if(workspaceAlwaysVisible)
                SizedBox(
                  width: drawerWidth,
                  child: TableOfContentWidget(
                    selectedKonspekt: selectedKonspekt,
                    padding: EdgeInsets.all(Dimen.defMarg),
                    onItemTap: (index) => setState(() => selectedKonspekt = allKonspekts[index]),
                  ),
                ),

              Expanded(
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 1000),
                      child:
                      selectedKonspekt == null?
                      ClickHereWidget(workspaceAlwaysVisible):
                      BaseKonspektWidget(
                        selectedKonspekt!,
                        withAppBar: false,
                        onDuchLevelInfoTap: () => null,
                        onDuchMechanismInfoTap: () => null,
                        maxRelatedDialogWidth: dialogWidth,
                        leading: Padding(
                            padding: EdgeInsets.only(top: KonspektsPage.defPaddingVal),
                            child: Material(
                              borderRadius: BorderRadius.circular(AppCard.bigRadius),
                              clipBehavior: Clip.hardEdge,
                              child: Image.asset(
                                selectedKonspekt!.coverPath,
                                fit: BoxFit.cover,
                                height: 500,
                              ),
                            ),
                          )
                      ),
                    ),
                  ),
              ),
            ],
          ),
        );
      }
  );

}

class ClickHereWidget extends StatelessWidget{

  final bool workspaceAlwaysVisible;

  const ClickHereWidget(this.workspaceAlwaysVisible);

  @override
  Widget build(BuildContext context) => Center(
    child: Material(
      color: cardEnab_(context),
      borderRadius: BorderRadius.circular(AppCard.bigRadius),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.all(Dimen.defMarg),
        child: SimpleButton(
          color: background_(context),
          borderRadius: BorderRadius.circular(AppCard.bigRadius - 4),
          clipBehavior: Clip.hardEdge,
          onTap: workspaceAlwaysVisible?
          null:
              () => Scaffold.of(context).openDrawer(),
          child: Padding(
            padding: EdgeInsets.all(40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  'Chcesz przeglądać inspiracje\nna pracę harcerską?',
                  style: AppTextStyle(
                      fontSize: 20.0,
                      color: textDisab_(context),
                      fontWeight: weight.halfBold
                  ),
                ),

                SizedBox(height: 20.0),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        workspaceAlwaysVisible?MdiIcons.arrowLeft:MdiIcons.gestureTap,
                        color: textDisab_(context),
                        size: 24.0
                    ),
                    SizedBox(width: Dimen.iconMarg),
                    Text(
                      workspaceAlwaysVisible?'Zerknij tam!':'Kliknij',
                      style: AppTextStyle(
                          fontSize: 20.0,
                          color: textDisab_(context),
                          fontWeight: weight.halfBold
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    ),
  );

}