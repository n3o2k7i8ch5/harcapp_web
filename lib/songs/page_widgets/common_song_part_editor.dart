
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:harcapp_web/common/app_card.dart';
import 'package:harcapp_web/common/app_text_style.dart';
import 'package:harcapp_web/common/color_pack.dart';
import 'package:harcapp_web/common/core_comm_widgets/animated_child_slider.dart';
import 'package:harcapp_web/common/core_comm_widgets/app_scaffold.dart';
import 'package:harcapp_web/common/core_comm_widgets/chord_shifter.dart';
import 'package:harcapp_web/common/core_comm_widgets/simple_button.dart';
import 'package:harcapp_web/common/core_comm_widgets/text_field_fit.dart';
import 'package:harcapp_web/common/core_comm_widgets/text_field_fit_chords.dart';
import 'package:harcapp_web/common/dimen.dart';
import 'package:harcapp_web/songs/core_own_song/common.dart';
import 'package:harcapp_web/songs/core_own_song/errors.dart';
import 'package:harcapp_web/songs/core_own_song/providers.dart';


import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

const double TEXT_FIELD_TOP_PADD = Dimen.TEXT_FIELD_PADD - 7;


class SongPartEditorTemplate extends StatefulWidget{

  final SongPart songPart;
  final bool isRefren;

  final Function onTextChanged;
  final Function onChordsChanged;
  final Function onShiftChanged;

  final Widget Function(BuildContext, SongPartEditorTemplateState) topBuilder;
  final Widget Function(BuildContext, SongPartEditorTemplateState) bottomBuilder;

  final double elevation;

  const SongPartEditorTemplate(
      this.songPart,
      {@required this.isRefren,

        this.onTextChanged,
        this.onChordsChanged,
        this.onShiftChanged,

        this.topBuilder,
        this.bottomBuilder,

        this.elevation: AppCard.bigElevation,
      });

  @override
  State<StatefulWidget> createState() => SongPartEditorTemplateState();
}


class SongPartEditorTemplateState extends State<SongPartEditorTemplate>{

  SongPart get songPart => widget.songPart;
  bool get isRefren => widget.isRefren;

  Function get onTextChanged => widget.onTextChanged;
  Function get onChordsChanged => widget.onChordsChanged;
  Function get onShiftChanged => widget.onShiftChanged;

  bool showErrBar;

  LinkedScrollControllerGroup _controllers;
  ScrollController textController;
  ScrollController chordsController;

  @override
  void initState() {

    _controllers = LinkedScrollControllerGroup();
    textController = _controllers.addAndGet();
    chordsController = _controllers.addAndGet();

    showErrBar = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    final FocusNode focusNode = FocusNode();

    return AppScaffold(
      backgroundColor: Colors.transparent,
      body: AppCard(
          elevation: widget.elevation,
          key: ValueKey(songPart),
          padding: EdgeInsets.zero,
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (context) => TextProvider(text: songPart.getText())),
              ChangeNotifierProvider(create: (context) => ChordsProvider(chords: songPart.chords)),
              ChangeNotifierProvider(create: (context) => TextShiftProvider(shifted: songPart.shift)),
              ChangeNotifierProvider(create: (context) => ErrorProvider<ChordsMissingError>(init: (errProv) => ChordsMissingError.handleErrors(context, errProv))),
              ChangeNotifierProvider(create: (context) => ErrorProvider<TextTooLongError>(init: (errProv) => TextTooLongError.handleErrors(context, errProv))),
            ],
            builder: (context, _) => Column(
              children: [

                if(widget.topBuilder!=null) widget.topBuilder(context, this),

                Expanded(
                    child: LayoutBuilder(
                      builder: (context, boxConstraints) => Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[

                          Expanded(
                            child: AppCard(
                              padding: EdgeInsets.only(left: Dimen.DEF_MARG/2, right: Dimen.DEF_MARG/2, bottom: Dimen.DEF_MARG/2),
                              elevation: 0,
                              color: background(context),
                              child: SongTextWidget(this, boxConstraints),
                            ),
                          ),

                          AppCard(
                            padding: EdgeInsets.only(left: Dimen.DEF_MARG/2, right: Dimen.DEF_MARG/2, bottom: Dimen.DEF_MARG/2),
                            elevation: 0,
                            color: background(context),
                            child: SongChordsWidget(this, boxConstraints),
                          )

                        ],
                      ),
                    )
                ),

                if(widget.bottomBuilder!=null) widget.bottomBuilder(context, this),

              ],
            ),
          )
      ),
    );

  }

}

class SongTextWidget extends StatelessWidget{

  final SongPartEditorTemplateState parent;
  final BoxConstraints boxConstraints;
  static FocusNode focusNode = FocusNode();

  const SongTextWidget(this.parent, this.boxConstraints);

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(focusNode),
      child: AppCard(
        padding: EdgeInsets.only(left: Dimen.DEF_MARG/2, right: Dimen.DEF_MARG/2, bottom: Dimen.DEF_MARG/2),
        elevation: 0,
        color: background(context),
        child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            controller: parent.textController,
            child: Consumer<TextShiftProvider>(
              builder: (context, provider, child) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeOutQuad,
                      width: provider.shifted?Dimen.ICON_SIZE + Dimen.MARG_ICON:0
                  ),
                  Expanded(child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    child: Consumer<ChordsProvider>(
                        builder: (context, chordsProvider, child) => TextFieldFit(
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: Dimen.TEXT_SIZE_NORMAL,
                            color: textEnabled(context),
                          ),
                          decoration: InputDecoration(
                              hintText: 'Słowa ${parent.isRefren?'refrenu':'zwrotki'}',
                              hintStyle: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: Dimen.TEXT_SIZE_NORMAL,
                                  color: hintEnabled(context)
                              ),
                              border: InputBorder.none,
                              isDense: true
                          ),
                          minLines: chordsProvider.chords.split('\n').length,
                          maxLines: null,
                          //expands: true,
                          focusNode: focusNode,
                          autofocus: false,
                          minWidth: Dimen.ICON_FOOTPRINT*2,
                          //controller: controller,
                          inputFormatters: [ALLOWED_TEXT_REGEXP],
                          onChanged: (text){
                            Provider.of<TextProvider>(context, listen: false).text = text;
                            parent.songPart.setText(text);
                            int errCount = handleErrors(context, parent.isRefren);
                            parent.songPart.isError = errCount != 0;
                            if(parent.onTextChanged!=null) parent.onTextChanged();
                          },
                          controller: Provider.of<TextProvider>(context, listen: false).controller,
                        )
                    ),
                  )),
                  Stack(
                    children: [
                      Positioned.fill(child: LineCount()),
                      TextLengthWarning(),
                    ],
                  )

                ],
              ),
            )
        ),
      ),
    );

  }

}

class SongChordsWidget extends StatelessWidget{

  final SongPartEditorTemplateState parent;
  final BoxConstraints boxConstraints;

  TextEditingController controller;

  static FocusNode focusNode = FocusNode();

  SongChordsWidget(this.parent, this.boxConstraints){
    controller = TextEditingController(text: parent.songPart.chords);
  }

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(focusNode),
      child: AppCard(
        padding: EdgeInsets.only(left: Dimen.DEF_MARG/2, right: Dimen.DEF_MARG/2, bottom: Dimen.DEF_MARG/2),
        elevation: 0,
        color: background(context),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          controller: parent.chordsController,
          child: Stack(
            children: [

              Positioned(
                  top: TEXT_FIELD_TOP_PADD,
                  right: 0,
                  left: 0,
                  child: ChordPresenceWarning(parent)
              ),

              Consumer<ChordsProvider>(
                  builder: (context, provider, child) => Consumer<TextProvider>(
                    builder: (context, textProvider, child) => TextFieldFitChords(
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: Dimen.TEXT_SIZE_NORMAL,
                          color: textEnabled(context),
                        ),
                        decoration: InputDecoration(
                            hintText: 'Chwyty ${parent.isRefren?'ref.':'zwr.'}',
                            hintStyle: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: Dimen.TEXT_SIZE_NORMAL,
                                color: hintEnabled(context)
                            ),
                            border: InputBorder.none,
                            isDense: true
                        ),
                        minLines: textProvider.text.split('\n').length,
                        maxLines: null,
                        focusNode: focusNode,
                        //expands: true,
                        //autofocus: false,
                        minWidth: CHORDS_WIDGET_MIN_WIDTH,
                        onChanged: (text){
                          provider.chords = text;
                          int errCount = handleErrors(context, parent.isRefren);
                          parent.songPart.chords = text;
                          parent.songPart.isError = errCount != 0;
                          if(parent.onChordsChanged!=null) parent.onTextChanged();
                        },
                        controller: provider.chordsController
                    ),
                  )
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ButtonsWidget extends StatelessWidget{

  final SongPartEditorTemplateState parent;

  bool get isRefren => parent.isRefren;
  SongPart get songPart => parent.songPart;

  ButtonsWidget(this.parent);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        isRefren?
        Padding(
          padding: EdgeInsets.all(Dimen.MARG_ICON),
          child: Icon(
              MdiIcons.rayStartArrow,
              color: iconDisabledColor(context)
          ),
        )
            :
        Consumer<TextShiftProvider>(
            builder: (context, provider, child) => IconButton(
              icon: AnimatedChildSlider(
                reverse: provider.shifted,
                direction: Axis.horizontal,
                index: provider.shifted?1:0,
                children: [
                  Icon(
                      MdiIcons.circleMedium,
                      color: iconEnabledColor(context)
                  ),
                  Icon(
                      MdiIcons.rayStartArrow,
                      color: iconEnabledColor(context)
                  )
                ],
              ),
              onPressed: isRefren?null:(){
                TextShiftProvider prov = Provider.of<TextShiftProvider>(context, listen: false);
                prov.reverseShift();
                songPart.shift = prov.shifted;
                if(parent.onShiftChanged!=null) parent.onShiftChanged();
              },
            )
        ),

        Expanded(child: AnyError(
            builder: (context, errCont) => AnimatedOpacity(
              opacity: errCont==0?0:1,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOutQuad,
              child: SimpleButton(
                onTap: errCont==0?null:(){
                  parent.setState(() => parent.showErrBar = !parent.showErrBar);
                },
                padding: EdgeInsets.all(Dimen.MARG_ICON),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(MdiIcons.alertOutline, color: Colors.red),
                    SizedBox(width: Dimen.MARG_ICON),
                    Text('$errCont', style: AppTextStyle(fontWeight: weight.halfBold, color: Colors.red),)
                  ],
                ),
              ),
            )
        )),



        IconButton(
          icon: Icon(MdiIcons.chevronDoubleDown),
          onPressed: (){

            ChordsProvider provider = Provider.of<ChordsProvider>(context, listen: false);

            ChordShifter cs = ChordShifter(provider.chords, 0);
            cs.down();

            String chords = cs.getText(true);
            provider.chordsController.text = chords;
            provider.chords = chords;
            handleErrors(context, isRefren);
            songPart.chords = chords;

            provider.chordsController.selection = TextSelection.collapsed(offset: provider.chords.length);
            if(parent.onChordsChanged!=null) parent.onTextChanged();
          },
        ),

        IconButton(
          icon: Icon(MdiIcons.chevronDoubleUp),
          onPressed: (){

            ChordsProvider provider = Provider.of<ChordsProvider>(context, listen: false);

            ChordShifter cs = ChordShifter(provider.chords, 0);
            cs.up();

            String chords = cs.getText(true);
            provider.chordsController.text = chords;
            provider.chords = chords;
            handleErrors(context, isRefren);
            songPart.chords = chords;

            provider.chordsController.selection = TextSelection.collapsed(offset: provider.chords.length);
            if(parent.onChordsChanged!=null) parent.onTextChanged();
          },
        ),
      ],
    );
  }

}

class ChordPresenceWarning extends StatelessWidget{

  final SongPartEditorTemplateState parent;
  const ChordPresenceWarning(this.parent);

  @override
  Widget build(BuildContext context) {

    return Consumer<ErrorProvider<ChordsMissingError>>(
      builder: (context, provider, child){

        List<Widget> lineWidgets = [];

        int lines = Provider.of<TextProvider>(context).text.split('\n').length;
        for(int i=0; i<lines; i++){
          ChordsMissingError error = provider.errorAt(i);
          lineWidgets.add(WarningShade(error==null?background(context).withOpacity(0):error.color));
        }

        return Column(
            mainAxisSize: MainAxisSize.min,
            children: lineWidgets
        );

      },
    );

  }

}

class WarningShade extends StatelessWidget{

  final Color color;
  const WarningShade(this.color);

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: EdgeInsets.only(top: 0.5, bottom: 0.5),
      child: AnimatedContainer(
        decoration: BoxDecoration(
            color: color,
            borderRadius: new BorderRadius.all(Radius.circular(4))
        ),
        duration: Duration(milliseconds: 500),
        height: Dimen.TEXT_SIZE_NORMAL + 1,
      ),
    );
  }


}

class TextLengthWarning extends StatelessWidget{

  @override
  Widget build(BuildContext context) {

    return Padding(
        padding: EdgeInsets.only(top: TEXT_FIELD_TOP_PADD),
        child: Consumer<ErrorProvider<TextTooLongError>>(builder: (context, provider, child) {

          List<Widget> lineWidgets = [];

          int lines = Provider.of<TextProvider>(context).text.split('\n').length;
          for(int i=0; i<lines; i++){
            TextTooLongError error = provider.errorAt(i);
            lineWidgets.add(WarningShade(error==null?background(context).withOpacity(0):error.color));
          }

          return Padding(
            padding: EdgeInsets.only(left: 3),
            child: SizedBox(
              width: Dimen.MARG_ICON+2,
              child: Column(children: lineWidgets),
            ),
          );

        })
    );

  }

}

class LineCount extends StatelessWidget{

  @override
  Widget build(BuildContext context) {

    return Padding(
        padding: EdgeInsets.only(top: TEXT_FIELD_TOP_PADD),
        child: Consumer<TextProvider>(builder: (context, textProv, child) {

          return Consumer<ChordsProvider>(
              builder: (context, chordsProv, child) {

                int textLines = textProv.text.split('\n').length;
                int chordsLines = chordsProv.chords.split('\n').length;

                int lines = max(textLines, chordsLines);
                String text = '';
                for(int i=0; i<lines; i++)
                  text += '${i + 1}\n';

                if(text.length>0)
                  text = text.substring(0, text.length-1);

                return Text(
                  text,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: Dimen.TEXT_SIZE_TINY,//initial font size
                      color: hintDisabled(context),
                      height: 1*Dimen.TEXT_SIZE_BIG/ Dimen.TEXT_SIZE_TINY
                  ),
                );
              });

        })
    );

  }

}