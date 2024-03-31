import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core/song_book/song_editor/providers.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/song_book/song_tags.dart';
import 'package:harcapp_web/songs/left_panel/song_list_view.dart';
import 'package:harcapp_web/songs/utils/generate_file_name.dart';
import 'package:harcapp_web/songs/old/parse_old_code.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pretty_json/pretty_json.dart';

class CodeEditorDialog extends StatelessWidget{

  final SongRaw song;
  const CodeEditorDialog(this.song, {super.key});

  @override
  Widget build(BuildContext context){

        TextEditingController controller = TextEditingController(
            text: prettyJson(jsonDecode(song.toCode()), indent: 4)
        );

        return Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Container(
                  width: 500,
                  child: AppCard(
                    radius: AppCard.bigRadius,
                    padding: EdgeInsets.zero,
                    margin: AppCard.normMargin,
                    child: Column(
                      children: [

                        AppBar(
                          title: Text(
                            'Edytor kodu',
                            style: AppTextStyle(color: textEnab_(context)),
                          ),
                          centerTitle: true,
                          actions: [

                            IconButton(
                              icon: Icon(MdiIcons.formatIndentIncrease),
                              onPressed: (){
                                String prettyText = prettyJson(jsonDecode(controller.text));
                                controller.text = prettyText;
                              },
                            ),

                            IconButton(
                                icon: Icon(MdiIcons.check),
                                onPressed: (){

                                  SongRaw song;

                                  try{
                                    song = parseOldCode('_nowa_piosenka', controller.text);
                                    String lclId = generateFileName(context: context, song: song);
                                    song.lclId = lclId;
                                  } catch(e){

                                    try {
                                      Map map = jsonDecode(controller.text);
                                      String fileName = map.keys.toList()[0];
                                      song = SongRaw.fromRespMap(fileName, map[fileName]);

                                    } catch(e){
                                      AppScaffold.showMessage(context, 'Błędny kod piosneki.');
                                      return;
                                    }
                                  }

                                  TagsProvider.of(context).set(SongTag.ALL, song.tags);

                                  this.song.set(song);
                                  AllSongsProvider.of(context).set(this.song, this.song.isConfid);

                                  SongFileNameDupErrProvider.of(context).checkAllDups(context);

                                  displaySong(context, this.song);
                                  Navigator.pop(context);
                                }
                            ),
                          ],
                          iconTheme: IconThemeData(color: iconEnab_(context)),
                          actionsIconTheme: IconThemeData(color: iconEnab_(context)),
                        ),

                        Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: Dimen.defMarg, right: Dimen.defMarg),
                              child: TextField(
                                minLines: 10,
                                maxLines: null,
                                controller: controller,
                                style: TextStyle(color: textEnab_(context)),
                                decoration: InputDecoration(
                                    hintText: 'Wpisz kod piosenki',
                                    hintStyle: TextStyle(color: hintEnab_(context)),
                                    border: InputBorder.none
                                ),
                              ),
                            )
                        ),

                      ],
                    ),
                  )
              ),
            )
        );

      }

}