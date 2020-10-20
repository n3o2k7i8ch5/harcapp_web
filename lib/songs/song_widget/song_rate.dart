
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/shadow_icon.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core_song/song_core.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class RateCard<T extends SongCore> extends StatefulWidget{

  static const double height = 2*Dimen.ICON_SIZE + 2*Dimen.DEF_MARG + 2*AppCard.defRadius + Dimen.TEXT_SIZE_SMALL;

  final T song;
  final Function(int rate, bool clicked) onClick;

  const RateCard(this.song, this.onClick);

  @override
  State<StatefulWidget> createState() => RateCardState<T>();
}

class RateCardState<T extends SongCore> extends State<RateCard>{

  T get song => widget.song;
  Function(int rate, bool clicked) get onClick => widget.onClick;

  @override
  Widget build(BuildContext context) {

    return Align(
        alignment: Alignment.topCenter,
        child: AppCard.Default(
            context: context,
            padding: EdgeInsets.all(0),
            elevation: AppCard.bigElevation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                        child: RateButton.from(song, SongRate.TEXT_DISLIKE, SongRate.iconDislike(), SongRate.RATE_DISLIKE, onClick)
                    ),
                    Expanded(
                        child: RateButton.from(song, SongRate.TEXT_LIKE_1, SongRate.iconLike1(), SongRate.RATE_LIKE_1, onClick)
                    ),
                    Expanded(
                        child: RateButton.from(song, SongRate.TEXT_LIKE_2, SongRate.iconLike2(), SongRate.RATE_LIKE_2, onClick)
                    ),
                    Expanded(
                        child: RateButton.from(song, SongRate.TEXT_LIKE_3, SongRate.iconLike3(), SongRate.RATE_LIKE_3, onClick)
                    ),
                    Expanded(
                        child: RateButton.from(song, SongRate.TEXT_BOOKMARK, SongRate.iconBookmark(), SongRate.RATE_BOOKMARK, onClick)
                    ),
                  ],
                ),
              ],
            )
        )
    );
  }
}

class SongRate{

  static const int RATE_NULL = 0;
  static const int RATE_DISLIKE = 1;
  static const int RATE_LIKE_1 = 2;
  static const int RATE_LIKE_2 = 3;
  static const int RATE_LIKE_3 = 4;
  static const int RATE_BOOKMARK = -1;

  static const String TEXT_DISLIKE = 'Słabe';
  static const String TEXT_LIKE_1 = 'Niezłe';
  static const String TEXT_LIKE_2 = 'Świetne';
  static const String TEXT_LIKE_3 = 'Perełka';
  static const String TEXT_BOOKMARK = 'Do nauki';

  static const Color COL_DISLIKE = Colors.orange;
  static const Color COL_LIKE_1 = Colors.lightBlueAccent;
  static const Color COL_LIKE_2 = Colors.blueAccent;
  static const Color COL_LIKE_3 = Colors.deepPurple;
  static const Color COL_BOOKMARK = Colors.pinkAccent;

  static const IconData IC_DATA_NULL = MdiIcons.heartOutline;
  static const IconData IC_DATA_DISLIKE = MdiIcons.musicRestQuarter;
  static const IconData IC_DATA_LIKE_1 = MdiIcons.musicNoteQuarter;
  static const IconData IC_DATA_LIKE_2 = MdiIcons.musicNoteEighth;
  static const IconData IC_DATA_LIKE_3 = MdiIcons.musicNoteSixteenth;
  static const IconData IC_DATA_BOOKMARK = MdiIcons.school;

  static int _disabledAlpha = 128;

  static iconDislike({enabled: true, size: Dimen.ICON_SIZE}) => Icon(SongRate.IC_DATA_DISLIKE, color: SongRate.COL_DISLIKE.withAlpha(enabled?255:_disabledAlpha), size: size,);
  static iconLike1({enabled: true, size: Dimen.ICON_SIZE}) => Icon(SongRate.IC_DATA_LIKE_1, color: SongRate.COL_LIKE_1.withAlpha(enabled?255:_disabledAlpha), size: size);
  static iconLike2({enabled: true, size: Dimen.ICON_SIZE}) => Icon(SongRate.IC_DATA_LIKE_2, color: SongRate.COL_LIKE_2.withAlpha(enabled?255:_disabledAlpha), size: size);
  static iconLike3({enabled: true, size: Dimen.ICON_SIZE}) => Icon(SongRate.IC_DATA_LIKE_3, color: SongRate.COL_LIKE_3.withAlpha(enabled?255:_disabledAlpha), size: size);
  static iconBookmark({enabled: true, size: Dimen.ICON_SIZE}) => Icon(SongRate.IC_DATA_BOOKMARK, color: SongRate.COL_BOOKMARK.withAlpha(enabled?255:_disabledAlpha), size: size);

}

class RateButton extends StatelessWidget{

  final String title;
  final Icon icon;
  final int rate;
  final Function(int rate, bool clicked) onClick;
  final bool clicked;
  final Color background;
  final bool glow;

  const RateButton(this.title, this.icon, this.rate, this.onClick, this.clicked, {this.background, this.glow:true});

  static RateButton from<T extends SongCore>(T song, String title, Icon icon, int rate, Function(int rate, bool clicked) onClick){
    return RateButton(title, icon, rate, onClick, song.rate == rate);
  }

  @override
  Widget build(BuildContext context) {

    Widget iconChild;
    if(clicked) {
      Widget shadowIconChild = Center(child: ShadowIcon(icon));
      iconChild =
          glow?
          AvatarGlow(
              child: shadowIconChild,
              endRadius: Dimen.ICON_SIZE, glowColor: defCardElevation(context),
              repeatPauseDuration: Duration(seconds: 1),
          ):shadowIconChild;
    }else
      iconChild = icon;

    Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          child: iconChild,
          height: 2*Dimen.ICON_SIZE,
        ),
        Text(
            title,
            style: AppTextStyle(
                fontSize: Dimen.TEXT_SIZE_SMALL,
                color: clicked?textEnabled(context):hintEnabled(context),
                fontWeight: clicked?weight.bold:weight.normal,
                shadow: clicked),
            textAlign: TextAlign.center
        )
      ],
    );

    return AppCard.Default(
      context: context,
      elevation: 0.0,
      padding: EdgeInsets.only(top: Dimen.DEF_MARG, bottom: Dimen.DEF_MARG),
      margin: EdgeInsets.zero,
      child: child,
      onTap: () => onClick(rate, clicked),
    );
  }

}

class RateIcon{

  final int rate;
  final bool enabled;
  final double size;
  const RateIcon(this.rate, {this.enabled:true, this.size: Dimen.ICON_SIZE});

  static Icon build(BuildContext context, int rate, {bool enabled:true, double size: Dimen.ICON_SIZE, Color iconColor}){
    switch(rate){
      case SongRate.RATE_NULL: return Icon(SongRate.IC_DATA_NULL, color: iconColor??iconEnabledColor(context));
      case SongRate.RATE_DISLIKE: return SongRate.iconDislike(enabled: enabled, size: size);
      case SongRate.RATE_LIKE_1: return SongRate.iconLike1(enabled: enabled, size: size);
      case SongRate.RATE_LIKE_2: return SongRate.iconLike2(enabled: enabled, size: size);
      case SongRate.RATE_LIKE_3: return SongRate.iconLike3(enabled: enabled, size: size);
      case SongRate.RATE_BOOKMARK: return SongRate.iconBookmark(enabled: enabled, size: size);
      default: return Icon(SongRate.IC_DATA_NULL, color: iconEnabledColor(context));
    }
  }

}

