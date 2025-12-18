import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_text_field_hint.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class BulletListEditorWidget extends StatefulWidget {
  final List<TextEditingController> controllers;
  final String itemHint;
  final String addButtonText;
  final VoidCallback? onChanged;

  const BulletListEditorWidget({
    super.key,
    required this.controllers,
    required this.itemHint,
    required this.addButtonText,
    this.onChanged,
  });

  @override
  State<BulletListEditorWidget> createState() => _BulletListEditorWidgetState();
}

class _BulletListEditorWidgetState extends State<BulletListEditorWidget> {
  List<TextEditingController> get controllers => widget.controllers;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ...List.generate(controllers.length, (index) {
        final controller = controllers[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < controllers.length - 1 ? Dimen.defMarg : 0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: Dimen.iconFootprint),

              SizedBox(width: Dimen.iconMarg),
              Icon(MdiIcons.circleMedium),
              SizedBox(width: Dimen.iconMarg),

              Expanded(
                child: AppTextFieldHint(
                  hint: widget.itemHint,
                  controller: controller,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: null,
                  onChanged: (_, __) => widget.onChanged?.call(),
                ),
              ),

              SizedBox(width: Dimen.defMarg),

              SimpleButton.from(
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
                onTap: () {
                  setState(() => controllers.removeAt(index));
                  widget.onChanged?.call();
                },
              ),
            ],
          ),
        );
      }),

      if (controllers.isNotEmpty) SizedBox(height: Dimen.defMarg),

      SimpleButton.from(
        color: backgroundIcon_(context),
        radius: AppCard.defRadius,
        context: context,
        icon: MdiIcons.plus,
        margin: EdgeInsets.zero,
        textColor: iconEnab_(context),
        text: widget.addButtonText,
        onTap: () {
          setState(() => controllers.add(TextEditingController()));
          widget.onChanged?.call();
        },
      ),
    ],
  );
}
