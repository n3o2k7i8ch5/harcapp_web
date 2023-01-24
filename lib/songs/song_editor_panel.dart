import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/title_show_row_widget.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core_own_song/page_widgets/add_buttons_widget.dart';
import 'package:harcapp_core_own_song/page_widgets/add_pers_list_widget.dart';
import 'package:harcapp_core_own_song/page_widgets/refren_template.dart';
import 'package:harcapp_core_own_song/page_widgets/scroll_to_bottom.dart';
import 'package:harcapp_core_own_song/page_widgets/song_parts_list_widget.dart';
import 'package:harcapp_core_own_song/page_widgets/tags_widget.dart';
import 'package:harcapp_core_own_song/page_widgets/top_cards.dart';
import 'package:harcapp_core_own_song/providers.dart';
import 'package:harcapp_core_own_song/song_raw.dart';
import 'package:harcapp_core_song_widget/add_pers_resolver.dart';
import 'package:harcapp_core_song_widget/song_widget_template.dart';
import 'package:harcapp_web/articles/article_editor/common.dart';
import 'package:harcapp_web/songs/generate_file_name.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/song_editor_no_song_widget.dart';
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
          return Padding(
            padding: EdgeInsets.only(top: 54.0),
            child: SongEditorNoSongWidget(),
          );

        if(!showSongProv.showSong)
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 54.0),

              Text(
                'Dodaj lub importuj piosenkę.',
                style: AppTextStyle(
                    fontSize: 24.0,
                    color: textDisab_(context),
                    fontWeight: weight.halfBold
                ),
              ),

              SizedBox(height: 24.0),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(MdiIcons.arrowLeft, color: textDisab_(context), size: 24.0),
                  SizedBox(width: Dimen.ICON_MARG),
                  Text(
                    'Zerknij tam!',
                    style: AppTextStyle(
                        fontSize: 24.0,
                        color: textDisab_(context),
                        fontWeight: weight.halfBold
                    ),
                  ),
                  SizedBox(width: Dimen.ICON_MARG),
                  Icon(MdiIcons.musicNote, color: textDisab_(context), size: 24.0),
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
                    onPartTap: (index) async {

                      String _text = currItemProv.song.songParts[index].getText();
                      String _chords = currItemProv.song.songParts[index].chords;
                      bool _shifted = currItemProv.song.songParts[index].shift;
                      bool _isError = currItemProv.song.songParts[index].isError;

                      await showDialog(context: context, builder: (_) => Center(
                        child: SizedBox(
                          width: SONG_PART_EDITOR_WIDTH,
                          child: SongPartEditor(
                            initText: _text,
                            initChords: _chords,
                            initShifted: _shifted,
                            isRefren: currItemProv.song.songParts[index].isRefren(context),
                            onTextChanged: (text, errCount){
                              _text = text;
                              _isError = errCount != 0;
                            },
                            onChordsChanged: (text, errCount){
                              _chords = text;
                              _isError = errCount != 0;
                            },
                            onShiftedChanged: (shifted){
                              _shifted = shifted;
                            },
                          ),
                        ),
                      ));

                      currItemProv.song.songParts[index].setText(_text);
                      currItemProv.song.songParts[index].chords = _chords;
                      currItemProv.song.songParts[index].shift = _shifted;
                      currItemProv.song.songParts[index].isError = _isError;
                      currItemProv.notify();

                    },

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
                              Material(
                                color: Colors.transparent,
                                clipBehavior: Clip.hardEdge,
                                borderRadius: BorderRadius.circular(AppCard.bigRadius),
                                child: SwitchListTile(
                                  contentPadding: EdgeInsets.only(left: Dimen.ICON_MARG),
                                  value: prov.bindTitle,
                                  onChanged: (value){
                                    prov.bindTitle = value;

                                    if(prov.bindTitle)
                                      Provider.of<CurrentItemProvider>(context, listen: false).setFileName(
                                          generateFileName(
                                              song: Provider.of<CurrentItemProvider>(context, listen: false).song,
                                              context: context
                                          )
                                      );

                                    SongFileNameDupErrProvider.of(context).checkAllDups(context);

                                  },
                                  title: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [

                                      Text(
                                        'Powiąż identyfikator piosenki z tytułem',
                                        style: AppTextStyle(
                                            color: prov.bindTitle?textEnab_(context):textDisab_(context),
                                            fontSize: Dimen.TEXT_SIZE_BIG
                                        ),
                                      ),
                                      SizedBox(width: Dimen.ICON_MARG),

                                    ],
                                  ),
                                ),
                              ),
                        ),

                        SizedBox(height: Dimen.defMarg),

                        Consumer<BindTitleFileNameProvider>(
                          builder: (context, prov, child) =>
                              Material(
                                color: Colors.transparent,
                                clipBehavior: Clip.hardEdge,
                                borderRadius: BorderRadius.circular(AppCard.bigRadius),
                                child: SwitchListTile(
                                  contentPadding: EdgeInsets.only(left: Dimen.ICON_MARG),
                                  value: prov.bindPerformer,
                                  onChanged: (value) {
                                    prov.bindPerformer = value;

                                    if(prov.bindTitle)
                                      CurrentItemProvider.of(context).setFileName(
                                          generateFileName(
                                              song: CurrentItemProvider.of(context).song,
                                              context: context
                                          )
                                      );

                                    SongFileNameDupErrProvider.of(context).checkAllDups(context);

                                  },
                                  title: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [

                                      Text(
                                        'Powiąż identyfikator piosenki z wykonawcą',
                                        style: AppTextStyle(
                                            color: prov.bindPerformer?textEnab_(context):textDisab_(context),
                                            fontSize: Dimen.TEXT_SIZE_BIG
                                        ),
                                      ),
                                      SizedBox(width: Dimen.ICON_MARG),

                                    ],
                                  ),
                                ),
                              ),
                        ),

                        SizedBox(height: Dimen.defMarg),

                        SimilarSongWidget(),

                        SizedBox(height: Dimen.defMarg),

                        TopCards(
                          onChangedTitle: (String text){
                            currItemProv.setTitle(text, notify: false);
                            SimilarSongProvider.of(context).title = text;
                            if(BindTitleFileNameProvider.of(context).bindTitle)
                              CurrentItemProvider.of(context).setFileName(
                                  generateFileName(
                                      song: CurrentItemProvider.of(context).song,
                                      context: context
                                  )
                              );
                          },
                          onChangedHiddenTitles: (List<String> texts) => currItemProv.setHidTitles(texts, notify: false),
                          onChangedAuthor: (List<String> texts) => currItemProv.setAuthors(texts, notify: false),
                          onChangedComposer: (List<String> texts) => currItemProv.setComposers(texts, notify: false),
                          onChangedPerformer: (List<String> texts){
                            currItemProv.setPerformers(texts, notify: false);
                            if(BindTitleFileNameProvider.of(context).bindTitle)
                              CurrentItemProvider.of(context).setFileName(
                                  generateFileName(
                                      song: CurrentItemProvider.of(context).song,
                                      context: context
                                  )
                              );
                          },
                          onChangedYT: (String? text) => currItemProv.setYoutubeLink(text, notify: false),
                        ),

                        const SizedBox(height: Dimen.defMarg),

                        const AddPersListWidget(),

                        const SizedBox(height: Dimen.defMarg),

                        TagsWidget(
                          linear: false,
                          onChanged: (List<String> tags){
                            currItemProv.setTags(tags, notify: false);
                          },
                        ),

                        SizedBox(height: SEPARATOR_HEIGHT),

                        RefrenTemplate(
                          onPartTap: () async {

                            String _text = currItemProv.song.refrenPart.getText();
                            String _chords = currItemProv.song.refrenPart.chords;
                            bool _shifted = currItemProv.song.refrenPart.shift;
                            bool _isError = currItemProv.song.refrenPart.isError;

                            await showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (context) => Center(
                                  child: SizedBox(
                                    width: SONG_PART_EDITOR_WIDTH,
                                    child: SongPartEditor(
                                      initText: _text,
                                      initChords: _chords,
                                      initShifted: _shifted,
                                      isRefren: currItemProv.song.refrenPart.isRefren(context),
                                      onTextChanged: (text, errCount){
                                        _text = text;
                                        _isError = errCount != 0;
                                      },
                                      onChordsChanged: (text, errCount){
                                        _chords = text;
                                        _isError = errCount != 0;
                                      },
                                      onShiftedChanged: (shifted){
                                        _shifted = shifted;
                                      },
                                    ),
                                  ),
                                )
                            );

                            currItemProv.song.refrenPart.setText(_text);
                            currItemProv.song.refrenPart.chords = _chords;
                            currItemProv.song.refrenPart.shift = _shifted;
                            currItemProv.song.refrenPart.isError = _isError;
                            currItemProv.notify();
                            Provider.of<RefrenPartProvider>(context, listen: false).notify();

                          }
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

              AddButtonsWidget(onPressed: () => scrollToBottom(parent.scrollController))

            ],
          );

      },
    );

  }

}

class SimilarSongWidget extends StatelessWidget{

  @override
  Widget build(BuildContext context) => Consumer<SimilarSongProvider>(
      builder: (context, prov, child) => Material(
          borderRadius: BorderRadius.circular(AppCard.bigRadius),
          clipBehavior: Clip.hardEdge,
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
                          radius: AppCard.bigRadius,
                          child: SizedBox(
                            width: 400,
                            child: SongWidgetTemplate<SongRaw, AddPersSimpleResolver>(
                                prov.similarSong![0],
                                SongBaseSettings(),
                                screenWidth: 372,
                                addPersResolver: AddPersSimpleResolver(),
                                key: UniqueKey()//ValueKey(currItemProv.song)
                            ),
                          ),
                        )
                    ),
                  )),
                ],
              )
          )

      )
  );

}

class SimilarSongProvider extends ChangeNotifier{

  static SimilarSongProvider of(BuildContext context) => Provider.of<SimilarSongProvider>(context, listen: false);

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

  bool hasSimilarSong(String title){
    String _title = remSpecChars(remPolChars(title.toLowerCase()));
    List<SongRaw> songs = allSongs![_title]??[];

    return songs.isNotEmpty;
  }

  void init() async {
    allSongs = await loadSongs();
    notifyListeners();
  }

}