import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_navigator.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_bar.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/dialog/base.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/comm_widgets/title_show_row_widget.dart';
import 'package:harcapp_core/song_book/piosenkomat/piosenkomat_data.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/song_book/widgets/song_widget_template.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/consts.dart';
import 'package:harcapp_web/songs/song_preview_widget.dart';
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
/// konflikt: po zbieżności id z czymś, co już w warsztacie leży. Gdy ślad
/// jeszcze jest (`candidates-*`, `reviewed-*`), bierzemy dodatkowo cel poprawki
/// - tam id poprawki potrafi być inne niż id pierwowzoru.
List<ImportConflict> findImportConflicts(
    List<SongRaw> imported,
    List<SongRaw> workspace,
){

  List<ImportConflict> conflicts = [];

  for(SongRaw song in imported){
    PiosenkomatData? data = song.piosenkomatData;

    Set<String> targetIds = {song.id, if(data?.correctionTarget != null) data!.correctionTarget!};

    List<SongRaw> existing = workspace.where((s) =>
        targetIds.contains(s.id) && !imported.any((i) => identical(i, s))
    ).toList();

    if(existing.isEmpty) continue;

    conflicts.add(ImportConflict(song, existing));
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
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height - 2*Dimen.sideMarg),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        AppBarX(
            title:
            conflicts.length == 1?
            'Ta piosenka już jest w warsztacie':
            'Piosenka już w warsztacie (${index + 1} z ${conflicts.length})'
        ),

        // Tytuły obu piosenek widać w podglądach pod spodem, więc zdanie o nich
        // byłoby powtórzeniem. Zostaje jedyna rzecz, której podglądy nie niosą:
        // id, które koliduje.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimen.sideMarg),
          child: Text(
            'to samo id: ${conflict.existing.map((s) => s.id).join(', ')}',
            textAlign: TextAlign.center,
            style: AppTextStyle(fontSize: Dimen.textSizeNormal, color: hintEnab_(context)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

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
                  child: _ConflictSongPreview(
                    song: conflict.existing.first,
                    title:
                    conflict.existing.length == 1?
                    'Stara (w warsztacie)':
                    'Stara (w warsztacie, 1 z ${conflict.existing.length})',
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: Dimen.sideMarg/2, right: Dimen.sideMarg),
                  child: _ConflictSongPreview(
                    song: conflict.imported,
                    title: 'Nowa (z importu)',
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
        if(index + 1 < conflicts.length)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              // Prawa krawędź równo z „Zachowaj obie”: rząd przycisków ma
              // padding `defMarg`, a każdy przycisk jeszcze własny margines
              // `defMarg/2`.
              padding: const EdgeInsets.only(
                  top: Dimen.defMarg,
                  right: Dimen.defMarg + Dimen.defMarg/2,
                  bottom: Dimen.defMarg),
              child: _ApplyToRestPill(
                count: conflicts.length - index - 1,
                value: applyToAll,
                onTap: () => setState(() => applyToAll = !applyToAll),
              ),
            ),
          )
        else
          const SizedBox(height: Dimen.defMarg),

      ],
    ),
  );

}

/// „Tak samo dla pozostałych” — przełącznik, nie akcja, więc bez tła
/// i poza rzędem wyboru.
class _ApplyToRestPill extends StatelessWidget{

  final int count;
  final bool value;
  final void Function() onTap;

  const _ApplyToRestPill({required this.count, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context){
    final color = value? accent_(context): hintEnab_(context);

    return SimpleButton(
      radius: 100,
      elevation: 0,
      // Bez tła: o stanie mówi kolor ikonki i napisu.
      padding: const EdgeInsets.symmetric(
          horizontal: Dimen.iconMarg, vertical: Dimen.defMarg/2),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [

          Icon(
            value? MdiIcons.checkboxMarkedOutline: MdiIcons.checkboxBlankOutline,
            size: Dimen.textSizeBig + 2,
            color: color,
          ),

          const SizedBox(width: Dimen.defMarg),

          Text(
            'Tak samo dla pozostałych ($count)',
            style: AppTextStyle(
              fontSize: Dimen.textSizeBig,
              fontWeight: weightHalfBold,
              color: color,
            ),
            maxLines: 1,
          ),

        ],
      ),
    );
  }

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
      color: backgroundIcon_(context),
      icon: icon,
      text: text,
      textColor: iconEnab_(context),
      onTap: onTap
  );

}

/// Podgląd jednej piosenki w kolumnie - jak w oknie podobnych piosenek.
class _ConflictSongPreview extends StatefulWidget{

  final SongRaw song;
  final String title;
  final double elevation;

  const _ConflictSongPreview({required this.song, required this.title, this.elevation = 0});

  @override
  State<StatefulWidget> createState() => _ConflictSongPreviewState();

}

class _ConflictSongPreviewState extends State<_ConflictSongPreview>{

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
      elevation: widget.elevation,
      borderRadius: BorderRadius.circular(AppCard.bigRadius),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [

          TitleShortcutRowWidget(title: widget.title, titleColor: hintEnab_(context)),

          Expanded(
            child: SongWidgetTemplate<SongRaw>(
              widget.song,
              settings,
              scrollController: scrollController,
            ),
          )

        ],
      )
  );

}
