import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_web/songs/left_panel/song_list_view.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/save_send_widget.dart';
import 'package:provider/provider.dart';

import 'song_list_title_widget.dart';

class LeftPanel extends StatelessWidget{

  final void Function(int)? onItemTap;

  const LeftPanel({this.onItemTap, Key? key}):super(key: key);

  @override
  Widget build(BuildContext context) => Column(
    children: [

      Padding(
        padding: EdgeInsets.only(left: Dimen.iconMarg, top: Dimen.iconMarg),
        child: SongListTileWidget()
      ),

      Consumer<AllSongsProvider>(
          builder: (context, allSongProv, child) =>
          allSongProv.length==0?
          Container():
          Padding(
            padding: EdgeInsets.only(bottom: Dimen.defMarg),
            child: SaveSendWidget(),
          )
      ),

      Expanded(
        child: Material(
          color: cardEnab_(context),
          borderRadius: BorderRadius.circular(AppCard.bigRadius),
          child: SongListView(onItemTap: onItemTap),
        ),
      ),

    ],
  );

}