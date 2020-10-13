import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:harcapp_web/common/app_card.dart';
import 'package:harcapp_web/common/app_text_style.dart';
import 'package:harcapp_web/common/color_pack.dart';
import 'package:harcapp_web/common/core_comm_widgets/tag_layout.dart';
import 'package:harcapp_web/common/dimen.dart';
import 'package:harcapp_web/common/show_toast.dart';
import 'package:harcapp_web/songs/core_own_song/providers.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import 'core_song_management/song_raw.dart';

class CodeEditorWidget extends StatelessWidget{
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
                            child: Column(
                              children: [

                                AppBar(
                                  backgroundColor: Colors.transparent,
                                  leading: IconButton(
                                      icon: Icon(MdiIcons.arrowLeft),
                                      onPressed: () => prov.value = false,
                                  ),
                                  title: Text(
                                    'Edytor kodu',
                                    style: AppTextStyle(color: textEnabled(context)),
                                  ),
                                  actions: [
                                    IconButton(
                                        icon: Icon(MdiIcons.check),
                                        onPressed: (){

                                          try {
                                            String fileName = prov.song.fileName;
                                            SongRaw song = SongRaw.parse(fileName, prov.text);

                                            Provider.of<TitleCtrlProvider>(context, listen: false).text = song.title;
                                            Provider.of<AuthorCtrlProvider>(context, listen: false).text = song.author;
                                            Provider.of<PerformerCtrlProvider>(context, listen: false).text = song.performer;
                                            Provider.of<YTCtrlProvider>(context, listen: false).text = song.youtubeLink;
                                            Provider.of<AddPersCtrlProvider>(context, listen: false).text = song.addPers;
                                            Provider.of<TagsProvider>(context, listen: false).tagsChecked = Tag.ALL_TAG_NAMES.map((tag) => song.tags.contains(tag)).toList();

                                            prov.song.set(song);
                                            Provider.of<CurrentItemProvider>(context, listen: false).notifyListeners();

                                            prov.value = false;
                                          } catch(e){
                                            showToast('Błędny kod piosneki.');
                                          }
                                        }
                                    ),
                                  ],
                                  iconTheme: IconThemeData(color: iconEnabledColor(context)),
                                  actionsIconTheme: IconThemeData(color: iconEnabledColor(context)),
                                ),

                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(left: Dimen.DEF_MARG, right: Dimen.DEF_MARG),
                                    child: TextField(
                                      minLines: 10,
                                      maxLines: null,
                                      controller: controller,
                                      onChanged: (text) => prov.text = text,
                                      style: TextStyle(color: textEnabled(context)),
                                      decoration: InputDecoration(
                                        hintText: 'Wpisz kod piosenki',
                                        hintStyle: TextStyle(color: hintEnabled(context)),
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