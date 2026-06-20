import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/comm_widgets/title_show_row_widget.dart';
import 'package:harcapp_core/song_book/song_editor/widgets/contributor_ref_list_widget.dart';
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
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
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

      if(!showSongProv.showSong)
        return Padding(
          padding: EdgeInsets.only(top: 54.0),
          child: SongEditorNoSongWidget(workspaceAlwaysVisible: widget.workspaceAlwaysVisible),
        );

      return Stack(
        children: [
          Consumer2<SimilarSongProvider, CurrentItemProvider>(
            builder: (context, simProv, currProv, _){
              bool bannerVisible = simProv.allSongs != null
                  && simProv.hasSimilarSong(currProv.titleController.text);
              return AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(top: bannerVisible ? _bannerSpace : 0),
                child: _buildPartsList(context, currProv),
              );
            },
          ),
          Positioned(
            top: Dimen.iconMarg * 2,
            left: 0,
            right: 0,
            child: SimilarSongWidget(),
          ),
        ],
      );
    },
  );

  static const double _bannerSpace = Dimen.iconMarg * 2 + Dimen.iconFootprint + Dimen.defMarg;

  Widget _buildPartsList(BuildContext context, CurrentItemProvider currItemProv) => SongPartsListWidget(
        // shrinkWrap: true,
        maxDialogWidth: appDialogMaxWidth,
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

            Material(
              color: backgroundIcon_(context),
              borderRadius: BorderRadius.circular(AppCard.bigRadius),
              clipBehavior: Clip.hardEdge,
              child: Column(
                children: [

                  Consumer<BindTitleFileNameProvider>(
                    builder: (context, prov, child) => _BindIdToggleRow(
                      label: 'Powiąż z tytułem',
                      value: prov.bindTitle,
                      onChanged: (value){
                        prov.bindTitle = value;
                        if(prov.bindTitle)
                          CurrentItemProvider.of(context).setLclIdFromTitleAndPerformer(withPerformer: prov.bindPerformer);
                        SongFileNameDupErrProvider.of(context).checkAllDups(context);
                      },
                    ),
                  ),

                  Divider(height: 1, color: hintEnab_(context).withValues(alpha: 0.12)),

                  Consumer2<BindTitleFileNameProvider, CurrentItemProvider>(
                    builder: (context, bindTitleFileNameProv, currItemProv, child){
                      bool hasPerformer = currItemProv.performersController.isContentNotEmpty;
                      return _BindIdToggleRow(
                        label: 'Powiąż z wykonawcą',
                        value: hasPerformer && bindTitleFileNameProv.bindPerformer,
                        onChanged: !hasPerformer ? null : (value){
                          bindTitleFileNameProv.bindPerformer = value;
                          if(bindTitleFileNameProv.bindTitle)
                            CurrentItemProvider.of(context).setLclIdFromTitleAndPerformer(withPerformer: value);
                          SongFileNameDupErrProvider.of(context).checkAllDups(context);
                        },
                      );
                    },
                  ),

                ],
              ),
            ),

            SizedBox(height: Dimen.defMarg),

            TitleShortcutRowWidget(
              title: 'Info. ogólne',
              textAlign: TextAlign.left,
            ),

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

            const ContributorRefListWidget(),

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

}

class SimilarSongWidget extends StatelessWidget{

  static IconData icon = MdiIcons.musicBoxMultiple;

  @override
  Widget build(BuildContext context) => Consumer2<SimilarSongProvider, CurrentItemProvider>(
      builder: (context, similarSongProv, currItemProv, child){
        if(similarSongProv.allSongs == null) return const SizedBox.shrink();
        if(!similarSongProv.hasSimilarSong(currItemProv.titleController.text))
          return const SizedBox.shrink();
        return _FoundSimilarSongWidget();
      }
  );

}

class _FoundSimilarSongWidget extends StatelessWidget{

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppCard.bigRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 18,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppCard.bigRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(AppCard.bigRadius),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: Dimen.defMarg, vertical: Dimen.defMarg / 2),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.all(Dimen.iconMarg),
                child: Icon(SimilarSongWidget.icon, color: Colors.red),
              ),

              Expanded(
                child: Text(
                  'Piosenka o takim tytule już jest!',
                  style: AppTextStyle(
                    color: Colors.red,
                    fontWeight: weightBold,
                    fontSize: Dimen.textSizeBig,
                  ),
                ),
              ),

              SimpleButton.from(
                context: context,
                icon: MdiIcons.eye,
                margin: EdgeInsets.zero,
                padding: EdgeInsets.symmetric(
                  horizontal: Dimen.iconMarg,
                  vertical: Dimen.defMarg,
                ),
                iconLeading: false,
                text: 'Podgląd',
                iconColor: Colors.red,
                textColor: Colors.red,
                onTap: () => showDialog(
                  context: context,
                  builder: (context) => Padding(
                    padding: EdgeInsets.all(Dimen.sideMarg),
                    child: SimilarSongViewerDialog(
                      currentSong: CurrentItemProvider.of(context).song,
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    ),
  );



}

class _BindIdToggleRow extends StatelessWidget {

  final String label;
  final bool value;
  final void Function(bool)? onChanged;

  const _BindIdToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    bool disabled = onChanged == null;
    return InkWell(
      onTap: disabled ? null : () => onChanged!(!value),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Dimen.iconMarg,
          vertical: Dimen.defMarg,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyle(
                  color: disabled
                      ? textDisab_(context)
                      : (value ? textEnab_(context) : hintEnab_(context)),
                  fontSize: Dimen.textSizeBig,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

}