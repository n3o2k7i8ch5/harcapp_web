import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_text_field_hint.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../providers.dart';


class FileNameEditorDialog extends StatefulWidget{

  final SongRaw song;

  FileNameEditorDialog(this.song, {super.key});

  @override
  State<StatefulWidget> createState() => FileNameEditorDialogState();

}

class FileNameEditorDialogState extends State<FileNameEditorDialog>{

  SongRaw get song => widget.song;

  bool get isConfid => allSongsProvider.isConf(song)!;

  late AllSongsProvider allSongsProvider;
  late TextEditingController textController;

  @override
  void initState() {
    allSongsProvider = Provider.of<AllSongsProvider>(context, listen: false);
    textController = TextEditingController(text: song.lclId.substring(song.isConfid?4:3));
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 400,
      child: Padding(
        padding: EdgeInsets.all(Dimen.iconMarg),
        child: Material(
            elevation: 6.0,
            borderRadius: BorderRadius.circular(AppCard.bigRadius),
            child: Padding(
              padding: EdgeInsets.only(top: Dimen.defMarg, bottom: Dimen.defMarg, right: Dimen.defMarg),
              child: ListTile(
                title: Row(
                  children: [
                    Text(isConfid?'oc!_':'o!_', style: AppTextStyle(fontWeight: weight.bold, fontSize: Dimen.textSizeBig),),
                    Expanded(
                        child: Consumer<SongFileNameDupErrProvider>(
                          builder: (context, prov, child) => AppTextFieldHint(
                              hint: 'podaj_nazwę_pliku:',
                              hintTop: prov.hasDup(song)?'Nazwa pliku zajęta':'Nazwa pliku',
                              controller: textController,
                              style: TextStyle(color: prov.hasDup(song)?Colors.red:textEnab_(context)),
                              hintStyle: TextStyle(color: hintEnab_(context)),
                              onAnyChanged: (texts){

                                song.lclId = (isConfid?'oc!_':'o!_') + texts[0];

                                prov.checkAllDups(context);
                              }
                          ),
                        )
                    )
                  ],
                ),
                trailing: IconButton(
                    icon: Icon(MdiIcons.check, color: iconEnab_(context)),
                    onPressed: (){
                      BindTitleFileNameProvider.of(context).setSetBasedOnSong(song);
                      SongFileNameDupErrProvider.of(context).checkAllDups(context);
                      Navigator.pop(context);
                    }
                ),
              ),
            )
        ),
      ),
    ),
  );

}
