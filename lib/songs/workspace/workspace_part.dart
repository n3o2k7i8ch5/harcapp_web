import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/save_send_widget.dart';
import 'package:harcapp_web/songs/workspace/workspace_widget.dart';
import 'package:provider/provider.dart';

import 'workspace_title_widget.dart';

class WorkspacePart extends StatelessWidget{

  final void Function(int)? onItemTap;

  const WorkspacePart({this.onItemTap, Key? key}):super(key: key);

  @override
  Widget build(BuildContext context) => Column(
    children: [

      Padding(
        padding: EdgeInsets.only(left: Dimen.ICON_MARG, top: Dimen.ICON_MARG),
        child: WorkspaceTitleWidget()
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
          borderRadius: BorderRadius.circular(AppCard.bigRadius),
          child: WorkspaceWidget(onItemTap: onItemTap),
        ),
      ),

    ],
  );

}