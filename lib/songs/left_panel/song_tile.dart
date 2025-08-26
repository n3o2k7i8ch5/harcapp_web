import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_navigator.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_dropdown.dart';
import 'package:harcapp_core/comm_widgets/dialog/alert_dialog.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/song_book/song_editor/providers.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_web/songs/left_panel/provider.dart';
import 'package:harcapp_web/songs/left_panel/song_list_view.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../song_editor_panel.dart';
import 'code_editor_dialog.dart';
import '../providers.dart';
import 'contrib_rules_dialog.dart';
import 'song_id_editor_dialog.dart';

class SongTile extends StatefulWidget{

  final SongRaw song;
  final ScrollController controller;
  final void Function()? onTap;

  const SongTile(this.song, this.controller, {this.onTap, Key? key}):super(key: key);

  @override
  State<StatefulWidget> createState() => SongTileState();
}

class SongTileState extends State<SongTile>{

  SongRaw get song => widget.song;

  static const String HINT_FILE_TITLE = 'Brak tytułu.';
  static const String HINT_FILE_NAME = 'Brak nazwy pliku.';

  static const String MENU_CONF = 'conf';
  static const String MENU_CODE = 'code';
  static const String MENU_NAME = 'name';

  @override
  Widget build(BuildContext context) => Consumer2<SongFileNameDupErrProvider, CurrentItemProvider>(
    builder: (context, songFileNameDupErrProv, currItemProv, child){

      String title = song.title;
      if(title.length==0) title = HINT_FILE_TITLE;

      String lclId = song.id;
      if(lclId.length==0) lclId = HINT_FILE_NAME;

      return ListTile(
        onTap: () {
          displaySong(context, song);
          widget.onTap?.call();
        },
        title: Row(
          children: [

            Consumer<SimilarSongProvider>(
              builder: (context, prov, child){
                if(prov.hasSimilarSong(song.title))
                  return Padding(
                    padding: EdgeInsets.only(right: Dimen.defMarg),
                    child: Tooltip(
                      message: 'Piosenka o takim tytule już jest w śpiewniku',
                      child: Icon(SimilarSongWidget.icon, color: hintEnab_(context)),
                    ),
                  );

                return Container();
              },
            ),

            if(song.contributorData != null)
            Padding(
              padding: EdgeInsets.only(right: Dimen.defMarg),
              child: Tooltip(
                message: 'Piosenka o potwierdzonym regulaminie współtwórców',
                child: Icon(MdiIcons.scriptTextKeyOutline),
              )
            ),

            Expanded(
              child: Text(
                title,
                style: AppTextStyle(fontSize: Dimen.textSizeBig),
                maxLines: 1,
                overflow: TextOverflow.ellipsis
              )
            )

          ],
        ),
        subtitle: Text(
          lclId,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle(
            color:
            lclId==HINT_FILE_NAME || songFileNameDupErrProv.hasDup(song)?
            Colors.red:hintEnab_(context)
          )
        ),
        selected: currItemProv.song == song,
        selectedTileColor: backgroundIcon_(context),
        trailing: _MoreButton(song: song),
      );

    },
  );

}

enum _MoreButtonItem implements IconTextEnum {
  editId,
  editCode,
  makeConfidential,
  makeNotConfidential,
  confirmContribRules,
  delete;

  @override
  IconData get icon {
    switch(this){
      case _MoreButtonItem.editId: return MdiIcons.formTextbox;
      case _MoreButtonItem.editCode: return MdiIcons.codeTags;
      case _MoreButtonItem.makeConfidential: return MdiIcons.eyeOffOutline;
      case _MoreButtonItem.makeNotConfidential: return MdiIcons.eyeOutline;
      case _MoreButtonItem.confirmContribRules: return MdiIcons.scriptTextKeyOutline;
      case _MoreButtonItem.delete: return MdiIcons.trashCanOutline;
    }
  }

  @override
  String get text {
    switch(this){
      case _MoreButtonItem.editId:
        return 'Edytuj identyfikator';
      case _MoreButtonItem.editCode:
        return 'Edytuj kod';
      case _MoreButtonItem.makeConfidential:
        return 'Ukryj';
      case _MoreButtonItem.makeNotConfidential:
        return 'Pokaż';
      case _MoreButtonItem.confirmContribRules:
        return 'Potwierdź regulamin';
      case _MoreButtonItem.delete:
        return 'Usuń';
    }
  }

}

class _MoreButton extends StatelessWidget{

  final SongRaw song;

  const _MoreButton({required this.song, super.key});

  void switchConfidential(BuildContext context){
    if(song.isConfid) song.id = 'o!_' + song.id.substring(4);
    else song.id = 'oc!_' + song.id.substring(3);

    AllSongsProvider.of(context).set(song, song.isConfid);
    SongFileNameDupErrProvider.of(context).checkAllDups(context);
  }

  void deleteSong(BuildContext context) => showAlertDialog(
    context,
    content: 'Czy na pewno chcesz <b>usunać</b> piosenkę "<b>${song.title}</b>"?',
    title: 'Ostrożnie...',
    actionBuilder: (context) => [
      AlertDialogButton(
          text: 'Usuń',
          onTap: (){
            AllSongsProvider allSongsProv = AllSongsProvider.of(context);

            int remIndex = allSongsProv.songs.indexOf(song);
            allSongsProv.remove(song);

            if(CurrentItemProvider.of(context).song == song){

              if(remIndex == allSongsProv.length)
                remIndex--;

              if(remIndex < 0) SongPreviewProvider.of(context).showSong = false;
              else displaySong(context, allSongsProv.songs[remIndex]);
            }

            SearchListProvider.of(context).research();
            SongFileNameDupErrProvider.of(context).checkAllDups(context);
            SongEditorPanelProvider.of(context).notify();

            popPage(context);
          }
      ),
      AlertDialogButton(
        text: 'Jednak nie',
        onTap: () => popPage(context),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => AppDropdown<_MoreButtonItem>(
    icon: Icon(MdiIcons.dotsVertical),
    onSelected: (_MoreButtonItem item) {
      switch(item){
        case _MoreButtonItem.editId:
          showSongIdEditorDialog(context, song);
          break;
        case _MoreButtonItem.editCode:
          showCodeEditorDialog(context, song);
          break;
        case _MoreButtonItem.makeConfidential:
        case _MoreButtonItem.makeNotConfidential:
          switchConfidential(context);
          break;
        case _MoreButtonItem.confirmContribRules:
          showContribRulesDialog(context);
          break;
        case _MoreButtonItem.delete:
          deleteSong(context);
          break;
      }
    },
    itemBuilder: (BuildContext context) => [
      AppDropdownButton(context, _MoreButtonItem.editId),
      AppDropdownButton(context, _MoreButtonItem.editCode),
      AppDropdownButton(context, song.isConfid?_MoreButtonItem.makeNotConfidential:_MoreButtonItem.makeConfidential),
      AppDropdownButton(context, _MoreButtonItem.confirmContribRules),
      AppDropdownButton(context, _MoreButtonItem.delete),
    ],
  );

}