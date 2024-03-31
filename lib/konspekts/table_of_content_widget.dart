import 'package:flutter/material.dart';
import 'package:harcapp_core/colors.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/common.dart';
import 'package:harcapp_core/comm_classes/meto.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/floating_container.dart';
import 'package:harcapp_core/comm_widgets/sliver_child_builder_separated_delegate.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core/konspekts/data.dart';
import 'package:harcapp_core/konspekts/konspekt.dart';
import 'package:harcapp_core/konspekts/konspekt_thumbnail_widget.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class TableOfContentWidget extends StatefulWidget{

  final Konspekt? selectedKonspekt;
  final EdgeInsets? padding;
  final void Function(int)? onItemTap;

  const TableOfContentWidget({required this.selectedKonspekt, this.padding, this.onItemTap});

  @override
  State<StatefulWidget> createState() => TableOfContentWidgetState();

}

class TableOfContentWidgetState extends State<TableOfContentWidget>{

  Konspekt? get selectedKonspekt => widget.selectedKonspekt;
  EdgeInsets? get padding => widget.padding;
  void Function(int)? get onItemTap => widget.onItemTap;

  late List<Konspekt> searchedKonspekts;

  late Set<Meto> selectedMetos;
  late Set<KonspektSphere> selectedSpheres;

  late TextEditingController controller;

  @override
  void initState() {
    searchedKonspekts = List.of(allKonspekts);

    controller = TextEditingController();

    selectedMetos = {};
    selectedSpheres = {};

    super.initState();
  }

  void runSearch(){

    String phrase = controller.text;
    searchedKonspekts.clear();

    if(phrase.isEmpty && selectedMetos.isEmpty && selectedSpheres.isEmpty) {
      searchedKonspekts.addAll(allKonspekts);
      setState(() {});
      return;
    }

    for(Konspekt konspekt in allKonspekts) {
      if(!remPolChars(konspekt.title).contains(remPolChars(phrase)))
        continue;

      if(!konspekt.containsMetos(selectedMetos))
        continue;

      if(!konspekt.containsSpheres(selectedSpheres))
        continue;

      searchedKonspekts.add(konspekt);
    }

    setState(() {});

  }

  @override
  Widget build(BuildContext context) => CustomScrollView(
    physics: BouncingScrollPhysics(),
    slivers: [

      FloatingContainer.child(
          child: Padding(
            padding: const EdgeInsets.all(Dimen.defMarg),
            child: Material(
              elevation: AppCard.bigElevation,
              borderRadius: BorderRadius.circular(AppCard.bigRadius - 4),
              color: cardEnab_(context),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.all(Dimen.iconMarg),
                    child: Icon(MdiIcons.magnify, color: hintEnab_(context)),
                  ),
                  Expanded(
                    child: TextField(
                      style: AppTextStyle(color: AppColors.text_def_enab),
                      controller: controller,
                      decoration: InputDecoration(
                          hintText: 'Szukaj',
                          hintStyle: AppTextStyle(color: AppColors.text_hint_enab),
                          border: InputBorder.none
                      ),
                      onChanged: (_) => runSearch(),
                    ),
                  )
                ],
              ),
            ),
          ),
          height: Dimen.iconFootprint + 2*Dimen.defMarg
      ),

      SliverPadding(
        padding: padding??EdgeInsets.zero,
        sliver: SliverList(
          delegate: SliverChildSeparatedBuilderDelegate(
            (BuildContext context, int index) => SizedBox(
                height: 140,
                child: KonspektThumbnailWidget(
                  searchedKonspekts[index],
                  elevation: searchedKonspekts[index] == selectedKonspekt?AppCard.bigElevation:0,
                  onTap: () => onItemTap?.call(index),
                )
            ),
            separatorBuilder: (BuildContext context, int index) => SizedBox(height: Dimen.defMarg),
            count: searchedKonspekts.length,
          ),
        ),
      ),

    ],
  );

}