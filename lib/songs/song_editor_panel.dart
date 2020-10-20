
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core_own_song/common.dart';
import 'package:harcapp_core_own_song/page_widgets/add_buttons_widget.dart';
import 'package:harcapp_core_own_song/page_widgets/refren_template.dart';
import 'package:harcapp_core_own_song/page_widgets/scroll_to_bottom.dart';
import 'package:harcapp_core_own_song/page_widgets/song_parts_list_widget.dart';
import 'package:harcapp_core_own_song/page_widgets/tags_widget.dart';
import 'package:harcapp_core_own_song/page_widgets/top_cards.dart';
import 'package:harcapp_core_own_song/providers.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '_main.dart';

class SongEditorPanel extends StatelessWidget{

  static const double SEPARATOR_HEIGHT = 42;

  final SongsPageState parent;

  const SongEditorPanel(this.parent);

  @override
  Widget build(BuildContext context) {

    return Consumer<SongEditorPanelProvider>(
      builder: (context, prov, child){

        CurrentItemProvider currItemProv = Provider.of<CurrentItemProvider>(context, listen: false);
        SongPreviewProvider songPrevProv = Provider.of<SongPreviewProvider>(context, listen: false);
        if(currItemProv.song == null)
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Dodaj lub importuj piosenkę.',
                style: AppTextStyle(
                    fontSize: Dimen.TEXT_SIZE_BIG,
                    color: textDisabled(context),
                    fontWeight: weight.halfBold
                ),
              ),

              SizedBox(height: 24),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(MdiIcons.arrowLeft, color: textDisabled(context)),
                  SizedBox(width: Dimen.MARG_ICON),
                  Text(
                    'Zerknij tam!',
                    style: AppTextStyle(
                        fontSize: Dimen.TEXT_SIZE_BIG,
                        color: textDisabled(context),
                        fontWeight: weight.bold
                    ),
                  ),
                  SizedBox(width: Dimen.MARG_ICON),
                  Icon(MdiIcons.musicNote, color: textDisabled(context)),
                ],
              )
            ],
          );
        else
          return Column(
            children: [

              Expanded(
                child: SongPartsListWidget(
                    controller: parent.scrollController,
                    shrinkWrap: true,
                    onPartTap: (part, prov) async {
                      if(part.isRefren(context)) return;
                      parent.setState((){
                        parent.part = part;
                        parent.showEditor = true;
                      });

                      parent.onSongPartChanged = parent.getSongPartChangedFunction(prov);
                    },
                    onDelete: (){
                      currItemProv.notifyListeners();
                    },

                    header: Column(
                      children: [


                        HeaderWidget('Info. ogólne', MdiIcons.textBoxOutline),
                        Consumer<BindTitleFileNameProvider>(
                          builder: (context, prov, child) =>
                              SwitchListTile(
                                contentPadding: EdgeInsets.only(left: Dimen.MARG_ICON),
                                value: prov.bind,
                                onChanged: (value) => prov.bind = value,
                                secondary: Icon(
                                    MdiIcons.paperclip,
                                    color: prov.bind?iconEnabledColor(context):iconDisabledColor(context)
                                ),
                                title: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Powiąż nazwę pliku z tytułem',
                                      style: AppTextStyle(
                                          fontWeight: weight.halfBold,
                                          color: prov.bind?textEnabled(context):textDisabled(context),
                                          fontSize: Dimen.TEXT_SIZE_BIG
                                      ),
                                    ),
                                    SizedBox(width: Dimen.MARG_ICON),

                                  ],
                                ),
                              ),
                        ),

                        TopCards(
                          onChangedTitle: (String text){
                            currItemProv.title = text;
                          },
                          onChangedAuthor: (String text){
                            currItemProv.author = text;
                          },
                          onChangedPerformer: (String text){
                            currItemProv.performer = text;
                          },
                          onChangedYT: (String text){
                            currItemProv.youtubeLink = text;
                          },
                          onChangedAddPers: (String text){
                            currItemProv.addPers = text;
                          },
                        ),

                        SizedBox(height: SEPARATOR_HEIGHT),

                        TagsWidget(
                          linear: false,
                          onChanged: (List<String> tags){
                            currItemProv.tags = tags;
                          },
                        ),

                        SizedBox(height: SEPARATOR_HEIGHT),

                        RefrenTemplate(
                            onPartTap: (part, prov) {
                              parent.setState((){
                                parent.part = part;
                                parent.showEditor = true;
                              });
                              parent.onSongPartChanged = parent.getSongPartChangedFunction(prov);
                            },
                            onRefrenEnabledChaned: (bool value){
                              currItemProv.hasRefren = value;
                              //songPrevProv.resizeText();
                            }
                        ),

                        SizedBox(height: SEPARATOR_HEIGHT),

                        HeaderWidget('Struktura piosenki', MdiIcons.playlistMusic),

                      ],
                    ),
                ),
              ),

              AddButtonsWidget(onPressed: () => scrollToBottom(parent.scrollController))
            ],
          );

      },
    );

  }

}