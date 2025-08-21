import 'dart:convert';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_widgets/dialog/dialog.dart';
import 'package:harcapp_core/values/colors.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/comm_widgets/floating_container.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/song_book/song_editor/providers.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/song_book/song_tags.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_web/songs/left_panel/provider.dart';
import 'package:harcapp_web/songs/left_panel/song_tile.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import 'code_editor_dialog.dart';
import '../new_song_buttons.dart';

enum NewSongType{
  importSongs,
  newSong,
  newSongExample,
  newSongFromCode,
  newSongEmpty;
  
  IconData get icon{
    switch(this){
      case NewSongType.importSongs: return MdiIcons.trayArrowUp;
      case NewSongType.newSong: return MdiIcons.musicNotePlus;
      case NewSongType.newSongExample: return MdiIcons.musicCircleOutline;
      case NewSongType.newSongFromCode: return MdiIcons.codeBraces;
      case NewSongType.newSongEmpty: return MdiIcons.squareRoundedOutline;
    }
  }
  
  String get displayName{
    switch(this){
      case NewSongType.importSongs: return 'Importuj piosenki';
      case NewSongType.newSong: return 'Nowa piosenka';
      case NewSongType.newSongExample: return 'Przykładowa piosenka';
      case NewSongType.newSongFromCode: return 'Piosenka z kodu';
      case NewSongType.newSongEmpty: return 'Pusta piosenka';
    }
  }
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
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => SearchListProvider(
          AllSongsProvider.of(context).songs
      ))
    ],
    builder: (context, child) => Consumer<AllSongsProvider>(
        builder: (context, allSongsProv, child) =>
        allSongsProv.length==0?
        NoSongsWidget():
        Column(
          children: [

            Expanded(
              child: Consumer3<AllSongsProvider, CurrentItemProvider, SearchListProvider>(
                  builder: (context, allSongsProv, currItemProv, searchListProv, child) =>
                  CustomScrollView(
                    controller: controller,
                    physics: BouncingScrollPhysics(),
                    slivers: [

                      FloatingContainer.child(
                          child: Padding(
                            padding: EdgeInsets.all(Dimen.defMarg),
                            child: SearchField(),
                          ),
                          height: Dimen.iconFootprint + 2*Dimen.defMarg
                      ),

                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => SongTile(
                            searchListProv.get(index)!,
                            controller,
                            onTap: () => widget.onItemTap?.call(index),
                          ),
                          childCount: searchListProv.length
                        ),
                      )

                    ],
                  )
              ),
            ),

            Material(
              clipBehavior: Clip.hardEdge,
              color: cardEnab_(context),
              child: Container(
                color: backgroundIcon_(context),
                child: SizedBox(
                  height: Dimen.iconFootprint,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      Expanded(
                          child: Tooltip(
                            message: 'Importuj piosenki',
                            child: SimpleButton(
                                radius: 0,
                                child: Icon(NewSongType.importSongs.icon),
                                onTap: () => handleImportSongsTap(context)
                            ),
                          )
                      ),

                      Expanded(
                        child: Tooltip(
                          message: 'Nowa piosenka',
                          child: DropdownButtonHideUnderline(
                              child: DropdownButton2<NewSongType>(
                                dropdownStyleData: DropdownStyleData(
                                  padding: EdgeInsets.zero,
                                  offset: Offset(0, 3*Dimen.iconFootprint),
                                  width: 240,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(AppCard.bigRadius),
                                  ),
                                ),
                                customButton: SimpleButton.from(
                                    context: context,
                                    margin: EdgeInsets.zero,
                                    radius: null,
                                    icon: NewSongType.newSong.icon,
                                    onTap: null
                                ),
                                value: null,
                                onChanged: (value){
                                  switch(value){
                                    case NewSongType.newSongExample:
                                      handleExampleSongTap(context);
                                      break;
                                    case NewSongType.newSongFromCode:
                                      handleNewSongFromCode(context);
                                      break;
                                    case NewSongType.newSongEmpty:
                                      handleNewSongEmptyTap(context);
                                      break;
                                    default:
                                      break;
                                  }
                                },
                                items: [

                                  DropdownMenuItem<NewSongType>(
                                      value: NewSongType.newSongExample,
                                      child: Row(
                                        children: [
                                          Icon(NewSongType.newSongExample.icon),
                                          SizedBox(width: Dimen.iconMarg),
                                          Text(NewSongType.newSongExample.displayName, style: AppTextStyle(fontSize: Dimen.textSizeBig)),
                                        ],
                                      )
                                  ),

                                  DropdownMenuItem<NewSongType>(
                                    value: NewSongType.newSongFromCode,
                                    child: Row(
                                      children: [
                                        Icon(NewSongType.newSongFromCode.icon),
                                        SizedBox(width: Dimen.iconMarg),
                                        Text(NewSongType.newSongFromCode.displayName, style: AppTextStyle(fontSize: Dimen.textSizeBig)),
                                      ],
                                    ),
                                  ),

                                  DropdownMenuItem<NewSongType>(
                                      value: NewSongType.newSongEmpty,
                                      child: Row(
                                        children: [
                                          Icon(NewSongType.newSongEmpty.icon),
                                          SizedBox(width: Dimen.iconMarg),
                                          Text(NewSongType.newSongEmpty.displayName, style: AppTextStyle(fontSize: Dimen.textSizeBig)),
                                        ],
                                      )
                                  ),

                                ],
                              )
                          ),
                        ),
                      )

                    ],
                  ),
                ),
              ),
            )

          ],
        )
    )
  );

}

class SearchField extends StatelessWidget{

  @override
  Widget build(BuildContext context) => Material(
    elevation: AppCard.bigElevation,
    borderRadius: BorderRadius.circular(AppCard.bigRadius - 4),
    color: background_(context),
    child: Consumer<SearchListProvider>(
      builder: (context, prov, child) => Row(
        children: [
          IconButton(
            icon:
            prov.searchPhrase.isEmpty?
            Icon(MdiIcons.magnify, color: hintEnab_(context)):
            Icon(MdiIcons.close),

            onPressed:
            prov.searchPhrase.isEmpty?
            null:
                () => prov.changeSearchPhrase(''),
          ),
          Expanded(
            child: TextField(
                style: AppTextStyle(color: AppColors.textDefEnab),
                decoration: InputDecoration(
                    hintText: 'Szukaj',
                    hintStyle: AppTextStyle(color: AppColors.textHintEnab),
                    border: InputBorder.none
                ),
                onChanged: (text) => prov.changeSearchPhrase(text)
            ),
          )
        ],
      ),
    )
  );

}

class NoSongsWidget extends StatelessWidget{

  static const double paddingVal = 32.0;

  const NoSongsWidget();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(paddingVal),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        ImportSongsButton(),

        SizedBox(height: Dimen.sideMarg),

        Icon(MdiIcons.circleMedium, color: hintEnab_(context)),

        SizedBox(height: Dimen.sideMarg),

        NewExampleSongButton(),

        NewEmptySongButton(),

        NewSongFromCodeButton(),

      ],
    ),
  );

}

void handleImportSongsTap(BuildContext context) async {

  FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['hrcpsng'],
  );

  if(result==null)
    return;

  String code;
  try {
    code = utf8.decode(result.files.single.bytes!);
  } catch(e){
    AppScaffold.showMessage(context, 'Błąd odczytu pliku (błąd kodowania binarnego)');
    return;
  }

  AllSongsProvider allSongsProv = AllSongsProvider.of(context);

  Map<String, dynamic> songMap;
  try{
    songMap = jsonDecode(code);
  } catch(e){
    AppScaffold.showMessage(context, 'Błąd odczytu pliku (błąd dekodowania JSON)');
    return;
  }

  Map<String, dynamic>? offSongsMap;
  try {
    offSongsMap = songMap['official'];
  } catch(e){
    AppScaffold.showMessage(context, 'Błąd odczytu pliku (brak sekcji "official")');
    return;
  }

  List<SongRaw?> offSongs;
  if(offSongsMap == null) offSongs = [];
  else {
    offSongs = List.filled(offSongsMap.keys.length, null, growable: true);

    for(String fileName in offSongsMap.keys){
      try {
        Map<String, dynamic> songPackMap = offSongsMap[fileName];
        SongRaw song = SongRaw.fromApiRespMap(fileName, songPackMap['song']);

        if (!song.isOfficial) song.id = 'o!_' + song.id;
        offSongs[songPackMap['index']] = song;
      } catch(e){
        AppScaffold.showMessage(context, 'Błąd odczytu pliku (błąd dekodowania piosenki ${fileName})');
        return;
      }
    }
  }

  Map<String, dynamic>? confSongsMap = songMap['conf'];
  List<SongRaw?> confSongs;
  if(confSongsMap == null) confSongs = [];
  else{
    confSongs = List.filled(confSongsMap.keys.length, null, growable: true);

    for(String fileName in confSongsMap.keys){
      try {
        Map<String, dynamic> songPackMap = confSongsMap[fileName];
        SongRaw song = SongRaw.fromApiRespMap(fileName, songPackMap['song']);

        if (!song.isConfid) song.id = 'oc!_' + song.id;
        confSongs[songPackMap['index']] = song;
      } catch(e){
        AppScaffold.showMessage(context, 'Błąd odczytu pliku (błąd dekodowania piosenki ${fileName})');
        return;
      }
    }
  }

  List<SongRaw> songs = confSongs.cast<SongRaw>() + offSongs.cast<SongRaw>();
  if(songs.isEmpty) return;
  Map<SongRaw, bool> map = {};
  for(SongRaw song in songs) map[song] = confSongs.contains(song);
  allSongsProv.addAll(songs, map);
  displaySong(context, songs.first);

  SongFileNameDupErrProvider songFileNameDupErrProv = SongFileNameDupErrProvider.of(context);
  songFileNameDupErrProv.checkAllDups(context);

}

void handleExampleSongTap(BuildContext context){

  Map<String, List<SongRaw>>? allSongs = SimilarSongProvider.of(context).allSongs;

  if(allSongs == null) {
    AppScaffold.showMessage(context, 'Ładowanie piosenek. Spróbuj za chwilę');
    return;
  }

  SongRaw song = allSongs.values.firstWhere((songs) => songs.first.id == 'o!_addio_pomidory@kabaret_starszych_panow').first.copy(withLclId: true);

  AllSongsProvider.of(context).addOff(song);
  displaySong(context, song);

  SongFileNameDupErrProvider.of(context).checkAllDups(context);

}

void handleNewSongFromCode(BuildContext context){
  SongRaw song = handleNewSongEmptyTap(context);
  openDialog(
      context: context,
      builder: (context) => CodeEditorDialog(song, showInitCode: false)
  );
}

SongRaw handleNewSongEmptyTap(BuildContext context){

  SongRaw song = SongRaw.empty();
  song.id = 'o!_';
  AllSongsProvider.of(context).addOff(song);

  SongFileNameDupErrProvider songFileNameDupErrProv = SongFileNameDupErrProvider.of(context);
  songFileNameDupErrProv.checkAllDups(context);

  displaySong(context, song);

  return song;
}

void displaySong(BuildContext context, SongRaw song){
  SongPreviewProvider.of(context).showSong = true;
  CurrentItemProvider.of(context).song = song;

  BindTitleFileNameProvider.of(context).setSetBasedOnSong(song);
  SongEditorPanelProvider.notify_(context);
  TagsProvider.of(context).set(SongTag.ALL, song.tags);

  // SimilarSongProvider.of(context).title = song.title;
}
