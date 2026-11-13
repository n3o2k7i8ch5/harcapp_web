import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_text_field_hint.dart';
import 'package:harcapp_core/comm_widgets/contributor_ref_field.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/konspekt_workspace/models/konspekt_author_data.dart';

/// Lista autorów konspektu w kolejności wyświetlania. Każdy autor ma
/// opcjonalny dopisek. Pusta karta na końcu służy do dodania kolejnego autora.
class AuthorsWidget extends StatelessWidget{

  final List<KonspektAuthorData> authors;
  /// Zmiana struktury listy (dodanie, usunięcie, podmiana osoby).
  final VoidCallback onChanged;
  /// Zmiana treści dopisku.
  final VoidCallback onNoteChanged;

  const AuthorsWidget({required this.authors, required this.onChanged, required this.onNoteChanged, super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [

      for(final author in authors)
        Padding(
          key: ObjectKey(author),
          padding: const EdgeInsets.only(bottom: Dimen.defMarg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ContributorRefField(
                identity: author.ref,
                dialogTitle: 'Autor konspektu',
                onChanged: (ref){
                  if(ref == null || ref.isEmpty) authors.remove(author);
                  else author.ref = ref;
                  onChanged();
                },
              ),
              AppTextFieldHint(
                hint: 'Dopisek (opcjonalnie):',
                hintTop: 'Dopisek',
                textCapitalization: TextCapitalization.sentences,
                controller: author.noteController,
                onChanged: (_, __) => onNoteChanged(),
                leading: Padding(
                  padding: const EdgeInsets.all(Dimen.iconMarg),
                  child: Icon(MdiIcons.commentTextOutline, color: hintEnab_(context)),
                ),
              ),
            ],
          ),
        ),

      ContributorRefField(
        identity: null,
        emptyLabel: authors.isEmpty ? 'Dodaj autora konspektu' : 'Dodaj kolejnego autora',
        dialogTitle: 'Autor konspektu',
        onChanged: (ref){
          if(ref == null || ref.isEmpty) return;
          authors.add(KonspektAuthorData.from(ref));
          onChanged();
        },
      ),

    ],
  );

}
