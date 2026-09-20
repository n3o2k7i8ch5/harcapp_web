import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_navigator.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_bar.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/dialog/base.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/song_book/similarity/similarity.dart';
import 'package:harcapp_core/song_book/similarity/similarity_widgets.dart';
import 'package:harcapp_core/song_book/similarity/song_index.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/consts.dart';
import 'package:harcapp_web/songs/song_compare_preview.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

/// Importowana piosenka i to, co ona zastaje w warsztacie pod tym samym id.
class ImportConflict{

  final SongRaw imported;
  final List<SongRaw> existing;

  const ImportConflict(this.imported, this.existing);

}

/// Co zrobić z jedną kolizją. Te same trzy wyjścia, co przy kopiowaniu pliku
/// do katalogu, w którym plik o tej nazwie już leży.
enum ImportConflictChoice{
  /// Stara zostaje, nowa nie wchodzi.
  keepOld,
  /// Obie zostają - z konfliktem nazw, jeśli taki wyjdzie.
  keepBoth,
  /// Nowa zastępuje starą - stara znika z warsztatu.
  replace;
}

/// Szuka importowanych piosenek, które w warsztacie mają swój pierwowzór.
///
/// Poprawka **nie zdradza się polem `piosenkomat`**: `prepare` ten ślad zdejmuje,
/// a poprawionej piosence ustawia `id` poprawianej (w apce piosenki są
/// referencjonowane po `lclId`). Poznajemy ją więc po tym, po czym i tak widać
/// konflikt: po dowodzie [SameId] z indeksu warsztatu. Gdy ślad jeszcze jest
/// (`candidates-*`, `reviewed-*`), bierzemy dodatkowo cel poprawki — tam id
/// poprawki potrafi być inne niż id pierwowzoru.
///
/// Celowo **nie** `correctionTargetOf`: ono liczy też `correctedSongId`,
/// a piosenka przerobiona z cudzej i importowana obok oryginału to nie
/// kolizja — to inna piosenka, która pamięta, z czego powstała.
List<ImportConflict> findImportConflicts(
    List<SongRaw> imported,
    List<SongRaw> workspace,
){

  SongIndex<SongRaw> index = SongIndex(workspace);
  bool fromImport(SongRaw s) => imported.any((i) => identical(i, s));

  List<ImportConflict> conflicts = [];

  for(SongRaw song in imported){
    // Set po tożsamości: `SongRaw` nie nadpisuje `==`, a ta sama piosenka
    // może wyjść i po id, i po celu poprawki.
    Set<SongRaw> existing = {
      for(SongMatch<SongRaw> m in index.matches(SongProfile(song), exclude: fromImport))
        if(m.similarities.any((s) => s is SameId)) m.song,
      if(song.piosenkomatData?.correctionTarget case final target?)
        for(SongRaw s in index.allById(target))
          if(!fromImport(s)) s,
    };

    if(existing.isEmpty) continue;

    conflicts.add(ImportConflict(song, existing.toList()));
  }

  return conflicts;

}

/// Pyta o każdą kolizję z osobna, pokazując starą piosenkę obok nowej.
/// [onResolved] dostaje wybór dla **każdej** kolizji; zamknięcie okna bez
/// decyzji przerywa cały import i [onResolved] nie leci wcale.
void showImportConflictDialog(
    BuildContext context,
    { required List<ImportConflict> conflicts,
      required void Function(Map<SongRaw, ImportConflictChoice> choices) onResolved,
    }) => openBaseDialog(
    context: context,
    maxWidth: 2*songPreviewWidth + 6*Dimen.sideMarg,
    // Szare tło, na nim białe, uniesione karty — obie tak samo. Jedna płaska,
    // druga uniesiona sugerowałaby, że któraś jest „tą właściwą”, a tu
    // właśnie o to pytamy.
    color: cardEnab_(context),
    builder: (context) => ImportConflictDialog(conflicts: conflicts, onResolved: onResolved)
);

class ImportConflictDialog extends StatefulWidget{

  final List<ImportConflict> conflicts;
  final void Function(Map<SongRaw, ImportConflictChoice> choices) onResolved;

  const ImportConflictDialog({required this.conflicts, required this.onResolved, super.key});

  @override
  State<StatefulWidget> createState() => ImportConflictDialogState();

}

class ImportConflictDialogState extends State<ImportConflictDialog>{

  List<ImportConflict> get conflicts => widget.conflicts;

  /// Na której kolizji stoimy.
  late int index;
  /// Czy wybór ma pójść na wszystkie kolejne kolizje - jak „tak samo dla
  /// pozostałych” w oknie kopiowania plików.
  late bool applyToAll;
  late Map<SongRaw, ImportConflictChoice> choices;

  ImportConflict get conflict => conflicts[index];

  @override
  void initState() {
    index = 0;
    applyToAll = false;
    choices = {};
    super.initState();
  }

  void choose(ImportConflictChoice choice){

    choices[conflict.imported] = choice;

    // „Tak samo dla pozostałych” dopina resztę bez pytania i kończy okno.
    if(applyToAll){
      for(ImportConflict rest in conflicts.skip(index + 1))
        choices[rest.imported] = choice;
      finish();
      return;
    }

    if(index + 1 >= conflicts.length){
      finish();
      return;
    }

    setState(() => index++);

  }

  void finish(){
    popPage(context);
    widget.onResolved(choices);
  }

  @override
  Widget build(BuildContext context){
    final List<Similarity> similarities = compare(
      SongProfile(conflict.imported),
      SongProfile(conflict.existing.first),
    );

    return ConstrainedBox(
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height - 2*Dimen.sideMarg),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        // Pasek w kolorze okna: motyw daje mu `background` (biały), a na
        // szarym oknie biały pasek z cieniem wygląda jak osobna, nakładająca
        // się karta.
        AppBarX(
            title:
            conflicts.length == 1?
            'Ta piosenka już jest w warsztacie':
            'Piosenka już w warsztacie (${index + 1} z ${conflicts.length})',
            backgroundColor: cardEnab_(context),
        ),

        // Bez zdania „to samo id” pod paskiem: id widać w nagłówku każdej
        // karty, a pastylka przy nowej mówi, że jest wspólne.
        const SizedBox(height: Dimen.sideMarg),

        Flexible(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: Dimen.sideMarg, right: Dimen.sideMarg/2),
                  // Kolizji z kilkoma piosenkami w warsztacie prawie nie ma
                  // (to id powtórzone po stronie warsztatu), ale gdy jest,
                  // pokazujemy pierwszą i mówimy, ile ich razem.
                  child: SongComparePreview(
                    key: ObjectKey(conflict.existing.first),
                    song: conflict.existing.first,
                    label:
                    conflict.existing.length == 1?
                    'stara · w warsztacie':
                    'stara · w warsztacie · 1 z ${conflict.existing.length}',
                    icon: MdiIcons.laptop,
                    elevation: AppCard.bigElevation,
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: Dimen.sideMarg/2, right: Dimen.sideMarg),
                  // Pastylki przy **nowej**: to ona przychodzi i to o niej
                  // pytamy — „to samo id, ten sam tekst” względem starej.
                  // Kolor po poziomie, jak w belce, a nie szary: szare
                  // na szarym ginęło.
                  child: SongComparePreview(
                    key: ObjectKey(conflict.imported),
                    song: conflict.imported,
                    label: 'nowa · z importu',
                    icon: MdiIcons.trayArrowDown,
                    similarities: similarities,
                    pillColor: matchLevelColor(levelOf(similarities)),
                    elevation: AppCard.bigElevation,
                  ),
                ),
              ),

            ],
          ),
        ),

        const SizedBox(height: Dimen.sideMarg),

        // Trzy razy „Zachowaj”, różnica w jednym słowie - wybór czyta się
        // jednym spojrzeniem. W rzędzie, bo to jeden wybór z trzech
        // równorzędnych, a nie lista kroków, i **w tej samej kolejności, co
        // podglądy**: stara jest po lewej, nowa po prawej, obie pośrodku.
        // Odwrotna kolejność kazałaby przy każdej kolizji przekładać wzrok.
        Padding(
          padding: const EdgeInsets.fromLTRB(
              Dimen.defMarg, Dimen.defMarg/2, Dimen.defMarg, 0),
          // IntrinsicHeight, bo `stretch` w kolumnie `MainAxisSize.min` nie ma
          // od czego liczyć wysokości. Dzięki niemu przycisk, któremu napis
          // zawinie się na dwie linijki, nie robi się wyższy od sąsiadów.
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                Expanded(
                  child: _ChoiceButton(
                    icon: MdiIcons.fileCancelOutline,
                    text: 'Zachowaj starą',
                    onTap: () => choose(ImportConflictChoice.keepOld),
                  ),
                ),

                Expanded(
                  child: _ChoiceButton(
                    icon: MdiIcons.contentDuplicate,
                    text: 'Zachowaj obie',
                    onTap: () => choose(ImportConflictChoice.keepBoth),
                  ),
                ),

                Expanded(
                  child: _ChoiceButton(
                    icon: MdiIcons.swapHorizontal,
                    text: 'Zachowaj nową',
                    onTap: () => choose(ImportConflictChoice.replace),
                  ),
                ),

              ],
            ),
          ),
        ),

        // Pod wyborem i po prawej, bo to jego przypis, nie czwarta opcja.
        // Odstęp od przycisków taki, jak między przyciskami a kartami.
        if(index + 1 < conflicts.length)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              // Prawa krawędź równo z „Zachowaj obie”: rząd przycisków ma
              // padding `defMarg`, a każdy przycisk jeszcze własny margines
              // `defMarg/2`.
              padding: const EdgeInsets.only(
                  top: Dimen.iconMarg,
                  right: Dimen.defMarg + Dimen.defMarg/2,
                  bottom: Dimen.sideMarg),
              child: _ApplyToRestToggle(
                count: conflicts.length - index - 1,
                value: applyToAll,
                onChanged: (v) => setState(() => applyToAll = v),
              ),
            ),
          )
        else
          const SizedBox(height: Dimen.sideMarg),

      ],
    ),
  );
  }

}

/// „Tak samo dla pozostałych” — przełącznik, nie akcja, więc `Switch`
/// z etykietą, jak przełączniki w panelu edytora („Powiąż z tytułem”),
/// a nie czwarty przycisk. Bez tła: biała karta robiła z niego czwarty
/// przycisk, a to ma być przypis do trzech nad nim.
class _ApplyToRestToggle extends StatelessWidget{

  final int count;
  final bool value;
  final void Function(bool) onChanged;

  const _ApplyToRestToggle({required this.count, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(AppCard.bigRadius),
    clipBehavior: Clip.hardEdge,
    child: InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.only(left: Dimen.iconMarg, right: Dimen.defMarg),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [

            Text(
              'Tak samo dla pozostałych ($count)',
              style: AppTextStyle(
                fontSize: Dimen.textSizeBig,
                color: value? textEnab_(context): hintEnab_(context),
              ),
            ),

            const SizedBox(width: Dimen.defMarg),

            Switch(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),

          ],
        ),
      ),
    ),
  );

}

class _ChoiceButton extends StatelessWidget{

  final IconData icon;
  final String text;
  final void Function() onTap;

  const _ChoiceButton({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SimpleButton.from(
      context: context,
      margin: const EdgeInsets.symmetric(horizontal: Dimen.defMarg/2),
      // Białe na szarym tle okna, jak karty z piosenkami nad nimi — i z tym
      // samym zaokrągleniem; domyślne 6 px obok kart na 20 px wyglądało
      // jak z innego zestawu.
      color: background_(context),
      radius: AppCard.bigRadius,
      icon: icon,
      text: text,
      textColor: iconEnab_(context),
      onTap: onTap
  );

}
