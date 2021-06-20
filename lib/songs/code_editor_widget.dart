import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core_own_song/providers.dart';
import 'package:harcapp_core_own_song/song_raw.dart';
import 'package:harcapp_core_tags/tag_layout.dart';
import 'package:harcapp_web/songs/_main.dart';
import 'package:harcapp_web/songs/generate_file_name.dart';
import 'package:harcapp_web/songs/old/parse_old_code.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/workspace/workspace.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class CodeEditorWidget extends StatelessWidget{

  //SongPreviewProvider get songPrevProv => parent.songPrevProv;

  SongsPageState parent;

  CodeEditorWidget(this.parent);


  @override
  Widget build(BuildContext context) {

    return Consumer<ShowCodeEditorProvider>(
        builder: (context, prov, child){

          TextEditingController controller = TextEditingController(text: prov.text);

          if(!prov.value)
            return Container();

          return GestureDetector(
              onTap: (){
                //prov.value = false;
              },
              child: Container(
                width: double.infinity,
                color: Colors.black54,
                child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Container(
                          width: 500,
                          child: AppCard(
                            padding: EdgeInsets.zero,
                            margin: AppCard.normMargin,
                            child: Column(
                              children: [

                                AppBar(
                                  leading: IconButton(
                                      icon: Icon(MdiIcons.arrowLeft),
                                      onPressed: () => prov.value = false,
                                  ),
                                  title: Text(
                                    'Edytor kodu',
                                    style: AppTextStyle(color: textEnab_(context)),
                                  ),
                                  actions: [
                                    IconButton(
                                        icon: Icon(MdiIcons.check),
                                        onPressed: (){

                                          SongRaw song;

                                          try{
                                            song = parseOldCode('_nowa_piosenka', prov.text);
                                            String fileName = generateFileName(title: song.title);
                                            song.fileName = fileName;
                                          } catch(e){

                                            try {
                                              Map map = jsonDecode(prov.text);
                                              String fileName = map.keys.toList()[0];
                                              song = SongRaw.fromMap(fileName, map[fileName]);

                                            } catch(e){
                                              AppScaffold.showMessage(context, 'Błędny kod piosneki.');
                                              return;
                                            }
                                          }

                                          Provider.of<TitleCtrlProvider>(context, listen: false).text = song.title;
                                          /*
                                          Provider.of<AuthorCtrlProvider>(context, listen: false).text = song.author;
                                          Provider.of<PerformerCtrlProvider>(context, listen: false).text = song.performer;
                                          Provider.of<YTCtrlProvider>(context, listen: false).text = song.youtubeLink;
                                          Provider.of<AddPersCtrlProvider>(context, listen: false).text = song.addPers;

                                           */
                                          Provider.of<TagsProvider>(context, listen: false).set(Tag.ALL_TAG_NAMES, song.tags);


                                          prov.song.set(song);
                                          Provider.of<CurrentItemProvider>(context, listen: false).song = song;
                                          AllSongsProvider allSongsProv = Provider.of<AllSongsProvider>(context, listen: false);
                                          allSongsProv.set(prov.song, prov.song.isConfid);

                                          displaySong(context, prov.song);

                                          prov.value = false;
                                        }
                                    ),
                                  ],
                                  iconTheme: IconThemeData(color: iconEnab_(context)),
                                  actionsIconTheme: IconThemeData(color: iconEnab_(context)),
                                ),

                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(left: Dimen.DEF_MARG, right: Dimen.DEF_MARG),
                                    child: TextField(
                                      minLines: 10,
                                      maxLines: null,
                                      controller: controller,
                                      onChanged: (text) => prov.text = text,
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
                ),
              )
          );

        }
    );

  }



}