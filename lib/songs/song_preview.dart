import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:harcapp_web/common/app_card.dart';
import 'package:harcapp_web/common/app_text_style.dart';
import 'package:harcapp_web/common/color_pack.dart';
import 'package:harcapp_web/common/core_comm_widgets/simple_button.dart';
import 'package:harcapp_web/common/dimen.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/song_widget/providers.dart';
import 'package:harcapp_web/songs/song_widget/song_widget_template.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pretty_json/pretty_json.dart';
import 'package:provider/provider.dart';

import 'core_own_song/common.dart';
import 'core_own_song/providers.dart';
import 'core_song_management/song_raw.dart';

class SongPreview extends StatelessWidget{

  @override
  Widget build(BuildContext context) {

    return Consumer2<CurrentItemProvider, SongPreviewProvider>(
        builder: (context, currItemProv, songPrevProv, child){
          if(currItemProv.song==null)
            return Container();

          return LayoutBuilder(
              builder: (context, constrains){
                return Container(
                  width: MediaQuery.of(context).size.width<1200 + 4*32?0:400,
                  child: Padding(
                      padding: EdgeInsets.only(top: 32, bottom: 32, right: 32),
                      child: Column(
                        children: [

                          HeaderWidget('Podgląd piosenki', MdiIcons.bookmarkMusicOutline, enabled: false),

                          AppCard(
                            padding: EdgeInsets.zero,
                            elevation: AppCard.bigElevation,
                            child: Row(
                              children: [
                                Expanded(
                                  child: SimpleButton(
                                    padding: EdgeInsets.all(Dimen.MARG_ICON),
                                      margin: EdgeInsets.zero,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(MdiIcons.eyeOutline, color: songPrevProv.code?iconDisabledColor(context):iconEnabledColor(context)),
                                          SizedBox(width: Dimen.MARG_ICON),
                                          Text('Podgląd', style: AppTextStyle(
                                              fontWeight: weight.halfBold,
                                              color: songPrevProv.code?iconDisabledColor(context):iconEnabledColor(context)
                                          ))
                                        ],
                                      ),
                                      onTap: (){
                                        songPrevProv.code = false;
                                      }
                                  ),
                                ),

                                Expanded(
                                  child: SimpleButton(
                                      padding: EdgeInsets.all(Dimen.MARG_ICON),
                                      margin: EdgeInsets.zero,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(MdiIcons.codeTags, color: songPrevProv.code?iconEnabledColor(context):iconDisabledColor(context)),
                                          SizedBox(width: Dimen.MARG_ICON),
                                          Text('Kod', style: AppTextStyle(
                                              fontWeight: weight.halfBold,
                                              color: songPrevProv.code?iconEnabledColor(context):iconDisabledColor(context)
                                          ))
                                        ],
                                      ),
                                      onTap: (){
                                        songPrevProv.code = true;
                                      }
                                  ),
                                )
                              ],
                            ),
                          ),

                          Expanded(
                              child: MultiProvider(
                                providers: [
                                  ChangeNotifierProvider(create: (context) => ShowChordsProvider()),
                                  ChangeNotifierProvider(create: (context) => ChordsDrawTypeProvider()),
                                  ChangeNotifierProvider(create: (context) => ChordsDrawShowProvider()),
                                  ChangeNotifierProvider(create: (context) => ChordsDrawPinnedProvider()),
                                ],
                                builder: (context, child) => Container(
                                  width: 400,
                                  child: songPrevProv.code?
                                  SelectableText(
                                      prettyJson(currItemProv.song.toMap(), indent: 2)
                                  ):
                                  SongWidgetTemplate<SongRaw>(
                                      currItemProv.song,
                                      screenWidth: 380,
                                      key: ValueKey(currItemProv.song)
                                  ),
                                ),
                              )
                          )
                        ],
                      )
                  ),
                );
              }
          );
        }
    );

  }
}
