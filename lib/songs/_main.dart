import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/common.dart';
import 'package:harcapp_core/comm_widgets/dialog/alert_dialog.dart';
import 'package:harcapp_core/comm_widgets/dialog/app_dialog.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:harcapp_web/main.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/song_contribution_rules_acceptance_manager.dart';
import 'package:harcapp_web/songs/song_editor_panel.dart';
import 'package:harcapp_web/songs/song_preview_widget.dart';
import 'package:provider/provider.dart';

import '../consts.dart';
import 'left_panel/left_panel.dart';

class SongsPage extends StatefulWidget{

  final bool openDrawerIfCollapsed;

  const SongsPage({this.openDrawerIfCollapsed = true});

  @override
  State<StatefulWidget> createState() => SongsPageState();
  
}

class SongsPageState extends State<SongsPage>{

  static const double collapseWidth = 920;

  bool get openDrawerIfCollapsed => widget.openDrawerIfCollapsed;

  late GlobalKey<ScaffoldState> scaffoldKey;

  Future<void> tryOpenDrawerIfCollapsed() async {
    if(!openDrawerIfCollapsed || MediaQuery.of(context).size.width>collapseWidth)
      return;

    await Future.delayed(Duration.zero);

    scaffoldKey.currentState?.openDrawer();
  }

  Future<void> tryClearCachedSongs() async {
    if(MyApp.lastLoadedSongs.isEmpty) return;

    bool remove = false;

    await showAlertDialog(
       context: context,
        title: 'Ostrożnie...',
        content: 'Wygląda na to, że zostały po Tobie niezapisane piosenki.'
            '\n\nCzy chcesz je usunąć?',
        buttons: [
          AppDialogButton(
              text: 'Nie, zostaw',
              onTap: (){
                remove = false;
                Navigator.pop(context);
              }
          ),
          AppDialogButton(
              text: 'Tak, usuń',
              onTap: (){
                remove = true;
                Navigator.pop(context);
              }
          ),
        ],
      maxWidth: appDialogMaxWidth
    );

    if(remove){
      AllSongsProvider.of(context).clear();
      MyApp.lastLoadedSongs.clear();
      SongFileNameDupErrProvider.of(context).checkAllDups(context);
    }
  }

  void asyncInitState() async {
    await SongContributionRulesAcceptanceManager.ensureRulesAccepted(context);
    await tryClearCachedSongs();
    if(MyApp.lastLoadedSongs.isNotEmpty)
      SongFileNameDupErrProvider.of(context).checkAllDups(context);
  }

  @override
  void initState() {

    scaffoldKey = GlobalKey();
    post(tryOpenDrawerIfCollapsed);

    post(asyncInitState);
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints){

        bool drawerAlwaysVisible = constraints.maxWidth>920;

        return BaseScaffold(
          scaffoldKey: scaffoldKey,
          backgroundColor: background_(context),
          drawer: drawerAlwaysVisible?
          null:
          Drawer(
            backgroundColor: background_(context),
            child: LeftPanel(
              onItemTap: (index) => Navigator.pop(context),
              withBackButton: true,
            ),
            width: drawerWidth,
          ),
          body: Consumer<SongPreviewProvider>(
            builder: (context, songPreviewProv, child) => Row(
              children: [

                if(drawerAlwaysVisible)
                  SizedBox(
                      width: drawerWidth,
                      child: Padding(
                        padding: EdgeInsets.only(left: 32, right: 32, bottom: 32),
                        child: LeftPanel(),
                      )
                  ),

                Expanded(
                    child: Padding(
                        padding: drawerAlwaysVisible?
                        EdgeInsets.only(right: 32, bottom: 32):
                        EdgeInsets.zero,

                        child: SongEditorPanel(workspaceAlwaysVisible: drawerAlwaysVisible)
                    )
                ),

                if(constraints.maxWidth>1280 && songPreviewProv.showSong)
                  SizedBox(
                    width: songPreviewWidth,
                    child: Padding(
                        padding: EdgeInsets.only(bottom: 32, right: 32),
                        child:
                        SongPreviewWidget()
                    ),
                  )
              ],
            ),
          )
        );
      }
  );

}