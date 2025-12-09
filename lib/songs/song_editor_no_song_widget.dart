import 'dart:math';

import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/blur.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/songs/left_panel/song_list_view.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../consts.dart';
import 'new_song_buttons.dart';

class SongEditorNoSongWidget extends StatelessWidget{

  final bool workspaceAlwaysVisible;

  const SongEditorNoSongWidget({required this.workspaceAlwaysVisible});

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [

      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: 2*32.0 + 2*24.0,
        child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: Dimen.iconFootprint,
              childAspectRatio: 1,
              mainAxisSpacing: 24.0,
              crossAxisSpacing: 24.0
            ),
            itemBuilder: (context, index) => SlidingMusicIcon()
        ),
      ),

      Blur(
        child: ClickHereWidget(workspaceAlwaysVisible)
      ),

    ],
  );

}

class SlidingMusicIcon extends StatefulWidget{

  const SlidingMusicIcon({super.key});

  @override
  State<StatefulWidget> createState() => SlidingMusicIconState();

}

class SlidingMusicIconState extends State<SlidingMusicIcon>{

  static List<IconData> icons = [
    MdiIcons.musicClefBass,
    MdiIcons.musicClefTreble,

    MdiIcons.musicAccidentalNatural,
    MdiIcons.musicAccidentalFlat,
    MdiIcons.musicAccidentalDoubleFlat,
    MdiIcons.musicAccidentalSharp,
    //MdiIcons.musicAccidentalDoubleSharp,

    MdiIcons.musicRestWhole,
    MdiIcons.musicRestHalf,
    MdiIcons.musicRestQuarter,
    MdiIcons.musicRestEighth,
    MdiIcons.musicRestSixteenth,

    MdiIcons.musicNoteWhole,
    MdiIcons.musicNoteWholeDotted,
    MdiIcons.musicNote,
    MdiIcons.musicNotePlus,
    MdiIcons.musicNoteHalf,
    MdiIcons.musicNoteHalfDotted,
    MdiIcons.music,
    MdiIcons.musicNoteEighth,
    MdiIcons.musicNoteEighthDotted,
    MdiIcons.musicNoteSixteenth,
    MdiIcons.musicNoteSixteenthDotted,

    MdiIcons.piano,
    MdiIcons.instrumentTriangle,
    //MdiIcons.guitarElectric,
    MdiIcons.guitarPickOutline,

    MdiIcons.campfire,

    MdiIcons.microphone,
    MdiIcons.microphoneVariant,
    MdiIcons.headphones,
    MdiIcons.candle,

    MdiIcons.play,
    MdiIcons.playCircleOutline,
    MdiIcons.pause,
    MdiIcons.pauseCircleOutline
  ];

  late int _millis;
  IconData? icon;
  bool? visible;

  void run(bool? visibleFirst) async {

    if(mounted) setState((){
      if(!visibleFirst!) icon = icons[Random().nextInt(icons.length)];
      visible = !visibleFirst;
    });
    await Future.delayed(Duration(milliseconds:_millis));

    if(mounted) setState((){
      if(visibleFirst!) icon = icons[Random().nextInt(icons.length)];
      visible = visibleFirst;
    });
    await Future.delayed(Duration(milliseconds: _millis));

    if(mounted) run(visibleFirst);
  }

  @override
  void initState() {
    _millis = 1000 + Random().nextInt(4000);
    icon = icons[Random().nextInt(icons.length)];
    visible = Random().nextBool();
    run(visible);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible!?1:0,
      duration: Duration(milliseconds: _millis),
      child: Icon(icon, color: hintEnab_(context), size: 32.0,),
    );
  }

}

class ClickHereWidget extends StatelessWidget {

  static const width = drawerWidth - 2*NoSongsWidget.paddingVal;

  final bool leftPanelAlwaysVisible;

  const ClickHereWidget(this.leftPanelAlwaysVisible);

  @override
  Widget build(BuildContext context) =>
      Center(
        child: SizedBox(
          width: width,
          child: ListView(
            padding: EdgeInsets.all(NoSongsWidget.paddingVal),
            shrinkWrap: true,
            children: [

              Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    'Pierwszy raz dodajesz piosenkę'
                        '\ndo śpiewnika HarcAppki?',
                    textAlign: TextAlign.center,
                    style: AppTextStyle(
                      fontSize: 20.0,
                      color: textDisab_(context),
                      fontWeight: weightHalfBold,
                    ),
                  )
              ),

              SizedBox(height: NoSongsWidget.paddingVal),

              NewEmptySongButton(),

              SizedBox(height: 20.0),

              NewExampleSongButton(),

              SizedBox(height: 20.0),
              Icon(MdiIcons.circleMedium, color: textDisab_(context)),
              SizedBox(height: 20.0),

              if(leftPanelAlwaysVisible)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 7.0),
                    Icon(MdiIcons.arrowLeft, color: textDisab_(context)),
                    SizedBox(width: 7.0),

                    Text(
                      'Po wszystkie dostępne opcje, zerknij tam',
                      style: AppTextStyle(
                        fontSize: 14.0,
                        color: textDisab_(context),
                        fontWeight: weightHalfBold,
                      ),
                    ),
                  ],
                )

              else
                SimpleButton.from(
                  context: context,
                  onTap: () => Scaffold.of(context).openDrawer(),
                  text: 'Kliknij, po więcej opcji',
                  color: backgroundIcon_(context),
                  icon: MdiIcons.menu,
                  iconSize: 32.0,
                  direction: Axis.vertical,
                )

            ],
          ),
        ),
      );

}