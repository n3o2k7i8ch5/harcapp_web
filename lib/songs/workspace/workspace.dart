

import 'dart:convert';
import 'dart:typed_data';

import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:file_picker_cross/file_picker_cross.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:harcapp_core/colors.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core_own_song/common.dart';
import 'package:harcapp_core_own_song/providers.dart';
import 'package:harcapp_core_own_song/song_raw.dart';
import 'package:harcapp_core_tags/tag_layout.dart';
import 'package:harcapp_web/articles/article_editor/common.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/workspace/workspace_item.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../generate_file_name.dart';

void importSongsFromCode(String code, {required Function(List<SongRaw?> offSongs, List<SongRaw?> confSongs) onFinished}){

  Map<String, dynamic> map = jsonDecode(code);

  Map<String, dynamic>? offSongsMap = map['official'];
  List<SongRaw?> offSongs;
  if(offSongsMap == null) offSongs = [];
  else {
    offSongs = List.filled(offSongsMap.keys.length, null, growable: true);

    for(String fileName in offSongsMap.keys){
      Map<String, dynamic> songPackMap = offSongsMap[fileName];
      Map<String, dynamic> songMap = songPackMap['song'];
      int index = songPackMap['index'];
      SongRaw song = SongRaw.fromMap(fileName, songMap);

      if(!song.isOfficial) song.fileName = 'o!_' + song.fileName;

      offSongs[index] = song;

    }
  }

  Map<String, dynamic>? confSongsMap = map['conf'];
  List<SongRaw?> confSongs;
  if(confSongsMap == null) confSongs = [];
  else{
    confSongs = List.filled(confSongsMap.keys.length, null, growable: true);

    for(String fileName in confSongsMap.keys){
      Map<String, dynamic> songPackMap = confSongsMap[fileName];
      Map<String, dynamic> songMap = songPackMap['song'];
      int index = songPackMap['index'];

      SongRaw song = SongRaw.fromMap(fileName, songMap);
      if(!song.isConfid) song.fileName = 'oc!_' + song.fileName;

      confSongs[index] = song;

    }
  }

  onFinished(offSongs, confSongs);
}

class WorkspacePart extends StatefulWidget{

  @override
  State<StatefulWidget> createState() => WorkspacePartState();

}

class WorkspacePartState extends State<WorkspacePart>{

  String? code;

  @override
  Widget build(BuildContext context) {

    return Consumer<AllSongsProvider>(
      builder: (context, allSongsProv, child){
        if(allSongsProv.length==0)
          return LoadWidget(
            onLoaded: (String code){
              importSongsFromCode(
                  code,
                  onFinished: (List<SongRaw?> offSongs, List<SongRaw?> confSongs){
                    List<SongRaw?> songs = confSongs + offSongs;
                    Map<SongRaw?, bool> map = {};
                    for(SongRaw? song in songs) map[song] = confSongs.contains(song);
                    allSongsProv.init(songs, map);
                  });

              Provider.of<SongEditorPanelProvider>(context, listen: false).notify();

              SongFileNameDupErrProvider songFileNameDupErrProv = Provider.of<SongFileNameDupErrProvider>(context, listen: false);
              songFileNameDupErrProv.checkAllDups(context);

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

  const LoadWidget({required this.onLoaded});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SimpleButton.from(
            context: context,
            icon: MdiIcons.fileUploadOutline,
            text: 'Importuj piosenki',
            onTap: ()async{

              FilePickerCross filePicker = await FilePickerCross.importFromStorage(
                  type: FileTypeCross.any,
                  fileExtension: '.hrcpsng'
              );

              //FilePickerCross filePicker = FilePickerCross();
              //bool picked = await filePicker.pick();
              if(filePicker.fileName != null){
                Uint8List uint8List = filePicker.toUint8List();
                String code = utf8.decode(uint8List);
                onLoaded(code);
              }
            }

        ),

        SimpleButton.from(
            context: context,
            icon: MdiIcons.musicNotePlus,
            text: 'Nowa piosenka',
            onTap: ()async{

              SongRaw song = SongRaw.empty();
              song.fileName = 'o!_';
              Provider.of<AllSongsProvider>(context, listen: false).addOff(song);

              SongFileNameDupErrProvider songFileNameDupErrProv = Provider.of<SongFileNameDupErrProvider>(context, listen: false);
              songFileNameDupErrProv.checkAllDups(context);

              displaySong(context, song);

            }

        )
      ],
    );
  }

}

class SongListView extends StatefulWidget{

  const SongListView();

  @override
  State<StatefulWidget> createState() => SongListViewState();

}

class SongListViewState extends State<SongListView>{

  ScrollController? controller;

  late BuildContext itemContext;

  @override
  void initState() {
    controller = ScrollController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SearchListProvider(
          Provider.of<AllSongsProvider>(context, listen: false).songs
        ))
      ],
      builder: (context, child){

        return Stack(
          children: [

            Column(
              children: [

                Consumer<WorkspaceBlockProvider>(
                  builder: (context, workspaceBlockProv, child) => Material(
                    color: cardEnab_(context),
                    elevation: 3,
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(Dimen.ICON_MARG),
                          child: Icon(MdiIcons.magnify, color: hintEnab_(context)),
                        ),
                        Expanded(
                          child: TextField(
                            readOnly: workspaceBlockProv.blocked!,
                            style: AppTextStyle(color: AppColors.text_def_enab),
                            decoration: InputDecoration(
                                hintText: 'Szukaj',
                                hintStyle: AppTextStyle(color: AppColors.text_hint_enab),
                                border: InputBorder.none
                            ),
                            onChanged: (text){

                              SearchListProvider searchListProv = Provider.of<SearchListProvider>(context, listen: false);
                              searchListProv.changeSearchPhrase(text);

                            },
                          ),
                        )
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: Consumer3<AllSongsProvider, WorkspaceBlockProvider, SearchListProvider>(
                      builder: (context, allSongsProv, workspaceBlockProv, searchListProv, child){

                        return DraggableScrollbar.rrect(
                          scrollbarTimeToFade: Duration(seconds: 2),
                          backgroundColor: accent_(context),
                          child: ListView.builder(
                            controller: controller,
                            itemCount: searchListProv.length,
                            physics: workspaceBlockProv.blocked!?NeverScrollableScrollPhysics():BouncingScrollPhysics(),
                            itemBuilder: (context, index) => GestureDetector(
                              onTap: workspaceBlockProv.blocked!?hideItemPopUps:null,
                              child: ItemWidget(
                                searchListProv.get(index),
                                controller,
                                index,
                                onShowMoreButt: (BuildContext context){
                                  this.itemContext = context;
                                },
                              ),
                            )
                          ),
                          controller: controller!,
                        );
                      }
                  ),
                ),

                Consumer<WorkspaceBlockProvider>(
                    builder: (context, workspaceBlockProv, child) => Material(
                      color: cardEnab_(context),
                      elevation: 6,
                      child: Row(
                        children: [
                          Expanded(
                            child: IconButton(
                                icon: Icon(MdiIcons.fileUploadOutline),
                                onPressed: workspaceBlockProv.blocked!?null:() async {

                                  FilePickerCross filePicker = await FilePickerCross.importFromStorage(
                                      type: FileTypeCross.any,
                                      fileExtension: '.hrcpsng'
                                  );

                                  if(filePicker.fileName==null)
                                    return;

                                  Uint8List uint8List = filePicker.toUint8List();
                                  String code = utf8.decode(uint8List);

                                  AllSongsProvider allSongsProv = Provider.of<AllSongsProvider>(context, listen: false);

                                  importSongsFromCode(
                                      code,
                                      onFinished: (List<SongRaw?> offSongs, List<SongRaw?> confSongs){
                                        List<SongRaw?> songs = confSongs + offSongs;
                                        Map<SongRaw?, bool> map = {};
                                        for(SongRaw? song in songs) map[song] = confSongs.contains(song);
                                        allSongsProv.addAll(songs, map);
                                      });

                                  SongFileNameDupErrProvider songFileNameDupErrProv = Provider.of<SongFileNameDupErrProvider>(context, listen: false);
                                  songFileNameDupErrProv.checkAllDups(context);

                                }
                            ),
                          ),

                          Expanded(
                            child: IconButton(
                                icon: Icon(MdiIcons.musicNotePlus),
                                onPressed: workspaceBlockProv.blocked!?null:(){

                                  SongRaw song = SongRaw.empty();
                                  song.fileName = 'o!_';
                                  Provider.of<AllSongsProvider>(context, listen: false).addOff(song);

                                  SongFileNameDupErrProvider songFileNameDupErrProv = Provider.of<SongFileNameDupErrProvider>(context, listen: false);
                                  songFileNameDupErrProv.checkAllDups(context);

                                  displaySong(context, song);

                                }
                            ),
                          ),

                        ],
                      ),
                    )
                )
              ],
            ),

          ],
        );
      },
    );

  }

  void hideItemPopUps(){
    Provider.of<ShowMoreButtProvider>(itemContext, listen: false).value = false;
    Provider.of<WorkspaceBlockProvider>(context, listen: false).blocked = false;
  }

}

void displaySong(BuildContext context, SongRaw? song){
  CurrentItemProvider currItemProv = Provider.of<CurrentItemProvider>(context, listen: false);
  currItemProv.song = song;

  if(song == null) return;

  Provider.of<TitleCtrlProvider>(context, listen: false).text = song.title;
  /*
  Provider.of<AuthorCtrlProvider>(context, listen: false).text = song?.author??'';
  Provider.of<PerformerCtrlProvider>(context, listen: false).text = song?.performer??'';
  Provider.of<ComposerCtrlProvider>(context, listen: false).text = song?.composer??'';
  Provider.of<YTCtrlProvider>(context, listen: false).text = song?.youtubeLink??'';
  Provider.of<AddPersCtrlProvider>(context, listen: false).text = song?.addPers??'';
*/

  SongPart? refPart;
  if(song.refrenPart == null)
    refPart = SongPart.empty();
  else
    refPart = song.refrenPart;

  Provider.of<BindTitleFileNameProvider>(context, listen: false).bind =
      song.fileName == generateFileName(title: song.title);

  Provider.of<RefrenPartProvider>(context, listen: false).part = refPart!;

  Provider.of<SongEditorPanelProvider>(context, listen: false).notify();

  TagsProvider tagsProv = Provider.of<TagsProvider>(context, listen: false);
  tagsProv.set(Tag.ALL_TAG_NAMES, song.tags);
}

class SearchListProvider extends ChangeNotifier{

  late bool anySearchPhrase;

  late List<SongRaw?> currSongList;

  List<SongRaw?>? _allSongs;

  List<SongRaw?>? get allSongs => _allSongs;

  SearchListProvider(this._allSongs){
    anySearchPhrase = false;
    currSongList = [];
  }

  changeSearchPhrase(String text){
    anySearchPhrase = text.length!=0;
    currSongList = [];

    for(SongRaw? song in allSongs!){
      if(remPolChars(song!.title).contains(remPolChars(text)))
        currSongList.add(song);
    }

    notifyListeners();

  }

  int get length{
    if(anySearchPhrase)
      return currSongList.length;
    else
      return allSongs!.length;
  }

  SongRaw? get(int index){
    if(anySearchPhrase)
      return currSongList[index];
    else
      return allSongs![index];
  }

}