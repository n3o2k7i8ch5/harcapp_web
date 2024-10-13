import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/comm_widgets/title_show_row_widget.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core/song_book/add_person_resolver.dart';
import 'package:harcapp_core/song_book/song_editor/providers.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/song_book/song_editor/widgets/add_buttons_widget.dart';
import 'package:harcapp_core/song_book/song_editor/widgets/add_pers_list_widget.dart';
import 'package:harcapp_core/song_book/song_editor/widgets/basic_data_widget.dart';
import 'package:harcapp_core/song_book/song_editor/widgets/refren_template.dart';
import 'package:harcapp_core/song_book/song_editor/widgets/scroll_to_bottom.dart';
import 'package:harcapp_core/song_book/song_editor/widgets/song_parts_list_widget.dart';
import 'package:harcapp_core/song_book/song_editor/widgets/tags_widget.dart';
import 'package:harcapp_core/song_book/widgets/song_widget_template.dart';
import 'package:harcapp_web/main.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/song_editor_no_song_widget.dart';
import 'package:harcapp_web/songs/song_part_editor.dart';
import 'package:harcapp_web/songs/song_preview_widget.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../consts.dart';

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
  Widget build(BuildContext context) => Consumer2<SongEditorPanelProvider, SongPreviewProvider>(
    builder: (context, prov, showSongProv, child){

      CurrentItemProvider currItemProv = CurrentItemProvider.of(context);

      if(!showSongProv.showSong)
        return Padding(
          padding: EdgeInsets.only(top: 54.0),
          child: SongEditorNoSongWidget(workspaceAlwaysVisible: widget.workspaceAlwaysVisible),
        );

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
                      width: songDialogWidth,
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
                          SwitchListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppCard.bigRadius)),
                            contentPadding: EdgeInsets.only(left: Dimen.iconMarg),
                            value: prov.bindTitle,
                            onChanged: (value){
                              prov.bindTitle = value;

                              if(prov.bindTitle)
                                CurrentItemProvider.of(context).setLclIdFromTitleAndPerformer(withPerformer: prov.bindPerformer);

                              SongFileNameDupErrProvider.of(context).checkAllDups(context);

                            },
                            title: Text(
                              'Powiąż identyfikator piosenki z tytułem',
                              style: AppTextStyle(
                                  color: prov.bindTitle?textEnab_(context):textDisab_(context),
                                  fontSize: Dimen.textSizeBig
                              ),
                            ),
                          ),
                    ),

                    SizedBox(height: Dimen.defMarg),

                    Consumer2<BindTitleFileNameProvider, CurrentItemProvider>(
                      builder: (context, bindTitleFileNameProv, currItemProv, child) =>
                          IgnorePointer(
                            ignoring: currItemProv.performersController.isEmpty,
                            child: AnimatedOpacity(
                              duration: Duration(milliseconds: 300),
                              opacity: currItemProv.performersController.isEmpty?
                              0.3:
                              1.0,

                              child: SwitchListTile(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppCard.bigRadius)),
                                contentPadding: EdgeInsets.only(left: Dimen.iconMarg),
                                value: currItemProv.performersController.isNotEmpty && bindTitleFileNameProv.bindPerformer,
                                onChanged: (value) {
                                  bindTitleFileNameProv.bindPerformer = value;

                                  if(bindTitleFileNameProv.bindTitle)
                                    CurrentItemProvider.of(context).setLclIdFromTitleAndPerformer(withPerformer: value);

                                  SongFileNameDupErrProvider.of(context).checkAllDups(context);

                                },
                                title: Text(
                                  'Powiąż identyfikator piosenki z wykonawcą',
                                  style: AppTextStyle(
                                      color: bindTitleFileNameProv.bindPerformer?
                                      textEnab_(context):
                                      textDisab_(context),

                                      fontSize: Dimen.textSizeBig
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ),

                    SizedBox(height: Dimen.defMarg),

                    SimilarSongWidget(),

                    SizedBox(height: Dimen.defMarg),

                    BasicDataWidget(
                      onChangedTitle: (String text){
                        BindTitleFileNameProvider bindTitleFileNameProv = BindTitleFileNameProvider.of(context);
                        if(bindTitleFileNameProv.bindTitle){
                          CurrentItemProvider.of(context).setLclIdFromTitleAndPerformer(withPerformer: bindTitleFileNameProv.bindPerformer);
                          SongFileNameDupErrProvider.of(context).checkAllDups(context);
                        }

                      },
                      onChangedHiddenTitles: (List<String> texts) => currItemProv.notify(),
                      onChangedAuthor: (List<String> texts) => currItemProv.notify(),
                      onChangedComposer: (List<String> texts) => currItemProv.notify(),
                      onChangedPerformer: (List<String> texts){

                        currItemProv.notify();

                        BindTitleFileNameProvider bindTitleFileNameProv = BindTitleFileNameProvider.of(context);
                        if(bindTitleFileNameProv.bindTitle){
                          CurrentItemProvider.of(context).setLclIdFromTitleAndPerformer(withPerformer: bindTitleFileNameProv.bindPerformer);
                          SongFileNameDupErrProvider.of(context).checkAllDups(context);
                        }
                      },
                      onChangedYT: (String? text) => currItemProv.notify(),
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
                                  width: songDialogWidth,
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

          Material(
            elevation: AppCard.bigElevation,
            borderRadius: BorderRadius.circular(AppCard.bigRadius),
            color: cardEnab_(context),
            child: AddButtonsWidget(onPressed: () => scrollToBottom(scrollController)),
          )

        ],
      );

    },
  );

}

class SimilarSongWidget extends StatelessWidget{

  static IconData icon = MdiIcons.musicBoxMultiple;

  @override
  Widget build(BuildContext context) => Consumer2<SimilarSongProvider, CurrentItemProvider>(
      builder: (context, similarSongProv, currItemProv, child) => Material(
          borderRadius: BorderRadius.circular(AppCard.bigRadius),
          clipBehavior: Clip.hardEdge,
          child:
          similarSongProv.allSongs == null?
          Row(
            children: [
              Padding(
                padding: EdgeInsets.all(Dimen.iconMarg),
                child: Icon(MdiIcons.timerSand, color: hintEnab_(context)),
              ),
              Expanded(child: Text(
                'Ładowanie listy istniejących piosenek...',
                style: AppTextStyle(fontSize: Dimen.textSizeBig, fontWeight: weight.halfBold, color: hintEnab_(context)),
                textAlign: TextAlign.center,
              )),
              SizedBox(width: Dimen.iconFootprint)
            ],
          ):(
              !similarSongProv.hasSimilarSong(currItemProv.titleController.text)?
              _NoSimilarSongsWidget():
              _FoundSimilarSongWidget()
          )

      )
  );

}

class _NoSimilarSongsWidget extends StatelessWidget{

  @override
  Widget build(BuildContext context) => Row(
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
  );

}

class _FoundSimilarSongWidget extends StatelessWidget{

  @override
  Widget build(BuildContext context) => Consumer2<SimilarSongProvider, CurrentItemProvider>(
      builder: (context, similarSongProv, currItemProv, child) => Row(
        children: [
          Padding(
            padding: EdgeInsets.all(Dimen.iconMarg),
            child: Icon(SimilarSongWidget.icon, color: Colors.red),
          ),

          Expanded(child: Text(
            'Piosenka o takim tytule już jest!',
            style: AppTextStyle(color: Colors.red, fontWeight: weight.halfBold, fontSize: Dimen.textSizeBig),
            textAlign: TextAlign.center,
          )),

          SimpleButton.from(
              context: context,
              icon: MdiIcons.eye,
              margin: EdgeInsets.zero,
              iconLeading: false,
              text: 'Podgląd',
              onTap: () => showDialog(
                context: context,
                builder: (context) => Center(
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppCard.bigRadius),
                      child: SizedBox(
                        width: 400,
                        child: SongWidgetTemplate<SongRaw, AddPersonSimpleResolver>(
                            similarSongProv.getSimilarSongs(currItemProv.titleController.text)![0],
                            SongBaseSettings(),
                            addPersonResolver: AddPersonSimpleResolver(),
                            scrollController: ScrollController(),
                            key: UniqueKey()//ValueKey(currItemProv.song)
                        ),
                      ),
                    )
                ),
              )
          ),

        ],
      )
  );



}