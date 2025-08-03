import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_text_field_hint.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_core/harcthought/konspekts/widgets/step_widget.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/konspekt_workspace/widgets/select_time_button.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class StepWidget extends StatefulWidget{

  final int index;

  const StepWidget({super.key, required this.index});

  @override
  State<StatefulWidget> createState() => StepWidgetState();

}

class StepWidgetState extends State<StepWidget> {

  late Duration duration;
  late KonspektStepActiveForm activeForm;
  late bool optional;

  void initState() {
    super.initState();
    duration = Duration(minutes: 15);
    activeForm = KonspektStepActiveForm.static;
    optional = false;
  }

  @override
  Widget build(BuildContext context) => Material(
    borderRadius: BorderRadius.circular(AppCard.bigRadius),
    color: backgroundIcon_(context),
    child: Padding(
      padding: EdgeInsets.all(Dimen.sideMarg),
      child: Column(
        children: [

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StepIndexWidget(widget.index),
              SizedBox(width: Dimen.sideMarg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    AppTextFieldHint(
                      hint: 'Tytuł kroku ${widget.index + 1}:',
                      textCapitalization: TextCapitalization.sentences,
                    ),

                    SizedBox(height: Dimen.defMarg),

                    Row(
                      children: [
                        SelectTimeButton(
                          duration,
                          onChanged: (newDuration) => newDuration==null?null:setState(() => duration = newDuration),
                          fontSize: Dimen.textSizeBig,
                        ),
                        SizedBox(width: Dimen.sideMarg),
                        _ActiveFormButton(activeForm: activeForm, onChanged: (activeForm) => setState(() => this.activeForm = activeForm)),
                        SizedBox(width: Dimen.sideMarg),
                        _OptionalButton(optional: optional, onChanged: (optional) => setState(() => this.optional = optional)),
                      ],
                    ),

                  ],
                ),
              )

            ],
          ),

          SizedBox(height: Dimen.sideMarg),

          AppTextFieldHint(
            hint: 'Opis kroku ${widget.index + 1}:',
            textCapitalization: TextCapitalization.sentences,
            maxLines: null,
          ),

        ],
      ),
    )
  );

}

class _ActiveFormButton extends StatelessWidget{

  final KonspektStepActiveForm activeForm;
  final void Function(KonspektStepActiveForm activeForm)? onChanged;

  const _ActiveFormButton({required this.activeForm, this.onChanged, super.key});

  @override
  Widget build(BuildContext context) => PopupMenuButton<KonspektStepActiveForm>(
    splashRadius: AppCard.bigRadius,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppCard.bigRadius)),
    borderRadius: BorderRadius.circular(AppCard.bigRadius),
    clipBehavior: Clip.hardEdge,
    menuPadding: EdgeInsets.zero,
    padding: EdgeInsets.zero,
    child: SimpleButton.from(
      textColor: activeForm.color,
      color: backgroundIcon_(context),
      margin: EdgeInsets.zero,
      text: activeForm.displayName,
      onTap: null,
      icon: MdiIcons.chevronDown,
      iconColor: iconEnab_(context),
      iconLeading: false,
    ),
    onSelected: onChanged,
    itemBuilder: (BuildContext context) => [
      PopupMenuItem<KonspektStepActiveForm>(
        value: KonspektStepActiveForm.active,
        padding: EdgeInsets.zero,
        child: SimpleButton.from(
          textColor: KonspektStepActiveForm.active.color,
          text: KonspektStepActiveForm.active.displayName,
          margin: EdgeInsets.zero,
          onTap: null,
        ),
      ),
      PopupMenuItem<KonspektStepActiveForm>(
        value: KonspektStepActiveForm.static,
        padding: EdgeInsets.zero,
        child: SimpleButton.from(
          textColor: KonspektStepActiveForm.static.color,
          text: KonspektStepActiveForm.static.displayName,
          margin: EdgeInsets.zero,
          onTap: null,
        )
      ),
    ],
  );

}

class _OptionalButton extends StatelessWidget{

  final bool optional;
  final void Function(bool optional)? onChanged;

  const _OptionalButton({required this.optional, this.onChanged, super.key});

  @override
  Widget build(BuildContext context) => PopupMenuButton<bool>(
    splashRadius: AppCard.bigRadius,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppCard.bigRadius)),
    borderRadius: BorderRadius.circular(AppCard.bigRadius),
    clipBehavior: Clip.hardEdge,
    menuPadding: EdgeInsets.zero,
    padding: EdgeInsets.zero,
    child: SimpleButton.from(
      context: context,
      color: backgroundIcon_(context),
      margin: EdgeInsets.zero,
      text: optional? 'Opcjonalnie' : 'Obowiązkowo',
      onTap: null,
      icon: MdiIcons.chevronDown,
      iconColor: iconEnab_(context),
      iconLeading: false,
    ),
    onSelected: onChanged,
    itemBuilder: (BuildContext context) => [
      PopupMenuItem<bool>(
        value: true,
        padding: EdgeInsets.zero,
        child: SimpleButton.from(
          context: context,
          text: 'Opcjonalnie',
          margin: EdgeInsets.zero,
          onTap: null,
        ),
      ),
      PopupMenuItem<bool>(
          value: false,
          padding: EdgeInsets.zero,
          child: SimpleButton.from(
            context: context,
            text: 'Obowiązkowo',
            margin: EdgeInsets.zero,
            onTap: null,
          )
      ),
    ],
  );

}