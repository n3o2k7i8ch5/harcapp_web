
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/title_show_row_widget.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core_own_song/page_widgets/add_buttons_widget.dart';
import 'package:harcapp_core_own_song/page_widgets/refren_template.dart';
import 'package:harcapp_core_own_song/page_widgets/scroll_to_bottom.dart';
import 'package:harcapp_core_own_song/page_widgets/song_parts_list_widget.dart';
import 'package:harcapp_core_own_song/page_widgets/tags_widget.dart';
import 'package:harcapp_core_own_song/page_widgets/top_cards.dart';
import 'package:harcapp_core_own_song/providers.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/song_part_editor.dart';
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

                        TopCards(
                          onChangedTitle: (String text){
                            currItemProv.title = text;
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