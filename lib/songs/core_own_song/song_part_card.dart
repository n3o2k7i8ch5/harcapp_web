
import 'package:flutter/material.dart';
import 'package:harcapp_web/common/app_text_style.dart';
import 'package:harcapp_web/common/color_pack.dart';
import 'package:harcapp_web/common/dimen.dart';
import 'package:harcapp_web/songs/core_own_song/providers.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import 'common.dart';


class SongPartCard extends StatelessWidget{

  final SongPart songPart;
  final bool isTemplate;
  final Widget Function(BuildContext, SongPart) topBuilder;
  final Function onTap;

  final FocusNode focusNode = FocusNode();

  SongPartCard(
      this.songPart,
      {
        this.isTemplate:false,
        this.topBuilder,
        this.onTap
      });

  static SongPartCard from(
      {@required SongPart songPart,
        bool isTemplate:false,
        Widget Function(BuildContext, SongPart) topBuilder,
        Function onTap
      }) =>
      SongPartCard(
          songPart,
          isTemplate: isTemplate,
          topBuilder: topBuilder,
          onTap: onTap
      );

  @override
  Widget build(BuildContext context) {

    RefrenEnabProvider isRefProv = Provider.of<RefrenEnabProvider>(context);

    return Consumer<RefrenEnabProvider>(
      builder: (context, prov, _){

        Widget songTextCard = Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              child: SongTextWidget(this, isRefProv),
            )
        );

        Widget songChordsCard = Container(
            child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: CHORDS_WIDGET_MIN_WIDTH),
                child: SongChordsWidget(this, isRefProv)
            )
        );

        String emptText;
        if(songPart.isRefren(context)){

          if(isTemplate){
            if(songPart.isEmpty)
              emptText = 'Dotknij, aby edytować szablon refrenu.';
          } else {
            if(prov.refEnab) {
              if(songPart.isEmpty)
                emptText = 'Brak refrenu, edytuj szablon refrenu powyżej.';
            }else
              emptText = 'Refren ukryty. Nie będzie wyświetlany w piosence.';
          }

        }else
        if(songPart.isEmpty)
          emptText = 'Dotknij, aby edytować zwrotkę.';

        Widget main = Padding(
          padding: EdgeInsets.all(Dimen.DEF_MARG/2),
          child:
          emptText!=null?
          SizedBox(height: 2*Dimen.TEXT_SIZE_NORMAL+4, child: Center(child: Text(
            emptText,
            style: AppTextStyle(color: hintEnabled(context)),
            textAlign: TextAlign.center,
          )))
              :
          Row(
            children: <Widget>[
              songTextCard,
              SizedBox(width: Dimen.DEF_MARG),
              songChordsCard
            ],
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if(topBuilder!=null) topBuilder(context, songPart),
            InkWell(
                onTap: onTap,
                child: main
            )
          ],
        );

      },
    );


  }
}

class SongTextWidget extends StatelessWidget{

  final SongPartCard parent;
  final RefrenEnabProvider isRefProv;

  const SongTextWidget(this.parent, this.isRefProv);

  bool isRefren(BuildContext context) => parent.songPart.isRefren(context);
  bool get hasRefren => isRefProv.refEnab;

  FocusNode get focusNode => parent.focusNode;

  @override
  Widget build(BuildContext context) {

    Color textColor;
    if(isRefren(context)){
      if(hasRefren && parent.isTemplate) textColor = textEnabled(context);
      else textColor = textDisabled(context);
    }else
      textColor = textEnabled(context);

    return Padding(
      padding: EdgeInsets.only(left: parent.songPart.shift?Dimen.ICON_SIZE:0),
      child: Text(
        text,
        style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: Dimen.TEXT_SIZE_NORMAL,
            color: textColor
        ),
      ),
    );
  }

  String get text{

    String songText = parent.songPart.getText();
    int textLineCnt = songText.split('\n').length;
    int chrdLineCnt = parent.songPart.chords.split('\n').length;

    int newLinesCnt = 0;
    if(textLineCnt<chrdLineCnt) {
      if(chrdLineCnt>2) newLinesCnt = chrdLineCnt - textLineCnt;
      else newLinesCnt = 2 - textLineCnt;
    }else{
      if(textLineCnt<2) newLinesCnt = 2 - textLineCnt;
    }

    return songText + '\n'*newLinesCnt;
  }
}

class SongChordsWidget extends StatelessWidget{

  final SongPartCard parent;
  final RefrenEnabProvider isRefProv;

  const SongChordsWidget(this.parent, this.isRefProv);

  bool isRefren(BuildContext context) => parent.songPart.isRefren(context);
  bool get hasRefren => isRefProv.refEnab;

  @override
  Widget build(BuildContext context) {

    Color textColor;
    if(isRefren(context)){
      if(hasRefren && parent.isTemplate) textColor = textEnabled(context);
      else textColor = textDisabled(context);
    }else
      textColor = textEnabled(context);

    return Text(
      text,
      style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: Dimen.TEXT_SIZE_NORMAL,
          color: textColor
      ),
    );
  }

  String get text{

    String songChords = parent.songPart.chords;
    int chrdLineCnt = songChords.split('\n').length;
    int textLineCnt = parent.songPart.getText().split('\n').length;

    int newLinesCnt = 0;
    if(chrdLineCnt<textLineCnt) {
      if(textLineCnt>2) newLinesCnt = textLineCnt - chrdLineCnt;
      else newLinesCnt = 2 - chrdLineCnt;
    }else{
      if(chrdLineCnt<2) newLinesCnt = 2 - chrdLineCnt;
    }

    return songChords + '\n'*newLinesCnt;
  }

}

class TopZwrotkaButtons extends StatelessWidget{

  final SongPart songPart;
  final Function(SongPart) onDuplicate;
  final Function(SongPart) onDelete;

  const TopZwrotkaButtons(
      this.songPart,
      {this.onDuplicate,
        this.onDelete,
      });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[

        Padding(
          padding: EdgeInsets.all(Dimen.MARG_ICON),
          child: Handle(child: Icon(MdiIcons.swapVertical, color: iconEnabledColor(context))),
        ),

        Expanded(child: Container()),

        if(songPart.isError)
          Padding(
              padding: EdgeInsets.all(Dimen.MARG_ICON),
              child: Icon(MdiIcons.alertOutline, color: Colors.red)
          ),

        IconButton(
          icon: Icon(MdiIcons.contentDuplicate, color: iconEnabledColor(context)),
          onPressed: (){
            if(onDuplicate!=null) onDuplicate(songPart);
            Provider.of<CurrentItemProvider>(context, listen: false).addPart(songPart.copy());
          },
        ),

        IconButton(
          icon: Icon(MdiIcons.trashCanOutline, color: iconEnabledColor(context)),
          onPressed: (){
            if(onDelete!=null) onDelete(songPart);
            Provider.of<CurrentItemProvider>(context, listen: false).removePart(songPart);
          },
        ),

      ],
    );
  }

}

class TopRefrenButtons extends StatelessWidget{

  final SongPart songPart;
  final Function(SongPart) onDelete;

  const TopRefrenButtons(
      this.songPart,
      {this.onDelete}
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[

        Padding(
          padding: EdgeInsets.all(Dimen.MARG_ICON),
          child: Handle(child: Icon(MdiIcons.swapVertical, color: iconEnabledColor(context))),
        ),

        Expanded(child: Container()),

        IconButton(
          icon: Icon(MdiIcons.trashCanOutline, color: iconEnabledColor(context)),
          onPressed: (){
            if(onDelete!=null) onDelete(songPart);
            Provider.of<CurrentItemProvider>(context, listen: false).removePart(songPart);
          },
        ),

      ],
    );
  }

}