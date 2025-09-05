import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/common.dart';
import 'package:harcapp_core/comm_widgets/app_bar.dart';
import 'package:harcapp_core/comm_widgets/app_button.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/title_show_row_widget.dart';
import 'package:harcapp_core/song_book/contributor_identity_resolver.dart';
import 'package:harcapp_core/song_book/song_editor/providers.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/song_book/widgets/song_widget_template.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/consts.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/song_preview_widget.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class SimilarSongViewerDialog extends StatefulWidget{

  @override
  State<StatefulWidget> createState() => SimilarSongViewerDialogState();

}

class SimilarSongViewerDialogState extends State<SimilarSongViewerDialog>{

  late List<SongRaw> similarSongs;

  late PageController controller;

  @override
  void initState() {
    SimilarSongProvider similarSongProv = SimilarSongProvider.of(context);
    CurrentItemProvider currentItemProv = CurrentItemProvider.of(context);

    String songTitle = currentItemProv.titleController.text;

    similarSongs = similarSongProv.getSimilarSongs(songTitle)??[];

    controller = PageController(viewportFraction: 0.75);

    post(() => setState(() {}));  // To update hasNext/hasPrev

    super.initState();
  }

  bool get hasNext => controller.hasClients && controller.page != null && controller.page! < (similarSongs.length-1);
  bool get hasPrev => controller.hasClients && controller.page != null && controller.page! > 0;

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
                  title: 'Podobne piosenki',
                  backgroundColor: cardEnab_(context),
                ),

                Expanded(
                  child:  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      SizedBox(width: Dimen.sideMarg),

                      Material(
                        color: background_(context),
                        elevation: AppCard.bigElevation,
                        borderRadius: BorderRadius.circular(100),
                        clipBehavior: Clip.hardEdge,
                        child: AppButton(
                          icon: Icon(MdiIcons.chevronLeft),
                          onTap: () async {
                            await controller.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOutCubic);
                            // setState(() {});
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
                                  child: SimilarSongWidget(song: similarSongs[index], title: 'Podobna piosenka ${index + 1}'),
                                ),
                                itemCount: similarSongs.length,
                              ),
                            ),
                          )
                      ),

                      Material(
                        color: background_(context),
                        elevation: AppCard.bigElevation,
                        borderRadius: BorderRadius.circular(100),
                        clipBehavior: Clip.hardEdge,
                        child: AppButton(
                          icon: Icon(MdiIcons.chevronRight),
                          onTap: () async {
                            await controller.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOutCubic);
                            // setState(() {});
                          },
                        ),
                      ),

                      SizedBox(width: Dimen.sideMarg),

                      Padding(
                        padding: EdgeInsets.all(Dimen.sideMarg),
                        child:  SizedBox(
                          width: songPreviewWidth,
                          child: SimilarSongWidget(
                            title: 'Aktualna piosenka',
                            song: CurrentItemProvider.of(context).song,
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

class SimilarSongWidget extends StatelessWidget{

  final String title;
  final SongRaw song;
  final double elevation;

  const SimilarSongWidget({required this.song, this.title = 'Podobna piosenka', this.elevation = 0, super.key});

  @override
  Widget build(BuildContext context) => Material(
      color: background_(context),
      elevation: elevation,
      borderRadius: BorderRadius.circular(AppCard.bigRadius),
      child: Column(
        children: [

          TitleShortcutRowWidget(title: title, titleColor: hintEnab_(context)),

          Expanded(
            child: SongWidgetTemplate<SongRaw, ContributorIdentitySimpleResolver>(
                song,
                SongBaseSettings(),
                contribIdResolver: ContributorIdentitySimpleResolver(),
                scrollController: ScrollController(),
                key: UniqueKey()//ValueKey(currItemProv.song)
            ),
          )

        ],
      )
  );

}