import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/title_show_row_widget.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core/song_book/add_person_resolver.dart';
import 'package:harcapp_core/song_book/song_editor/providers.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/song_book/song_editor/widgets/add_buttons_widget.dart';
import 'package:harcapp_core/song_book/song_editor/widgets/add_pers_list_widget.dart';
import 'package:harcapp_core/song_book/song_editor/widgets/refren_template.dart';
import 'package:harcapp_core/song_book/song_editor/widgets/scroll_to_bottom.dart';
import 'package:harcapp_core/song_book/song_editor/widgets/song_parts_list_widget.dart';
import 'package:harcapp_core/song_book/song_editor/widgets/tags_widget.dart';
import 'package:harcapp_core/song_book/song_editor/widgets/top_cards.dart';
import 'package:harcapp_core/song_book/widgets/song_widget_template.dart';
import 'package:harcapp_web/articles/article_editor/common.dart';
import 'package:harcapp_web/main.dart';
import 'package:harcapp_web/songs/utils/generate_file_name.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/song_editor_no_song_widget.dart';
import 'package:harcapp_web/songs/utils/song_loader.dart';
import 'package:harcapp_web/songs/song_part_editor.dart';
import 'package:harcapp_web/songs/song_preview_widget.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class SongEditorPanel extends StatefulWidget{

  final bool workspaceAlwaysVisible;

  const SongEditorPanel({required this.workspaceAlwaysVisible});

  @override
  State<StatefulWidget> createState() => SongEditorPanelState();

}

class SongEditorPanelState extends State<SongEditorPanel>{

  static const double SEPARATOR_HEIGHT = 42;

  late ScrollController scrollController;

  @override
  void initState() {
    scrollController = ScrollController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Consumer2<SongEditorPanelProvider, ShowSongProvider>(
    builder: (context, prov, showSongProv, child){

      CurrentItemProvider currItemProv = CurrentItemProvider.of(context);

      if(!showSongProv.showSong)
        return Padding(
          padding: EdgeInsets.only(top: 54.0),
          child: SongEditorNoSongWidget(workspaceAlwaysVisible: widget.workspaceAlwaysVisible),
        );
      else
        return Column(
          children: [

            // SingleChildScrollView is used with SongPartsListWidget(shrinkWrap: true),
            // because for some reason this is the only way the Handle used for moving
            // ImplicitlyAnimatedReorderableList items doesn't throw a Scrollable.of() exception.
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                controller: scrollController,
                child: SongPartsListWidget(
                  shrinkWrap: true,
                  onPartTap: (index) async {

                    String _text = currItemProv.song.songParts[index].getText();
                    String _chords = currItemProv.song.songParts[index].chords;
                    bool _shifted = currItemProv.song.songParts[index].shift;
                    bool _isError = currItemProv.song.songParts[index].isError;

                    await showDialog(context: context, builder: (_) => Center(
                      child: SizedBox(
                        width: dialogWidth,
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
                        padding: EdgeInsets.only(left: Dimen.iconMarg, top: Dimen.iconMarg),
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
                                contentPadding: EdgeInsets.only(left: Dimen.iconMarg),
                                value: prov.bindTitle,
                                onChanged: (value){
                                  prov.bindTitle = value;

                                  if(prov.bindTitle)
                                    Provider.of<CurrentItemProvider>(context, listen: false).setLclId(
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
                                          fontSize: Dimen.textSizeBig
                                      ),
                                    ),
                                    SizedBox(width: Dimen.iconMarg),

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
                                contentPadding: EdgeInsets.only(left: Dimen.iconMarg),
                                value: prov.bindPerformer,
                                onChanged: (value) {
                                  prov.bindPerformer = value;

                                  if(prov.bindTitle)
                                    CurrentItemProvider.of(context).setLclId(
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
                                          fontSize: Dimen.textSizeBig
                                      ),
                                    ),
                                    SizedBox(width: Dimen.iconMarg),

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
                            CurrentItemProvider.of(context).setLclId(
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
                            CurrentItemProvider.of(context).setLclId(
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

                      SongTagsWidget(
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
                                    width: dialogWidth,
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
                        padding: EdgeInsets.only(left: Dimen.iconMarg),
                        child: TitleShortcutRowWidget(
                          title: 'Struktura piosenki',
                          textAlign: TextAlign.start,
                        ),
                      )

                    ],
                  ),
                ),
              )
            ),

            AddButtonsWidget(onPressed: () => scrollToBottom(scrollController))

          ],
        );

    },
  );

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
                padding: EdgeInsets.all(Dimen.iconMarg),
                child: Icon(MdiIcons.timerSand, color: hintEnab_(context)),
              ),
              Expanded(child: Text(
                'Ładowanie listy weryfikacyjnej piosenek...',
                style: AppTextStyle(fontSize: Dimen.textSizeBig, fontWeight: weight.halfBold, color: hintEnab_(context)),
                textAlign: TextAlign.center,
              )),
              SizedBox(width: Dimen.iconFootprint)
            ],
          ):(
              prov.similarSong!.length==0?
              Row(
                children: [
                  Padding(
                      padding: EdgeInsets.all(Dimen.iconMarg),
                      child: Icon(MdiIcons.check, color: accent_(context))
                  ),

                  Expanded(child: Text(
                    'Sądząc po tytule, tego jeszcze nie ma w śpiewniku!',
                    style: AppTextStyle(fontSize: Dimen.textSizeBig, fontWeight: weight.halfBold, color: accent_(context)),
                    textAlign: TextAlign.center,
                  )),
                  SizedBox(width: Dimen.iconFootprint)
                ],
              ):
              Row(
                children: [
                  Padding(
                    padding: EdgeInsets.all(Dimen.iconMarg),
                    child: Icon(MdiIcons.alertCircleOutline, color: Colors.red),
                  ),

                  Expanded(child: Text(
                    'Ostrożnie! Piosenka o takim tytule już jest!',
                    style: AppTextStyle(color: Colors.red, fontWeight: weight.halfBold, fontSize: Dimen.textSizeBig),
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
                            child: SongWidgetTemplate<SongRaw, AddPersonSimpleResolver>(
                                prov.similarSong![0],
                                SongBaseSettings(),
                                addPersonResolver: AddPersonSimpleResolver(),
                                scrollController: ScrollController(),
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

  Map<String, List<SongRaw>>? allSongs;

  late String _title;
  String get title => _title;
  set title(String value){
    _title = value;
    notifyListeners();
  }

  List<SongRaw>? get similarSong{
    if(allSongs == null) return null;

    String _title = remSpecChars(remPolChars(this._title.toLowerCase()));
    List<SongRaw> songs = allSongs![_title]??[];
    return songs;
  }

  SimilarSongProvider(){
    _title = '';
  }

  bool hasSimilarSong(String title){
    if(allSongs == null) return false;
    String _title = remSpecChars(remPolChars(title.toLowerCase()));
    List<SongRaw> songs = allSongs![_title]??[];

    return songs.isNotEmpty;
  }

  void init() async {
    allSongs = await loadSongs();
    notifyListeners();
  }

}