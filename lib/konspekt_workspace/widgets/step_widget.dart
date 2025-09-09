import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_text_field_hint.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_core/harcthought/konspekts/widgets/step_widget.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/konspekt_workspace/models/konspekt_step_data.dart';
import 'package:harcapp_web/konspekt_workspace/widgets/select_time_button.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class StepWidget extends StatefulWidget{

  final int index;
  final KonspektStepData stepData;
  final Widget? nameTrailing;

  const StepWidget({super.key, required this.index, required this.stepData, this.nameTrailing});

  @override
  State<StatefulWidget> createState() => StepWidgetState();

}

class StepWidgetState extends State<StepWidget> {

  // late Duration duration;
  // late KonspektStepActiveForm activeForm;
  // late bool optional;

  KonspektStepData get stepData => widget.stepData;

  @override
  Widget build(BuildContext context) => Material(
    borderRadius: BorderRadius.circular(AppCard.defRadius),
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

                    Row(
                      children: [
                        Expanded(
                          child: AppTextFieldHint(
                            hint: 'Tytuł kroku ${widget.index + 1}:',
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),

                        if(widget.nameTrailing != null)
                          widget.nameTrailing!
                      ],
                    ),

                    SizedBox(height: Dimen.defMarg),

                    Row(
                      children: [
                        SelectTimeButton(
                          stepData.duration,
                          onChanged: (newDuration) => newDuration==null?null:setState(() => stepData.duration = newDuration),
                          removable: false,
                          fontSize: Dimen.textSizeBig,
                        ),
                        SizedBox(width: Dimen.sideMarg),
                        _ActiveFormButton(activeForm: stepData.activeForm, onChanged: (activeForm) => setState(() => stepData.activeForm = activeForm)),
                        SizedBox(width: Dimen.sideMarg),
                        _RequiredButton(required: stepData.required, onChanged: (optional) => setState(() => stepData.required = optional)),
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
    splashRadius: AppCard.defRadius,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppCard.defRadius)),
    borderRadius: BorderRadius.circular(AppCard.defRadius),
    clipBehavior: Clip.hardEdge,
    menuPadding: EdgeInsets.zero,
    padding: EdgeInsets.zero,
    child: SimpleButton.from(
      textColor: activeForm.color,
      radius: AppCard.defRadius,
      padding: EdgeInsets.all(Dimen.defMarg),
      color: backgroundIcon_(context),
      margin: EdgeInsets.zero,
      text: activeForm.displayName,
      onTap: null,
      icon: MdiIcons.chevronDown,
      iconColor: iconEnab_(context),
      iconLeading: false,
    ),
    onSelected: onChanged,
    color: background_(context),
    itemBuilder: (BuildContext context) => [
      PopupMenuItem<KonspektStepActiveForm>(
        value: KonspektStepActiveForm.active,
        padding: EdgeInsets.zero,
        child: SimpleButton.from(
          radius: AppCard.defRadius,
          padding: EdgeInsets.all(Dimen.defMarg),
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
          radius: AppCard.defRadius,
          padding: EdgeInsets.all(Dimen.defMarg),
          textColor: KonspektStepActiveForm.static.color,
          text: KonspektStepActiveForm.static.displayName,
          margin: EdgeInsets.zero,
          onTap: null,
        )
      ),
    ],
  );

}

class _RequiredButton extends StatelessWidget{

  final bool required;
  final void Function(bool optional)? onChanged;

  const _RequiredButton({required this.required, this.onChanged, super.key});

  @override
  Widget build(BuildContext context) => PopupMenuButton<bool>(
    splashRadius: AppCard.defRadius,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppCard.defRadius)),
    borderRadius: BorderRadius.circular(AppCard.defRadius),
    clipBehavior: Clip.hardEdge,
    menuPadding: EdgeInsets.zero,
    padding: EdgeInsets.zero,
    child: SimpleButton.from(
      context: context,
      radius: AppCard.defRadius,
      padding: EdgeInsets.all(Dimen.defMarg),
      color: backgroundIcon_(context),
      margin: EdgeInsets.zero,
      text: required? 'Obowiązkowo' : 'Opcjonalnie',
      onTap: null,
      icon: MdiIcons.chevronDown,
      iconColor: iconEnab_(context),
      iconLeading: false,
    ),
    onSelected: onChanged,
    color: background_(context),
    itemBuilder: (BuildContext context) => [
      PopupMenuItem<bool>(
        value: true,
        padding: EdgeInsets.zero,
        child: SimpleButton.from(
          context: context,
          radius: AppCard.defRadius,
          padding: EdgeInsets.all(Dimen.defMarg),
          text: 'Obowiązkowo',
          margin: EdgeInsets.zero,
          onTap: null,
        ),
      ),
      PopupMenuItem<bool>(
          value: false,
          padding: EdgeInsets.zero,
          child: SimpleButton.from(
            context: context,
            radius: AppCard.defRadius,
            padding: EdgeInsets.all(Dimen.defMarg),
            text: 'Opcjonalnie',
            margin: EdgeInsets.zero,
            onTap: null,
          )
      ),
    ],
  );

}