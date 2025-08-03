import 'package:duration_picker/duration_picker.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_navigator.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/date_to_str.dart';
import 'package:harcapp_core/comm_widgets/app_bar.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/comm_widgets/title_show_row_widget.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/common/alert_dialog.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class SelectTimeButton extends StatelessWidget {

  final Duration? time;
  final void Function(Duration?) onChanged;

  const SelectTimeButton(this.time, {required this.onChanged, super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [

      SimpleButton(
          color: backgroundIcon_(context),
          radius: AppCard.defRadius,
          padding: EdgeInsets.symmetric(vertical: Dimen.iconMarg, horizontal: Dimen.defMarg),
          child: SizedBox(
            height: Dimen.iconSize,
            child: Text(
              time==null?'[Automatycznie]':durationToString(time),
              style: AppTextStyle(
                fontSize: TitleShortcutRowWidget.style.fontSize,
                color: textEnab_(context),
                fontWeight: weightNormal,
              ),
            ),
          ),
          onTap: () async {
            Duration? duration = await selectDuration(context, time);
            if(duration != null) onChanged.call(duration);
          }
      ),

      if(time != null)
        SizedBox(width: Dimen.defMarg),

      if(time != null)
        SimpleButton.from(
          context: context,
          color: backgroundIcon_(context),
          margin: EdgeInsets.zero,
          radius: AppCard.defRadius,
          icon: Icons.close,
          onTap: () => onChanged.call(null)
        ),
    ],
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

                  IconButton(
                    icon: Icon(MdiIcons.check, color: iconEnab_(context)),
                    onPressed: (){
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