import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/web_utils_web.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/song_book/song_contribution_rules.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/router.dart';
import 'package:harcapp_web/songs/left_panel/song_list_view.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/save_send_widget.dart';
import 'package:provider/provider.dart';

import 'song_list_title_widget.dart';

class LeftPanel extends StatelessWidget{

  final void Function(int)? onItemTap;
  final bool withBackButton;

  const LeftPanel({this.onItemTap, this.withBackButton = false, Key? key}):super(key: key);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [

      Padding(
        padding: EdgeInsets.only(left: Dimen.iconMarg, top: Dimen.iconMarg),
        child: SongListTileWidget(withBackButton: withBackButton),
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
          clipBehavior: Clip.hardEdge,
          borderRadius: BorderRadius.circular(AppCard.bigRadius),
          child: SongListView(onItemTap: onItemTap),
        ),
      ),

      SizedBox(height: Dimen.defMarg),

      SimpleButton.from(
        context: context,
        margin: EdgeInsets.zero,
        color: cardEnab_(context),
        text: songContributionRulesTitle,
        onTap: () => openPathInNewTab(pathSongContributionRules)
      )

    ],
  );

}