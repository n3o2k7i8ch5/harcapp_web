import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_text_field_hint.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/konspekt_workspace/models/konspekt_material_data.dart';

class MaterialWidget extends StatefulWidget {
  final int index;
  final KonspektMaterialData materialData;
  final Widget? nameTrailing;

  const MaterialWidget({super.key, required this.index, required this.materialData, this.nameTrailing});

  @override
  State<MaterialWidget> createState() => _MaterialWidgetState();
}

class _AmountCounter extends StatefulWidget {
  final TextEditingController? controller;

  const _AmountCounter({required this.controller});

  @override
  State<_AmountCounter> createState() => _AmountCounterState();
}

class _AmountCounterState extends State<_AmountCounter> {
  TextEditingController? _internalController;

  TextEditingController get _controller => widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = TextEditingController(text: '1');
    } else if ((widget.controller!.text).trim().isEmpty) {
      widget.controller!.text = '1';
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  int get _value => int.tryParse(_controller.text) ?? 1;

  void _setValue(int newValue) {
    _controller.text = newValue.clamp(1, 9999).toString();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: backgroundIcon_(context),
          borderRadius: BorderRadius.circular(AppCard.defRadius),
        ),
        child: Row(
          children: [
            _CounterButton(
              icon: Icons.remove,
              onTap: () => _setValue(_value - 1),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: Dimen.textSizeSmall),
                decoration: const InputDecoration(
                  isDense: true,
                  isCollapsed: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (text) {
                  if ((int.tryParse(text) ?? 0) < 1) {
                    _setValue(1);
                  }
                },
              ),
            ),
            _CounterButton(
              icon: Icons.add,
              onTap: () => _setValue(_value + 1),
            ),
          ],
        ),
      );
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CounterButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Icon(icon, size: 18),
        ),
      );
}

enum _AmountMode { absolute, perParticipant }

class _MaterialWidgetState extends State<MaterialWidget> {

  late _AmountMode _amountMode;

  int get index => widget.index;
  KonspektMaterialData get materialData => widget.materialData;
  Widget? get nameTrailing => widget.nameTrailing;

  TextEditingController? get _activeAmountController =>
      _amountMode == _AmountMode.absolute
          ? materialData.amountController
          : materialData.amountAttendantFactorController;

  @override
  void initState() {
    super.initState();
    final hasPerParticipant =
        (materialData.amountAttendantFactorController?.text.trim() ?? '').isNotEmpty;
    final hasAbsolute =
        (materialData.amountController?.text.trim() ?? '').isNotEmpty;
    _amountMode = hasPerParticipant && !hasAbsolute
        ? _AmountMode.perParticipant
        : _AmountMode.absolute;
  }

  @override
  Widget build(BuildContext context) => Material(
        borderRadius: BorderRadius.circular(AppCard.defRadius),
        color: cardEnab_(context),
        child: Padding(
          padding: EdgeInsets.all(Dimen.sideMarg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextFieldHint(
                      hint: 'Nazwa materiału ${index + 1}:',
                      controller: materialData.nameController,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  SizedBox(width: Dimen.defMarg),
                  _AmountSection(
                    controller: _activeAmountController,
                    amountMode: _amountMode,
                    onModeChanged: (mode) => setState(() {
                      // Preserve entered value when switching between absolute / per-participant
                      final prevController = _activeAmountController;
                      _amountMode = mode;
                      final nextController = _activeAmountController;
                      if (prevController != null &&
                          nextController != null &&
                          !identical(prevController, nextController) &&
                          prevController.text.trim().isNotEmpty) {
                        nextController.text = prevController.text;
                      }
                    }),
                  ),
                  if (nameTrailing != null) ...[
                    SizedBox(width: Dimen.defMarg),
                    nameTrailing!,
                  ]
                ],
              ),

              SizedBox(height: Dimen.defMarg),

              _SecondaryField(
                hint: 'Komentarz (opcjonalnie):',
                hintTop: 'Komentarz',
                controller: materialData.commentController,
              ),

              SizedBox(height: Dimen.defMarg),

              _AttachmentField(controller: materialData.attachmentNameController),

              SizedBox(height: Dimen.defMarg),

              _AdditionalPreparationField(controller: materialData.additionalPreparationController),
            ],
          ),
        ),
      );
}

class _SecondaryField extends StatelessWidget {
  final String hint;
  final String? hintTop;
  final TextEditingController? controller;
  final Color? backgroundColor;

  const _SecondaryField({required this.hint, this.hintTop, this.controller, this.backgroundColor});

  @override
  Widget build(BuildContext context) => Material(
        borderRadius: BorderRadius.circular(AppCard.defRadius),
        color: backgroundColor??backgroundIcon_(context),
        child: Padding(
          padding: EdgeInsets.all(Dimen.defMarg),
          child: AppTextFieldHint(
            hint: hint,
            hintTop: hintTop,
            controller: controller,
            textCapitalization: TextCapitalization.sentences,
            maxLines: null,
          ),
        ),
      );
}

class _AmountSection extends StatelessWidget {
  final TextEditingController? controller;
  final _AmountMode amountMode;
  final ValueChanged<_AmountMode> onModeChanged;

  const _AmountSection({
    required this.controller,
    required this.amountMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 120,
              child: _AmountCounter(controller: controller),
            ),
            SizedBox(width: Dimen.defMarg),
            Container(
              decoration: BoxDecoration(
                color: backgroundIcon_(context),
                borderRadius: BorderRadius.circular(AppCard.defRadius),
              ),
              clipBehavior: Clip.hardEdge,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AmountModeButton(
                  text: 'Łącznie',
                  selected: amountMode == _AmountMode.absolute,
                  onTap: () => onModeChanged(_AmountMode.absolute),
                ),
                _AmountModeButton(
                  text: 'Na uczestnika',
                  selected: amountMode == _AmountMode.perParticipant,
                  onTap: () => onModeChanged(_AmountMode.perParticipant),
                )
              ],
            ),
          ),
        ],
      )
  );
}

class _AmountModeButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _AmountModeButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SimpleButton.from(
        context: context,
        margin: EdgeInsets.zero,
        radius: 0,
        padding: EdgeInsets.symmetric(horizontal: Dimen.defMarg, vertical: 2),
        color: selected ? backgroundIcon_(context).withValues(alpha: 0.6) : Colors.transparent,
        textColor: selected ? Colors.white : hintEnab_(context),
        text: text,
        textSize: Dimen.textSizeSmall,
        onTap: onTap,
      );
}

class _AttachmentField extends StatelessWidget {
  final TextEditingController? controller;

  const _AttachmentField({this.controller});

  @override
  Widget build(BuildContext context) => _SecondaryField(
    hint: 'Nazwa lub adres załącznika (opcjonalnie)',
    hintTop: 'Załącznik',
    controller: controller,
  );
}

class _AdditionalPreparationField extends StatelessWidget {
  final TextEditingController? controller;

  const _AdditionalPreparationField({this.controller});

  @override
  Widget build(BuildContext context) => _SecondaryField(
    hint: 'Opis dodatkowego przygotowania (opcjonalnie):',
    hintTop: 'Dodatkowe przygotowanie',
    controller: controller,
    backgroundColor: Colors.red.withValues(alpha: 0.08),
  );
}

