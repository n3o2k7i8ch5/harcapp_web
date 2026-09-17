import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_widgets/app_dropdown.dart';
import 'package:harcapp_core/comm_widgets/dialog/base.dart';
import 'package:harcapp_core/song_book/import_hrcpsng.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/comm_widgets/floating_container.dart';
import 'package:harcapp_core/comm_widgets/search_field.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/song_book/song_editor/providers.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_web/songs/left_panel/song_tile.dart';
import 'package:harcapp_web/consts.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';

import 'code_editor_dialog.dart';
import 'import_selection_dialog.dart';
import 'song_file_drop_target.dart';
import 'email_song_dialog.dart';
import '../new_song_buttons.dart';

enum NewSongType implements IconTextEnum{
  importSongs,
  newSong,
  newSongExample,
  newSongFromCode,
  newSongEmpty,
  newSongFromEmail;

  IconData get icon{
    switch(this){
      case NewSongType.importSongs: return MdiIcons.trayArrowUp;
      case NewSongType.newSong: return MdiIcons.musicNotePlus;
      case NewSongType.newSongExample: return MdiIcons.musicCircleOutline;
      case NewSongType.newSongFromCode: return MdiIcons.codeBraces;
      case NewSongType.newSongEmpty: return MdiIcons.squareRoundedOutline;
      case NewSongType.newSongFromEmail: return MdiIcons.emailOutline;
    }
  }

  String get text{
    switch(this){
      case NewSongType.importSongs: return 'Importuj piosenki';
      case NewSongType.newSong: return 'Nowa piosenka';
      case NewSongType.newSongExample: return 'Przykładowa piosenka';
      case NewSongType.newSongFromCode: return 'Piosenka z kodu';
      case NewSongType.newSongEmpty: return 'Pusta piosenka';
      case NewSongType.newSongFromEmail: return 'Piosenka z mejla';
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
  Widget build(BuildContext context) => SongFileDropTarget(
    onFilesDropped: (filesBytes) => importSongsFromFiles(context, filesBytes),
    child: Consumer<AllSongsProvider>(
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
                              child: SearchField(
                                hint: 'Szukaj',
                                margin: EdgeInsets.zero,
                                color: background_(context),
                                onChanged: searchListProv.changeSearchPhrase,
                                onTextCleared: () => searchListProv.changeSearchPhrase(''),
                              ),
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
                          child: Consumer<EmailSongUnlockProvider>(
                            builder: (context, emailUnlockProv, _) => AppDropdown<NewSongType>(
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
                                    case NewSongType.newSongFromEmail:
                                      handleNewSongFromEmail(context);
                                      break;
                                    default:
                                      break;
                                  }
                                },
                                items: [
                                  NewSongType.newSongExample,
                                  NewSongType.newSongFromCode,
                                  NewSongType.newSongEmpty,
                                  if(emailUnlockProv.unlocked)
                                    NewSongType.newSongFromEmail,
                                ]
                            ),
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
    ),
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

        Consumer<EmailSongUnlockProvider>(
          builder: (context, prov, _) => prov.unlocked?
          NewEmailSongButton():
          const SizedBox.shrink(),
        ),

        NewSongFromCodeButton(),

      ],
    ),
  );

}

void handleImportSongsTap(BuildContext context) async {

  FilePickerResult? result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: [songFileExtension],
    withData: true,
  );

  if(result==null)
    return;

  importSongsFromFiles(context, [result.files.single.bytes!]);

}

void importSongsFromFiles(BuildContext context, List<Uint8List> filesBytes){

  List<SongRaw> parsedSongs = [];
  Map<SongRaw, bool> confMap = {};

  for(Uint8List bytes in filesBytes){
    var (List<SongRaw> songs, Map<SongRaw, bool> map) = parseSongsFromBytes(context, bytes);
    parsedSongs.addAll(songs);
    confMap.addAll(map);
  }

  if(parsedSongs.isEmpty) return;

  showImportSelectionDialog(
      context,
      songs: parsedSongs,
      onImport: (selectedSongs) => addImportedSongs(
          context,
          selectedSongs,
          {for(SongRaw song in selectedSongs) song: confMap[song]!}
      )
  );

}

/// Wczytuje piosenki z jednego pliku. Nic jeszcze nie dodaje do śpiewnika.
(List<SongRaw>, Map<SongRaw, bool>) parseSongsFromBytes(BuildContext context, Uint8List bytes) {

  String code;
  try {
    code = utf8.decode(bytes);
  } catch(e, s){
    AppScaffold.showMessage(context, text: 'Błąd odczytu pliku (błąd kodowania binarnego): $e');
    debugPrint('Błąd odczytu pliku: $e\n$s');
    return ([], {});
  }

  var songsResult;
  try {
    songsResult = importHrcpsng(code);
  } catch(e, s){
    AppScaffold.showMessage(context, text: 'Błąd importu piosenek: $e');
    debugPrint('Błąd importu piosenek: $e\n$s');
    return ([], {});
  }
  List<SongRaw> offSongs = songsResult.$1;
  List<SongRaw> confSongs = songsResult.$2;

  List<SongRaw> songs = confSongs.cast<SongRaw>() + offSongs.cast<SongRaw>();
  Map<SongRaw, bool> confMap = {for(SongRaw song in songs) song: confSongs.contains(song)};

  return (songs, confMap);

}

/// Dodaje do śpiewnika piosenki wybrane w oknie importu.
void addImportedSongs(BuildContext context, List<SongRaw> songs, Map<SongRaw, bool> confMap){

  if(songs.isEmpty) return;

  AllSongsProvider.of(context).addAll(songs, confMap);
  displaySong(context, songs.first);

  SearchListProvider.of(context).research();
  SongFileNameDupErrProvider.of(context).checkAllDups(context);

  AppScaffold.showMessage(
      context,
      text:
      songs.length == 1?
      'Zaimportowano 1 piosenkę':
      'Zaimportowano ${songs.length} piosenek',
      buttonText: 'Cofnij',
      onButtonPressed: () => undoSongImport(context, songs),
      duration: const Duration(seconds: 10)
  );

}

/// Cofa import - usuwa dokładnie te piosenki, które przed chwilą doszły.
void undoSongImport(BuildContext context, List<SongRaw> songs){

  if(!context.mounted) return;

  AllSongsProvider allSongsProv = AllSongsProvider.of(context);

  int remIndex = allSongsProv.songs.indexOf(songs.first);
  bool currentSongRemoved = songs.contains(CurrentItemProvider.of(context).song);

  allSongsProv.removeAll(songs);

  if(currentSongRemoved){
    if(remIndex >= allSongsProv.length) remIndex = allSongsProv.length - 1;

    if(remIndex < 0) SongPreviewProvider.of(context).showSong = false;
    else displaySong(context, allSongsProv.songs[remIndex]);
  }

  SearchListProvider.of(context).research();
  SongFileNameDupErrProvider.of(context).checkAllDups(context);
  SongEditorPanelProvider.of(context).notify();

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

void handleNewSongFromCode(BuildContext context) => openBaseDialog(
    context: context,
    maxWidth: songDialogWidth,
    builder: (context) => CodeEditorDialog(null)
);

void handleNewSongFromEmail(BuildContext context) => openBaseDialog(
    context: context,
    maxWidth: 2 * (songPreviewWidth + 24) + 2,
    builder: (context) => EmailSongDialog()
);

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
}
