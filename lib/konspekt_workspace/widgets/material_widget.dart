import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_text_field_hint.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/konspekt_workspace/models/konspekt_material_data.dart';

class MaterialWidget extends StatelessWidget {
  final int index;
  final KonspektMaterialData materialData;
  final Widget? nameTrailing;

  const MaterialWidget({super.key, required this.index, required this.materialData, this.nameTrailing});

  @override
  Widget build(BuildContext context) => Material(
        borderRadius: BorderRadius.circular(AppCard.defRadius),
        color: backgroundIcon_(context),
        child: Padding(
          padding: EdgeInsets.all(Dimen.sideMarg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppTextFieldHint(
                                hint: 'Nazwa materiału:',
                                controller: materialData.nameController,
                                textCapitalization: TextCapitalization.sentences,
                              ),
                            ),
                            if (nameTrailing != null) nameTrailing!,
                          ],
                        ),

                        SizedBox(height: Dimen.defMarg),

                        Row(
                          children: [
                            Expanded(
                              child: AppTextFieldHint(
                                hint: 'Ilość (np. 3):',
                                controller: materialData.amountController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            SizedBox(width: Dimen.defMarg),
                            Expanded(
                              child: AppTextFieldHint(
                                hint: 'Na uczestnika (np. 1):',
                                controller: materialData.attendantFactorController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: Dimen.defMarg),

                        AppTextFieldHint(
                          hint: 'Komentarz (opcjonalnie):',
                          controller: materialData.commentController,
                          textCapitalization: TextCapitalization.sentences,
                        ),

                        SizedBox(height: Dimen.defMarg),

                        AppTextFieldHint(
                          hint: 'Nazwa załącznika (opcjonalnie):',
                          controller: materialData.attachmentNameController,
                          textCapitalization: TextCapitalization.sentences,
                        ),

                        SizedBox(height: Dimen.defMarg),

                        AppTextFieldHint(
                          hint: 'Dodatkowe przygotowanie (opcjonalnie):',
                          controller: materialData.additionalPreparationController,
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

