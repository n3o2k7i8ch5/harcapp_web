import 'dart:math';

import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

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
              maxCrossAxisExtent: Dimen.ICON_FOOTPRINT,
              childAspectRatio: 1,
              mainAxisSpacing: 24.0,
              crossAxisSpacing: 24.0
            ),
            itemBuilder: (context, index) => SlidingMusicIcon()
        ),
      ),
      
      Center(
        child: Material(
          color: cardEnab_(context),
          borderRadius: BorderRadius.circular(AppCard.bigRadius),
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: const EdgeInsets.all(Dimen.defMarg),
            child: Material(
              color: background_(context),
              borderRadius: BorderRadius.circular(AppCard.bigRadius - 4),
              clipBehavior: Clip.hardEdge,
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      'Chcesz dodać lub edytować piosenkę'
                      '\ndo śpiewnika HarcAppki?',
                      style: AppTextStyle(
                          fontSize: 20.0,
                          color: textDisab_(context),
                          fontWeight: weight.halfBold
                      ),
                    ),

                    SizedBox(height: 20.0),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                            workspaceAlwaysVisible?MdiIcons.arrowLeft:MdiIcons.gestureTap,
                            color: textDisab_(context),
                            size: 24.0
                        ),
                        SizedBox(width: Dimen.ICON_MARG),
                        Text(
                          workspaceAlwaysVisible?'Zerknij tam!':'Kliknij',
                          style: AppTextStyle(
                              fontSize: 20.0,
                              color: textDisab_(context),
                              fontWeight: weight.halfBold
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      )
      
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