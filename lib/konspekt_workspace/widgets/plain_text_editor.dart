import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/values/dimen.dart';

class PlainTextEditor extends StatelessWidget {
  static const _editorMinHeight = 100.0;
  static const _editorMaxHeight = 500.0;

  final double? radius;
  final Color? background;
  final TextEditingController controller;
  final String? placeholder;
  final VoidCallback? onChanged;

  const PlainTextEditor({
    super.key,
    this.radius,
    this.background,
    required this.controller,
    this.placeholder,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Material(
    borderRadius: BorderRadius.circular(radius ?? AppCard.defRadius),
    color: background ?? backgroundIcon_(context),
    child: Padding(
      padding: EdgeInsets.all(Dimen.defMarg),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: _editorMinHeight,
          maxHeight: _editorMaxHeight,
        ),
        decoration: BoxDecoration(
          color: background_(context),
          borderRadius: BorderRadius.circular(AppCard.defRadius),
        ),
        padding: EdgeInsets.all(Dimen.defMarg),
        child: TextField(
          controller: controller,
          maxLines: null,
          textCapitalization: TextCapitalization.sentences,
          style: AppTextStyle(fontSize: Dimen.textSizeBig),
          decoration: InputDecoration.collapsed(
            hintText: placeholder,
            hintStyle: AppTextStyle(
              fontSize: Dimen.textSizeBig,
              color: hintEnab_(context),
            ),
          ),
          onChanged: (_) => onChanged?.call(),
        ),
      ),
    ),
  );
}
