import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:harcapp_web/common/app_text_style.dart';
import 'package:harcapp_web/common/color_pack.dart';
import 'package:harcapp_web/common/core_comm_widgets/simple_button.dart';
import 'package:harcapp_web/common/dimen.dart';
import 'package:harcapp_web/common/download_file.dart';
import 'package:harcapp_web/songs/core_own_song/common.dart';
import 'package:harcapp_web/songs/core_song_management/song_raw.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class SaveSendWidget extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        Expanded(
            child: Consumer<SongFileNameDupErrProvider>(
              builder: (context, prov, child) => SimpleButton(
                  padding: EdgeInsets.all(Dimen.MARG_ICON),
                  margin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        MdiIcons.folderDownloadOutline,
                        color: prov.count==0?iconEnabledColor(context):iconDisabledColor(context),
                      ),
                      SizedBox(width: Dimen.MARG_ICON),
                      Text(
                        'Zapisz',
                        style: AppTextStyle(
                            fontWeight: weight.halfBold,
                            color: prov.count==0?iconEnabledColor(context):iconDisabledColor(context)
                        ),
                      )
                    ],
                  ),
                  onTap: prov.count!=0?null:(){

                    Map offSongMap = {};
                    Map confSongMap = {};

                    AllSongsProvider allSongsProv = Provider.of<AllSongsProvider>(context, listen: false);
                    List<SongRaw> allSongs = allSongsProv.songs;

                    allSongsProv.songs.sort(
                        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase())
                    );

                    int iterOff = 0;
                    int iterConf = 0;
                    for(SongRaw song in allSongs){
                      Map map = song.toMap(withFileName: false);
                      if(allSongsProv.isConf(song))
                        confSongMap[song.fileName] = {
                          'song': map,
                          'index': iterConf++
                        };
                      else
                        offSongMap[song.fileName] = {
                          'song': map,
                          'index': iterOff++
                        };
                    }

                    String code = jsonEncode({
                      'official': offSongMap,
                      'conf': confSongMap,
                    });

                    downloadFile(content: code, fileName: 'songs.hrcpsngs');
                  }
              ),
            )
        ),

        Expanded(
            child: SimpleButton(
                padding: EdgeInsets.all(Dimen.MARG_ICON),
                margin: EdgeInsets.zero,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(MdiIcons.sendCircleOutline),
                    SizedBox(width: Dimen.MARG_ICON),
                    Text(
                      'Prześlij',
                      style: AppTextStyle(fontWeight: weight.halfBold, color: iconEnabledColor(context)),
                    )
                  ],
                ),
                onTap: null
            )
        ),
        
      ],
    );
  }

}