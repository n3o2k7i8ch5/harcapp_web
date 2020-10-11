
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:harcapp_web/common/app_card.dart';
import 'package:harcapp_web/common/color_pack.dart';
import 'package:harcapp_web/common/dimen.dart';
import 'package:harcapp_web/songs/core_own_song/common.dart';
import 'package:harcapp_web/songs/core_own_song/providers.dart';
import 'package:harcapp_web/songs/core_own_song/song_part_card.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';


class RefrenTemplate extends StatelessWidget{

  final Function(SongPart, RefrenPartProvider) onPartTap;
  final Function(bool value) onRefrenEnabledChaned;

  const RefrenTemplate({this.onPartTap, this.onRefrenEnabledChaned});

  @override
  Widget build(BuildContext context) {

    return Consumer<RefrenPartProvider>(
        builder: (context, prov, child) => AppCard(
          padding: EdgeInsets.zero,
          margin: EdgeInsets.only(bottom: 12),
          color: background(context),
          elevation: 0,
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(left: Dimen.DEF_MARG, right: Dimen.DEF_MARG),
                child: SongPartCard.from(
                  songPart: prov.part,
                  type: SongPartType.REFREN_TEMPLATE,
                  topBuilder: (context, part) => Consumer<RefrenEnabProvider>(
                    builder: (context, refEnabProv, child) => Row(
                        children: <Widget>[
                          HeaderWidget(
                              'Szablon refrenu',
                              prov.isError?MdiIcons.alertOutline:MdiIcons.musicBoxOutline,
                              iconColor: prov.isError?Colors.red:null,
                              enabled: refEnabProv.refEnab
                          ),
                          Expanded(child:Container()),
                          SizedBox(width: 34),
                          Switch(
                              value: refEnabProv.refEnab,
                              onChanged: (bool value){
                                refEnabProv.refEnab = !refEnabProv.refEnab;
                                if(onRefrenEnabledChaned != null) onRefrenEnabledChaned(value);
                              }),
                        ]
                    ),
                  ),
                  onTap: () => onPartTap(prov.part, prov),
                ),
              ),
            ],
          ),
        )
    );
  }

}