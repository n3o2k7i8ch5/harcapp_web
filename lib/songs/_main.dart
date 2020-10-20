

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core_own_song/common.dart';
import 'package:harcapp_core_own_song/providers.dart';
import 'package:harcapp_core_own_song/song_raw.dart';
import 'package:harcapp_core_song/song_element.dart';
import 'package:harcapp_web/articles/article_editor/common.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/save_send_widget.dart';
import 'package:harcapp_web/songs/song_editor_panel.dart';
import 'package:harcapp_web/songs/song_part_editor.dart';
import 'package:harcapp_web/songs/song_preview.dart';
import 'package:harcapp_web/songs/workspace/workspace.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import 'code_editor_widget.dart';
import 'core_tags/tag_layout.dart';

class SongsPage extends StatefulWidget{

  const SongsPage();

  @override
  State<StatefulWidget> createState() => SongsPageState();

}

class SongsPageState extends State<SongsPage>{

  HidTitlesProvider hidTitleProv;
  ScrollController scrollController;

  bool showEditor;
  SongPart part;
  Function() onSongPartChanged;

  @override
  void initState(){
    showEditor = false;
    scrollController = ScrollController();
    super.initState();
  }

  CurrentItemProvider currItemProv;
  BindTitleFileNameProvider bindTitleFileNameProv;
  SongFileNameDupErrProvider songFileNameDupErrProv;
  SongPreviewProvider songPrevProv;

  @override
  Widget build(BuildContext context) {

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AllSongsProvider()),

        ChangeNotifierProvider(create: (context) => LoadingProvider()),
        ChangeNotifierProvider(create: (context){
          currItemProv = CurrentItemProvider();
          return currItemProv;
        }),

        ChangeNotifierProvider(create: (context) => TitleCtrlProvider(
          onChanged: (text){
            AllSongsProvider allSongsProv = Provider.of<AllSongsProvider>(context, listen: false);

            SongRaw song = currItemProv.song;

            bool isConf = allSongsProv.isConf(song);

            if(bindTitleFileNameProv.bind)
              song.fileName = (isConf?'oc!_':'o!_') + remPolChars(text).replaceAll(' ', '_');

             songFileNameDupErrProv.chedkDupsFor(context, song);

            allSongsProv.notifyListeners();

          }
        )),
        ChangeNotifierProvider(create: (context) => AuthorCtrlProvider()),
        ChangeNotifierProvider(create: (context) => PerformerCtrlProvider()),
        ChangeNotifierProvider(create: (context) => YTCtrlProvider()),
        ChangeNotifierProvider(create: (context) => AddPersCtrlProvider()),

        ChangeNotifierProvider(create: (context) {
          hidTitleProv = HidTitlesProvider(hidTitles: []);
          return hidTitleProv;
        }),
        ChangeNotifierProvider(create: (context) => RefrenEnabProvider(true)),
        ChangeNotifierProvider(create: (context) => RefrenPartProvider(SongPart.empty(isRefren: true))),
        ChangeNotifierProvider(create: (context) => TagsProvider(Tag.ALL_TAG_NAMES, [])),

        ChangeNotifierProvider(create: (context){
          bindTitleFileNameProv = BindTitleFileNameProvider();
          return bindTitleFileNameProv;
        }),

        ChangeNotifierProvider(create: (context) => WorkspaceBlockProvider()),
        ChangeNotifierProvider(create: (context){
          songFileNameDupErrProv = SongFileNameDupErrProvider();
          return songFileNameDupErrProv;
        }),

        ChangeNotifierProvider(create: (context) => ShowCodeEditorProvider()),

        ChangeNotifierProvider(create: (context){
          songPrevProv = SongPreviewProvider();
          return songPrevProv;
        }),

        ChangeNotifierProvider(create: (context) => SongEditorPanelProvider()),
      ],
      builder: (context, child) => Scaffold(
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

                        Row(
                          children: [

                            Consumer<AllSongsProvider>(
                              builder: (context, prov, child) => HeaderWidget(
                                'Lista piosenek' + (prov.songs!=null?' (${prov.length})':''),
                                MdiIcons.toolboxOutline,
                              ),
                            ),

                            Consumer<SongFileNameDupErrProvider>(
                              builder: (context, prov, child) => AnimatedOpacity(
                                opacity: prov.count==0?0:1,
                                duration: Duration(milliseconds: 300),
                                child: Row(
                                  children: [

                                    Text(
                                      '${prov.count} ',
                                      style: AppTextStyle(
                                          fontWeight: weight.halfBold,
                                          fontSize: Dimen.TEXT_SIZE_BIG,
                                          shadow: true,
                                          color: Colors.red
                                      ),
                                    ),

                                    Icon(MdiIcons.alertOutline, color: Colors.red, size: Dimen.TEXT_SIZE_BIG),

                                  ],
                                ),
                              )
                            ),

                          ],
                        ),

                        Consumer2<AllSongsProvider, WorkspaceBlockProvider>(
                            builder: (context, allSongProv, songFileNameBlockProv, child) =>
                            allSongProv.length==0?Container():AppCard(
                                color: songFileNameBlockProv.blocked?Colors.black.withOpacity(0.1):null,
                                padding: EdgeInsets.zero,
                                elevation: AppCard.bigElevation,
                                child: IgnorePointer(
                                  ignoring: songFileNameBlockProv.blocked,
                                  child: SaveSendWidget(),
                                )
                            )
                        ),

                        Expanded(
                            child: Consumer<WorkspaceBlockProvider>(
                              builder: (context, prov, child) => AppCard(
                                color: prov.blocked?Colors.black.withOpacity(0.1):null,
                                elevation: AppCard.bigElevation,
                                padding: EdgeInsets.zero,
                                child: WorkspacePart(),
                              ),
                            )
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

            AnimatedOpacity(
                opacity: showEditor?1:0,
                duration: Duration(milliseconds: 500),
                child: IgnorePointer(
                  ignoring: !showEditor,
                  child: SongEditorDialog(this),
                )
            ),


            CodeEditorWidget(this),

            Consumer<LoadingProvider>(
              child: AppCard(
                elevation: AppCard.bigElevation,
                padding: EdgeInsets.all(Dimen.MARG_ICON),
                child: Text('Ładowanie...', style: AppTextStyle(fontSize: Dimen.TEXT_SIZE_APPBAR)),
              ),
              builder: (context, prov, child) => AnimatedOpacity(
                opacity: prov.loading?1:0,
                duration: Duration(milliseconds: 0),
                child: AbsorbPointer(
                  absorbing: prov.loading,
                  child: Center(child: child),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Function getSongPartChangedFunction(SongPartProvider prov){

    return (){
      //songPrevProv.resizeText();
      currItemProv.notifyListeners();
      prov.notify();
    };

  }

}


class SongEditorDialog extends StatelessWidget{

  final SongsPageState parent;

  const SongEditorDialog(this.parent);

  @override
  Widget build(BuildContext context) {

    if(parent.part == null)
      return Container();

    return GestureDetector(
          onTap: (){
            parent.setState(() => parent.showEditor = false);
            parent.onSongPartChanged();
          },
          child: Container(
            width: double.infinity,
            color: Colors.black54,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Container(
                    width: 500,
                    child: SongPartEditor(
                        parent.part,
                        onCheckPressed: () => parent.setState(() => parent.showEditor = false)
                        //onSongPartChanged: parent.onSongPartChanged
                    )
                ),
              )
            ),
          )
      );
  }

}
