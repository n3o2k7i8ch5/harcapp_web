import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_navigator.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_bar.dart';
import 'package:harcapp_core/comm_widgets/app_button.dart';
import 'package:harcapp_core/comm_widgets/dialog/base.dart';
import 'package:harcapp_core/comm_widgets/search_field.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/consts.dart';
import 'package:harcapp_web/songs/utils/song_search.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

/// Pokazuje listę piosenek z importowanego pliku i pozwala wybrać, które
/// faktycznie mają trafić do śpiewnika.
void showImportSelectionDialog(
    BuildContext context,
    { required List<SongRaw> songs,
      required void Function(List<SongRaw> selectedSongs) onImport,
    }) => openBaseDialog(
    context: context,
    maxWidth: songDialogWidth,
    builder: (context) => ImportSelectionDialog(songs: songs, onImport: onImport)
);

class ImportSelectionDialog extends StatefulWidget{

  final List<SongRaw> songs;
  final void Function(List<SongRaw> selectedSongs) onImport;

  const ImportSelectionDialog({required this.songs, required this.onImport, super.key});

  @override
  State<StatefulWidget> createState() => ImportSelectionDialogState();

}

class ImportSelectionDialogState extends State<ImportSelectionDialog>{

  static const String HINT_NO_TITLE = 'Brak tytułu.';

  List<SongRaw> get songs => widget.songs;

  late Set<SongRaw> selected;
  late TextEditingController searchController;
  String searchPhrase = '';

  List<SongRaw> get displayedSongs{
    if(searchPhrase.isEmpty) return songs;
    return searchSongs(songs, searchPhrase);
  }

  @override
  void initState() {
    selected = songs.toSet();
    searchController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void toggle(SongRaw song) => setState((){
    if(selected.contains(song)) selected.remove(song);
    else selected.add(song);
  });

  void toggleAll(){
    List<SongRaw> displayed = displayedSongs;
    bool allSelected = displayed.every(selected.contains);
    setState((){
      if(allSelected) selected.removeAll(displayed);
      else selected.addAll(displayed);
    });
  }

  void import(){
    if(selected.isEmpty) return;
    List<SongRaw> selectedSongs = songs.where(selected.contains).toList();
    popPage(context);
    widget.onImport(selectedSongs);
  }

  @override
  Widget build(BuildContext context){

    List<SongRaw> displayed = displayedSongs;
    bool allDisplayedSelected = displayed.isNotEmpty && displayed.every(selected.contains);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        AppBarX(title: 'Wybierz piosenki do importu'),

        SearchField(
          hint: 'Szukaj',
          controller: searchController,
          onChanged: (text) => setState(() => searchPhrase = text),
          onTextCleared: () => setState(() => searchPhrase = ''),
          trailing: Tooltip(
            message: allDisplayedSelected?'Odznacz wszystkie':'Zaznacz wszystkie',
            child: AppButton(
                icon: Icon(
                    allDisplayedSelected?
                    MdiIcons.checkboxMultipleMarkedOutline:
                    MdiIcons.checkboxMultipleBlankOutline
                ),
                onTap: displayed.isEmpty?null:toggleAll
            ),
          ),
        ),

        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: displayed.length,
            itemBuilder: (context, index){

              SongRaw song = displayed[index];
              bool isSelected = selected.contains(song);

              String title = song.title;
              if(title.isEmpty) title = HINT_NO_TITLE;

              return ListTile(
                onTap: () => toggle(song),
                leading: Icon(
                    isSelected?
                    MdiIcons.checkboxMarkedOutline:
                    MdiIcons.checkboxBlankOutline,
                    color: isSelected?iconEnab_(context):hintEnab_(context)
                ),
                title: Text(
                  title,
                  style: AppTextStyle(
                      fontSize: Dimen.textSizeBig,
                      color: isSelected?textEnab_(context):hintEnab_(context)
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  song.id,
                  style: AppTextStyle(color: hintEnab_(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        ),

        SizedBox(
          width: double.infinity,
          child: SimpleButton.from(
            context: context,
            margin: const EdgeInsets.all(Dimen.defMarg),
            color: backgroundIcon_(context),
            icon: MdiIcons.trayArrowDown,
            text:
            selected.isEmpty?
            'Nic nie zaznaczono':
            'Importuj zaznaczone (${selected.length} z ${songs.length})',
            textColor: selected.isEmpty?hintEnab_(context):iconEnab_(context),
            onTap: selected.isEmpty?null:import
          ),
        )

      ],
    );
  }

}
