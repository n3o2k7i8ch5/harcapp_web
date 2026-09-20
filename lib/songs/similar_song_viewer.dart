import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_bar.dart';
import 'package:harcapp_core/comm_widgets/app_button.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/title_show_row_widget.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/song_book/widgets/song_widget_template.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/consts.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/song_preview_widget.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

/// Dwie piosenki obok siebie: po lewej to, z czym porównujemy, po prawej ta
/// z edytora. Domyślnie po lewej są piosenki z apki o tym samym tytule;
/// [compareTo] podmienia je na konkretne — tak poprawka staje obok
/// pierwowzoru.
class SimilarSongViewerDialog extends StatefulWidget{

  final SongRaw currentSong;
  final List<SongRaw>? compareTo;
  final String dialogTitle;
  final String currentTitle;
  final String Function(int index)? compareTitle;

  const SimilarSongViewerDialog({
    required this.currentSong,
    this.compareTo,
    this.dialogTitle = 'Podobne piosenki',
    this.currentTitle = 'Aktualna piosenka',
    this.compareTitle,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => SimilarSongViewerDialogState();

}

class SimilarSongViewerDialogState extends State<SimilarSongViewerDialog>{

  late List<SongRaw> similarSongs;

  late PageController controller;

  @override
  void initState() {
    SimilarSongProvider similarSongProv = SimilarSongProvider.of(context);

    similarSongs = widget.compareTo
        ?? similarSongProv.getSimilarSongs(widget.currentSong.title)
        ?? [];

    controller = PageController(viewportFraction: 0.75);

    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: songPreviewWidth*2.5 + 6*Dimen.sideMarg + 2*Dimen.iconFootprint,
        ),
        child: Material(
            color: cardEnab_(context),
            clipBehavior: Clip.hardEdge,
            borderRadius: BorderRadius.circular(AppCard.bigRadius),
            child: Column(
              children: [

                AppBarX(
                  title: widget.dialogTitle,
                  backgroundColor: cardEnab_(context),
                ),

                Expanded(
                  child:  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      SizedBox(width: Dimen.sideMarg),

                      // Strzałki tylko, gdy jest między czym przewijać —
                      // przy jednej piosence po lewej nic nie robiły.
                      if(similarSongs.length > 1)
                        Material(
                          color: background_(context),
                          elevation: AppCard.bigElevation,
                          borderRadius: BorderRadius.circular(100),
                          clipBehavior: Clip.hardEdge,
                          child: AppButton(
                            icon: Icon(MdiIcons.chevronLeft),
                            onTap: () async {
                              await controller.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOutCubic);
                            },
                          ),
                        ),

                      SizedBox(
                          width: songPreviewWidth * 1.5 + 2*Dimen.sideMarg,
                          child: Padding(
                            padding: EdgeInsets.all(Dimen.sideMarg),
                            child: Material(
                              borderRadius: BorderRadius.circular(AppCard.bigRadius),
                              elevation: AppCard.bigElevation,
                              color: cardEnab_(context),
                              clipBehavior: Clip.hardEdge,
                              child: PageView.builder(
                                controller: controller,
                                physics: BouncingScrollPhysics(),
                                itemBuilder: (context, index) => Padding(
                                  padding: EdgeInsets.symmetric(horizontal: Dimen.sideMarg/2),
                                  child: _SimilarSongPreview(
                                    song: similarSongs[index],
                                    title: widget.compareTitle?.call(index)
                                        ?? 'Podobna piosenka ${index + 1}',
                                  ),
                                ),
                                itemCount: similarSongs.length,
                              ),
                            ),
                          )
                      ),

                      if(similarSongs.length > 1)
                        Material(
                          color: background_(context),
                          elevation: AppCard.bigElevation,
                          borderRadius: BorderRadius.circular(100),
                          clipBehavior: Clip.hardEdge,
                          child: AppButton(
                            icon: Icon(MdiIcons.chevronRight),
                            onTap: () async {
                              await controller.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOutCubic);
                            },
                          ),
                        ),

                      SizedBox(width: Dimen.sideMarg),

                      Padding(
                        padding: EdgeInsets.all(Dimen.sideMarg),
                        child:  SizedBox(
                          width: songPreviewWidth,
                          child: _SimilarSongPreview(
                            title: widget.currentTitle,
                            song: widget.currentSong,
                            elevation: AppCard.bigElevation,
                          ),
                        ),
                      )

                    ],
                  ),
                )
              ],
            )
        ),
      )
  );

}

class _SimilarSongPreview extends StatefulWidget{

  final String title;
  final SongRaw song;
  final double elevation;

  const _SimilarSongPreview({required this.song, this.title = 'Podobna piosenka', this.elevation = 0});

  @override
  State<_SimilarSongPreview> createState() => _SimilarSongPreviewState();

}

class _SimilarSongPreviewState extends State<_SimilarSongPreview>{

  String get title => widget.title;
  SongRaw get song => widget.song;
  double get elevation => widget.elevation;

  late ScrollController scrollController;
  late SongBaseSettings settings;

  @override
  void initState() {
    scrollController = ScrollController();
    settings = SongBaseSettings();
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
      color: background_(context),
      elevation: elevation,
      borderRadius: BorderRadius.circular(AppCard.bigRadius),
      child: Column(
        children: [

          TitleShortcutRowWidget(title: title, titleColor: hintEnab_(context)),

          Expanded(
            child: SongWidgetTemplate<SongRaw>(
                song,
                settings,
                scrollController: scrollController,
            ),
          )

        ],
      )
  );

}