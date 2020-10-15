

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:harcapp_web/articles/article_editor/common.dart';
import 'package:harcapp_web/common/app_card.dart';
import 'package:harcapp_web/common/app_text_style.dart';
import 'package:harcapp_web/common/color_pack.dart';
import 'package:harcapp_web/common/dimen.dart';
import 'package:harcapp_web/common/simple_button.dart';
import 'package:harcapp_web/songs/core_song_management/song_element.dart';
import 'package:harcapp_web/songs/page_widgets/add_buttons_widget.dart';
import 'package:harcapp_web/songs/page_widgets/refren_template.dart';
import 'package:harcapp_web/songs/page_widgets/scroll_to_bottom.dart';
import 'package:harcapp_web/songs/page_widgets/song_parts_list_widget.dart';
import 'package:harcapp_web/songs/page_widgets/tags_widget.dart';
import 'package:harcapp_web/songs/page_widgets/top_cards.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/save_send_widget.dart';
import 'package:harcapp_web/songs/song_part_editor.dart';
import 'package:harcapp_web/songs/song_preview.dart';
import 'package:harcapp_web/songs/song_widget/providers.dart';
import 'package:harcapp_web/songs/song_widget/song_widget_template.dart';
import 'package:harcapp_web/songs/workspace/workspace.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import 'code_editor_widget.dart';
import 'core_own_song/common.dart';
import 'core_own_song/providers.dart';
import 'core_song_management/song_raw.dart';
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
        ChangeNotifierProvider(create: (context) => RefrenPartProvider(SongPart.from(SongElement.empty(isRefren: true)))),
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

        ChangeNotifierProvider(create: (context) => SongPreviewProvider()),
      ],
      builder: (context, child) => Scaffold(
        body: Stack(
          children: [

            Row(
              children: [
                Padding(
                  padding: EdgeInsets.all(32),
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
                    child: Container(
                        constraints: BoxConstraints(minHeight: double.infinity, minWidth: 400),
                        child: Padding(
                          padding: EdgeInsets.only(top: 32, bottom: 32, right: 32),
                          child: Consumer<CurrentItemProvider>(
                            builder: (context, currItemProv, child){

                              if(currItemProv.song == null)
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Dodaj lub importuj piosenkę, by móc ją edytować.',
                                      style: AppTextStyle(
                                        fontSize: Dimen.TEXT_SIZE_BIG,
                                        color: textDisabled(context),
                                        fontWeight: weight.halfBold
                                      ),
                                    ),

                                    SizedBox(height: 24),

                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(MdiIcons.arrowLeft, color: textDisabled(context)),
                                        SizedBox(width: Dimen.MARG_ICON),
                                        Text(
                                          'Zerknij tam.',
                                          style: AppTextStyle(
                                            fontSize: Dimen.TEXT_SIZE_BIG,
                                            color: textDisabled(context),
                                            fontWeight: weight.halfBold
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                );

                              return Column(
                                children: [

                                  Expanded(
                                      child: ListView(
                                        controller: scrollController,
                                        children: [

                                          Row(
                                            children: [
                                              HeaderWidget('Info. ogólne', MdiIcons.textBoxOutline),

                                              Expanded(child: Container()),

                                              Consumer<BindTitleFileNameProvider>(
                                                builder: (context, prov, child) => SimpleButton(
                                                    padding: EdgeInsets.all(Dimen.MARG_ICON),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          'Powiąż nazwę pliku z tytułem',
                                                          style: AppTextStyle(
                                                              fontWeight: weight.halfBold,
                                                              color: prov.bind?iconEnabledColor(context):iconDisabledColor(context),
                                                              fontSize: Dimen.TEXT_SIZE_BIG
                                                          ),
                                                        ),
                                                        SizedBox(width: Dimen.MARG_ICON),
                                                        Icon(
                                                          MdiIcons.textRecognition,
                                                          color: prov.bind?iconEnabledColor(context):iconDisabledColor(context)
                                                        ),
                                                      ],
                                                    ),
                                                    onTap: (){
                                                      prov.bind = !prov.bind;
                                                    }
                                                ),
                                              )

                                            ],
                                          ),


                                          TopCards(
                                            onChangedTitle: (String text){
                                              currItemProv.title = text;
                                            },
                                            onChangedAuthor: (String text){
                                              currItemProv.author = text;
                                            },
                                            onChangedPerformer: (String text){
                                              currItemProv.performer = text;
                                            },
                                            onChangedYT: (String text){
                                              currItemProv.youtubeLink = text;
                                            },
                                            onChangedAddPers: (String text){
                                              currItemProv.addPers = text;
                                            },
                                          ),
                                          TagsWidget(
                                            linear: false,
                                            onChanged: (List<String> tags){
                                              currItemProv.tags = tags;
                                            },
                                          ),

                                          RefrenTemplate(
                                              onPartTap: (part, prov) {
                                                setState((){
                                                  this.part = part;
                                                  this.showEditor = true;
                                                });
                                                onSongPartChanged = getSongPartChangedFunction(prov);
                                              },
                                              onRefrenEnabledChaned: (bool value){
                                                currItemProv.hasRefren = value;
                                              }
                                          ),
                                          HeaderWidget('Struktura piosenki', MdiIcons.playlistMusic),
                                          SongPartsListWidget(
                                            shrinkWrap: true,
                                            onPartTap: (part, prov) async {
                                              if(part.isRefren(context)) return;
                                              setState((){
                                                this.part = part;
                                                this.showEditor = true;
                                              });

                                              onSongPartChanged = getSongPartChangedFunction(prov);
                                            },
                                            onChanged: (){
                                              currItemProv.notifyListeners();
                                            },
                                          ),

                                        ],
                                      )
                                  ),

                                  AddButtonsWidget(onPressed: () => scrollToBottom(scrollController)),

                                ],
                              );

                            },
                          )
                        )
                    )
                ),

                Consumer<CurrentItemProvider>(
                  builder: (context, prov, child) => SongPreview(),
                )

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


            CodeEditorWidget(),

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
                        //onSongPartChanged: parent.onSongPartChanged
                    )
                ),
              )
            ),
          )
      );
  }

}
