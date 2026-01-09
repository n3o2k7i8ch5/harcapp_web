import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_widgets/app_button.dart';
import 'package:harcapp_core/comm_widgets/app_dropdown.dart';
import 'package:harcapp_core/comm_widgets/dialog/base.dart';
import 'package:harcapp_core/song_book/import_hrcpsng.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/comm_widgets/floating_container.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/song_book/song_editor/providers.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_web/songs/left_panel/provider.dart';
import 'package:harcapp_web/songs/left_panel/song_tile.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import 'code_editor_dialog.dart';
import '../new_song_buttons.dart';

enum NewSongType implements IconTextEnum{
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
  
  String get text{
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
  Widget build(BuildContext context) => Consumer<AllSongsProvider>(
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
                          child: AppDropdown<NewSongType>(
                              child: SimpleButton.from(
                                  context: context,
                                  margin: EdgeInsets.zero,
                                  radius: null,
                                  icon: NewSongType.newSong.icon,
                                  onTap: null
                              ),
                              onSelected: (value){
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
                                NewSongType.newSongExample,
                                NewSongType.newSongFromCode,
                                NewSongType.newSongEmpty,
                              ]
                          )

                      ),
                    )

                  ],
                ),
              ),
            ),
          )

        ],
      )
  );

}

class SearchField extends StatefulWidget{

  const SearchField();

  @override
  State<StatefulWidget> createState() => SearchFieldState();

}

class SearchFieldState extends State<SearchField> {

  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
      elevation: AppCard.bigElevation,
      borderRadius: BorderRadius.circular(AppCard.bigRadius - 4),
      color: background_(context),
      child: Consumer<SearchListProvider>(
        builder: (context, prov, child) => Row(
          children: [
            AppButton(
              icon:
              prov.searchPhrase.isEmpty?
              Icon(MdiIcons.magnify, color: hintEnab_(context)):
              Icon(MdiIcons.close),

              onTap:
              prov.searchPhrase.isEmpty?
              null:
              (){
                controller.clear();
                prov.changeSearchPhrase('');
              }
            ),
            Expanded(
              child: TextField(
                controller: controller,
                style: AppTextStyle(),
                decoration: InputDecoration(
                    hintText: 'Szukaj',
                    hintStyle: AppTextStyle(color: hintEnab_(context)),
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
  Widget build(BuildContext context) => Center(
    child: ListView(
      padding: const EdgeInsets.all(paddingVal),
      shrinkWrap: true,
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
    AppScaffold.showMessage(context, text: 'Błąd odczytu pliku (błąd kodowania binarnego)');
    return;
  }

  var songsResult;
  try {
    songsResult = importHrcpsng(code);
  } catch(e){
    AppScaffold.showMessage(context, text: e.toString());
    return;
  }
  List<SongRaw> offSongs = songsResult.$1;
  List<SongRaw> confSongs = songsResult.$2;

  AllSongsProvider allSongsProv = AllSongsProvider.of(context);

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
    AppScaffold.showMessage(context, text: 'Ładowanie piosenek. Spróbuj za chwilę');
    return;
  }

  SongRaw song = allSongs.values.firstWhere((songs) => songs.first.id == 'o!_addio_pomidory@kabaret_starszych_panow').first.copy(withId: true);

  AllSongsProvider.of(context).addOff(song);
  displaySong(context, song);

  SongFileNameDupErrProvider.of(context).checkAllDups(context);

}

void handleNewSongFromCode(BuildContext context) async {
  SongRaw song = handleNewSongEmptyTap(context);
  bool saved = false;
  await openBaseDialog(
      context: context,
      builder: (context) => CodeEditorDialog(
        song,
        showInitCode: false,
        onSaved: () => saved = true,
      )
  );
  if(!saved) AllSongsProvider.of(context).remove(song);

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
  TagsProvider.of(context).set(song.tags);

  // SimilarSongProvider.of(context).title = song.title;
}
