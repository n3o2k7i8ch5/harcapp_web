import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core/konspekts/base_konspekt_widget.dart';
import 'package:harcapp_core/konspekts/data.dart';
import 'package:harcapp_core/konspekts/konspekt.dart';
import 'package:harcapp_web/konspekts/table_of_content_widget.dart';
import 'package:harcapp_web/main.dart';
import 'package:harcapp_web/songs/song_preview_widget.dart';
import 'package:harcapp_web/songs/workspace/workspace_title_widget.dart';

class KonspektsPage extends StatefulWidget{

  static const double defPaddingVal = 32.0;

  const KonspektsPage();

  @override
  State<StatefulWidget> createState() => KonspektsPageState();

}

class KonspektsPageState extends State<KonspektsPage>{

  Konspekt? selectedKonspekt;

  @override
  void initState() {
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints){

        bool workspaceAlwaysVisible = constraints.maxWidth>920;

        return Scaffold(
          backgroundColor: background_(context),
          drawer: workspaceAlwaysVisible?
          null:
          Drawer(
            backgroundColor: background_(context),
            child: TableOfContentWidget(
              selectedKonspekt: selectedKonspekt,
              onItemTap: (index){
                setState(() => selectedKonspekt = allKonspekts[index]);
                Navigator.pop(context);
              },
            ),
            width: 450,
          ),
          body: Row(
            children: [

              if(workspaceAlwaysVisible)
                SizedBox(
                  width: 450,
                  child: TableOfContentWidget(
                    selectedKonspekt: selectedKonspekt,
                    padding: EdgeInsets.all(KonspektsPage.defPaddingVal),
                    onItemTap: (index) => setState(() => selectedKonspekt = allKonspekts[index]),
                  ),
                ),

              Expanded(
                  child: Padding(
                    padding: !workspaceAlwaysVisible?
                    EdgeInsets.only(top: WorkspaceTitleWidget.height + Dimen.defMarg):
                    EdgeInsets.zero,
                    child:
                    selectedKonspekt == null?
                    Center(child: Text('Wybierz konspekt, który chcesz przejrzeć')):
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
                          child: Image.asset(selectedKonspekt!.coverPath),
                        ),
                      )
                    ),
                  ),
              ),

              if(constraints.maxWidth>1280)
                SizedBox(
                  width: 400,
                  child: Padding(
                      padding: EdgeInsets.only(
                          bottom: KonspektsPage.defPaddingVal,
                          right: KonspektsPage.defPaddingVal
                      ),
                      child:
                      SongPreviewWidget()
                  ),
                )
            ],
          ),
        );
      }
  );

}