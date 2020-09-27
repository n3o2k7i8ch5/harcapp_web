
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker_cross/file_picker_cross.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_web/common/app_card.dart';
import 'package:harcapp_web/common/app_text_style.dart';
import 'package:harcapp_web/common/color_pack.dart';
import 'package:harcapp_web/common/dimen.dart';
import 'package:harcapp_web/common/simple_button.dart';
import 'package:harcapp_web/songs/core_song_management/song_element.dart';
import 'package:harcapp_web/songs/page_widgets/add_buttons_widget.dart';
import 'package:harcapp_web/songs/page_widgets/error_widget.dart';
import 'package:harcapp_web/songs/page_widgets/refren_template.dart';
import 'package:harcapp_web/songs/page_widgets/scroll_to_bottom.dart';
import 'package:harcapp_web/songs/page_widgets/song_parts_list_widget.dart';
import 'package:harcapp_web/songs/page_widgets/tags_widget.dart';
import 'package:harcapp_web/songs/page_widgets/top_cards.dart';
import 'package:harcapp_web/songs/song_part_editor.dart';
import 'package:harcapp_web/songs/song_widget/providers.dart';
import 'package:harcapp_web/songs/song_widget/song_widget_template.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import 'core_own_song/common.dart';
import 'core_own_song/providers.dart';
import 'core_song_management/song_raw.dart';
import 'core_tags/tag_layout.dart';

class SongsPage extends StatefulWidget{

  final SongRaw song;

  const SongsPage({this.song});

  @override
  State<StatefulWidget> createState() => SongsPageState();

}

class SongsPageState extends State<SongsPage>{

  SongRaw get song => widget.song;

  TextCtrlsProvider textCtrlsProv;
  HidTitlesProvider hidTitleProv;
  ScrollController scrollController;

  bool showEditor;
  SongPart part;
  Function onSongPartChanged;

  @override
  void initState(){
    showEditor = false;
    scrollController = ScrollController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) {
            hidTitleProv = HidTitlesProvider(hidTitles: song==null?[]:song.hidTitles);
            return hidTitleProv;
          }),
          ChangeNotifierProvider(create: (context) => SongPreviewProvider()),
          ChangeNotifierProvider(create: (context) => RefrenEnabProvider(song==null?true:song.hasRefren)),
          ChangeNotifierProvider(create: (context) => RefrenPartProvider(SongPart.from(song==null?SongElement.empty():song.refrenElement))),
          ChangeNotifierProvider(create: (context) => SongPartsProvider(song==null?[]:song.songElements.map((el) => SongPart.from(el)).toList())),
          ChangeNotifierProvider(create: (context) => TagsProvider(Tag.ALL_TAG_NAMES, song==null?[]:song.tags)),
          ChangeNotifierProvider(create: (context){

            TextEditingController controllerTitle = TextEditingController(text: song==null?'':song.title);
            TextEditingController controllerAuthor = TextEditingController(text: song==null?'':song.author);
            TextEditingController controllerPerformer = TextEditingController(text: song==null?'':song.performer);
            TextEditingController controllerYT = TextEditingController(text: song==null?'':song.youtubeLink);
            TextEditingController controllerAddPers = TextEditingController(text: song==null?'':song.addPers);

            controllerTitle.addListener(() {
              SongPreviewProvider prov = Provider.of<SongPreviewProvider>(context, listen: false);
              prov.notify();
            });
            controllerAuthor.addListener(() {
              SongPreviewProvider prov = Provider.of<SongPreviewProvider>(context, listen: false);
              prov.notify();
            });
            controllerPerformer.addListener(() {
              SongPreviewProvider prov = Provider.of<SongPreviewProvider>(context, listen: false);
              prov.notify();
            });
            controllerYT.addListener(() {
              SongPreviewProvider prov = Provider.of<SongPreviewProvider>(context, listen: false);
              prov.notify();
            });
            controllerAddPers.addListener(() {
              SongPreviewProvider prov = Provider.of<SongPreviewProvider>(context, listen: false);
              prov.notify();
            });

            textCtrlsProv = TextCtrlsProvider(
              controllerTitle: controllerTitle,
              controllerAuthor: controllerAuthor,
              controllerPerformer: controllerPerformer,
              controllerYT: controllerYT,
              controllerAddPers: controllerAddPers,
            );
            return textCtrlsProv;
          }),

        ],
      builder: (context, child) => Scaffold(
        body: Stack(
          children: [

            Row(
              children: [
                Padding(
                  padding: EdgeInsets.all(32),
                  child: AppCard(
                    elevation: AppCard.bigElevation,
                    padding: EdgeInsets.zero,
                    child: WorkspacePart(),
                  ),
                ),

                Expanded(
                    child: Container(
                        constraints: BoxConstraints(minHeight: double.infinity, minWidth: 400),
                        width: 400,
                        child: Padding(
                          padding: EdgeInsets.only(top: 32, bottom: 32, right: 32),
                          child: Column(
                            children: [

                              Expanded(
                                  child: ListView(
                                    controller: scrollController,
                                    children: [

                                      HeaderWidget('Informacje ogólne', MdiIcons.textBoxOutline),
                                      TopCards(),
                                      TagsWidget(
                                        linear: false,
                                        onChanged: (){
                                          SongPreviewProvider prov = Provider.of<SongPreviewProvider>(context, listen: false);
                                          prov.notify();
                                        },
                                      ),

                                      RefrenTemplate(
                                          onPartTap: (part, prov) {
                                            setState((){
                                              this.part = part;
                                              this.showEditor = true;
                                            });
                                            onSongPartChanged = () => prov.notify();
                                          }
                                      ),
                                      HeaderWidget('Struktura piosenki', MdiIcons.playlistMusic),
                                      SongPartsListWidget(
                                        shrinkWrap: true,
                                        onPartTap: (part, prov) async {
                                          if(part.isRefren(context)) return;
                                          setState((){
                                            this.part = part;
                                            this.showEditor = true;
                                          });

                                          onSongPartChanged = () => prov.notify();
                                        },
                                        onChanged: (){
                                          SongPreviewProvider prov = Provider.of<SongPreviewProvider>(context, listen: false);
                                          prov.notify();
                                        }
                                      ),

                                    ],
                                  )
                              ),

                              AddButtonsWidget(onPressed: () => scrollToBottom(scrollController)),

                            ],
                          ),
                        )
                    )
                ),

                SongPreview(),

              ],
            ),

            AnimatedOpacity(
                opacity: showEditor?1:0,
                duration: Duration(milliseconds: 500),
                child: IgnorePointer(
                  ignoring: !showEditor,
                  child: SongEditorDialog(this),
                )
            )

          ],
        ),
      ),
    );
  }

}

class WorkspacePart extends StatefulWidget{

  @override
  State<StatefulWidget> createState() => WorkspacePartState();

}

class WorkspacePartState extends State<WorkspacePart>{

  @override
  Widget build(BuildContext context) {

    return Container(
      width: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.max,
        children: [
          HeaderWidget(
            'Przestrzeń robocza',
            MdiIcons.toolboxOutline,
            enabled: false,
          ),
          Expanded(child: Center(
            child: SimpleButton(
                radius: 100,
                margin: EdgeInsets.all(Dimen.MARG_ICON),
                padding: EdgeInsets.all(Dimen.MARG_ICON),
                child: Text('Importuj piosenki', style: AppTextStyle(fontSize: Dimen.TEXT_SIZE_BIG), textAlign: TextAlign.center),
                onTap: ()async{

                  FilePickerCross filePikcer = FilePickerCross();
                  bool picked = await filePikcer.pick();
                  if(picked){
                    Uint8List uint8List = filePikcer.toUint8List();
                    String code = utf8.decode(uint8List);
                    print(code);
                  }

                }
            ),
          ))
        ],
      ),
    );
  }

}

class SongEditorDialog extends StatelessWidget{

  final SongsPageState parent;

  const SongEditorDialog(this.parent);

  @override
  Widget build(BuildContext context) {

    if(parent.part == null)
      return Container();

    return GestureDetector(
          onTap: () => parent.setState(() => parent.showEditor = false),
          child: Container(
            width: double.infinity,
            color: Colors.black54,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Container(
                    width: 500,
                    child: SongPartEditor(
                      parent.part,
                      isRefren: parent.part.isRefren(context),
                      onTextChanged: (){
                        parent.onSongPartChanged();
                        SongPreviewProvider prov = Provider.of<SongPreviewProvider>(context, listen: false);
                        prov.notify();
                      },
                      onChordsChanged: (){
                        parent.onSongPartChanged();
                        SongPreviewProvider prov = Provider.of<SongPreviewProvider>(context, listen: false);
                        prov.notify();
                      },
                      onShiftChanged: (){
                        parent.onSongPartChanged();
                        SongPreviewProvider prov = Provider.of<SongPreviewProvider>(context, listen: false);
                        prov.notify();
                      },
                      topBuilder: (context, state) => ButtonsWidget(state),
                      bottomBuilder: (context, state) => ErrorListWidget(state, true),
                    )
                ),
              )
            ),
          )
      );
  }

}

class SongPreview extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constrains){
          return AnimatedContainer(
            duration: Duration(milliseconds: 0),
            width: MediaQuery.of(context).size.width<1200 + 4*32?0:400,
            child: Padding(
                padding: EdgeInsets.only(top: 32, bottom: 32, right: 32),
                child: Column(
                  children: [

                    HeaderWidget('Podgląd piosenki', MdiIcons.bookmarkMusicOutline, enabled: false),

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
                          child: Consumer<SongPreviewProvider>(
                            builder: (context, prov, child){
                              print('new new new');
                              return SongWidgetTemplate(
                                  SongRaw.parse('o!_fileName', convertToCode(context, 'o!_fileName'))
                              );
                            }
                          )
                        ),
                      ),
                    )

                  ],
                )
            ),
          );
        }
    );
  }
}

class SongPreviewProvider extends ChangeNotifier{

  void notify() => notifyListeners();

}
