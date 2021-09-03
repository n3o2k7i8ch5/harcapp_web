
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/comm_widgets/title_show_row_widget.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core_own_song/page_widgets/add_buttons_widget.dart';
import 'package:harcapp_core_own_song/page_widgets/refren_template.dart';
import 'package:harcapp_core_own_song/page_widgets/scroll_to_bottom.dart';
import 'package:harcapp_core_own_song/page_widgets/song_parts_list_widget.dart';
import 'package:harcapp_core_own_song/page_widgets/tags_widget.dart';
import 'package:harcapp_core_own_song/page_widgets/top_cards.dart';
import 'package:harcapp_core_own_song/providers.dart';
import 'package:harcapp_core_own_song/song_raw.dart';
import 'package:harcapp_core_song_widget/providers.dart';
import 'package:harcapp_core_song_widget/song_widget_template.dart';
import 'package:harcapp_web/articles/article_editor/common.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/song_loader.dart';
import 'package:harcapp_web/songs/song_part_editor.dart';
import 'package:harcapp_web/songs/song_preview.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '_main.dart';

class SongEditorPanel extends StatelessWidget{

  static const double SONG_PART_EDITOR_WIDTH = 500;
  static const double SEPARATOR_HEIGHT = 42;

  final SongsPageState parent;

  const SongEditorPanel(this.parent);

  @override
  Widget build(BuildContext context) {

    return Consumer2<SongEditorPanelProvider, ShowSongProvider>(
      builder: (context, prov, showSongProv, child){

        CurrentItemProvider currItemProv = Provider.of<CurrentItemProvider>(context, listen: false);

        if(!showSongProv.showSong)
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 54.0),

              Text(
                'Dodaj lub importuj piosenkę.',
                style: AppTextStyle(
                    fontSize: 32.0,
                    color: textDisab_(context),
                    fontWeight: weight.halfBold
                ),
              ),

              SizedBox(height: 32.0),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(MdiIcons.arrowLeft, color: textDisab_(context), size: 32.0),
                  SizedBox(width: Dimen.ICON_MARG),
                  Text(
                    'Zerknij tam!',
                    style: AppTextStyle(
                        fontSize: 32.0,
                        color: textDisab_(context),
                        fontWeight: weight.halfBold
                    ),
                  ),
                  SizedBox(width: Dimen.ICON_MARG),
                  Icon(MdiIcons.musicNote, color: textDisab_(context), size: 32.0),
                ],
              )
            ],
          );
        else
          return Column(
            children: [

              Expanded(
                child: SongPartsListWidget(
                    controller: parent.scrollController,
                    shrinkWrap: true,
                    onPartTap: (index) => showDialog(context: context, builder: (_) => Center(
                      child: Container(
                        width: SONG_PART_EDITOR_WIDTH,
                        child: SongPartEditor(
                          initText: currItemProv.song.songParts[index].getText(),
                          initChords: currItemProv.song.songParts[index].chords,
                          initShifted: currItemProv.song.songParts[index].shift,
                          isRefren: currItemProv.song.songParts[index].isRefren(context),
                          onTextChanged: (text, errCount){
                            currItemProv.song.songParts[index].setText(text);
                            currItemProv.song.songParts[index].isError = errCount != 0;
                            currItemProv.notify();
                          },
                          onChordsChanged: (text, errCount){
                            currItemProv.song.songParts[index].chords = text;
                            currItemProv.song.songParts[index].isError = errCount != 0;
                            currItemProv.notify();
                          },
                          onShiftedChanged: (shifted){
                            currItemProv.song.songParts[index].shift = shifted;
                            currItemProv.notify();
                          },
                        ),
                      ),
                    )),

                    header: Column(
                      children: [

                        Padding(
                          padding: EdgeInsets.only(left: Dimen.ICON_MARG, top: Dimen.ICON_MARG),
                          child: TitleShortcutRowWidget(
                            title: 'Info. ogólne',
                            textAlign: TextAlign.start,
                          ),
                        ),

                        Consumer<BindTitleFileNameProvider>(
                          builder: (context, prov, child) =>
                              SwitchListTile(
                                contentPadding: EdgeInsets.only(left: Dimen.ICON_MARG),
                                value: prov.bind!,
                                onChanged: (value) => prov.bind = value,
                                secondary: Icon(
                                    MdiIcons.paperclip,
                                    color: prov.bind!?iconEnab_(context):iconDisab_(context)
                                ),
                                title: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Powiąż nazwę pliku z tytułem',
                                      style: AppTextStyle(
                                          fontWeight: weight.bold,
                                          color: prov.bind!?textEnab_(context):textDisab_(context),
                                          fontSize: Dimen.TEXT_SIZE_APPBAR
                                      ),
                                    ),
                                    SizedBox(width: Dimen.ICON_MARG),

                                  ],
                                ),
                              ),
                        ),

                        SimilarSongWidget(),

                        SizedBox(height: Dimen.DEF_MARG),

                        TopCards(
                          onChangedTitle: (String text){
                            currItemProv.title = text;
                            Provider.of<SimilarSongProvider>(context, listen: false).title = text;
                          },
                          onChangedAuthor: (List<String> texts){
                            currItemProv.authors = texts;
                          },
                          onChangedComposer: (List<String> texts){
                            currItemProv.composers = texts;
                          },
                          onChangedPerformer: (List<String> texts){
                            currItemProv.performers = texts;
                          },
                          onChangedYT: (String? text){
                            currItemProv.youtubeLink = text;
                          },
                          onChangedAddPers: (List<String> texts){
                            currItemProv.addPers = texts;
                          },
                        ),

                        SizedBox(height: SEPARATOR_HEIGHT),

                        TagsWidget(
                          linear: false,
                          onChanged: (List<String>? tags){
                            currItemProv.tags = tags!;
                          },
                        ),

                        SizedBox(height: SEPARATOR_HEIGHT),

                        RefrenTemplate(
                            onPartTap: () => showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (context) => Center(
                                  child: Container(
                                    width: SONG_PART_EDITOR_WIDTH,
                                    child: SongPartEditor(
                                      initText: currItemProv.song.refrenPart.getText(),
                                      initChords: currItemProv.song.refrenPart.chords,
                                      initShifted: currItemProv.song.refrenPart.shift,
                                      isRefren: currItemProv.song.refrenPart.isRefren(context),
                                      onTextChanged: (text, errCount){
                                        currItemProv.song.refrenPart.setText(text);
                                        currItemProv.song.refrenPart.isError = errCount != 0;
                                        currItemProv.notify();
                                        Provider.of<RefrenPartProvider>(context, listen: false).notify();
                                      },
                                      onChordsChanged: (text, errCount){
                                        currItemProv.song.refrenPart.chords = text;
                                        currItemProv.song.refrenPart.isError = errCount != 0;
                                        currItemProv.notify();
                                        Provider.of<RefrenPartProvider>(context, listen: false).notify();
                                      },
                                      onShiftedChanged: (shifted){
                                        currItemProv.song.refrenPart.shift = shifted;
                                        currItemProv.notify();
                                        Provider.of<RefrenPartProvider>(context, listen: false).notify();
                                      },
                                    ),
                                  ),
                                )
                            ),
                        ),

                        SizedBox(height: SEPARATOR_HEIGHT),

                        Padding(
                          padding: EdgeInsets.only(left: Dimen.ICON_MARG),
                          child: TitleShortcutRowWidget(
                            title: 'Struktura piosenki',
                            textAlign: TextAlign.start,
                          ),
                        )

                      ],
                    ),
                ),
              ),

              AddButtonsWidget(onPressed: () => scrollToBottom(parent.scrollController!))

            ],
          );

      },
    );

  }

}

class SimilarSongWidget extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return Consumer<SimilarSongProvider>(
      builder: (context, prov, child){
        return AppCard(
            elevation: AppCard.bigElevation,
            radius: AppCard.BIG_RADIUS,
            margin: AppCard.normMargin,
            child:
            prov.similarSong == null?
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.all(Dimen.ICON_MARG),
                  child: Icon(MdiIcons.timerSand, color: hintEnab_(context)),
                ),
                Expanded(child: Text(
                  'Ładowanie listy weryfikacyjnej piosenek...',
                  style: AppTextStyle(fontSize: Dimen.TEXT_SIZE_BIG, fontWeight: weight.halfBold, color: hintEnab_(context)),
                  textAlign: TextAlign.center,
                )),
                SizedBox(width: Dimen.ICON_FOOTPRINT)
              ],
            ):(
                prov.similarSong!.length==0?
                Row(
                  children: [
                    Padding(
                        padding: EdgeInsets.all(Dimen.ICON_MARG),
                        child: Icon(MdiIcons.check, color: accent_(context))
                    ),

                    Expanded(child: Text(
                      'Sądząc po tytule, tego jeszcze nie ma w śpiewniku!',
                      style: AppTextStyle(fontSize: Dimen.TEXT_SIZE_BIG, fontWeight: weight.halfBold, color: accent_(context)),
                      textAlign: TextAlign.center,
                    )),
                    SizedBox(width: Dimen.ICON_FOOTPRINT)
                  ],
                ):
                Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(Dimen.ICON_MARG),
                      child: Icon(MdiIcons.alertCircleOutline, color: Colors.red),
                    ),

                    Expanded(child: Text(
                      'Ostrożnie! Piosenka o takim tytule już jest!',
                      style: AppTextStyle(color: Colors.red, fontWeight: weight.halfBold, fontSize: Dimen.TEXT_SIZE_BIG),
                      textAlign: TextAlign.center,
                    )),
                    IconButton(icon: Icon(MdiIcons.eye), onPressed: () => showDialog(
                      context: context,
                      builder: (context) => Center(
                          child: AppCard(
                            padding: EdgeInsets.zero,
                            color: Colors.white,
                            radius: AppCard.BIG_RADIUS,
                            child: MultiProvider(
                              providers: [
                                ChangeNotifierProvider(create: (context) => ShowChordsProvider(SongBaseSettings())),
                                ChangeNotifierProvider(create: (context) => ChordsDrawTypeProvider(SongBaseSettings())),
                                ChangeNotifierProvider(create: (context) => ChordsDrawShowProvider(SongBaseSettings())),
                              ],
                              builder: (context, child) => Container(
                                width: 400,
                                child: SongWidgetTemplate<SongRaw>(
                                    prov.similarSong![0],
                                    SongBaseSettings(),
                                    screenWidth: 372,
                                    key: UniqueKey()//ValueKey(currItemProv.song)
                                ),
                              ),
                            ),
                          )
                      ),
                    )),
                  ],
                )
            )

        );

        return Container();
      },
    );
  }

}

class SimilarSongProvider extends ChangeNotifier{

  HashMap<String, List<SongRaw>>? allSongs;

  late String _title;
  String get title => _title;
  set title(String value){
    _title = value;
    notifyListeners();
  }

  List<SongRaw>? get similarSong{
    if(allSongs == null) return null;

    String _title = remSpecChars(remPolChars(this._title.toLowerCase()));
    List<SongRaw>? songs = allSongs![_title];
    return songs??[];
  }

  SimilarSongProvider(){
    _title = '';
  }

  void init() async {
    allSongs = await loadSongs();
    notifyListeners();
  }

}