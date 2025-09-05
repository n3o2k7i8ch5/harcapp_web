import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_text_field_hint.dart';
import 'package:harcapp_core/comm_widgets/multi_text_field.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_core/harcthought/konspekts/widgets/spheres_widget.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class SpheresWidget extends StatefulWidget{

  final Map<KonspektSphere, KonspektSphereDetails?> spheres;

  final void Function(Map<KonspektSphere, KonspektSphereDetails?> spheres) onChanged;

  const SpheresWidget({required this.spheres, required this.onChanged});

  @override
  State<StatefulWidget> createState() => SpheresWidgetState();

}

class SpheresWidgetState extends State<SpheresWidget> {

  Map<KonspektSphere, KonspektSphereDetails?> get spheres => {
    KonspektSphere.cialo: widget.spheres[KonspektSphere.cialo],
    KonspektSphere.umysl: widget.spheres[KonspektSphere.umysl],
    KonspektSphere.duch: widget.spheres[KonspektSphere.duch],
    KonspektSphere.emocje: widget.spheres[KonspektSphere.emocje],
    KonspektSphere.relacje: widget.spheres[KonspektSphere.relacje],
  };

  @override
  Widget build(BuildContext context) => ListView.separated(
    itemBuilder: (context, index) => SphereWidget(
      spheres.keys.elementAt(index),
      spheres.values.elementAt(index)
    ),
    separatorBuilder: (context, index) => SizedBox(height: Dimen.defMarg),
    itemCount: spheres.length,
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
  );

}

class SphereWidget extends StatefulWidget{

  final KonspektSphere sphere;
  final KonspektSphereDetails? details;

  const SphereWidget(this.sphere, this.details, {super.key});

  @override
  State<StatefulWidget> createState() => SphereWidgetState();

}

class SphereWidgetState extends State<SphereWidget>{

  KonspektSphere get sphere => widget.sphere;
  KonspektSphereDetails? get details => widget.details;

  late MultiTextFieldController controller;

  @override
  void initState() {
    controller = MultiTextFieldController(
      texts: details?.levels[KonspektSphereLevel.other]?.fields.keys.toList(),
      minCount: 0
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Material(
    borderRadius: BorderRadius.circular(AppCard.bigRadius),
    color: cardEnab_(context),
    child: Padding(
      padding: EdgeInsets.all(Dimen.sideMarg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          KonspektSphereTitleWidget(sphere),

          AppTextFieldHint(
            multiController: controller,
            hint: 'Elemenet sfery ${sphere.displayNameDopelniacz.toLowerCase()}:',
            multiHintTop: '',
            multi: true,
            multiAllowZeroFields: true,
            multiLayout: LayoutMode.column,
            multiItemBuilder: (index, key, widget) => Row(
              key: key,
              children: [
                // Because when having more than one item, the close button appears adding height.
                SizedBox(height: Dimen.iconFootprint),

                SizedBox(width: Dimen.iconMarg),
                Icon(MdiIcons.circleMedium),
                SizedBox(width: Dimen.iconMarg),
                Expanded(child: widget)
              ],
            ),
            multiAddButtonBuilder: (bool tappable, void Function() onTap) => SimpleButton.from(
              color: backgroundIcon_(context),
              context: context,
              icon: MdiIcons.plus,
              margin: EdgeInsets.zero,
              textColor: tappable? iconEnab_(context) : iconDisab_(context),
              text: 'Dodaj element rozwoju sfery ${sphere.displayNameDopelniacz.toLowerCase()}',
              onTap: tappable? onTap: null,
            ),
            multiIsCollapsed: true,
          ),

        ],
      ),
    ),
  );

}