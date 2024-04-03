import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core/song_book/song_editor/providers.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_web/songs/left_panel/song_list_view.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../song_editor_panel.dart';
import 'code_editor_dialog.dart';
import '../providers.dart';
import 'file_name_editor_dialog.dart';

class SongTile extends StatefulWidget{

  final SongRaw song;
  final ScrollController controller;
  final int index;
  final void Function(BuildContext context)? onShowMoreButt;
  final void Function()? onTap;

  const SongTile(this.song, this.controller, this.index, {this.onShowMoreButt, this.onTap, Key? key}):super(key: key);

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

      String lclId = song.lclId;
      if(lclId.length==0) lclId = HINT_FILE_NAME;

      return SimpleButton(
        radius: AppCard.bigRadius - 4,
        onTap: () {
          displaySong(context, song);
          widget.onTap?.call();
        },
        child: ListTile(
          title: Row(
            children: [

              Consumer<SimilarSongProvider>(
                builder: (context, prov, child){
                  if(prov.hasSimilarSong(song.title))
                    return Padding(
                      padding: EdgeInsets.only(right: Dimen.defMarg),
                      child: Tooltip(
                        message: 'Piosenka o takim tytule już jest w śpiewniku',
                        child: Icon(MdiIcons.musicBoxMultiple, color: hintEnab_(context)),
                      ),
                    );

                  return Container();
                },
              ),

              Expanded(
                  child: Text(
                      title,
                      style: AppTextStyle(
                          fontSize: Dimen.textSizeBig
                      ),
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [

              SimpleButton.from(
                  context: context,
                  margin: EdgeInsets.zero,
                  radius: 100,
                  icon: MdiIcons.close,
                  onTap: () =>
                      AppScaffold.showMessage(context, 'Przytrzymaj przycisk, by usunąć piosenkę.'),
                  onLongPress: (){

                    AllSongsProvider allSongsProv = AllSongsProvider.of(context);

                    int remIndex = allSongsProv.songs.indexOf(song);
                    allSongsProv.remove(song);

                    if(currItemProv.song == song){

                      if(remIndex == allSongsProv.length)
                        remIndex--;

                      if(remIndex < 0)
                        ShowSongProvider.of(context).showSong = false;
                      else
                        displaySong(context, allSongsProv.songs[remIndex]);

                    }

                    SearchListProvider searchListProv = SearchListProvider.of(context);
                    searchListProv.research();

                    SongFileNameDupErrProvider.of(context).checkAllDups(context);
                    SongEditorPanelProvider.of(context).notify();

                  }
              ),

              DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    dropdownStyleData: DropdownStyleData(
                      width: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppCard.bigRadius),
                      ),
                    ),
                    buttonStyleData: ButtonStyleData(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100)
                      ),
                    ),
                    customButton: SimpleButton.from(
                        context: context,
                        margin: EdgeInsets.zero,
                        icon: MdiIcons.dotsHorizontal,
                        onTap: null
                    ),
                    value: null,
                    onChanged: (value){

                      switch(value){
                        case MENU_CONF:
                          if(song.isConfid) song.lclId = 'o!_' + song.lclId.substring(4);
                          else song.lclId = 'oc!_' + song.lclId.substring(3);

                          AllSongsProvider.of(context).set(song, song.isConfid);

                          SongFileNameDupErrProvider songFileNameDupErrProv = Provider.of<SongFileNameDupErrProvider>(context, listen: false);
                          songFileNameDupErrProv.checkAllDups(context);

                          break;
                        case MENU_CODE:
                          showDialog(
                              context: context,
                              builder: (context) => CodeEditorDialog(song)
                          );
                          break;
                        case MENU_NAME:
                          showDialog(
                              context: context,
                              builder: (context) => FileNameEditorDialog(song)
                          );
                          break;
                      }

                    },
                    items: [
                      DropdownMenuItem<String>(
                          value: MENU_CONF,
                          child: Row(
                            children: [
                              Icon(song.isConfid?MdiIcons.eyeOutline:MdiIcons.eyeOffOutline),
                              SizedBox(width: Dimen.iconMarg),
                              Text(song.isConfid?'Pokaż':'Ukryj', style: AppTextStyle(fontSize: Dimen.textSizeBig)),
                            ],
                          )
                      ),

                      DropdownMenuItem<String>(
                        value: MENU_CODE,
                        child: Row(
                          children: [
                            Icon(MdiIcons.codeTags),
                            SizedBox(width: Dimen.iconMarg),
                            Text('Edytuj kod', style: AppTextStyle(fontSize: Dimen.textSizeBig)),
                          ],
                        ),
                      ),

                      DropdownMenuItem<String>(
                          value: MENU_NAME,
                          child: Row(
                            children: [
                              Icon(MdiIcons.formTextbox),
                              SizedBox(width: Dimen.iconMarg),
                              Text('Edytuj nazwę', style: AppTextStyle(fontSize: Dimen.textSizeBig)),
                            ],
                          )
                      )

                    ],
                  )
              ),

            ],
          ),
        ),
      );

    },
  );

}
