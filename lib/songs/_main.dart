import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/comm_widgets/title_show_row_widget.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core_own_song/providers.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/save_send_widget.dart';
import 'package:harcapp_web/songs/song_editor_panel.dart';
import 'package:harcapp_web/songs/song_preview.dart';
import 'package:harcapp_web/songs/workspace/workspace.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class SongsPage extends StatefulWidget{

  const SongsPage();

  @override
  State<StatefulWidget> createState() => SongsPageState();

}

class SongsPageState extends State<SongsPage>{

  late ScrollController scrollController;

  late Function() onSongPartChanged;

  @override
  void initState(){

    scrollController = ScrollController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(
        children: [

          Row(
            children: [
              Padding(
                  padding: EdgeInsets.only(left: 32, right: 32, bottom: 32),
                  child: Container(
                    width: 400,
                    child: Column(
                      children: [

                        Padding(
                          padding: EdgeInsets.only(left: Dimen.ICON_MARG, top: Dimen.ICON_MARG),
                          child: Consumer<AllSongsProvider>(
                              builder: (context, prov, child) =>
                                  TitleShortcutRowWidget(
                                    title: 'Lista piosenek (${prov.length})',
                                    textAlign: TextAlign.start,
                                    trailing: Consumer<SongFileNameDupErrProvider>(
                                        builder: (context, prov, child) => AnimatedOpacity(
                                          opacity: prov.count==0?0:1,
                                          duration: Duration(milliseconds: 300),
                                          child: SimpleButton.from(
                                            textColor: Colors.red,
                                            icon: MdiIcons.alertCircleOutline,
                                            text: '${prov.count}',
                                            onTap: () => AppScaffold.showMessage(
                                                context,
                                                'Liczba piosenek o takiej samej nazwie: ${prov.count}'
                                            )
                                          ),
                                        )
                                    ),
                                  )
                          ),
                        ),

                        Consumer<AllSongsProvider>(
                            builder: (context, allSongProv, child) =>
                            allSongProv.length==0?
                            Container():
                            Padding(
                              padding: EdgeInsets.only(bottom: Dimen.defMarg),
                              child: SaveSendWidget(),
                            )
                        ),

                        Expanded(
                            child: Material(
                              borderRadius: BorderRadius.circular(AppCard.bigRadius),
                              child: WorkspacePart(),
                            ),
                        ),

                      ],
                    ),
                  )
              ),

              Expanded(
                  child: Padding(
                      padding: EdgeInsets.only(right: 32, bottom: 32),
                      child: SongEditorPanel(this)
                  )
              ),

              SongPreview()

            ],
          ),
/*
          AnimatedOpacity(
              opacity: showEditor?1:0,
              duration: Duration(milliseconds: 500),
              child: IgnorePointer(
                ignoring: !showEditor,
                child: SongEditorDialog(this),
              )
          ),
*/

          Consumer<LoadingProvider>(
            child: AppCard(
              elevation: AppCard.bigElevation,
              padding: EdgeInsets.all(Dimen.ICON_MARG),
              child: Text('Ładowanie...', style: AppTextStyle(fontSize: Dimen.TEXT_SIZE_APPBAR)),
            ),
            builder: (context, prov, child) => AnimatedOpacity(
              opacity: prov.loading!?1:0,
              duration: Duration(milliseconds: 0),
              child: AbsorbPointer(
                absorbing: prov.loading!,
                child: Center(child: child),
              ),
            ),
          ),

        ],
      ),
    );

  }

  Function getSongPartChangedFunction(SongPartProvider prov){

    return (){
      Provider.of<CurrentItemProvider>(context, listen: false).notifyListeners();
      prov.notify();
    };

  }

}