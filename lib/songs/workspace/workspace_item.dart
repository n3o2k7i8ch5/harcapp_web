
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_button.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/comm_widgets/app_text_field_hint.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core_own_song/providers.dart';
import 'package:harcapp_core_own_song/song_raw.dart';
import 'package:harcapp_web/songs/workspace/workspace.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pretty_json/pretty_json.dart';
import 'package:provider/provider.dart';

import '../providers.dart';

class ItemWidget extends StatefulWidget{

  final SongRaw song;
  final ScrollController controller;
  final int index;
  final void Function(BuildContext context) onShowMoreButt;

  const ItemWidget(this.song, this.controller, this.index, {this.onShowMoreButt, Key key}):super(key: key);

  @override
  State<StatefulWidget> createState() => ItemWidgetState();
}

class ItemWidgetState extends State<ItemWidget>{

  SongRaw get song => widget.song;

  static const String HINT_FILE_TITLE = 'Brak tytułu.';
  static const String HINT_FILE_NAME = 'Brak nazwy pliku.';

  static const double LIST_TILE_HEIGHT = 64;

  @override
  Widget build(BuildContext context) {

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ShowMoreButtProvider()),
        ChangeNotifierProvider(create: (context) => ShowFileNameEditorProvider())
      ],
      builder: (context, child){
        return Consumer<SongFileNameDupErrProvider>(
          builder: (context, prov, child){

            String title = song.title;
            if(title.length==0) title = HINT_FILE_TITLE;

            String fileName = song.fileName;
            if(fileName.length==0) fileName = HINT_FILE_NAME;

            bool fileNameTaken = prov.hasAny(song);

            return Stack(
              children: [

                Consumer2<CurrentItemProvider, WorkspaceBlockProvider>(
                    builder: (context, currItemProv, workspaceBlockProv, child) => ListTile(
                        dense: true,
                        title: Text(title, style: AppTextStyle(color: workspaceBlockProv.blocked?hintEnabled(context):textEnabled(context))),
                        subtitle: Text(fileName, style: AppTextStyle(color: fileName==HINT_FILE_NAME || fileNameTaken?Colors.red:hintEnabled(context))),
                        selected: currItemProv.song == song,
                        tileColor: workspaceBlockProv.blocked?
                        Colors.black.withOpacity(0.05):Colors.transparent,
                        selectedTileColor: Colors.black12,
                        onTap: workspaceBlockProv.blocked?null:() {

                          LoadingProvider loadingProv = Provider.of<LoadingProvider>(context, listen: false);
                          displaySong(context, song);
                          loadingProv.loading = false;
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            AppButton(
                                icon: Icon(MdiIcons.close),
                                onTap: (){
                                  AppScaffold.showMessage(context, 'Przytrzymaj przycisk, by usunąć piosenkę.');
                                },
                                onLongPress: workspaceBlockProv.blocked?null:(){

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

                                  SongFileNameDupErrProvider errProv = Provider.of<SongFileNameDupErrProvider>(context, listen: false);

                                  List<SongRaw> errSongs = errProv.get(song);
                                  if(errSongs != null)
                                    for(SongRaw errSongOth in errSongs)
                                      errProv.removePair(song, errSongOth);

                                  Provider.of<SongEditorPanelProvider>(context, listen: false).notify();

                                }
                            ),

                            IconButton(
                                icon: Icon(MdiIcons.dotsHorizontal),
                                onPressed: workspaceBlockProv.blocked?null:(){
                                  workspaceBlockProv.blocked = true;
                                  Provider.of<ShowMoreButtProvider>(context, listen: false).value = true;
                                  if(widget.onShowMoreButt!=null) widget.onShowMoreButt(context);
                                }
                            ),

                          ],
                        )
                    )
                ),

                Positioned(
                  child: Consumer<ShowMoreButtProvider>(
                    builder: (context, prov, child){
                      if(prov.value)
                        return _MoreButtonsWidget(this);
                      else
                        return Container();
                    },
                  ),
                  top: 0,
                  bottom: 0,
                  right: 0,
                ),

                Positioned.fill(
                  child: Consumer<ShowFileNameEditorProvider>(
                    builder: (context, prov, child) => prov.value?_FileNameEditorWidget(this):Container(),
                  )
                )

              ],
            );

          },
        );
      },
    );

  }

  //void hideMoreButts() => Provider.of<ShowMoreButtProvider>(context, listen: false).value = false;

}

class _FileNameEditorWidget extends StatelessWidget{

  ItemWidgetState parent;

  SongRaw get song => parent.song;

  _FileNameEditorWidget(this.parent);

  @override
  Widget build(BuildContext context) {

    SongFileNameDupErrProvider errProv = Provider.of<SongFileNameDupErrProvider>(context, listen: false);
    bool fileNameTaken = Provider.of<SongFileNameDupErrProvider>(context, listen: false).hasAny(song);

    AllSongsProvider allSongsProvider = Provider.of<AllSongsProvider>(context, listen: false);
    bool isConfid = allSongsProvider.isConf(song);

    return AppCard(
      elevation: 6.0,
      padding: EdgeInsets.zero,
      child: ListTile(
        title: Row(
          children: [
            Text(isConfid?'oc!_':'o!_', style: AppTextStyle(fontWeight: weight.bold, fontSize: Dimen.TEXT_SIZE_BIG),),
            Expanded(
                child: AppTextFieldHint(
                    hint: 'podaj_nazwę_pliku:',
                    hintTop: fileNameTaken?'Nazwa pliku zajęta':'Nazwa pliku',
                    controller: TextEditingController(text: song.fileName.substring(isConfid?4:3)),
                    style: TextStyle(color: fileNameTaken?Colors.red:textEnabled(context)),
                    hintStyle: TextStyle(color: hintEnabled(context)),
                    onChanged: (text){

                      song.fileName = (isConfid?'oc!_':'o!_') + text;

                      SongFileNameDupErrProvider songFileNameDupErrProv = Provider.of<SongFileNameDupErrProvider>(context, listen: false);
                      songFileNameDupErrProv.chedkDupsFor(context, song);
                    }
                )
            )
          ],
        ),
        trailing: IconButton(
            icon: Icon(MdiIcons.check, color: iconEnabledColor(context)),
            onPressed: (){
              Provider.of<ShowFileNameEditorProvider>(context, listen: false).value = false;
              Provider.of<WorkspaceBlockProvider>(context, listen: false).blocked = false;
            }
        ),
      ),
    );
  }

}

class _MoreButtonsWidget extends StatelessWidget{

  ItemWidgetState parent;

  SongRaw get song => parent.song;

  _MoreButtonsWidget(this.parent);

  @override
  Widget build(BuildContext context) {

    return AppCard(
      elevation: AppCard.bigElevation,
      child: Row(
        children: [

          Consumer<AllSongsProvider>(
            builder: (context, allSongsProv, child){

              bool isConf = allSongsProv.isConf(song);

              return IconButton(
                  icon: Icon(isConf?MdiIcons.eyeOffOutline:MdiIcons.eyeOutline),
                  onPressed: (){
                    if(isConf) song.fileName = 'o!_' + song.fileName.substring(4);
                    else song.fileName = 'oc!_' + song.fileName.substring(3);

                    allSongsProv.set(song, !isConf);

                    SongFileNameDupErrProvider songFileNameDupErrProv = Provider.of<SongFileNameDupErrProvider>(context, listen: false);
                    songFileNameDupErrProv.checkAllDups(context);
                  }
              );
            },
          ),

          IconButton(
              icon: Icon(MdiIcons.codeTags),
              onPressed: (){
                Provider.of<ShowCodeEditorProvider>(context, listen: false).text = prettyJson(jsonDecode(song.toCode()), indent: 4);
                Provider.of<ShowCodeEditorProvider>(context, listen: false).song = song;
                Provider.of<ShowCodeEditorProvider>(context, listen: false).value = true;

                Provider.of<ShowMoreButtProvider>(context, listen: false).value = false;
                Provider.of<WorkspaceBlockProvider>(context, listen: false).blocked = false;

              }
          ),

          IconButton(
              icon: Icon(MdiIcons.formTextbox),
              onPressed: (){
                Provider.of<ShowFileNameEditorProvider>(context, listen: false).value = true;
                Provider.of<WorkspaceBlockProvider>(context, listen: false).blocked = true;

                Provider.of<ShowMoreButtProvider>(context, listen: false).value = false;
                //Provider.of<WorkspaceBlockProvider>(context, listen: false).blocked = false;
/*
                parent.widget.controller.animateTo(
                    parent.widget.index*ItemWidgetState.LIST_TILE_HEIGHT,
                    duration: Duration(milliseconds: 1000),
                    curve: Curves.easeOutQuad
                );
 */
              }
          ),

          IconButton(
              icon: Icon(MdiIcons.dotsVertical),
              onPressed: (){
                Provider.of<WorkspaceBlockProvider>(context, listen: false).blocked = false;
                Provider.of<ShowMoreButtProvider>(context, listen: false).value = false;
              }
          ),

        ],
      ),
    );

  }

}

class ShowMoreButtProvider extends ChangeNotifier{

  bool _value;

  ShowMoreButtProvider(){
    _value = false;
  }

  bool get value => _value;
  set value(bool v){
    _value = v;
    notifyListeners();
  }
}

class ShowFileNameEditorProvider extends ChangeNotifier{

  bool _value;

  ShowFileNameEditorProvider(){
    _value = false;
  }

  bool get value => _value;
  set value(bool v){
    _value = v;
    notifyListeners();
  }
}