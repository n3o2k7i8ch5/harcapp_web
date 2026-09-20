import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/song_book/song_editor/providers.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/similar_song_viewer.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';

/// Piosenka z apki, którą poprawia piosenka z edytora — albo `null`, gdy to
/// nie poprawka albo pierwowzoru nie da się wskazać.
///
/// Szukamy **po id, nie po tytule**: poprawka wolno zmienia tytuł, a dalej
/// dotyczy tej samej piosenki. Kolejno: `correctionTarget` ze śladu
/// piosenkomatu, potem id samej poprawki (gdy narzędzie celu nie znało — ta
/// sama reguła, co w `findCorrectionConflicts`), a na końcu, gdy id nic nie
/// daje, zbieżność tytułu.
SongRaw? correctedAppSong(SimilarSongProvider prov, SongRaw song){
  if(!isCorrection(song)) return null;
  final target = song.piosenkomatData!.correctionTarget;
  return prov.songById(target ?? song.id)
      ?? (target == null? null: prov.songById(song.id))
      ?? prov.getSimilarSongs(song.title)?.firstOrNull;
}

bool isCorrection(SongRaw song) => song.piosenkomatData?.isCorrection ?? false;

/// Czy nad edytorem jest belka — do wyliczenia miejsca na nią.
bool similarSongBannerVisible(SimilarSongProvider prov, CurrentItemProvider curr){
  if(prov.allSongs == null) return false;
  if(isCorrection(curr.song)) return correctedAppSong(prov, curr.song) != null;
  return prov.hasSimilarSong(curr.titleController.text);
}

class SimilarSongBanner extends StatelessWidget{

  static const IconData icon = MdiIcons.musicBoxMultiple;

  const SimilarSongBanner({super.key});

  @override
  Widget build(BuildContext context) => Consumer2<SimilarSongProvider, CurrentItemProvider>(
      builder: (context, similarSongProv, currItemProv, child){
        if(similarSongProv.allSongs == null) return const SizedBox.shrink();

        // Przy poprawce „taki tytuł już jest” nie jest ostrzeżeniem — o to
        // przecież chodzi. Zamiast tego: pierwowzór obok propozycji, a gdy
        // pierwowzoru nie znajdziemy — nic, bo czerwone byłoby kłamstwem.
        if(isCorrection(currItemProv.song)){
          final SongRaw? original =
              correctedAppSong(similarSongProv, currItemProv.song);
          if(original == null) return const SizedBox.shrink();
          return _Banner(
            color: Colors.orange,
            icon: MdiIcons.compareHorizontal,
            text: 'Poprawka piosenki „${original.title}”',
            buttonText: 'Porównaj',
            onTap: () => showDialog(
              context: context,
              builder: (_) => Padding(
                padding: EdgeInsets.all(Dimen.sideMarg),
                child: SimilarSongViewerDialog(
                  currentSong: currItemProv.song,
                  compareTo: [original],
                  dialogTitle: 'Poprawka piosenki',
                  currentTitle: 'Proponowana poprawka',
                  compareTitle: (_) => 'Piosenka w apce',
                ),
              ),
            ),
          );
        }

        if(!similarSongProv.hasSimilarSong(currItemProv.titleController.text))
          return const SizedBox.shrink();

        return _Banner(
          color: Colors.red,
          icon: SimilarSongBanner.icon,
          text: 'Piosenka o takim tytule już jest!',
          buttonText: 'Podgląd',
          onTap: () => showDialog(
            context: context,
            builder: (_) => Padding(
              padding: EdgeInsets.all(Dimen.sideMarg),
              child: SimilarSongViewerDialog(
                currentSong: currItemProv.song,
              ),
            ),
          ),
        );
      }
  );

}

class _Banner extends StatelessWidget{

  final Color color;
  final IconData icon;
  final String text;
  final String buttonText;
  final void Function() onTap;

  const _Banner({
    required this.color,
    required this.icon,
    required this.text,
    required this.buttonText,
    required this.onTap,
  });

  // Bez cienia. `BackdropFilter` rozmywa wszystko, co jest pod nim — razem
  // z cieniem rzucanym przez tę samą belkę — i brud lądował w środku, za
  // półprzezroczystym wypełnieniem. Od odcięcia od tła jest tu samo rozmycie
  // plus obwódka; zamiast cienia mocniejsze wypełnienie.
  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(AppCard.bigRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(AppCard.bigRadius),
            border: Border.all(
              color: color.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: Dimen.defMarg, vertical: Dimen.defMarg / 2),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.all(Dimen.iconMarg),
                child: Icon(icon, color: color),
              ),

              Expanded(
                child: Text(
                  text,
                  style: AppTextStyle(
                    color: color,
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
                text: buttonText,
                iconColor: color,
                textColor: color,
                onTap: onTap,
              ),

            ],
          ),
        ),
      ),
  );

}
