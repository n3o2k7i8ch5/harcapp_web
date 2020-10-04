

import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker_cross/file_picker_cross.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:harcapp_web/common/app_text_style.dart';
import 'package:harcapp_web/common/color_pack.dart';
import 'package:harcapp_web/common/core_comm_widgets/simple_button.dart';
import 'package:harcapp_web/common/dimen.dart';
import 'package:harcapp_web/songs/core_own_song/providers.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import 'core_own_song/common.dart';
import 'core_song_management/song_raw.dart';
import 'core_tags/tag_layout.dart';

class WorkspacePart extends StatefulWidget{

  @override
  State<StatefulWidget> createState() => WorkspacePartState();

}

class WorkspacePartState extends State<WorkspacePart>{

  String code;

  @override
  Widget build(BuildContext context) {

    if(code == null)
      return LoadWidget(
        onLoaded: (String code){
          setState(() => this.code = code);
        },
      );

    return SongListView(code);

  }

}

class LoadWidget extends StatelessWidget{

  final Function(String code) onLoaded;

  const LoadWidget({@required this.onLoaded});

  @override
  Widget build(BuildContext context) {
    return  Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.max,
      children: [
        HeaderWidget(
          'Przestrzeń robocza',
          MdiIcons.toolboxOutline,
          enabled: false,
        ),
        Expanded(child: Center(
          child: SimpleButton(
              radius: 100,
              margin: EdgeInsets.all(Dimen.MARG_ICON),
              padding: EdgeInsets.all(Dimen.MARG_ICON),
              child: Text('Importuj piosenki', style: AppTextStyle(fontSize: Dimen.TEXT_SIZE_BIG), textAlign: TextAlign.center),
              onTap: ()async{

                FilePickerCross filePicker = FilePickerCross();
                bool picked = await filePicker.pick();
                if(picked){
                  Uint8List uint8List = filePicker.toUint8List();
                  String code = utf8.decode(uint8List);
                  onLoaded(code);

                }

              }
          ),
        ))
      ],
    );
  }

}

class SongListView extends StatefulWidget{

  final String code;
  const SongListView(this.code);

  @override
  State<StatefulWidget> createState() => SongListViewState();

}

class SongListViewState extends State<SongListView>{

  String get code => widget.code;

  List<SongRaw> songs;

  @override
  void initState() {

    songs = [];

    Map<String, dynamic> map = jsonDecode(code);
    Map<String, dynamic> offSongs = map['official'] as Map<String, dynamic>;

    for(String fileName in offSongs.keys){

      Map<String, dynamic> songPackMap = offSongs[fileName];

      Map<String, dynamic> songMap = songPackMap['song'];
      int index = songPackMap['index'];

      songs.add(
        SongRaw.fromMap(fileName, songMap)
      );
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) => ItemWidget(songs[index]),

    );
  }

}

class ItemWidget extends StatelessWidget{

  final SongRaw song;
  const ItemWidget(this.song);

  @override
  Widget build(BuildContext context) {

    return Consumer<CurrentItemProvider>(
        builder: (context, prov, child) => ListTile(
          dense: true,
          title: Text(song.title, style: AppTextStyle(color: textEnabled(context))),
          subtitle: Text(song.fileName, style: AppTextStyle(color: hintEnabled(context))),
          selected: prov.song == song,
          selectedTileColor: Colors.black12,
          onTap: () {

            LoadingProvider loadingProv = Provider.of<LoadingProvider>(context, listen: false);
            //loadingProv.loading = true;

            prov.song = song;

            Provider.of<TitleCtrlProvider>(context, listen: false).text = song.title;
            Provider.of<AuthorCtrlProvider>(context, listen: false).text = song.author;
            Provider.of<PerformerCtrlProvider>(context, listen: false).text = song.performer;
            Provider.of<YTCtrlProvider>(context, listen: false).text = song.youtubeLink;
            Provider.of<AddPersCtrlProvider>(context, listen: false).text = song.addPers;

            SongPart refPart;
            if(song.refrenPart == null)
              refPart = SongPart.empty();
            else
              refPart = song.refrenPart;

            Provider.of<RefrenPartProvider>(context, listen: false).part = refPart;

            //SongPartsProvider songPartsProv = Provider.of<SongPartsProvider>(context, listen: false);
            //songPartsProv.set(song.songElements.map((e) => SongPart.from(e)).toList());

            TagsProvider tagsProv = Provider.of<TagsProvider>(context, listen: false);
            tagsProv.set(Tag.ALL_TAG_NAMES, song.tags);

            loadingProv.loading = false;
          }
        )
    );
  }

}