import 'dart:math';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:harcapp_web/common/app_card.dart';
import 'package:harcapp_web/common/app_text_style.dart';
import 'package:harcapp_web/common/color_pack.dart';
import 'package:harcapp_web/common/core_comm_classes/primitive_wrapper.dart';
import 'package:harcapp_web/common/core_comm_widgets/app_button.dart';
import 'package:harcapp_web/common/core_comm_widgets/chord_draw_bar.dart';
import 'package:harcapp_web/common/core_comm_widgets/simple_button.dart';
import 'package:harcapp_web/common/core_comm_widgets/tag_layout.dart';
import 'package:harcapp_web/common/dimen.dart';
import 'package:harcapp_web/songs/core_song_management/song_core.dart';
import 'package:harcapp_web/songs/song_widget/providers.dart';
import 'package:harcapp_web/songs/song_widget/settings.dart';
import 'package:harcapp_web/songs/song_widget/song_rate.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import 'get_line_nums.dart';

class SongWidgetTemplate<T extends SongCore> extends StatefulWidget{

  final T song;

  final double screenWidth;

  final ValueNotifier pageNotifier;
  final int index;

  final double topScreenPadding;

  final Function(ScrollController controller) onScroll;

  final Function() onTitleTap;
  final Function() onAuthorTap;
  final Function() onPerformerTap;
  final Function(String tag) onTagTap;

  final Function(double position) onYTLinkTap;
  final Function onYTLinkLongPress;

  final Function(BuildContext context, bool changedSize) onMinusTap;
  final Function(BuildContext context, bool changedSize) onPlusTap;

  final Function() onAlbumsTap;

  final Function(double position) onRateTap;

  final Function() onDeleteTap;
  final Function() onDeleteLongPress;

  final Function() onReportTap;

  final Function(TextSizeProvider) onEditTap;

  final void Function() onSendSongTap;

  final void Function() onShareTap;

  final void Function() onCopyTap;

  final void Function(bool isTypeGuitar) onChordsTypeChanged;

  final Function(TextSizeProvider provider) onChordsTap;
  final Function(TextSizeProvider provider) onChordsLongPress;

  final Widget Function(BuildContext, ScrollController) header;
  final Widget Function(BuildContext, ScrollController) footer;

  const SongWidgetTemplate(
      this.song,
      {
        this.screenWidth,
        this.pageNotifier,
        this.index: -1,

        this.topScreenPadding: 0,

        this.onScroll,

        this.onTitleTap,
        this.onAuthorTap,
        this.onPerformerTap,
        this.onTagTap,

        this.onYTLinkTap,
        this.onYTLinkLongPress,

        this.onMinusTap,
        this.onPlusTap,

        this.onAlbumsTap,

        this.onRateTap,

        this.onDeleteTap,
        this.onDeleteLongPress,

        this.onReportTap,

        this.onEditTap,

        this.onSendSongTap,

        this.onShareTap,

        this.onCopyTap,

        this.onChordsTypeChanged,

        this.onChordsTap,
        this.onChordsLongPress,

        this.header,
        this.footer,
        Key key
      }):super(key: key);

  @override
  State createState() => SongWidgetTemplateState<T>();
}

class SongWidgetTemplateState<T extends SongCore> extends State<SongWidgetTemplate> with TickerProviderStateMixin {

  T get song => widget.song;

  List<Widget> widgets = [];

  Orientation oldOrientation;

  GlobalKey contentCardsKey;

  String lineNum;

  bool showChords() =>
      Settings.showChords
          && widget.song.hasChords;

  ScrollController scrollController;

  void resetDisplayChordDraw() =>
      setState(() => displayChordDraw = widget.song.hasChords && Settings.showChords && Settings.chordsDrawShow);

  bool displayChordDraw;

  @override
  void initState() {
    //wantedFontSize = defFontSize;
    contentCardsKey = GlobalKey();

    displayChordDraw = widget.song.hasChords && Settings.showChords && Settings.chordsDrawShow;

    scrollController = ScrollController();
    if(widget.onScroll != null) scrollController.addListener(() => widget.onScroll(scrollController));

    lineNum = getLineNums(song.text);

    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    double screenWidth = MediaQuery.of(context).size.width;
    return ChangeNotifierProvider<TextSizeProvider>(
      create: (context) => TextSizeProvider(widget.screenWidth??screenWidth, song),
      builder: (context, child) => OrientationBuilder(
          builder: (BuildContext context, Orientation orientation) {
            // To po to, żeby tekst został zresetowany po zmianie orientacji.
            if (oldOrientation != MediaQuery.of(context).orientation) {
              oldOrientation = orientation;
            }

            SingleChildScrollView listView = SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              controller: scrollController,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.max,
                  children: [

                    Consumer3<ChordsDrawPinnedProvider, ChordsDrawShowProvider, ShowChordsProvider>(
                        builder: (context, chordsDrawPinProv, chordsDrawShowProv, showChordsProv, child) =>
                            SizedBox(
                                height: (chordsDrawPinProv.pinChordsDraw && chordsDrawShowProv.chordsDrawShow && showChordsProv.showChords)?
                                ChordWidget.height(Settings.chordsDrawType?6:4) + Dimen.DEF_MARG.toInt():0
                            )
                    ),

                    if(!widget.song.official)
                      AppCard(
                          color: accentColor(context),
                          child: Text(
                            'Piosenka nieoficjalna.',
                            style: AppTextStyle(color: accentIcon(context)),
                            textAlign: TextAlign.center,
                          )
                      ),

                    if(widget.header!=null) widget.header(context, scrollController),

                    TitleCard<T>(this),

                    Column(
                      children: <Widget>[

                        Consumer3<ChordsDrawPinnedProvider, ChordsDrawShowProvider, ShowChordsProvider>(
                          child: ChordsBarCard(this),
                          builder: (context, chordsDrawPinProv, chordsDrawShowProv, showChordsProv, child){
                            if(!chordsDrawPinProv.pinChordsDraw && chordsDrawShowProv.chordsDrawShow && showChordsProv.showChords)
                              return child;
                            else
                              return Container();
                          },
                        ),

                        ButtonWidget<T>(this),

                        ContentWidget<T>(this, scrollController, globalKey: contentCardsKey),

                        //SizedBox(height: 18.0),

                        if(widget.footer!=null) widget.footer(context, scrollController)

                      ],
                    ),

                    if(widget.song.addPers.length != 0)
                      Padding(
                        padding: EdgeInsets.all(Dimen.DEF_MARG),
                        child: RichText(
                            textAlign: TextAlign.start,
                            text: TextSpan(
                              children: [
                                TextSpan(text: 'Os. dodająca:\n', style: AppTextStyle(color: hintEnabled(context), fontSize: Dimen.TEXT_SIZE_TINY)),
                                TextSpan(text: widget.song.addPers, style: AppTextStyle(color: hintEnabled(context), fontSize: Dimen.TEXT_SIZE_TINY, fontWeight: weight.halfBold)),
                              ],
                            )
                        ),
                      ),

                  ]
              ),
            );

            return Stack(
              children: <Widget>[

                listView,
                Consumer3<ChordsDrawPinnedProvider, ChordsDrawShowProvider, ShowChordsProvider>(
                  child: Material(
                    color: defCardEnabled(context),
                    elevation: AppCard.bigElevation,
                    child: ChordsBarCard<T>(this),
                  ),
                  builder: (context, chordsDrawPinProv, chordsDrawShowProv, showChordsProv, child){
                    if(chordsDrawPinProv.pinChordsDraw && chordsDrawShowProv.chordsDrawShow && showChordsProv.showChords)
                      return child;
                    else
                      return Container();
                  },
                ),


              ],
            );
          }),
    );

  }

  void notify() => setState((){});
}



class TitleCard<T extends SongCore> extends StatelessWidget{

  final SongWidgetTemplateState<T> parent;
  const TitleCard(this.parent);

  T get song => parent.song;
  ValueNotifier get pageNotifier => parent.widget.pageNotifier;
  int get index => parent.widget.index;

  @override
  Widget build(BuildContext context) {

    Widget widgetTitle = SimpleButton(
      child: AutoSizeText(
        song.title,
        style: AppTextStyle(fontSize: 24.0, color: textEnabled(context), fontWeight: weight.halfBold, shadow: true),
        maxLines: 1,
        textAlign: TextAlign.center,
      ),
      padding: EdgeInsets.all(2*Dimen.DEF_MARG),
      onTap: parent.widget.onTitleTap,
    );


    Widget widgetAuthor = SimpleButton(
      child: Row(
        //crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children:[
            Text(
              'Autor sł.: ',
              style: AppTextStyle(
                fontSize: Dimen.TEXT_SIZE_SMALL,
                color: hintEnabled(context),
              ),
              textAlign: TextAlign.left,
            ),
            if(song.author.length>0)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    song.author,
                    style: AppTextStyle(
                      fontWeight: weight.halfBold,
                      fontSize: Dimen.TEXT_SIZE_SMALL,
                      color: textEnabled(context),
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              )
          ]
      ),
      onTap: parent.widget.onAuthorTap,
    );

    Widget widgetPerformer = SimpleButton(
      child: Row(
        //crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children:[
          Text(
            'Wykona.: ',
            style: AppTextStyle(
              fontSize: Dimen.TEXT_SIZE_SMALL,
              color: hintEnabled(context),
            ),
            textAlign: TextAlign.left,
          ),

          if(song.performer.length>0)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  song.performer,
                  style: AppTextStyle(
                    fontWeight: weight.halfBold,
                    fontSize: Dimen.TEXT_SIZE_SMALL,
                    color: textEnabled(context),
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            )
        ],),
      onTap: parent.widget.onPerformerTap,
    );

    Widget widgetTags = Container(
        height: Tag.height,
        child: ListView.builder(
          physics: BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          itemCount: song.tags.length,
          itemBuilder: (BuildContext context, int index) {
            return SimpleButton(
              child: Text(
                song.tags[index],
                style: AppTextStyle(fontSize: Dimen.TEXT_SIZE_SMALL, color: textEnabled(context), fontWeight: weight.halfBold),
              ),
              onTap: parent.widget.onTagTap==null?null:() => parent.widget.onTagTap(song.tags[index]),
            );
          },
        )
    );

    return AppCard.Default(
        padding: EdgeInsets.zero,
        context: context,
        elevation: AppCard.bigElevation,
        child:

        Stack(
          children: <Widget>[

            Padding(
              padding: AppCard.defMargin,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  if(pageNotifier == null) widgetTitle
                  else AnimatedBuilder(
                    animation: pageNotifier,
                    builder: (context, _) => Transform.translate(
                        offset: Offset(MediaQuery.of(context).size.width/4*(pageNotifier.value - index), 0),
                        child: widgetTitle
                    ),
                  ),

                  SizedBox(height: 6,),

                  pageNotifier == null?
                  widgetAuthor
                      :AnimatedBuilder(
                    animation: pageNotifier,
                    builder: (context, _) => Transform.translate(
                        offset: Offset(MediaQuery.of(context).size.width/8*(pageNotifier.value - index), 0),
                        child: widgetAuthor
                    ),
                  ),

                  pageNotifier == null?
                  widgetPerformer
                      :
                  AnimatedBuilder(
                    animation: pageNotifier,
                    builder: (context, _) =>
                        Transform.translate(
                            offset: Offset(MediaQuery.of(context).size.width / 8 * (pageNotifier.value - index), 0),
                            child: widgetPerformer
                        ),
                  ),


                  if(song.tags.length != 0)
                    (pageNotifier == null)? widgetTags
                        : AnimatedBuilder(
                      animation: pageNotifier,
                      builder: (context, _) => Transform.translate(
                          offset: Offset(MediaQuery.of(context).size.width/8*(pageNotifier.value - index), 0),
                          child: widgetTags
                      ),
                    ),

                ],
              ),
            ),
          ],
        )


    );
  }

}

class ButtonWidget<T extends SongCore> extends StatelessWidget{

  final SongWidgetTemplateState<T> fragmentState;
  const ButtonWidget(this.fragmentState);

  @override
  Widget build(BuildContext context) {

    PageController controller = PageController();

    return Row(
      children: <Widget>[
        IconButton(
          icon: Icon(MdiIcons.dotsHorizontal, color: iconEnabledColor(context)),
          onPressed: (){
            controller.animateToPage(
              (controller.page-1).abs().toInt(),
              duration: Duration(milliseconds: 150),
              curve: Curves.easeInOutSine,
            );
          },
        ),

        Expanded(
          child: Container(
            child: PageView(
              scrollDirection: Axis.vertical,
              physics: NeverScrollableScrollPhysics(),
              children: <Widget>[
                TopWidget<T>(fragmentState),
                BottomWidget<T>(fragmentState)
              ],
              controller: controller,
            ),
            height: Dimen.ICON_SIZE + 2*Dimen.MARG_ICON,
          ),
        )

      ],
    );
  }

}

class TopWidget<T extends SongCore> extends StatelessWidget{

  final SongWidgetTemplateState<T> parent;

  T get song => parent.widget.song;

  double get topScreenPadding => parent.widget.topScreenPadding;

  const TopWidget(this.parent);


  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: BouncingScrollPhysics(),
      reverse: true,
      child: Row(
        children: [

          if(song.youtubeLink != null && song.youtubeLink.length!=0)
            AppButton(
                icon: Icon(
                    MdiIcons.playOutline,
                    color: iconEnabledColor(context)
                ),
                onLongPress: parent.widget.onYTLinkLongPress,
                onTap: parent.widget.onYTLinkTap==null?null:(){
                  final RenderBox renderBox = parent.contentCardsKey.currentContext.findRenderObject();
                  final position = renderBox.localToGlobal(Offset.zero).dy - parent.widget.topScreenPadding;
                  parent.widget.onYTLinkTap(position);
                }
            ),

          IconButton(icon: Icon(MdiIcons.minusCircleOutline, color: iconEnabledColor(context)),
              onPressed: parent.widget.onMinusTap==null?null:(){

                TextSizeProvider prov = Provider.of<TextSizeProvider>(context, listen: false);

                bool changedSize = true;
                if(prov.value-0.5 >= Dimen.TEXT_SIZE_LIMIT)
                  prov.value -= 0.5;
                else
                  changedSize = false;

                parent.widget.onMinusTap(context, changedSize);

              }),
          IconButton(icon: Icon(MdiIcons.plusCircleOutline, color: iconEnabledColor(context)),
              onPressed: parent.widget.onPlusTap==null?null:(){

                TextSizeProvider prov = Provider.of<TextSizeProvider>(context, listen: false);

                double scaleFactor = TextSizeProvider.fits(
                    parent.widget.screenWidth??MediaQuery.of(context).size.width,
                    song.text,
                    parent.showChords()?song.getChords():null,
                    parent.lineNum,
                    prov.value + 0.5);

                bool changedSize = true;
                if(scaleFactor == 1){
                  if(prov.value >= 24) changedSize = false;
                  else parent.setState(() => prov.value += 0.5);
                }else
                  changedSize = false;

                parent.widget.onPlusTap(context, changedSize);
              }
          ),

          IconButton(
            icon: Icon(MdiIcons.bookmarkCheckOutline, color: iconEnabledColor(context)),
            onPressed: parent.widget.onAlbumsTap,
          ),

          IconButton(
              icon: RateIcon.build(context, song.rate),
              onPressed: parent.widget.onRateTap==null?null:
                  (){
                final RenderBox renderBox = parent.contentCardsKey.currentContext.findRenderObject();
                final position = renderBox.localToGlobal(Offset.zero).dy - parent.widget.topScreenPadding;
                parent.widget.onRateTap(position);
              }
          )
        ],
      ),
    );
  }

}

class BottomWidget<T extends SongCore> extends StatelessWidget{

  final SongWidgetTemplateState<T> parent;
  const BottomWidget(this.parent);

  T get song => parent.song;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: BouncingScrollPhysics(),
      reverse: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if(!song.official)
            AppButton(
                icon: Icon(MdiIcons.trashCanOutline, color: iconEnabledColor(context)),
                onTap: parent.widget.onDeleteTap,
                onLongPress: parent.widget.onDeleteLongPress),
          if(song.official)
            IconButton(icon: Icon(MdiIcons.alertOutline, color: iconEnabledColor(context)),
                onPressed: parent.widget.onReportTap),
          IconButton(
              icon: Icon(MdiIcons.pencilOutline, color: iconEnabledColor(context)),
              onPressed: parent.widget.onEditTap==null?null:
                  () => parent.widget.onEditTap(Provider.of<TextSizeProvider>(context, listen: false))
          ),

          IconButton(
              icon: Icon(MdiIcons.shareVariant, color: iconEnabledColor(context)),
              onPressed: parent.widget.onShareTap
          ),

          if(!song.official)
            IconButton(
                icon: Icon(
                    MdiIcons.sendCircleOutline,
                    color: iconEnabledColor(context)),
                onPressed: parent.widget.onSendSongTap
            ),

          IconButton(icon: Icon(MdiIcons.contentCopy, color: iconEnabledColor(context)),
              onPressed: parent.widget.onCopyTap
          ),

        ],
      ),
    );
  }
}

class ContentWidget<T extends SongCore> extends StatelessWidget{

  final SongWidgetTemplateState<T> parent;
  final ScrollController listView;

  T get song => parent.widget.song;

  String get text => song.text;
  String get chords => song.getChords();
  String get lineNum => parent.lineNum;

  static const double lineSpacing = 1.2;

  const ContentWidget(this.parent, this.listView, {GlobalKey globalKey}):super(key: globalKey);

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[

        Consumer<TextSizeProvider>(
          builder: (context, prov, child) => Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Expanded(
                child: SimpleButton(
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Expanded(
                            child: Text(
                              text,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: prov.value, //initial font size
                                color: textEnabled(context),
                                height: lineSpacing,
                              ),
                            )
                        ),
                        Text(
                          lineNum,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: prov.value<Dimen.TEXT_SIZE_TINY?
                              prov.value:
                              Dimen.TEXT_SIZE_TINY,//initial font size
                              color: hintDisabled(context),
                              height: prov.value<Dimen.TEXT_SIZE_TINY?
                              lineSpacing:
                              lineSpacing*(prov.value/ Dimen.TEXT_SIZE_TINY)
                          ),
                        ),
                      ],
                    ),
                    onTap: (){
                      if(Settings.scrollText) {

                        double scrollDefDelta = MediaQuery.of(context).size.height / 2;
                        double scrollDelta = min(
                            scrollDefDelta,
                            listView.position.maxScrollExtent - listView.offset
                        );

                        int scrollDuration = (2000*scrollDelta/scrollDefDelta).round();

                        listView.animateTo(
                            listView.offset + scrollDelta,
                            duration: Duration(milliseconds: scrollDuration),
                            curve: Curves.ease
                        );
                      }
                    },
                    onLongPress: () async {
                      if(!Settings.autoscrollText) return;

                      double scrollLeft = listView.position.maxScrollExtent - listView.offset;
                      double duration = scrollLeft*(1.1-Settings.autoscrollTextSpeed)*500;
                      listView.animateTo(
                          listView.position.maxScrollExtent,
                          duration: Duration(milliseconds: duration.round()),
                          curve: Curves.linear);
                    }
                ),
              ),

              Consumer<ShowChordsProvider>(
                  builder: (context, showChordsProv, child){

                    if(!showChordsProv.showChords)
                      return Container();
                    return SimpleButton(
                        child: Text(
                          chords,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: prov.value, //initial font size
                            color: textEnabled(context),
                            height: lineSpacing,
                          ),
                        ),
                        onTap: parent.widget.onChordsTap==null?null:(){
                          parent.widget.onChordsTap(prov);
                        },
                        onLongPress: parent.widget.onChordsLongPress==null?null:(){
                          parent.widget.onChordsLongPress(prov);
                        }
                    );

                  }
              )
            ],
          ),
        )
      ],
    );
  }

}

class ChordsBarCard<T extends SongCore> extends StatelessWidget{

  final SongWidgetTemplateState parent;

  const ChordsBarCard(this.parent);

  T get song => parent.song;

  @override
  Widget build(BuildContext context) {

    Widget chordsBar = Consumer<ChordsDrawTypeProvider>(
      builder: (context, prov, child) => ChordDrawBar(
        song.getChords(),
        typeGuitar: PrimitiveWrapper(Settings.chordsDrawType),
        onTypeChanged: parent.widget.onChordsTypeChanged,
        elevation: 0,
        chordBackground: Colors.transparent,
      ),
    );

    /*
    bool chordsLocked = Settings.pinChordsDraw;

    if(chordsLocked)
      return AppCard.Default(
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppCard.defRadius)),
          context: context,
          margin: EdgeInsets.zero,
          elevation: AppCard.bigElevation,
          child: chordsBar
      );

    else */
    return chordsBar;

  }

}


