import 'dart:ui';

import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_button.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/konspekt_workspace/models/konspekt_material_data.dart';
import 'package:harcapp_web/konspekt_workspace/widgets/material_widget.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class MaterialsWidget extends StatefulWidget {
  final List<KonspektMaterialData> materials;

  const MaterialsWidget({super.key, required this.materials});

  @override
  State<MaterialsWidget> createState() => _MaterialsWidgetState();
}

class _MaterialsWidgetState extends State<MaterialsWidget> {
  List<KonspektMaterialData> get materials => widget.materials;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedReorderableListView(
            buildDefaultDragHandles: false,
            proxyDecorator: proxyDecorator,
            physics: const NeverScrollableScrollPhysics(),
            items: materials,
            clipBehavior: Clip.none,
            dragStartDelay: Duration(milliseconds: 300),
            isSameItem: (oldItem, newItem) => oldItem.hashCode == newItem.hashCode,
            onReorder: (int oldIndex, int newIndex) {
              final KonspektMaterialData item = materials.removeAt(oldIndex);
              materials.insert(newIndex, item);
            },
            itemBuilder: (BuildContext context, int index) => Padding(
              key: ValueKey("material_${materials[index].hashCode}"),
              padding: EdgeInsets.only(bottom: index < materials.length - 1 ? Dimen.defMarg : 0),
              child: MaterialWidget(
                index: index,
                materialData: materials[index],
                nameTrailing: AppButton(
                  icon: Icon(MdiIcons.close),
                  onTap: () => setState(() => materials.removeAt(index)),
                ),
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
            text: 'Dodaj materiał',
            onTap: () => setState(() => materials.add(KonspektMaterialData.empty())),
          )
        ],
      );

  Widget proxyDecorator(Widget child, int index, Animation<double> animation) => AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double animValue = Curves.easeInOut.transform(animation.value);
          return Material(
            borderRadius: BorderRadius.circular(AppCard.defRadius),
            elevation: lerpDouble(0, AppCard.bigElevation, animValue)!,
            color: Color.lerp(background_(context), cardEnab_(context), animValue),
            child: child,
          );
        },
        child: child,
      );
}
