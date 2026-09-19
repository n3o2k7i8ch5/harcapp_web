import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_navigator.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_bar.dart';
import 'package:harcapp_core/comm_widgets/dialog/base.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/song_book/piosenkomat/piosenkomat_data.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/consts.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

/// Piosenka-poprawka z importu i to, co ona poprawia w warsztacie.
class CorrectionConflict{

  final SongRaw imported;
  final List<SongRaw> existing;

  const CorrectionConflict(this.imported, this.existing);

}

/// Co zrobić z poprawkami, które mają w warsztacie swój pierwowzór.
enum CorrectionImportMode{
  /// Pierwowzór znika, zostaje sama poprawka.
  replace,
  /// Pierwowzór zostaje obok poprawki - z konfliktem nazw, jeśli taki wyjdzie.
  keepBoth;
}

/// Szuka poprawek, które w warsztacie mają co poprawiać.
///
/// Poprawka celuje w konkretne `lclId` (`correctionTarget`); gdy piosenkomat
/// celu nie zna, zostaje zbieżność id - poprawka zwykle nazywa się tak samo,
/// jak to, co poprawia, i to właśnie ona robi konflikt nazw.
List<CorrectionConflict> findCorrectionConflicts(
    List<SongRaw> imported,
    List<SongRaw> workspace,
){

  List<CorrectionConflict> conflicts = [];

  for(SongRaw song in imported){
    PiosenkomatData? data = song.piosenkomatData;
    if(data == null || !data.isCorrection) continue;

    String targetId = data.correctionTarget ?? song.id;

    List<SongRaw> existing = workspace.where((s) =>
        s.id == targetId && !imported.any((i) => identical(i, s))
    ).toList();

    if(existing.isEmpty) continue;

    conflicts.add(CorrectionConflict(song, existing));
  }

  return conflicts;

}

void showCorrectionImportDialog(
    BuildContext context,
    { required List<CorrectionConflict> conflicts,
      required void Function(CorrectionImportMode mode) onChosen,
    }) => openBaseDialog(
    context: context,
    maxWidth: songDialogWidth,
    builder: (context) => CorrectionImportDialog(conflicts: conflicts, onChosen: onChosen)
);

class CorrectionImportDialog extends StatelessWidget{

  final List<CorrectionConflict> conflicts;
  final void Function(CorrectionImportMode mode) onChosen;

  const CorrectionImportDialog({required this.conflicts, required this.onChosen, super.key});

  int get replacedCount =>
      conflicts.fold(0, (sum, conflict) => sum + conflict.existing.length);

  void choose(BuildContext context, CorrectionImportMode mode){
    popPage(context);
    onChosen(mode);
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [

      AppBarX(
          title:
          conflicts.length == 1?
          'Poprawka do piosenki z warsztatu':
          'Poprawki do piosenek z warsztatu'
      ),

      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimen.sideMarg),
        child: Text(
          conflicts.length == 1?
          'Jedna z importowanych piosenek to poprawka czegoś, co już jest w warsztacie.':
          '${conflicts.length} importowanych piosenek to poprawki tego, co już jest w warsztacie.',
          style: AppTextStyle(fontSize: Dimen.textSizeBig, color: textEnab_(context)),
        ),
      ),

      const SizedBox(height: Dimen.sideMarg),

      Flexible(
        child: ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: conflicts.length,
          itemBuilder: (context, index){

            CorrectionConflict conflict = conflicts[index];
            String title = conflict.imported.title;
            if(title.isEmpty) title = 'Brak tytułu.';

            return ListTile(
              leading: Icon(MdiIcons.pencilOutline, color: iconEnab_(context)),
              title: Text(
                title,
                style: AppTextStyle(fontSize: Dimen.textSizeBig, color: textEnab_(context)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                'poprawia: ${conflict.existing.map((s) => s.id).join(', ')}',
                style: AppTextStyle(color: hintEnab_(context)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
      ),

      SizedBox(
        width: double.infinity,
        child: SimpleButton.from(
            context: context,
            margin: const EdgeInsets.symmetric(horizontal: Dimen.defMarg, vertical: Dimen.defMarg/2),
            color: backgroundIcon_(context),
            icon: MdiIcons.swapHorizontal,
            text:
            replacedCount == 1?
            'Podmień istniejącą piosenkę':
            'Podmień istniejące piosenki ($replacedCount)',
            textColor: iconEnab_(context),
            onTap: () => choose(context, CorrectionImportMode.replace)
        ),
      ),

      SizedBox(
        width: double.infinity,
        child: SimpleButton.from(
            context: context,
            margin: const EdgeInsets.only(
                left: Dimen.defMarg,
                right: Dimen.defMarg,
                bottom: Dimen.defMarg,
            ),
            color: backgroundIcon_(context),
            icon: MdiIcons.contentDuplicate,
            text: 'Zostaw stare, dodaj poprawki obok',
            textColor: iconEnab_(context),
            onTap: () => choose(context, CorrectionImportMode.keepBoth)
        ),
      ),

    ],
  );

}
