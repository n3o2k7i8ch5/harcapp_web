import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/comm_widgets/title_show_row_widget.dart';
import 'package:harcapp_core/song_book/song_editor/widgets/contributor_identity_list_widget.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/song_book/song_editor/providers.dart';
import 'package:harcapp_core/song_book/song_editor/widgets/add_buttons_widget.dart';
import 'package:harcapp_core/song_book/song_editor/widgets/basic_data_widget.dart';
import 'package:harcapp_core/song_book/song_editor/widgets/refren_template.dart';
import 'package:harcapp_core/song_book/song_editor/widgets/scroll_to_bottom.dart';
import 'package:harcapp_core/song_book/song_editor/widgets/song_parts_list_widget.dart';
import 'package:harcapp_core/song_book/song_editor/widgets/tags_widget.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/similar_song_viewer.dart';
import 'package:harcapp_web/songs/song_editor_no_song_widget.dart';
import 'package:harcapp_web/songs/song_part_editor.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../consts.dart';

class SongEditorPanel extends StatefulWidget{

  final bool workspaceAlwaysVisible;

  const SongEditorPanel({required this.workspaceAlwaysVisible});

  @override
  State<StatefulWidget> createState() => SongEditorPanelState();

}

class SongEditorPanelState extends State<SongEditorPanel>{

  static const double SEPARATOR_HEIGHT = 42;

  late ScrollController scrollController;

  @override
  void initState() {
    scrollController = ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _updateBindingIfNeeded(BuildContext context) {
    final bindProv = BindTitleFileNameProvider.of(context);
    if (bindProv.bindTitle) {
      CurrentItemProvider.of(context).setLclIdFromTitleAndPerformer(withPerformer: bindProv.bindPerformer);
      SongFileNameDupErrProvider.of(context).checkAllDups(context);
    }
  }

  Future<void> _editPart({
    required BuildContext context,
    required dynamic part,
    required VoidCallback onAfterChange,
    bool barrierDismissible = true,
  }) async {
    String text = part.getText();
    String chords = part.chords;
    bool shifted = part.shift;
    bool isError = part.isError;

    await showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => Center(
        child: SizedBox(
          width: songDialogWidth,
          child: SongPartEditor(
            initText: text,
            initChords: chords,
            initShifted: shifted,
            isRefren: part.isRefren(dialogContext),
            onTextChanged: (newText, errCount) {
              text = newText;
              isError = errCount != 0;
            },
            onChordsChanged: (newChords, errCount) {
              chords = newChords;
              isError = errCount != 0;
            },
            onShiftedChanged: (newShifted) {
              shifted = newShifted;
            },
          ),
        ),
      ),
    );

    part.setText(text);
    part.chords = chords;
    part.shift = shifted;
    part.isError = isError;
    onAfterChange();
  }

  @override
  Widget build(BuildContext context) => Consumer2<SongEditorPanelProvider, SongPreviewProvider>(
    builder: (context, prov, showSongProv, child){

      CurrentItemProvider currItemProv = CurrentItemProvider.of(context);

      if(!showSongProv.showSong)
        return Padding(
          padding: EdgeInsets.only(top: 54.0),
          child: SongEditorNoSongWidget(workspaceAlwaysVisible: widget.workspaceAlwaysVisible),
        );

      return SongPartsListWidget(
        // shrinkWrap: true,
        onPartTap: (index) async {
          final part = currItemProv.song.songParts[index];
          await _editPart(
            context: context,
            part: part,
            onAfterChange: () => currItemProv.notify(),
          );
        },
        controller: scrollController,
        header: Column(
          children: [

            SizedBox(height: Dimen.iconMarg),

            TitleShortcutRowWidget(
              title: 'Identyfikator piosenki',
              textAlign: TextAlign.left,
            ),

            Consumer<BindTitleFileNameProvider>(
              builder: (context, prov, child) =>
                SwitchListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppCard.bigRadius)),
                  hoverColor: Colors.transparent,
                  contentPadding: EdgeInsets.zero,
                  value: prov.bindTitle,
                  onChanged: (value){
                    prov.bindTitle = value;
                    if(prov.bindTitle)
                      CurrentItemProvider.of(context).setLclIdFromTitleAndPerformer(withPerformer: prov.bindPerformer);
                    SongFileNameDupErrProvider.of(context).checkAllDups(context);
                  },
                  title: Text(
                    'Powiąż identyfikator piosenki z tytułem',
                    style: AppTextStyle(
                      color: prov.bindTitle?textEnab_(context):textDisab_(context),
                      fontSize: Dimen.textSizeBig
                    ),
                  ),
                ),
            ),

            SizedBox(height: Dimen.defMarg),

            Consumer2<BindTitleFileNameProvider, CurrentItemProvider>(
              builder: (context, bindTitleFileNameProv, currItemProv, child) =>
                  IgnorePointer(
                    ignoring: currItemProv.performersController.isContentEmpty,
                    child: AnimatedOpacity(
                      duration: Duration(milliseconds: 300),
                      opacity: currItemProv.performersController.isContentEmpty?
                      0.3:
                      1.0,

                      child: SwitchListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppCard.bigRadius)),
                        hoverColor: Colors.transparent,
                        contentPadding: EdgeInsets.zero,
                        value: currItemProv.performersController.isContentNotEmpty && bindTitleFileNameProv.bindPerformer,
                        onChanged: (value) {
                          bindTitleFileNameProv.bindPerformer = value;

                          if(bindTitleFileNameProv.bindTitle)
                            CurrentItemProvider.of(context).setLclIdFromTitleAndPerformer(withPerformer: value);

                          SongFileNameDupErrProvider.of(context).checkAllDups(context);

                        },
                        title: Text(
                          'Powiąż identyfikator piosenki z wykonawcą',
                          style: AppTextStyle(
                              color: bindTitleFileNameProv.bindPerformer?
                              textEnab_(context):
                              textDisab_(context),

                              fontSize: Dimen.textSizeBig
                          ),
                        ),
                      ),
                    ),
                  ),
            ),

            SizedBox(height: Dimen.defMarg),

            TitleShortcutRowWidget(
              title: 'Info. ogólne',
              textAlign: TextAlign.left,
            ),

            SimilarSongWidget(),

            SizedBox(height: Dimen.defMarg),

            BasicDataWidget(
              onChangedTitle: (String text) => _updateBindingIfNeeded(context),
              onChangedHiddenTitles: (List<String> texts) => currItemProv.notify(),
              onChangedAuthor: (List<String> texts) => currItemProv.notify(),
              onChangedComposer: (List<String> texts) => currItemProv.notify(),
              onChangedPerformer: (List<String> texts){
                currItemProv.notify();
                _updateBindingIfNeeded(context);
              },
              onChangedYT: (String? text) => currItemProv.notify(),
            ),

            const SizedBox(height: Dimen.defMarg),

            const ContributorIdentityListWidget(),

            const SizedBox(height: Dimen.defMarg),

            SongTagsWidget(
              linear: false,
              onChanged: (List<String> tags){
                currItemProv.setTags(tags, notify: false);
              },
            ),

            SizedBox(height: SEPARATOR_HEIGHT),

            RefrenTemplate(
                accentColor: iconEnab_(context),
                onPartTap: () async {
                  final part = currItemProv.song.refrenPart;
                  await _editPart(
                    context: context,
                    part: part,
                    onAfterChange: () {
                      currItemProv.notify();
                      Provider.of<RefrenPartProvider>(context, listen: false).notify();
                    },
                    barrierDismissible: false,
                  );
                }
            ),

            SizedBox(height: SEPARATOR_HEIGHT),

            TitleShortcutRowWidget(
              title: 'Struktura piosenki',
              textAlign: TextAlign.left,
            )

          ],
        ),
        footer: Material(
          elevation: AppCard.bigElevation,
          borderRadius: BorderRadius.circular(AppCard.bigRadius),
          color: cardEnab_(context),
          child: AddButtonsWidget(onPressed: () => scrollToBottom(scrollController)),
        ),
      );

    },
  );

}

class SimilarSongWidget extends StatelessWidget{

  static IconData icon = MdiIcons.musicBoxMultiple;

  @override
  Widget build(BuildContext context) => Consumer2<SimilarSongProvider, CurrentItemProvider>(
      builder: (context, similarSongProv, currItemProv, child) => Material(
          borderRadius: BorderRadius.circular(AppCard.bigRadius),
          clipBehavior: Clip.hardEdge,
          child:
          similarSongProv.allSongs == null?
          Row(
            children: [
              Padding(
                padding: EdgeInsets.all(Dimen.iconMarg),
                child: Icon(MdiIcons.timerSand, color: hintEnab_(context)),
              ),
              Expanded(child: Text(
                'Ładowanie listy istniejących piosenek...',
                style: AppTextStyle(fontSize: Dimen.textSizeBig, fontWeight: weightHalfBold, color: hintEnab_(context)),
                textAlign: TextAlign.center,
              )),
              SizedBox(width: Dimen.iconFootprint)
            ],
          ):(
              !similarSongProv.hasSimilarSong(currItemProv.titleController.text)?
              _NoSimilarSongsWidget():
              _FoundSimilarSongWidget()
          )

      )
  );

}

class _NoSimilarSongsWidget extends StatelessWidget{

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Padding(
          padding: EdgeInsets.all(Dimen.iconMarg),
          child: Icon(MdiIcons.check, color: accent_(context))
      ),

      Expanded(
        child: Text(
          'Sądząc po tytule, tego jeszcze nie ma w śpiewniku!',
          style: AppTextStyle(fontSize: Dimen.textSizeBig, fontWeight: weightHalfBold, color: accent_(context)),
          textAlign: TextAlign.center,
        )
      ),
      SizedBox(width: Dimen.iconFootprint)
    ],
  );

}

class _FoundSimilarSongWidget extends StatelessWidget{

  @override
  Widget build(BuildContext context) => Consumer2<SimilarSongProvider, CurrentItemProvider>(
      builder: (context, similarSongProv, currItemProv, child) => Row(
        children: [
          Padding(
            padding: EdgeInsets.all(Dimen.iconMarg),
            child: Icon(SimilarSongWidget.icon, color: Colors.red),
          ),

          Expanded(child: Text(
            'Piosenka o takim tytule już jest!',
            style: AppTextStyle(color: Colors.red, fontWeight: weightHalfBold, fontSize: Dimen.textSizeBig),
            textAlign: TextAlign.center,
          )),

          SimpleButton.from(
              context: context,
              icon: MdiIcons.eye,
              margin: EdgeInsets.zero,
              iconLeading: false,
              text: 'Podgląd',
              onTap: () => showDialog(
                context: context,
                builder: (context) => Padding(
                  padding: EdgeInsets.all(Dimen.sideMarg),
                  child: SimilarSongViewerDialog(),
                ),
              )
          ),

        ],
      )
  );



}