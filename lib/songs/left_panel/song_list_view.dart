import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_core/colors.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core/song_book/song_editor/providers.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/song_book/song_tags.dart';
import 'package:harcapp_web/articles/article_editor/common.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_web/songs/left_panel/song_tile.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../song_editor_panel.dart';

void importSongsFromCode(String code, {required Function(List<SongRaw> offSongs, List<SongRaw> confSongs) onFinished}){

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
      SongRaw song = SongRaw.fromRespMap(fileName, songMap);

      if(!song.isOfficial) song.lclId = 'o!_' + song.lclId;

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

      SongRaw song = SongRaw.fromRespMap(fileName, songMap);
      if(!song.isConfid) song.lclId = 'oc!_' + song.lclId;

      confSongs[index] = song;

    }
  }

  onFinished(offSongs.cast<SongRaw>(), confSongs.cast<SongRaw>());
}

class LoadWidget extends StatelessWidget{

  const LoadWidget();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.max,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [

      Consumer<SimilarSongProvider>(
          builder: (context, prov, child) => SimpleButton.from(
              icon: MdiIcons.musicBoxOutline,
              textColor: prov.allSongs == null?iconDisab_(context):iconEnab_(context),
              text: 'Przykład piosenki',
              onTap: prov.allSongs == null?null:() => handleExampleSongTap(context)
          )
      ),

      SizedBox(height: Dimen.sideMarg),

      Icon(MdiIcons.circleMedium, color: hintEnab_(context)),

      SizedBox(height: Dimen.sideMarg),

      SimpleButton.from(
          context: context,
          icon: MdiIcons.fileUploadOutline,
          text: 'Importuj piosenki',
          onTap: () => handleImportSongTap(context)
      ),

      SimpleButton.from(
          context: context,
          icon: MdiIcons.musicNotePlus,
          text: 'Nowa piosenka',
          onTap: () => handleNewSongTap(context)
      ),

    ],
  );

}

class SongListView extends StatefulWidget{

  final void Function(int)? onItemTap;

  const SongListView({this.onItemTap});

  @override
  State<StatefulWidget> createState() => SongListViewState();

}

class SongListViewState extends State<SongListView>{

  late ScrollController controller;

  late BuildContext itemContext;

  @override
  void initState() {
    controller = ScrollController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => SearchListProvider(
          AllSongsProvider.of(context).songs
      ))
    ],
    builder: (context, child) => Consumer<AllSongsProvider>(
        builder: (context, allSongsProv, child){

          if(allSongsProv.length==0)
            return LoadWidget();

          return Column(
            children: [

              Padding(
                padding: EdgeInsets.only(
                  top: Dimen.defMarg,
                  left: Dimen.defMarg,
                  right: Dimen.defMarg
                ),
                child: Material(
                  elevation: AppCard.bigElevation,
                  borderRadius: BorderRadius.circular(AppCard.bigRadius - 4),
                  color: background_(context),
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(Dimen.iconMarg),
                        child: Icon(MdiIcons.magnify, color: hintEnab_(context)),
                      ),
                      Expanded(
                        child: TextField(
                          style: AppTextStyle(color: AppColors.text_def_enab),
                          decoration: InputDecoration(
                              hintText: 'Szukaj',
                              hintStyle: AppTextStyle(color: AppColors.text_hint_enab),
                              border: InputBorder.none
                          ),
                          onChanged: (text) => SearchListProvider.of(context).changeSearchPhrase(text)
                        ),
                      )
                    ],
                  ),
                ),
              ),

              Expanded(
                child: Consumer3<AllSongsProvider, CurrentItemProvider, SearchListProvider>(
                    builder: (context, allSongsProv, currItemProv, searchListProv, child) => ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: Dimen.defMarg),
                      controller: controller,
                      itemCount: searchListProv.length,
                      physics: BouncingScrollPhysics(),
                      itemBuilder: (context, index) => SongTile(
                        searchListProv.get(index)!,
                        controller,
                        index,
                        onShowMoreButt: (BuildContext context) =>
                        this.itemContext = context,
                        onTap: () => widget.onItemTap?.call(index),
                      ),
                      separatorBuilder: (context, index) => SizedBox(height: Dimen.defMarg),
                    )
                ),
              ),

              Padding(
                padding: EdgeInsets.all(Dimen.defMarg),
                child: Material(
                  borderRadius: BorderRadius.circular(AppCard.bigRadius - 4),
                  clipBehavior: Clip.hardEdge,
                  color: backgroundIcon_(context),
                  child: SizedBox(
                    height: Dimen.iconFootprint,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        Expanded(
                          child: Consumer<SimilarSongProvider>(
                              builder: (context, prov, child) => Tooltip(
                                message: 'Przykład piosenki',
                                child: SimpleButton(
                                    radius: 0,
                                    child: Icon(
                                      MdiIcons.musicBoxOutline,
                                      color: prov.allSongs == null?iconDisab_(context):iconEnab_(context),
                                    ),
                                    onTap: prov.allSongs == null?null:() => handleExampleSongTap(context)
                                ),
                              )
                          ),
                        ),

                        Expanded(
                            child: Tooltip(
                              message: 'Importuj piosenki',
                              child: SimpleButton(
                                  radius: 0,
                                  child: Icon(MdiIcons.fileUploadOutline),
                                  onTap: () => handleImportSongTap(context)
                              ),
                            )
                        ),

                        Expanded(
                            child: Tooltip(
                              message: 'Nowa piosenka',
                              child: SimpleButton(
                                  radius: 0,
                                  child: Icon(MdiIcons.musicNotePlus),
                                  onTap: () => handleNewSongTap(context)
                              ),
                            )
                        ),

                      ],
                    ),
                  ),
                ),
              )
            ],
          );

        })
  );

}

void handleImportSongTap(BuildContext context) async {

  FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['hrcpsng'],
  );

  if(result==null)
    return;

  Uint8List uint8List = result.files.single.bytes!;
  String code = utf8.decode(uint8List);

  AllSongsProvider allSongsProv = AllSongsProvider.of(context);

  importSongsFromCode(
      code,
      onFinished: (List<SongRaw> offSongs, List<SongRaw> confSongs){
        List<SongRaw> songs = confSongs + offSongs;
        if(songs.isEmpty) return;
        Map<SongRaw, bool> map = {};
        for(SongRaw song in songs) map[song] = confSongs.contains(song);
        allSongsProv.addAll(songs, map);
        displaySong(context, songs.first);
      });

  SongFileNameDupErrProvider songFileNameDupErrProv = SongFileNameDupErrProvider.of(context);
  songFileNameDupErrProv.checkAllDups(context);

}

void handleNewSongTap(BuildContext context){

  SongRaw song = SongRaw.empty();
  song.lclId = 'o!_';
  Provider.of<AllSongsProvider>(context, listen: false).addOff(song);

  SongFileNameDupErrProvider songFileNameDupErrProv = SongFileNameDupErrProvider.of(context);
  songFileNameDupErrProv.checkAllDups(context);

  displaySong(context, song);

}

void handleExampleSongTap(BuildContext context){

  SongRaw song = SimilarSongProvider.of(context).allSongs!.values.firstWhere((songs) => songs.first.lclId == 'o!_addio_pomidory@kabaret_starszych_panow').first.copy(withLclId: true);

  AllSongsProvider.of(context).addOff(song);
  displaySong(context, song);

  SongFileNameDupErrProvider.of(context).checkAllDups(context);

}

void displaySong(BuildContext context, SongRaw song){
  Provider.of<ShowSongProvider>(context, listen: false).showSong = true;
  CurrentItemProvider.of(context).song = song;

  BindTitleFileNameProvider.of(context).setSetBasedOnSong(song);
  SongEditorPanelProvider.notify_(context);
  TagsProvider.of(context).set(SongTag.ALL, song.tags);

  SimilarSongProvider.of(context).title = song.title;
}

class SearchListProvider extends ChangeNotifier{

  static SearchListProvider of(BuildContext context) => Provider.of<SearchListProvider>(context, listen: false);

  late bool anySearchPhrase;

  late List<SongRaw?> currSongList;

  late String searchPhrase;

  List<SongRaw> _allSongs;

  List<SongRaw> get allSongs => _allSongs;

  SearchListProvider(this._allSongs){
    searchPhrase = '';
    anySearchPhrase = false;
    currSongList = [];
  }

  void changeSearchPhrase(String text){
    searchPhrase = text;
    anySearchPhrase = text.length!=0;
    currSongList = [];

    for(SongRaw? song in allSongs){
      if(remPolChars(song!.title).contains(remPolChars(text)))
        currSongList.add(song);
    }

    notifyListeners();

  }

  void research() => changeSearchPhrase(searchPhrase);

  int get length{
    if(anySearchPhrase)
      return currSongList.length;
    else
      return allSongs.length;
  }

  SongRaw? get(int index){
    if(anySearchPhrase)
      return currSongList[index];
    else
      return allSongs[index];
  }

}