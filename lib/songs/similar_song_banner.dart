import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/song_book/similarity/similarity_widgets.dart';
import 'package:harcapp_core/song_book/similarity/song_index.dart';
import 'package:harcapp_core/song_book/song_editor/providers.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/similar_song_viewer.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';

/// Czy nad edytorem jest belka — do wyliczenia miejsca na nią.
bool similarSongBannerVisible(SimilarSongProvider sim, AllSongsProvider all, CurrentItemProvider curr){
  if(!sim.loaded) return false;
  return sim.originalMatchOf(curr.song, workspace: all.songs) != null
      || sim.matchesFor(curr.song, workspace: all.songs).isNotEmpty;
}

/// Belka nad edytorem: co jest podobne do edytowanej piosenki — w apce
/// i w warsztacie — i jak bardzo. Zapala się na **każde** trafienie, nie
/// tylko na zbieżny tytuł; kolor mówi o poziomie najsilniejszego.
class SimilarSongBanner extends StatelessWidget{

  static const IconData icon = MdiIcons.musicBoxMultiple;

  const SimilarSongBanner({super.key});

  @override
  Widget build(BuildContext context) => Consumer3<SimilarSongProvider, AllSongsProvider, CurrentItemProvider>(
      builder: (context, simProv, allSongsProv, currItemProv, child){
        if(!simProv.loaded) return const SizedBox.shrink();

        final SongRaw song = currItemProv.song;
        final List<SongRaw> workspace = allSongsProv.songs;
        final SongMatch<SongRaw>? original = simProv.originalMatchOf(song, workspace: workspace);
        final List<SongMatch<SongRaw>> matches = simProv.matchesFor(song, workspace: workspace);

        if(original == null && matches.isEmpty) return const SizedBox.shrink();

        final String text;
        final Color color;
        final IconData icon;

        if(original != null){
          // Przy poprawce pierwowzór nie jest ostrzeżeniem — o to przecież
          // chodzi. Pomarańcz, nie czerwień, a obok ewentualne inne trafienia.
          color = Colors.orange;
          icon = MdiIcons.compareHorizontal;
          text = matches.isEmpty?
          'Poprawka piosenki „${original.song.title}”':
          'Poprawka piosenki „${original.song.title}” · ${similarCountText(matches.length)}';
        } else {
          color = matchLevelColor(matches.first.level);
          icon = SimilarSongBanner.icon;
          text = similarSongsSummary(matches);
        }

        return _Banner(
          color: color,
          icon: icon,
          text: text,
          buttonText: 'Porównaj',
          onTap: () => showSimilarSongViewer(
            context,
            currentSong: song,
            matches: matches,
            original: original,
            title: original != null? 'Poprawka piosenki': 'Podobne piosenki',
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
