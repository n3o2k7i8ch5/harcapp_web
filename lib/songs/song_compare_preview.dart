import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/song_book/similarity/similarity.dart';
import 'package:harcapp_core/song_book/similarity/similarity_widgets.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/song_book/playback/widgets/song_playback_bar.dart';
import 'package:harcapp_core/song_book/widgets/song_widget_template.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/songs/song_preview_widget.dart';

/// Jedna kolumna porównania: skąd piosenka, jej id, pastylki dowodów i pełny
/// podgląd. Ten sam widget w oknie podobnych piosenek i w oknie konfliktu
/// importu — dwa okna, jedno „obok siebie”.
///
/// Tytuł piosenki nie jest w nagłówku: pokazuje go sam podgląd, a dwa razy
/// ten sam tytuł jeden nad drugim to szum.
class SongComparePreview extends StatefulWidget{

  final SongRaw song;
  /// Skąd: „w apce”, „w warsztacie”, „w edytorze”, „z importu”. Pisane
  /// wersalikami, więc podawaj małymi.
  final String label;
  final IconData icon;
  /// Dowody podobieństwa do piosenki z drugiej kolumny. Puste — bez rzędu
  /// pastylek (kolumna z Twoją piosenką nie porównuje się sama ze sobą).
  final List<Similarity> similarities;
  final Color? pillColor;
  final double elevation;

  const SongComparePreview({
    required this.song,
    required this.label,
    required this.icon,
    this.similarities = const [],
    this.pillColor,
    this.elevation = 0,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _SongComparePreviewState();

}

class _SongComparePreviewState extends State<SongComparePreview>{

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
  Widget build(BuildContext context){
    final hint = hintEnab_(context);

    return Material(
      color: background_(context),
      elevation: widget.elevation,
      borderRadius: BorderRadius.circular(AppCard.bigRadius),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          Padding(
            padding: const EdgeInsets.fromLTRB(
                Dimen.iconMarg, Dimen.iconMarg, Dimen.iconMarg, Dimen.defMarg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  children: [
                    Icon(widget.icon, size: Dimen.textSizeNormal + 2, color: textEnab_(context)),
                    const SizedBox(width: Dimen.defMarg),
                    Expanded(
                      child: Text(
                        widget.label.toUpperCase(),
                        // Pełny kolor tekstu: to jest nagłówek kolumny, nie
                        // przypis. Szare zostaje id pod nim.
                        style: AppTextStyle(
                          fontSize: Dimen.textSizeSmall,
                          fontWeight: weightBold,
                          color: textEnab_(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                Text(
                  widget.song.id.isEmpty? 'bez id': widget.song.id,
                  style: AppTextStyle(fontSize: Dimen.textSizeSmall, color: hint),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                if(widget.similarities.isNotEmpty) ...[
                  const SizedBox(height: Dimen.defMarg),
                  SimilarityPills(widget.similarities, color: widget.pillColor ?? hint),
                ],

              ],
            ),
          ),

          Divider(height: 1, color: hint.withValues(alpha: 0.12)),

          Expanded(
            child: SongWidgetTemplate<SongRaw>(
              widget.song,
              settings,
              scrollController: scrollController,
              playbackBar: PlaybackBarMode.preview,
            ),
          ),

        ],
      ),
    );
  }

}
