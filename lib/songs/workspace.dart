

import 'dart:convert';
import 'dart:typed_data';

import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:file_picker_cross/file_picker_cross.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:harcapp_web/common/app_card.dart';
import 'package:harcapp_web/common/app_text_style.dart';
import 'package:harcapp_web/common/color_pack.dart';
import 'package:harcapp_web/common/colors.dart';
import 'package:harcapp_web/common/core_comm_widgets/app_text_field_hint.dart';
import 'package:harcapp_web/common/core_comm_widgets/simple_button.dart';
import 'package:harcapp_web/common/dimen.dart';
import 'package:harcapp_web/songs/core_own_song/providers.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import 'core_own_song/common.dart';
import 'core_song_management/song_raw.dart';
import 'core_tags/tag_layout.dart';

List<SongRaw> importSongsFromCode(String code){

  Map<String, dynamic> map = jsonDecode(code);
  Map<String, dynamic> offSongs = map['official'] as Map<String, dynamic>;

  List<SongRaw> songs = List.filled(offSongs.keys.length, null, growable: true);

  for(String fileName in offSongs.keys){

    Map<String, dynamic> songPackMap = offSongs[fileName];

    Map<String, dynamic> songMap = songPackMap['song'];
    int index = songPackMap['index'];

    songs[index] = SongRaw.fromMap(fileName, songMap);
  }

  return songs;
}

class WorkspacePart extends StatefulWidget{

  @override
  State<StatefulWidget> createState() => WorkspacePartState();

}

class WorkspacePartState extends State<WorkspacePart>{

  String code;

  @override
  Widget build(BuildContext context) {

    return Consumer<AllSongsProvider>(
      builder: (context, allSongsProv, child){
        if(allSongsProv.length==0)
          return LoadWidget(
            onLoaded: (String code){
              allSongsProv.songs = importSongsFromCode(code);
              setState(() => this.code = code);
            },
          );
        else
          return SongListView();

      },
    );

  }
}

class LoadWidget extends StatelessWidget{

  final Function(String code) onLoaded;

  const LoadWidget({@required this.onLoaded});

  @override
  Widget build(BuildContext context) {
    return  Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        WorkspaceButton(
            icon: MdiIcons.fileUploadOutline,
            text: 'Importuj piosenki',
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

        WorkspaceButton(
            icon: MdiIcons.musicNotePlus,
            text: 'Nowa piosenka',
            onTap: ()async{

              SongRaw song = SongRaw.empty();
              Provider.of<AllSongsProvider>(context, listen: false).add(song);

              displaySong(context, song);

            }

        )
      ],
    );
  }

}

class WorkspaceButton extends StatelessWidget{

  final IconData icon;
  final String text;
  final void Function() onTap;

  const WorkspaceButton({
    @required this.icon,
    @required this.text,
    @required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SimpleButton(
          radius: 100,
          margin: EdgeInsets.all(Dimen.MARG_ICON),
          padding: EdgeInsets.all(Dimen.MARG_ICON),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                  padding: EdgeInsets.all(Dimen.MARG_ICON),
                  child: Icon(icon)
              ),
              Text(text, style: AppTextStyle(fontSize: Dimen.TEXT_SIZE_BIG, fontWeight: weight.halfBold), textAlign: TextAlign.center),
              SizedBox(width: Dimen.MARG_ICON)
            ],
          ),
          onTap: onTap
      ),
    );
  }

}

class SongListView extends StatefulWidget{

  const SongListView();

  @override
  State<StatefulWidget> createState() => SongListViewState();

}

class SongListViewState extends State<SongListView>{

  @override
  Widget build(BuildContext context) {

    ScrollController controller = ScrollController();

    return Column(
      children: [

        Consumer<SongFileNameBlockProvider>(
          builder: (context, songFileNameBlockProv, child) => Material(
            color: songFileNameBlockProv.blocked?Colors.black.withOpacity(0.05):Colors.transparent,
            shadowColor: Colors.black26,
            elevation: 3,
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.all(Dimen.MARG_ICON),
                  child: Icon(MdiIcons.magnify, color: hintEnabled(context)),
                ),
                Expanded(
                  child: TextField(
                    readOnly: songFileNameBlockProv.blocked,
                    style: AppTextStyle(color: AppColors.text_def_enab),
                    decoration: InputDecoration(
                        hintText: 'Szukaj',
                        hintStyle: AppTextStyle(color: AppColors.text_hint_enab),
                        border: InputBorder.none
                    ),
                  ),
                )
              ],
            ),
          ),
        ),

        Expanded(
          child: Consumer2<AllSongsProvider, SongFileNameBlockProvider>(
            builder: (context, allSongsProv, songFileNameBlockProv, child){

              return DraggableScrollbar.rrect(
                scrollbarTimeToFade: Duration(seconds: 2),
                backgroundColor: accentColor(context),
                child: ListView.builder(
                  controller: controller,
                  itemCount: allSongsProv.length,
                  physics: songFileNameBlockProv.blocked?NeverScrollableScrollPhysics():BouncingScrollPhysics(),
                  itemBuilder: (context, index) => ItemWidget(allSongsProv.songs[index], controller, index),
                ),
                controller: controller,
              );
            }
          ),
        ),

        Consumer<SongFileNameBlockProvider>(
          builder: (context, songFileNameBlockProv, child) => Material(
            color: songFileNameBlockProv.blocked?Colors.black.withOpacity(0.05):Colors.transparent,
            elevation: 6,
            child: Row(
              children: [
                Expanded(
                  child: IconButton(
                      icon: Icon(MdiIcons.fileUploadOutline),
                      onPressed: songFileNameBlockProv.blocked?null:() async {

                        FilePickerCross filePicker = FilePickerCross();
                        bool picked = await filePicker.pick();
                        if(!picked)
                          return;

                        Uint8List uint8List = filePicker.toUint8List();
                        String code = utf8.decode(uint8List);
                        List<SongRaw> songs = importSongsFromCode(code);
                        AllSongsProvider allSongsProv = Provider.of<AllSongsProvider>(context, listen: false);
                        allSongsProv.addAll(songs);

                        SongFileNameDupErrProvider songFileNameDupErrProv = Provider.of<SongFileNameDupErrProvider>(context, listen: false);

                        for(SongRaw song1 in allSongsProv.songs)
                          for(SongRaw song2 in allSongsProv.songs)
                            if(song1 != song2 && song1.fileName == song2.fileName){
                              songFileNameDupErrProv.putPair(song1, song2);
                            }

                      }
                  ),
                ),

                Expanded(
                  child: IconButton(
                      icon: Icon(MdiIcons.musicNotePlus),
                      onPressed: songFileNameBlockProv.blocked?null:(){

                        SongRaw song = SongRaw.empty();
                        Provider.of<AllSongsProvider>(context, listen: false).add(song);

                        displaySong(context, song);

                      }
                  ),
                ),

              ],
            ),
          )
        )
      ],
    );

  }

}

class ItemWidget extends StatefulWidget{

  final SongRaw song;
  final ScrollController controller;
  final int index;

  const ItemWidget(this.song, this.controller, this.index);

  @override
  State<StatefulWidget> createState() => ItemWidgetState();
}

class ItemWidgetState extends State<ItemWidget>{

  SongRaw get song => widget.song;

  static const String HINT_FILE_TITLE = 'Brak tytułu.';
  static const String HINT_FILE_NAME = 'Brak nazwy pliku.';

  static const double LIST_TILE_HEIGHT = 64;

  bool editing;

  @override
  void initState() {
    editing = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Consumer<SongFileNameDupErrProvider>(
      builder: (context, prov, child){

        String title = song.title;
        if(title.length==0) title = HINT_FILE_TITLE;

        String fileName = song.fileName;
        if(fileName.length==0) fileName = HINT_FILE_NAME;

        bool fileNameTaken = prov.hasAny(song);

        if(editing)
          return AppCard(
            elevation: 6.0,
            padding: EdgeInsets.zero,
            child: ListTile(
              title: AppTextFieldHint(
                  hint: 'Podaj nazwę pliku:',
                  hintTop: fileNameTaken?'Nazwa pliku zajęta':'Nazwa pliku',
                  controller: TextEditingController(text: song.fileName),
                  style: TextStyle(color: fileNameTaken?Colors.red:textEnabled(context)),
                  hintStyle: TextStyle(color: hintEnabled(context)),
                  onChanged: (text){

                    List<SongRaw> allSongs = Provider.of<AllSongsProvider>(context, listen: false).songs;
                    for(SongRaw song in allSongs)
                      if(song != this.song && text == song.fileName){
                        prov.putPair(song, this.song);
                      }else{
                        prov.removePair(song, this.song);
                      }

                    song.fileName = text;
                  }
              ),
              trailing: IconButton(
                  icon: Icon(MdiIcons.check, color: iconEnabledColor(context)),
                  onPressed: (){
                    setState(() => editing = false);
                    Provider.of<SongFileNameBlockProvider>(context, listen: false).blocked = false;
                  }
              ),
            ),
          );

        return Consumer2<CurrentItemProvider, SongFileNameBlockProvider>(
            builder: (context, currItemProv, songFileNameBlockProv, child) => ListTile(
                dense: true,
                title: Text(title, style: AppTextStyle(color: songFileNameBlockProv.blocked?hintEnabled(context):textEnabled(context))),
                subtitle: Text(fileName, style: AppTextStyle(color: fileName==HINT_FILE_NAME || fileNameTaken?Colors.red:hintEnabled(context))),
                selected: currItemProv.song == song,
                tileColor: songFileNameBlockProv.blocked?
                Colors.black.withOpacity(0.05):Colors.transparent,
                selectedTileColor: Colors.black12,
                onTap: songFileNameBlockProv.blocked?null:() {

                  LoadingProvider loadingProv = Provider.of<LoadingProvider>(context, listen: false);
                  displaySong(context, song);
                  loadingProv.loading = false;
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    IconButton(
                        icon: Icon(MdiIcons.formTextbox),
                        onPressed: songFileNameBlockProv.blocked?null:(){
                          setState(() => editing = true);
                          songFileNameBlockProv.blocked = true;

                          widget.controller.animateTo(
                              widget.index*LIST_TILE_HEIGHT,
                              duration: Duration(milliseconds: 1000),
                              curve: Curves.easeOutQuad
                          );
                        }
                    ),

                    IconButton(
                        icon: Icon(MdiIcons.close),
                        onPressed: songFileNameBlockProv.blocked?null:(){

                          AllSongsProvider allSongsProv = Provider.of<AllSongsProvider>(context, listen: false);

                          int remIndex = allSongsProv.songs.indexOf(song);
                          allSongsProv.remove(song);

                          if(currItemProv.song == song){

                            if(remIndex == allSongsProv.length)
                              remIndex--;

                            if(remIndex < 0)
                              displaySong(context, null);
                            else
                              displaySong(context, allSongsProv.songs[remIndex]);
                          }
                        }
                    ),

                  ],
                )
            )
        );

      },
    );

  }

}

void displaySong(BuildContext context, SongRaw song){
  CurrentItemProvider currItemProv = Provider.of<CurrentItemProvider>(context, listen: false);
  currItemProv.song = song;

  Provider.of<TitleCtrlProvider>(context, listen: false).text = song?.title??'';
  Provider.of<AuthorCtrlProvider>(context, listen: false).text = song?.author??'';
  Provider.of<PerformerCtrlProvider>(context, listen: false).text = song?.performer??'';
  Provider.of<YTCtrlProvider>(context, listen: false).text = song?.youtubeLink??'';
  Provider.of<AddPersCtrlProvider>(context, listen: false).text = song?.addPers??'';

  SongPart refPart;
  if(song?.refrenPart == null)
    refPart = SongPart.empty();
  else
    refPart = song.refrenPart;

  Provider.of<RefrenPartProvider>(context, listen: false).part = refPart;

  TagsProvider tagsProv = Provider.of<TagsProvider>(context, listen: false);
  tagsProv.set(Tag.ALL_TAG_NAMES, song?.tags??[]);
}