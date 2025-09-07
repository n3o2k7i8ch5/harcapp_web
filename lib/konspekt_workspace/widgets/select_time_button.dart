import 'package:duration_picker/duration_picker.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_navigator.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/date_to_str.dart';
import 'package:harcapp_core/comm_widgets/app_bar.dart';
import 'package:harcapp_core/comm_widgets/app_button.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/dialog/dialog.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class SelectTimeButton extends StatelessWidget {

  final Duration? time;
  final void Function(Duration?) onChanged;
  final double? fontSize;
  final bool removable;

  const SelectTimeButton(
      this.time,
      { required this.onChanged,
        this.fontSize,
        this.removable = true,
        super.key
      });

  @override
  Widget build(BuildContext context) => Material(
    borderRadius: BorderRadius.circular(AppCard.defRadius),
    clipBehavior: Clip.hardEdge,
    color: backgroundIcon_(context),
    child: Row(
      children: [

        SimpleButton(
          radius: 0,
          padding: EdgeInsets.symmetric(vertical: Dimen.defMarg, horizontal: 1.5*Dimen.defMarg),
          child: SizedBox(
            height: Dimen.iconSize,
            child: Center(
              child: Text(
                time==null?'Auto':durationToString(time),
                style: AppTextStyle(
                  fontSize: fontSize??Dimen.textSizeBig,
                  color: textEnab_(context),
                  fontWeight: weightNormal,
                ),
              )
            )
          ),
          onTap: () async {
            Duration? duration = await selectDuration(context, time);
            if(duration != null) onChanged.call(duration);
          }
        ),

        if(removable && time != null)
          SimpleButton.from(
            context: context,
            padding: EdgeInsets.all(Dimen.defMarg),
            radius: 0,
            margin: EdgeInsets.zero,
            icon: Icons.close,
            onTap: () => onChanged.call(null)
          )
        else if(!removable)
          Padding(
            padding: EdgeInsets.all(Dimen.defMarg),
            child: Icon(MdiIcons.pencilOutline),
          )
      ],
    ),
  );
}

class DurationSelectorDialog extends StatefulWidget {

  final Duration? initDuration;
  final void Function(Duration?) onSelected;

  const DurationSelectorDialog(this.initDuration, {required this.onSelected, super.key});

  @override
  State<StatefulWidget> createState() => DurationSelectorDialogState();

}

class DurationSelectorDialogState extends State<DurationSelectorDialog> {

  late Duration duration;
  late BaseUnit baseUnit;

  @override
  void initState() {
    duration = widget.initDuration??Duration(minutes: 15);
    baseUnit = BaseUnit.minute;
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(Dimen.sideMarg),
      child: Material(
          color: background_(context),
          clipBehavior: Clip.hardEdge,
          borderRadius: BorderRadius.circular(AppCard.bigRadius),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              AppBarX(
                title: 'Czas trwania',
                backgroundColor: background_(context),
                actions: [

                  AppButton(
                    icon: Icon(MdiIcons.check, color: iconEnab_(context)),
                    onTap: (){
                      widget.onSelected.call(duration);
                      popPage(context);
                    }
                  )

                ],
              ),

              Padding(
                  padding: EdgeInsets.all(Dimen.sideMarg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      DurationPicker(
                        duration: duration,
                        baseUnit: baseUnit,
                        onChange: (value) => setState(() => duration = value),
                      ),

                      SizedBox(height: Dimen.sideMarg),

                      Row(
                        children: [
                          Expanded(
                            child: SimpleButton.from(
                                context: context,
                                margin: EdgeInsets.zero,
                                color: baseUnit == BaseUnit.minute ? backgroundIcon_(context) : background_(context),
                                fontWeight: baseUnit == BaseUnit.minute ? weightBold : weightNormal,
                                text: 'Minuty',
                                onTap: () => setState(() => baseUnit = BaseUnit.minute)
                            ),
                          ),

                          SizedBox(width: Dimen.defMarg),

                          Expanded(
                            child: SimpleButton.from(
                                context: context,
                                margin: EdgeInsets.zero,
                                color: baseUnit == BaseUnit.hour ? backgroundIcon_(context) : background_(context),
                                fontWeight: baseUnit == BaseUnit.hour ? weightBold : weightNormal,
                                text: 'Godziny',
                                onTap: () => setState(() => baseUnit = BaseUnit.hour)
                            ),
                          ),
                        ],
                      )

                    ],
                  )
              ),

            ],
          ),
      ),
    ),
  );
  
}

Future<Duration?> selectDuration(
  BuildContext context,
  Duration? initialDuration,
) async {
  Duration? selectedDuration = initialDuration;
  await openDialog(
    context: context,
    builder: (context) => DurationSelectorDialog(
      initialDuration,
      onSelected: (duration) => selectedDuration = duration,
    ),
  );
  return selectedDuration;
}