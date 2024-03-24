import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core/konspekts/base_konspekt_widget.dart';
import 'package:harcapp_core/konspekts/data.dart';
import 'package:harcapp_core/konspekts/konspekt.dart';
import 'package:harcapp_web/konspekts/table_of_content_widget.dart';
import 'package:harcapp_web/songs/song_editor_panel.dart';
import 'package:harcapp_web/songs/song_preview_widget.dart';
import 'package:harcapp_web/songs/workspace/workspace_title_widget.dart';

class KonspektsPage extends StatefulWidget{

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
                  child: Padding(
                    padding: EdgeInsets.only(left: 32, right: 32, bottom: 32),
                    child: TableOfContentWidget(
                      onItemTap: (index) => setState(() => selectedKonspekt = allKonspekts[index]),
                    ),
                  )
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
                    ),
                  ),
              ),

              if(constraints.maxWidth>1280)
                SizedBox(
                  width: 400,
                  child: Padding(
                      padding: EdgeInsets.only(bottom: 32, right: 32),
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