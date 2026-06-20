import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_bar.dart';
import 'package:harcapp_core/comm_widgets/app_button.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/comm_widgets/dialog/base.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/song_book/song_core.dart';
import 'package:harcapp_core/song_book/song_editor/providers.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_web/consts.dart';
import 'package:harcapp_web/songs/left_panel/song_list_view.dart';
import 'package:harcapp_web/songs/old/parse_old_code.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:pretty_json/pretty_json.dart';

class CodeEditorDialog extends StatefulWidget{

  final SongRaw? song;
  final void Function()? onSaved;

  const CodeEditorDialog(this.song, {this.onSaved, super.key});

  @override
  State<StatefulWidget> createState() => CodeEditorDialogState();

}

class CodeEditorDialogState extends State<CodeEditorDialog> {

  SongRaw? get song => widget.song;

  late TextEditingController controller;

  @override
  void initState() {
    controller = TextEditingController(
        text: song == null
            ? ''
            : prettyJson(song!.toApiJsonMap(withId: false), indent: 4)
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [

      AppBarX(
        title: 'Edytor kodu',
        actions: [

          AppButton(
            icon: Icon(MdiIcons.formatIndentIncrease),
            onTap: cleanupText
          ),

          AppButton(
            icon: Icon(MdiIcons.check),
            onTap: save
          ),

        ],
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
                hintText: 'Wpisz lub wklej kod piosenki',
                hintStyle: TextStyle(color: hintEnab_(context)),
                border: InputBorder.none
              ),
            ),
          )
      ),

    ],
  );

  void cleanupText(){
    try {
      String prettyText = prettyJson(jsonDecode(controller.text), indent: 4);
      controller.text = prettyText;
    } catch(e){
      AppScaffold.showMessage(context, text: 'Błędny kod piosenki.');
    }
  }

  void save(){

    SongRaw parsedSong;

    try{
      // Try parsing the old song code
      parsedSong = parseOldCode('_nowa_piosenka', controller.text);
      parsedSong.id = parsedSong.generateFileName(withPerformer: BindTitleFileNameProvider.of(context).bindPerformer);
    } catch(e){

      try {
        // Try parsing the entire song code
        Map map = jsonDecode(controller.text);
        String songId = map.keys.toList()[0];
        parsedSong = SongRaw.fromApiRespMap(songId, map[songId]);

      } catch(e){

        // Try parsing the song code without the songId level
        try{
          Map map = jsonDecode(controller.text);
          String title = map['title'];
          parsedSong = SongRaw.fromApiRespMap("o!_${SongCore.filenameFromTitle(title)}", map);

        }catch(e){
          AppScaffold.showMessage(context, text: 'Błędny kod piosneki.');
          return;
        }
      }
    }

    TagsProvider.of(context).set(parsedSong.tags);

    SongRaw? existing = song;
    if(existing == null){
      AllSongsProvider.of(context).addOff(parsedSong);
      widget.onSaved?.call();
      SongFileNameDupErrProvider.of(context).checkAllDups(context);
      displaySong(context, parsedSong);
    } else {
      existing.set(parsedSong);
      AllSongsProvider.of(context).set(existing, existing.isConfid);
      widget.onSaved?.call();
      SongFileNameDupErrProvider.of(context).checkAllDups(context);
      displaySong(context, existing);
    }

    Navigator.pop(context);
  }

}

void showCodeEditorDialog(BuildContext context, SongRaw song) => openBaseDialog(
  context: context,
  maxWidth: songDialogWidth,
  builder: (context) => CodeEditorDialog(song)
);