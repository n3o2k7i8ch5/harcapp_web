import 'dart:ui';

import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/konspekt_workspace/models/konspekt_data.dart';
import 'package:harcapp_web/konspekt_workspace/models/konspekt_step_data.dart';
import 'package:harcapp_web/konspekt_workspace/widgets/step_widget.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class StepsWidget extends StatefulWidget {
  final List<KonspektStepData> steps;
  final List<KonspektAttachmentData>? attachments;
  // final Function() onReordered;

  const StepsWidget({
    Key? key,
    required this.steps,
    this.attachments,
    // required this.onReordered,
  }) : super(key: key);

  @override
  _StepsWidgetState createState() => _StepsWidgetState();
}

class _StepsWidgetState extends State<StepsWidget> {

  List<KonspektStepData> get steps => widget.steps;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [

      // TODO: Migrate this to a .seperated() constructor once it's available.
      // Currently, the padding is visible when moving the item.
      AnimatedReorderableListView(
        buildDefaultDragHandles: false,
        proxyDecorator: proxyDecorator,
        physics: NeverScrollableScrollPhysics(),
        items: steps,
        clipBehavior: Clip.none,
        dragStartDelay: Duration(milliseconds: 300),
        isSameItem: (oldItem, newItem) => oldItem.hashCode == newItem.hashCode,
        onReorder: (int oldIndex, int newIndex){
          final KonspektStepData stepData = steps.removeAt(oldIndex);
          steps.insert(newIndex, stepData);
          // widget.onReordered.call();
        },
        itemBuilder: (BuildContext context, int index) => Padding(
          key: ValueKey("song_part_${steps[index].hashCode}"),
          padding: EdgeInsets.only(bottom: index < steps.length-1 ? Dimen.defMarg : 0),
          child: StepWidget(
            index: index,
            stepData: steps[index],
            attachments: widget.attachments,
            onRemove: () => setState(() => steps.removeAt(index)),
          ),
        ),

        shrinkWrap: true,
        enterTransition: [FadeIn()],
        exitTransition: [SlideInDown(), FadeIn()],
      ),

      if(steps.isNotEmpty)
        SizedBox(height: Dimen.defMarg),

      SimpleButton.from(
        context: context,
        radius: AppCard.defRadius,
        color: backgroundIcon_(context),
        icon: MdiIcons.plus,
        margin: EdgeInsets.zero,
        text: 'Dodaj krok',
        onTap: () => setState(() => steps.add(KonspektStepData.empty())),
      )

    ],
  );

  Widget proxyDecorator(Widget child, int index, Animation<double> animation) => AnimatedBuilder(
    animation: animation,
    builder: (BuildContext context, Widget? child) {
      final double animValue = Curves.easeInOut.transform(animation.value);
      final color = Color.lerp(background_(context), cardEnab_(context), animValue);
      final double elevation = lerpDouble(0, AppCard.bigElevation, animValue)!;
      return Material(
        borderRadius: BorderRadius.circular(AppCard.defRadius),
        elevation: elevation,
        color: color,
        child: child,
      );
    },
    child: child,
  );

}