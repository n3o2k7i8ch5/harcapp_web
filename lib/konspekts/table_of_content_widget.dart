import 'package:flutter/material.dart';
import 'package:harcapp_core/colors.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/common.dart';
import 'package:harcapp_core/comm_classes/meto.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt_thumbnail_widget.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class TableOfContentWidget extends StatefulWidget{

  final List<Konspekt> allKonspekts;
  final Konspekt? selectedKonspekt;
  final EdgeInsets? padding;
  final void Function(Konspekt)? onItemTap;
  final bool withBackButton;

  const TableOfContentWidget({
    required this.allKonspekts,
    required this.selectedKonspekt,
    this.padding,
    this.onItemTap,
    this.withBackButton = false,
  });

  @override
  State<StatefulWidget> createState() => TableOfContentWidgetState();

}

class TableOfContentWidgetState extends State<TableOfContentWidget>{

  List<Konspekt> get allKonspekts => widget.allKonspekts;
  Konspekt? get selectedKonspekt => widget.selectedKonspekt;
  EdgeInsets? get padding => widget.padding;
  void Function(Konspekt)? get onItemTap => widget.onItemTap;
  bool get withBackButton => widget.withBackButton;

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
  Widget build(BuildContext context) => Stack(
    children: [

      Padding(
        padding: EdgeInsets.only(top: Dimen.iconFootprint/2),
        child: ListView.separated(
          padding: (padding??EdgeInsets.zero).add(EdgeInsets.only(top: Dimen.iconFootprint/2)),
          itemBuilder: (context, index) => SizedBox(
            height: 140,
            child: KonspektThumbnailWidget(
              searchedKonspekts[index],
              radius: AppCard.defRadius,
              background: searchedKonspekts[index] == selectedKonspekt?Colors.grey[300]!:Colors.grey[100]!,
              elevation: searchedKonspekts[index] == selectedKonspekt?AppCard.bigElevation:0,
              onTap: () => onItemTap?.call(searchedKonspekts[index]),
            ),
          ),
          separatorBuilder: (context, index) => SizedBox(height: Dimen.defMarg),
          itemCount: searchedKonspekts.length,
        ),
      ),

      Positioned(
        top: 0,
        right: 0,
        left: 0,
        child: Material(
          elevation: AppCard.bigElevation,
          borderRadius: BorderRadius.circular(AppCard.bigRadius - 4),
          color: cardEnab_(context),
          child: Row(
            children: [
              if(withBackButton)
                IconButton(
                  icon: Icon(MdiIcons.arrowLeft),
                  onPressed: () => Navigator.pop(context),
                )
              else
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

    ],
  );
}