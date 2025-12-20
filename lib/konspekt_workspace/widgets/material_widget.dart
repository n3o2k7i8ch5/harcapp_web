import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_widgets/app_bar.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_text_field_hint.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/harcthought/common/file_format.dart';
import 'package:harcapp_core/harcthought/common/file_format_selector_row_widget.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/konspekt_workspace/models/konspekt_attachment_data.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:harcapp_web/konspekt_workspace/models/konspekt_material_data.dart';

class MaterialWidget extends StatefulWidget {
  final int index;
  final KonspektMaterialData materialData;
  final Widget? nameTrailing;
  final List<KonspektAttachmentData> attachments;
  final VoidCallback? onAttachmentChange;
  final VoidCallback? onRemove;

  const MaterialWidget({
    super.key,
    required this.index,
    required this.materialData,
    required this.attachments,
    this.nameTrailing,
    this.onAttachmentChange,
    this.onRemove,
  });

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
          color: cardEnab_(context),
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
                style: const TextStyle(fontSize: Dimen.textSizeNormal),
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
  List<KonspektAttachmentData> get attachments => widget.attachments;
  VoidCallback? get onRemove => widget.onRemove;

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

              _AttachmentField(
                controller: materialData.attachmentNameController,
                attachments: attachments,
                onChanged: widget.onAttachmentChange,
              ),

              SizedBox(height: Dimen.defMarg),

              _AdditionalPreparationField(controller: materialData.additionalPreparationController),

              if (onRemove != null) ...[
                SizedBox(height: Dimen.defMarg),
                Align(
                  alignment: Alignment.centerRight,
                  child: SimpleButton.from(
                    context: context,
                    radius: AppCard.defRadius,
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimen.defMarg * 1.5,
                      vertical: Dimen.defMarg,
                    ),
                    color: Colors.red.withValues(alpha: 0.3),
                    margin: EdgeInsets.zero,
                    text: 'Usuń',
                    textColor: Colors.red,
                    icon: MdiIcons.trashCanOutline,
                    iconColor: Colors.red,
                    onTap: onRemove,
                  ),
                ),
              ],
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
        textSize: Dimen.textSizeNormal,
        onTap: onTap,
      );
}

class _AttachmentField extends StatefulWidget {
  final TextEditingController? controller;
  final List<KonspektAttachmentData> attachments;
  final void Function()? onChanged;

  const _AttachmentField({required this.controller, required this.attachments, this.onChanged});

  @override
  State<_AttachmentField> createState() => _AttachmentFieldState();
}

class _AttachmentFieldState extends State<_AttachmentField> {

  Future<void> _selectAttachment(BuildContext context) async {
    final String? selectedId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: EdgeInsets.all(Dimen.defMarg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 520,
          ),
          child: Material(
            borderRadius: BorderRadius.circular(AppCard.bigRadius),
            color: background_(dialogContext),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header / app bar
                  AppBarX(
                    backgroundColor: backgroundIcon_(dialogContext),
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppCard.bigRadius),
                      ),
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: iconEnab_(dialogContext),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                    title: 'Wybierz załącznik',
                  ),

                  // Content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(Dimen.sideMarg),
                      child: widget.attachments.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.insert_drive_file_outlined,
                                  size: 48,
                                  color: hintEnab_(dialogContext),
                                ),
                                SizedBox(height: Dimen.defMarg),
                                Text(
                                  'Brak załączników do dodania',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyle(
                                    color: hintEnab_(dialogContext),
                                    fontSize: Dimen.textSizeBig,
                                  ),
                                ),
                              ],
                            )
                          : SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ...widget.attachments.map((att) {
                                    final Set<FileFormat> formats = {
                                      ...att.pickedFiles.keys,
                                      ...att.pickedUrls.keys,
                                    };
                                    final bool hasName = att.name.isNotEmpty;

                                    return Padding(
                                      padding: EdgeInsets.only(bottom: Dimen.defMarg),
                                      child: SimpleButton(
                                        color: backgroundIcon_(dialogContext),
                                        radius: AppCard.defRadius,
                                        clipBehavior: Clip.hardEdge,
                                        onTap: hasName ? () => Navigator.of(dialogContext).pop(att.name) : null,
                                        child: Padding(
                                          padding: EdgeInsets.all(Dimen.defMarg),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                att.displayTitle,
                                                style: AppTextStyle(
                                                  color: hasName ? iconEnab_(dialogContext) : hintEnab_(dialogContext),
                                                  fontSize: Dimen.textSizeBig,
                                                  fontWeight: weightHalfBold,
                                                  fontStyle: att.hasTitle
                                                      ? FontStyle.normal
                                                      : FontStyle.italic,
                                                ),
                                              ),
                                              if (!hasName) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Nadaj nazwę załącznikowi, aby go wybrać',
                                                  style: AppTextStyle(
                                                    color: hintEnab_(dialogContext),
                                                    fontSize: Dimen.textSizeSmall,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
                                              if (att.name.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  att.name,
                                                  style: AppTextStyle(
                                                    color: hintEnab_(dialogContext),
                                                    fontSize: Dimen.textSizeSmall,
                                                  ),
                                                ),
                                              ],
                                              if (formats.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: formats
                                                      .map((format) => Padding(
                                                            padding: EdgeInsets.only(right: Dimen.defMarg / 2),
                                                            child: FileFormatWidget(format),
                                                          ))
                                                      .toList(),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (selectedId != null) {
      setState(() {
        widget.controller?.text = selectedId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller?.text.trim() ?? '';
    final bool hasValue = text.isNotEmpty;
    final String? displayText = hasValue
        ? KonspektAttachmentData.findTitleByName(widget.attachments, text)
        : null;

    return Material(
      borderRadius: BorderRadius.circular(AppCard.defRadius),
      color: backgroundIcon_(context),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppCard.defRadius),
        onTap: () async {
          await _selectAttachment(context);
          widget.onChanged?.call();
        },
        child: Padding(
          padding: EdgeInsets.all(Dimen.defMarg),
          child: Row(
            children: [

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      hasValue ? 'Załącznik' : '',
                      style: AppTextStyle(
                        fontSize: AppTextFieldHint.topHintFontSize,
                        fontWeight: AppTextFieldHint.topHintFontWeight,
                        color: AppTextFieldHint.topHintColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayText ?? 'Załącznik (opcjonalnie)',
                      style: AppTextStyle(
                        color: hasValue ? iconEnab_(context) : hintEnab_(context),
                        fontSize: Dimen.textSizeBig,
                        fontStyle: displayText == 'bez nazwy' ? FontStyle.italic : FontStyle.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTextFieldHint.topHintFontSize),
                  ],
                ),
              ),

              if (hasValue)
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Usuń załącznik',
                  onPressed: () {
                    setState(() {
                      widget.controller?.text = '';
                    });
                    widget.onChanged?.call();
                  },
                ),

            ],
          ),
        ),
      ),
    );
  }
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

