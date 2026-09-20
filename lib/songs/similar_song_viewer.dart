import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_bar.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/song_book/similarity/similarity_widgets.dart';
import 'package:harcapp_core/song_book/similarity/song_index.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/consts.dart';
import 'package:harcapp_web/songs/song_compare_preview.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

/// „1 podobna piosenka”, „3 podobne piosenki”, „12 podobnych piosenek”.
String similarCountText(int n){
  if(n == 1) return '1 podobna piosenka';
  final unit = n % 10, tens = n % 100;
  if(unit >= 2 && unit <= 4 && (tens < 12 || tens > 14)) return '$n podobne piosenki';
  return '$n podobnych piosenek';
}

/// Jedno zdanie o liście trafień, do belki i do banera w oknie mejla:
/// przy jednym — co i skąd, przy kilku — ile i które najbliższe.
/// `„Barka” w apce: ta sama piosenka, drobne różnice`,
/// `3 podobne piosenki — najbliżej „Barka” w apce: ten sam tytuł, inna treść`.
String similarSongsSummary(List<SongMatch<SongRaw>> matches){
  final best = matches.first;
  final String title = best.song.title.isEmpty? 'bez tytułu': best.song.title;
  final String what = '„$title” ${best.source.inText}: ${best.level?.text ?? ''}';
  if(matches.length == 1) return what;
  return '${similarCountText(matches.length)} — najbliżej $what';
}

IconData matchSourceIcon(MatchSource source) => switch(source){
  MatchSource.app => MdiIcons.cellphone,
  MatchSource.workspace => MdiIcons.laptop,
};

/// Otwiera przeglądarkę podobnych piosenek. Jedno wejście dla belki nad
/// edytorem i dla okna mejla, żeby oba wyglądały tak samo.
Future<void> showSimilarSongViewer(
    BuildContext context,
    { required SongRaw currentSong,
      required List<SongMatch<SongRaw>> matches,
      SongMatch<SongRaw>? original,
      String title = 'Podobne piosenki',
      String currentLabel = 'w edytorze',
    }) => showDialog(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(Dimen.sideMarg),
      child: SimilarSongViewerDialog(
        currentSong: currentSong,
        matches: matches,
        original: original,
        title: title,
        currentLabel: currentLabel,
      ),
    ),
);

/// Po lewej lista trafień (tytuł, skąd, poziom), pośrodku wybrane trafienie
/// z pastylkami dowodów, po prawej Twoja piosenka. Przy jednym trafieniu
/// lista znika — zostają dwie równe kolumny.
///
/// Pierwowzór poprawki ([original]) idzie na listę jako pierwszy i jest
/// podpisany osobno: nie jest „podobny”, jest tym, co poprawiasz.
class SimilarSongViewerDialog extends StatefulWidget{

  final SongRaw currentSong;
  final List<SongMatch<SongRaw>> matches;
  final SongMatch<SongRaw>? original;
  final String title;
  final String currentLabel;

  const SimilarSongViewerDialog({
    required this.currentSong,
    required this.matches,
    this.original,
    this.title = 'Podobne piosenki',
    this.currentLabel = 'w edytorze',
    super.key,
  });

  @override
  State<StatefulWidget> createState() => SimilarSongViewerDialogState();

}

class _Entry{

  final SongMatch<SongRaw> match;
  final bool isOriginal;

  const _Entry(this.match, {this.isOriginal = false});

  /// Podpis na liście i w nagłówku kolumny: skąd, a przy pierwowzorze — co to.
  String get kindText => isOriginal? 'poprawiana piosenka': match.level?.text ?? '';
  Color color(BuildContext context) => isOriginal? accent_(context): matchLevelColor(match.level);
  IconData get icon => isOriginal? MdiIcons.compareHorizontal: matchSourceIcon(match.source);

}

class SimilarSongViewerDialogState extends State<SimilarSongViewerDialog>{

  static const double listWidth = 260;

  late List<_Entry> entries;
  int selected = 0;

  @override
  void initState() {
    entries = [
      if(widget.original case final original?) _Entry(original, isOriginal: true),
      for(final m in widget.matches) _Entry(m),
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context){
    final bool withList = entries.length > 1;
    final _Entry? entry = entries.isEmpty? null: entries[selected];

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: (withList? listWidth: 0) + 2*songPreviewWidth + 3*Dimen.sideMarg,
        ),
        child: Material(
          color: cardEnab_(context),
          clipBehavior: Clip.hardEdge,
          borderRadius: BorderRadius.circular(AppCard.bigRadius),
          child: Column(
            children: [

              AppBarX(
                title: widget.title,
                backgroundColor: cardEnab_(context),
              ),

              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    if(withList)
                      SizedBox(
                        width: listWidth,
                        child: _MatchList(
                          entries: entries,
                          selected: selected,
                          onSelect: (i) => setState(() => selected = i),
                        ),
                      ),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            Dimen.sideMarg, Dimen.sideMarg, Dimen.sideMarg/2, Dimen.sideMarg),
                        child: entry == null?
                        const SizedBox.shrink():
                        SongComparePreview(
                          // Klucz po piosence: przeskok na inne trafienie ma
                          // dać świeży scroll, a nie przewinięty po starym.
                          key: ObjectKey(entry.match.song),
                          song: entry.match.song,
                          label: entry.isOriginal?
                          '${entry.kindText} · ${entry.match.source.inText}':
                          entry.match.source.inText,
                          icon: entry.icon,
                          similarities: entry.match.similarities,
                          pillColor: entry.color(context),
                          elevation: AppCard.bigElevation,
                        ),
                      ),
                    ),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            Dimen.sideMarg/2, Dimen.sideMarg, Dimen.sideMarg, Dimen.sideMarg),
                        child: SongComparePreview(
                          song: widget.currentSong,
                          label: widget.currentLabel,
                          icon: MdiIcons.pencilOutline,
                          elevation: AppCard.bigElevation,
                        ),
                      ),
                    ),

                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

}

/// Lewa kolumna: wszystkie trafienia na raz — co, skąd, jak mocno — bez
/// klikania. Klik wybiera, co pokazać pośrodku.
class _MatchList extends StatelessWidget{

  final List<_Entry> entries;
  final int selected;
  final void Function(int index) onSelect;

  const _MatchList({required this.entries, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context){
    final hint = hintEnab_(context);
    final int similarCount = entries.where((e) => !e.isOriginal).length;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: hint.withValues(alpha: 0.12))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          Padding(
            padding: const EdgeInsets.fromLTRB(
                Dimen.sideMarg, Dimen.sideMarg, Dimen.sideMarg, Dimen.defMarg),
            child: Text(
              similarCountText(similarCount).toUpperCase(),
              style: AppTextStyle(fontSize: Dimen.textSizeSmall, fontWeight: weightBold, color: hint),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: Dimen.sideMarg),
              itemCount: entries.length,
              itemBuilder: (context, index) => _MatchTile(
                entry: entries[index],
                selected: index == selected,
                onTap: () => onSelect(index),
              ),
            ),
          ),

        ],
      ),
    );
  }

}

class _MatchTile extends StatelessWidget{

  final _Entry entry;
  final bool selected;
  final void Function() onTap;

  const _MatchTile({required this.entry, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context){
    final color = entry.color(context);
    final String title = entry.match.song.title.isEmpty? 'Brak tytułu.': entry.match.song.title;

    return Material(
      color: selected? accent_(context).withValues(alpha: 0.10): Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimen.sideMarg, vertical: Dimen.iconMarg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(
                  entry.isOriginal? MdiIcons.compareHorizontal: MdiIcons.circleMedium,
                  size: Dimen.textSizeBig,
                  color: color,
                ),
              ),

              const SizedBox(width: Dimen.defMarg),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      title,
                      style: AppTextStyle(
                        fontSize: Dimen.textSizeBig,
                        fontWeight: selected? weightHalfBold: weightNormal,
                        color: textEnab_(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2),

                    Text(
                      '${entry.match.source.inText} · ${entry.kindText}',
                      style: AppTextStyle(fontSize: Dimen.textSizeSmall, color: hintEnab_(context)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

}
