import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt_to_pdf/common.dart' as Dimen;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class MultiTextFieldAddButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool tappable;
  final String text;
  

  const MultiTextFieldAddButton({super.key, required this.onTap, this.tappable = true, required this.text});

  @override
  Widget build(BuildContext context) => SimpleButton.from(
    color: backgroundIcon_(context),
    padding: EdgeInsets.all(Dimen.defMarg),
    radius: AppCard.defRadius,
    context: context,
    icon: MdiIcons.plus,
    margin: EdgeInsets.zero,
    textColor: tappable? iconEnab_(context) : iconDisab_(context),
    text: text,
    onTap: tappable? onTap: null,
  );
}