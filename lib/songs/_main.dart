import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_web/common/alert_dialog.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:harcapp_web/main.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/song_editor_panel.dart';
import 'package:harcapp_web/songs/song_preview_widget.dart';

import 'left_panel/left_panel.dart';

class SongsPage extends StatefulWidget{

  const SongsPage();

  @override
  State<StatefulWidget> createState() => SongsPageState();
  
}

class SongsPageState extends State<SongsPage>{

  Future<void> tryClearCachedSongs() async {
    if(MyApp.lastLoadedSongs.isEmpty) return;

    bool remove = false;

    await showAlertDialog(
        context,
        title: 'Ostrożnie...',
        content: 'Wygląda na to, że zostały po Tobie niezapisane piosenki.'
            '\n\nCzy chcesz je usunąć?',
        actionBuilder: (context) => [
          AlertDialogButton(
              text: 'Nie, zostaw',
              onTap: (){
                remove = false;
                Navigator.pop(context);
              }
          ),
          AlertDialogButton(
              text: 'Tak, usuń',
              onTap: (){
                remove = true;
                Navigator.pop(context);
              }
          ),
        ]
    );

    if(remove){
      AllSongsProvider.of(context).clear();
      MyApp.lastLoadedSongs.clear();
      SongFileNameDupErrProvider.of(context).checkAllDups(context);
    }
  }

  @override
  void initState() {
    tryClearCachedSongs();
    if(MyApp.lastLoadedSongs.isNotEmpty)
      SongFileNameDupErrProvider.of(context).checkAllDups(context);
    super.initState();
  }
  
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
            child: LeftPanel(
              onItemTap: (index) => Navigator.pop(context),
            ),
            width: drawerWidth,
          ),
          body: Row(
            children: [

              if(workspaceAlwaysVisible)
                SizedBox(
                    width: drawerWidth,
                    child: Padding(
                      padding: EdgeInsets.only(left: 32, right: 32, bottom: 32),
                      child: LeftPanel(),
                    )
                ),

              Expanded(
                  child: Padding(
                      padding: workspaceAlwaysVisible?
                      EdgeInsets.only(right: 32, bottom: 32):
                      EdgeInsets.zero,

                      child: SongEditorPanel(workspaceAlwaysVisible: workspaceAlwaysVisible)
                  )
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
          )
        );
      }
  );

}