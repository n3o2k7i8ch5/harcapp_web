import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/song_book/song_editor/providers.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/similar_song_viewer.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';

class SimilarSongBanner extends StatelessWidget{

  static const IconData icon = MdiIcons.musicBoxMultiple;

  const SimilarSongBanner({super.key});

  @override
  Widget build(BuildContext context) => Consumer2<SimilarSongProvider, CurrentItemProvider>(
      builder: (context, similarSongProv, currItemProv, child){
        if(similarSongProv.allSongs == null) return const SizedBox.shrink();
        if(!similarSongProv.hasSimilarSong(currItemProv.titleController.text))
          return const SizedBox.shrink();
        return const _FoundSimilarSongBanner();
      }
  );

}

class _FoundSimilarSongBanner extends StatelessWidget{

  const _FoundSimilarSongBanner();

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
                child: Icon(SimilarSongBanner.icon, color: Colors.red),
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
