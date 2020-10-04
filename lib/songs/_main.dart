

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_web/common/app_card.dart';
import 'package:harcapp_web/common/app_text_style.dart';
import 'package:harcapp_web/common/dimen.dart';
import 'package:harcapp_web/songs/core_song_management/song_element.dart';
import 'package:harcapp_web/songs/page_widgets/add_buttons_widget.dart';
import 'package:harcapp_web/songs/page_widgets/refren_template.dart';
import 'package:harcapp_web/songs/page_widgets/scroll_to_bottom.dart';
import 'package:harcapp_web/songs/page_widgets/song_parts_list_widget.dart';
import 'package:harcapp_web/songs/page_widgets/tags_widget.dart';
import 'package:harcapp_web/songs/page_widgets/top_cards.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/song_part_editor.dart';
import 'package:harcapp_web/songs/song_widget/providers.dart';
import 'package:harcapp_web/songs/song_widget/song_widget_template.dart';
import 'package:harcapp_web/songs/workspace.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import 'core_own_song/common.dart';
import 'core_own_song/providers.dart';
import 'core_song_management/song_raw.dart';
import 'core_tags/tag_layout.dart';

class SongsPage extends StatefulWidget{

  final SongRaw song;

  const SongsPage({this.song});

  @override
  State<StatefulWidget> createState() => SongsPageState();

}

class SongsPageState extends State<SongsPage>{

  SongRaw get song => widget.song;

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

  @override
  Widget build(BuildContext context) {

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LoadingProvider()),
        ChangeNotifierProvider(create: (context) => CurrentItemProvider()),

        ChangeNotifierProvider(create: (context) => TitleCtrlProvider()),
        ChangeNotifierProvider(create: (context) => AuthorCtrlProvider()),
        ChangeNotifierProvider(create: (context) => PerformerCtrlProvider()),
        ChangeNotifierProvider(create: (context) => YTCtrlProvider()),
        ChangeNotifierProvider(create: (context) => AddPersCtrlProvider()),

        ChangeNotifierProvider(create: (context) {
          hidTitleProv = HidTitlesProvider(hidTitles: song==null?[]:song.hidTitles);
          return hidTitleProv;
        }),
        ChangeNotifierProvider(create: (context) => RefrenEnabProvider(song==null?true:song.hasRefren)),
        ChangeNotifierProvider(create: (context) => RefrenPartProvider(SongPart.from(song==null?SongElement.empty():song.refrenPart))),
        //ChangeNotifierProvider(create: (context) => SongPartsProvider(song==null?[]:song.songElements.map((el) => SongPart.from(el)).toList())),
        ChangeNotifierProvider(create: (context) => TagsProvider(Tag.ALL_TAG_NAMES, song==null?[]:song.tags)),

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
                    child: AppCard(
                      elevation: AppCard.bigElevation,
                      padding: EdgeInsets.zero,
                      child: WorkspacePart(),
                    ),
                  )
                ),

                Expanded(
                    child: Container(
                        constraints: BoxConstraints(minHeight: double.infinity, minWidth: 400),
                        width: 400,
                        child: Padding(
                          padding: EdgeInsets.only(top: 32, bottom: 32, right: 32),
                          child: Column(
                            children: [

                              Expanded(
                                  child: ListView(
                                    controller: scrollController,
                                    children: [

                                      HeaderWidget('Informacje ogólne', MdiIcons.textBoxOutline),
                                      TopCards(
                                        onChangedTitle: (String text){
                                          CurrentItemProvider currItemProv = Provider.of<CurrentItemProvider>(context, listen: false);
                                          currItemProv.copyWidth(title: text);
                                        },
                                        onChangedAuthor: (String text){
                                          CurrentItemProvider currItemProv = Provider.of<CurrentItemProvider>(context, listen: false);
                                          currItemProv.copyWidth(author: text);
                                        },
                                        onChangedPerformer: (String text){
                                          CurrentItemProvider currItemProv = Provider.of<CurrentItemProvider>(context, listen: false);
                                          currItemProv.copyWidth(performer: text);
                                        },
                                        onChangedYT: (String text){
                                          CurrentItemProvider currItemProv = Provider.of<CurrentItemProvider>(context, listen: false);
                                          currItemProv.copyWidth(youtubeLink: text);
                                        },
                                        onChangedAddPers:  (String text){
                                          CurrentItemProvider currItemProv = Provider.of<CurrentItemProvider>(context, listen: false);
                                          currItemProv.copyWidth(addPers: text);
                                        },
                                      ),
                                      TagsWidget(
                                        linear: false,
                                        onChanged: (List<String> tags){
                                          CurrentItemProvider prov = Provider.of<CurrentItemProvider>(context, listen: false);
                                          prov.copyWidth(tags: tags);
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
                                            CurrentItemProvider prov = Provider.of<CurrentItemProvider>(context, listen: false);
                                            prov.copyWidth(hasRefren: value);
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
                                            CurrentItemProvider currItemProv = Provider.of<CurrentItemProvider>(context, listen: false);
                                            currItemProv.notifyListeners();
                                          },
                                      ),

                                    ],
                                  )
                              ),

                              AddButtonsWidget(onPressed: () => scrollToBottom(scrollController)),

                            ],
                          ),
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
      CurrentItemProvider currSongProv = Provider.of<CurrentItemProvider>(context, listen: false);
      currSongProv.notifyListeners();
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
          onTap: () => parent.setState(() => parent.showEditor = false),
          child: Container(
            width: double.infinity,
            color: Colors.black54,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Container(
                    width: 500,
                    child: SongPartEditor(parent.part, onSongPartChanged: parent.onSongPartChanged)
                ),
              )
            ),
          )
      );
  }

}

class SongPreview extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constrains){
          return AnimatedContainer(
            duration: Duration(milliseconds: 0),
            width: MediaQuery.of(context).size.width<1200 + 4*32?0:400,
            child: Padding(
                padding: EdgeInsets.only(top: 32, bottom: 32, right: 32),
                child: Column(
                  children: [

                    HeaderWidget('Podgląd piosenki', MdiIcons.bookmarkMusicOutline, enabled: false),

                    Expanded(
                      child: MultiProvider(
                        providers: [
                          ChangeNotifierProvider(create: (context) => ShowChordsProvider()),
                          ChangeNotifierProvider(create: (context) => ChordsDrawTypeProvider()),
                          ChangeNotifierProvider(create: (context) => ChordsDrawShowProvider()),
                          ChangeNotifierProvider(create: (context) => ChordsDrawPinnedProvider()),
                        ],
                        builder: (context, child) => Container(
                          width: 400,
                          child: Consumer<CurrentItemProvider>(
                            builder: (context, currItemProv, child){
                              return SongWidgetTemplate<SongRaw>(currItemProv.song);
                            }
                          )
                        ),
                      ),
                    )
                  ],
                )
            ),
          );
        }
    );
  }
}
