import 'dart:ui';

import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/konspekt_workspace/widgets/attachment_widget.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class AttachmentsWidget extends StatefulWidget {
  const AttachmentsWidget({super.key});

  @override
  State<AttachmentsWidget> createState() => _AttachmentsWidgetState();
}

class _AttachmentsWidgetState extends State<AttachmentsWidget> {
  final List<int> _ids = [DateTime.now().microsecondsSinceEpoch];

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedReorderableListView(
            buildDefaultDragHandles: false,
            proxyDecorator: proxyDecorator,
            physics: const NeverScrollableScrollPhysics(),
            items: _ids,
            clipBehavior: Clip.none,
            dragStartDelay: Duration(milliseconds: 300),
            isSameItem: (oldItem, newItem) => oldItem == newItem,
            onReorder: (int oldIndex, int newIndex) {
              final int id = _ids.removeAt(oldIndex);
              _ids.insert(newIndex, id);
              setState(() {});
            },
            itemBuilder: (BuildContext context, int index) => Padding(
              key: ValueKey("attachment_${_ids[index]}"),
              padding: EdgeInsets.only(
                  bottom: index < _ids.length - 1 ? Dimen.defMarg : 0),
              child: AttachmentWidget(
                onRemove: () => setState(() => _ids.removeAt(index)),
              ),
            ),
            shrinkWrap: true,
            enterTransition: [FadeIn()],
            exitTransition: [SlideInDown(), FadeIn()],
          ),

          const SizedBox(height: Dimen.defMarg),

          SimpleButton.from(
            context: context,
            radius: AppCard.defRadius,
            color: backgroundIcon_(context),
            icon: MdiIcons.plus,
            margin: EdgeInsets.zero,
            text: 'Dodaj załącznik',
            onTap: () => setState(() =>
                _ids.add(DateTime.now().microsecondsSinceEpoch)),
          )
        ],
      );

  Widget proxyDecorator(
    Widget child,
    int index,
    Animation<double> animation,
  ) =>
      AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double animValue =
              Curves.easeInOut.transform(animation.value);
          final color = Color.lerp(
              background_(context), cardEnab_(context), animValue);
          final double elevation =
              lerpDouble(0, AppCard.bigElevation, animValue)!;
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
