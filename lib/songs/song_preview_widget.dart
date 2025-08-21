import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/instrument_type.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/comm_widgets/title_show_row_widget.dart';
import 'package:harcapp_core/song_book/contributor_identity_resolver.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/song_book/settings.dart';
import 'package:harcapp_core/song_book/song_editor/providers.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/song_book/widgets/song_widget_template.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pretty_json/pretty_json.dart';
import 'package:provider/provider.dart';

class SongPreviewWidget extends StatelessWidget{

  @override
  Widget build(BuildContext context) => Consumer2<CurrentItemProvider, SongPreviewProvider>(
      builder: (context, currItemProv, songPrevProv, child) => Column(
        children: [

          Padding(
            padding: EdgeInsets.only(left: Dimen.iconMarg, top: Dimen.iconMarg),
            child: TitleShortcutRowWidget(
              title: 'Podgląd piosenki',
              textAlign: TextAlign.start,
            ),
          ),

          Material(
            clipBehavior: Clip.hardEdge,
            color: cardEnab_(context),
            borderRadius: BorderRadius.circular(AppCard.bigRadius),
            child: Row(
              children: [
                Expanded(
                  child: SimpleButton(
                      padding: EdgeInsets.all(Dimen.iconMarg),
                      radius: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(MdiIcons.eyeOutline, color: songPrevProv.code?iconDisab_(context):iconEnab_(context)),
                          SizedBox(width: Dimen.iconMarg),
                          Text('Podgląd', style: AppTextStyle(
                              fontWeight: weightHalfBold,
                              color: songPrevProv.code?iconDisab_(context):iconEnab_(context)
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
                      padding: EdgeInsets.all(Dimen.iconMarg),
                      radius: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(MdiIcons.codeTags, color: songPrevProv.code?iconEnab_(context):iconDisab_(context)),
                          SizedBox(width: Dimen.iconMarg),
                          Text('Kod', style: AppTextStyle(
                              fontWeight: weightHalfBold,
                              color: songPrevProv.code?iconEnab_(context):iconDisab_(context)
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

          SizedBox(height: Dimen.defMarg),

          Expanded(
              child: SizedBox(
                width: 400,
                child: songPrevProv.code?
                SelectableText(
                    prettyJson(currItemProv.song.toApiJsonMap(), indent: 2)
                ):
                SongWidgetTemplate<SongRaw, ContributorIdentitySimpleResolver>(
                  currItemProv.song,
                  SongBaseSettings(),
                  cacheSizes: false,
                  scrollController: ScrollController(),
                  key: UniqueKey(),
                  contribIdResolver: ContributorIdentitySimpleResolver(),
                ),
              )
          )

        ],
      )
  );
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
  InstrumentType get chordsDrawType => InstrumentType.GUITAR;
  @override
  set chordsDrawType(InstrumentType value) => null;

  @override
  bool chordsTrailing = true;

}