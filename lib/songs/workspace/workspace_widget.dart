import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_core/colors.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core_own_song/providers.dart';
import 'package:harcapp_core_own_song/song_raw.dart';
import 'package:harcapp_core_tags/tag_layout.dart';
import 'package:harcapp_web/articles/article_editor/common.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/workspace/workspace_tile.dart';
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

class WorkspaceWidget extends StatefulWidget{

  final void Function(int)? onItemTap;

  const WorkspaceWidget({this.onItemTap});

  @override
  State<StatefulWidget> createState() => WorkspaceWidgetState();

}

class WorkspaceWidgetState extends State<WorkspaceWidget>{

  @override
  Widget build(BuildContext context) => Consumer<AllSongsProvider>(
    builder: (context, allSongsProv, child){
      if(allSongsProv.length==0)
        return LoadWidget();
      else
        return SongListView(
          onItemTap: widget.onItemTap,
        );

    },
  );

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

      SizedBox(height: Dimen.SIDE_MARG),

      Icon(MdiIcons.circleMedium, color: hintEnab_(context)),

      SizedBox(height: Dimen.SIDE_MARG),

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
    builder: (context, child){

      return Stack(
        children: [

          Column(
            children: [

              Padding(
                padding: EdgeInsets.all(Dimen.defMarg),
                child: Material(
                  borderRadius: BorderRadius.circular(AppCard.bigRadius - 4),
                  color: backgroundIcon_(context),
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(Dimen.ICON_MARG),
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
                          onChanged: (text){

                            SearchListProvider searchListProv = SearchListProvider.of(context);
                            searchListProv.changeSearchPhrase(text);

                          },
                        ),
                      )
                    ],
                  ),
                ),
              ),

              Expanded(
                child: Consumer3<AllSongsProvider, CurrentItemProvider, SearchListProvider>(
                    builder: (context, allSongsProv, currItemProv, searchListProv, child){

                      return DraggableScrollbar.rrect(
                        scrollbarTimeToFade: Duration(seconds: 2),
                        backgroundColor: accent_(context),
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: Dimen.defMarg),
                          controller: controller,
                          itemCount: searchListProv.length,
                          physics: BouncingScrollPhysics(),
                          itemBuilder: (context, index) => WorkspaceTile(
                              searchListProv.get(index)!,
                              controller,
                              index,
                              onShowMoreButt: (BuildContext context) =>
                              this.itemContext = context,
                              onTap: () => widget.onItemTap?.call(index),
                          ),
                          separatorBuilder: (context, index) => SizedBox(height: Dimen.defMarg),
                        ),
                        controller: controller,
                      );
                    }
                ),
              ),

              Padding(
                padding: EdgeInsets.all(Dimen.defMarg),
                child: Material(
                  borderRadius: BorderRadius.circular(AppCard.bigRadius - 4),
                  clipBehavior: Clip.hardEdge,
                  color: backgroundIcon_(context),
                  child: SizedBox(
                    height: Dimen.ICON_FOOTPRINT,
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
          ),

        ],
      );
    },
  );

}

void handleImportSongTap(BuildContext context) async {

  FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['hrcpsng'],
  );

  // FilePicker filePicker = await FilePicker.importFromStorage(
  //   type: FileTypeCross.any,
  //   fileExtension: '.hrcpsng'
  // );

  if(result==null)
    return;

  Uint8List uint8List = result.files.single.bytes!;
  String code = utf8.decode(uint8List);

  AllSongsProvider allSongsProv = Provider.of<AllSongsProvider>(context, listen: false);

  importSongsFromCode(
      code,
      onFinished: (List<SongRaw> offSongs, List<SongRaw> confSongs){
        List<SongRaw> songs = confSongs + offSongs;
        Map<SongRaw, bool> map = {};
        for(SongRaw song in songs) map[song] = confSongs.contains(song);
        allSongsProv.addAll(songs, map);
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

  SongRaw song = SimilarSongProvider.of(context).allSongs!.values.firstWhere((songs) => songs.first.lclId == 'o!_addio_pomidory@kabaret_starszych_panow').first;

  AllSongsProvider.of(context).addOff(song);
  displaySong(context, song);

  SongFileNameDupErrProvider.of(context).checkAllDups(context);

}

void displaySong(BuildContext context, SongRaw song){
  Provider.of<ShowSongProvider>(context, listen: false).showSong = true;
  CurrentItemProvider.of(context).song = song;

  // Provider.of<TitleCtrlProvider>(context, listen: false).text = song.title;
  // Provider.of<HidTitlesProvider>(context, listen: false).controllers = song.hidTitles.map((title) => TextEditingController(text: title)).toList();
  /*
  Provider.of<AuthorCtrlProvider>(context, listen: false).text = song?.author??'';
  Provider.of<PerformerCtrlProvider>(context, listen: false).text = song?.performer??'';
  Provider.of<ComposerCtrlProvider>(context, listen: false).text = song?.composer??'';
  Provider.of<YTCtrlProvider>(context, listen: false).text = song?.youtubeLink??'';
  Provider.of<AddPersCtrlProvider>(context, listen: false).text = song?.addPers??'';
*/

  BindTitleFileNameProvider.of(context).setSetBasedOnSong(song);
  SongEditorPanelProvider.notify_(context);
  TagsProvider.of(context).set(Tag.ALL_TAG_NAMES, song.tags);

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