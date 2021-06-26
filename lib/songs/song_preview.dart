import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/comm_widgets/title_show_row_widget.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core_own_song/providers.dart';
import 'package:harcapp_core_own_song/song_raw.dart';
import 'package:harcapp_core_song_widget/providers.dart';
import 'package:harcapp_core_song_widget/settings.dart';
import 'package:harcapp_core_song_widget/song_widget_template.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pretty_json/pretty_json.dart';
import 'package:provider/provider.dart';

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
                      padding: EdgeInsets.only(bottom: 32, right: 32),
                      child: Column(
                        children: [

                          Padding(
                            padding: EdgeInsets.only(left: Dimen.ICON_MARG, top: Dimen.ICON_MARG),
                            child: TitleShortcutRowWidget(
                              title: 'Podgląd piosenki',
                              textAlign: TextAlign.start,
                            ),
                          ),

                          AppCard(
                            radius: AppCard.BIG_RADIUS,
                            margin: AppCard.normMargin,
                            padding: EdgeInsets.zero,
                            elevation: AppCard.bigElevation,
                            child: Row(
                              children: [
                                Expanded(
                                  child: SimpleButton(
                                    padding: EdgeInsets.all(Dimen.ICON_MARG),
                                      margin: EdgeInsets.zero,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(MdiIcons.eyeOutline, color: songPrevProv.code!?iconDisab_(context):iconEnab_(context)),
                                          SizedBox(width: Dimen.ICON_MARG),
                                          Text('Podgląd', style: AppTextStyle(
                                              fontWeight: weight.halfBold,
                                              color: songPrevProv.code!?iconDisab_(context):iconEnab_(context)
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
                                      padding: EdgeInsets.all(Dimen.ICON_MARG),
                                      margin: EdgeInsets.zero,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(MdiIcons.codeTags, color: songPrevProv.code!?iconEnab_(context):iconDisab_(context)),
                                          SizedBox(width: Dimen.ICON_MARG),
                                          Text('Kod', style: AppTextStyle(
                                              fontWeight: weight.halfBold,
                                              color: songPrevProv.code!?iconEnab_(context):iconDisab_(context)
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
                                  ChangeNotifierProvider(create: (context) => ShowChordsProvider(SongBaseSettings())),
                                  ChangeNotifierProvider(create: (context) => ChordsDrawTypeProvider(SongBaseSettings())),
                                  ChangeNotifierProvider(create: (context) => ChordsDrawShowProvider(SongBaseSettings())),
                                ],
                                builder: (context, child) => Container(
                                  width: 400,
                                  child: songPrevProv.code!?
                                  SelectableText(
                                      prettyJson(currItemProv.song!.toMap(), indent: 2)
                                  ):
                                  SongWidgetTemplate<SongRaw>(
                                      currItemProv.song!,
                                      SongBaseSettings(),
                                      screenWidth: 372,
                                      key: UniqueKey()//ValueKey(currItemProv.song)
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

class SongBaseSettings extends SongBookSettTempl{

  @override
  bool get alwaysOnScreen => false;
  @override
  set alwaysOnScreen(bool value) => null;

  @override
  bool get scrollText => false;
  @override
  set scrollText(bool value) => null;

  @override
  double get autoscrollTextSpeed => 0;
  @override
  set autoscrollTextSpeed(double value) => null;

  @override
  bool get showChords => true;
  @override
  set showChords(bool value) => null;

  @override
  bool get chordsDrawShow => true;
  @override
  set chordsDrawShow(bool value) => null;

  @override
  bool get chordsDrawType => true;
  @override
  set chordsDrawType(bool value) => null;

}