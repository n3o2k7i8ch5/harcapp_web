// import 'package:flutter/material.dart';
// import 'package:harcapp_core/colors.dart';
// import 'package:harcapp_core/comm_classes/app_text_style.dart';
// import 'package:harcapp_core/comm_classes/color_pack.dart';
// import 'package:harcapp_core/comm_classes/common.dart';
// import 'package:harcapp_core/comm_classes/meto.dart';
// import 'package:harcapp_core/comm_widgets/app_bar.dart';
// import 'package:harcapp_core/comm_widgets/app_card.dart';
// import 'package:harcapp_core/dimen.dart';
// import 'package:harcapp_core/harcthought/konspekts/filter_widgets/konspekts_harcerskie_filter_widget.dart';
// import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
// import 'package:harcapp_core/harcthought/konspekts/konspekt_thumbnail_widget.dart';
// import 'package:harcapp_web/consts.dart';
// import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
//
// class TableOfContentWidget extends StatefulWidget{
//
//   final List<Konspekt> allKonspekts;
//   final Konspekt? selectedKonspekt;
//   final EdgeInsets? padding;
//   final void Function(Konspekt)? onItemTap;
//   final bool withBackButton;
//
//   const TableOfContentWidget({
//     required this.allKonspekts,
//     required this.selectedKonspekt,
//     this.padding,
//     this.onItemTap,
//     this.withBackButton = false,
//   });
//
//   @override
//   State<StatefulWidget> createState() => TableOfContentWidgetState();
//
// }
//
// class TableOfContentWidgetState extends State<TableOfContentWidget>{
//
//   List<Konspekt> get allKonspekts => widget.allKonspekts;
//   Konspekt? get selectedKonspekt => widget.selectedKonspekt;
//   EdgeInsets? get padding => widget.padding;
//   void Function(Konspekt)? get onItemTap => widget.onItemTap;
//   bool get withBackButton => widget.withBackButton;
//
//   late List<Konspekt> searchedKonspekts;
//
//   late Set<Meto> selectedMetos;
//   late Set<KonspektSphere> selectedSpheres;
//
//   late TextEditingController controller;
//
//   bool get hideSearchFieldBottom => selectedMetos.isEmpty && selectedSpheres.isEmpty;
//
//   @override
//   void initState() {
//     searchedKonspekts = List.of(allKonspekts);
//
//     controller = TextEditingController();
//
//     selectedMetos = {};
//     selectedSpheres = {};
//
//     super.initState();
//   }
//
//   void runSearch(){
//
//     String phrase = controller.text;
//     searchedKonspekts.clear();
//
//     searchedKonspekts.addAll(
//         runKonspektsHarcerskieSearch(phrase, selectedMetos, selectedSpheres)
//     );
//
//     setState(() {});
//
//   }
//
//   @override
//   Widget build(BuildContext context) => Stack(
//     children: [
//
//       Padding(
//         padding: EdgeInsets.only(top: Dimen.iconFootprint/2 + (hideSearchFieldBottom?0:35.0)),
//         child: ListView.separated(
//           padding: (padding??EdgeInsets.zero).add(EdgeInsets.only(top: Dimen.iconFootprint/2)),
//           itemBuilder: (context, index) => SizedBox(
//             height: 140,
//             child: KonspektThumbnailWidget(
//               searchedKonspekts[index],
//               radius: AppCard.defRadius,
//               background: searchedKonspekts[index] == selectedKonspekt?Colors.grey[300]!:Colors.grey[100]!,
//               elevation: searchedKonspekts[index] == selectedKonspekt?AppCard.bigElevation:0,
//               onTap: () => onItemTap?.call(searchedKonspekts[index]),
//             ),
//           ),
//           separatorBuilder: (context, index) => SizedBox(height: Dimen.defMarg),
//           itemCount: searchedKonspekts.length,
//         ),
//       ),
//
//       Positioned(
//         top: 0,
//         right: 0,
//         left: 0,
//         child: Material(
//           elevation: AppCard.bigElevation,
//           borderRadius: BorderRadius.circular(AppCard.bigRadius - 4),
//           color: cardEnab_(context),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//
//               Row(
//                 children: [
//
//                   if(selectedMetos.isNotEmpty || selectedSpheres.isNotEmpty || controller.text.isNotEmpty)
//                     IconButton(
//                       icon: Icon(MdiIcons.close),
//                       onPressed: (){
//                         selectedMetos.clear();
//                         selectedSpheres.clear();
//                         controller.clear();
//                         runSearch();
//                       },
//                     )
//                   else if(withBackButton)
//                     IconButton(
//                       icon: Icon(MdiIcons.arrowLeft),
//                       onPressed: () => Navigator.pop(context),
//                     )
//                   else
//                     Padding(
//                       padding: EdgeInsets.all(Dimen.iconMarg),
//                       child: Icon(MdiIcons.magnify, color: hintEnab_(context)),
//                     ),
//
//                   Expanded(
//                     child: TextField(
//                       style: AppTextStyle(color: AppColors.text_def_enab),
//                       controller: controller,
//                       decoration: InputDecoration(
//                           hintText: 'Szukaj',
//                           hintStyle: AppTextStyle(color: AppColors.text_hint_enab),
//                           border: InputBorder.none
//                       ),
//                       onChanged: (_) => runSearch(),
//                     ),
//                   ),
//
//                   IconButton(
//                     icon: Icon(MdiIcons.cogOutline),
//                     onPressed: () => showDialog(
//                         context: context,
//                         builder: (context) => SettingsDialog(
//                           selectedMetos: selectedMetos,
//                           selectedSpheres: selectedSpheres,
//                           onChanged: (Set<Meto> selectedMetos, Set<KonspektSphere> selectedSpheres){
//                             this.selectedMetos = selectedMetos;
//                             this.selectedSpheres = selectedSpheres;
//                             setState(() {});
//                             runSearch();
//                           },
//                           maxWidth: songDialogWidth,
//                         )
//                     ),
//                   )
//
//                 ],
//               ),
//
//               if(selectedMetos.isNotEmpty || selectedSpheres.isNotEmpty)
//                 SearchFieldBottomHarcerskieFiltersWidget(selectedMetos, selectedSpheres),
//
//             ],
//           )
//         ),
//       ),
//
//     ],
//   );
// }
//
// class SettingsDialog extends StatefulWidget{
//
//   final Set<Meto> selectedMetos;
//   final Set<KonspektSphere> selectedSpheres;
//   final void Function(Set<Meto>, Set<KonspektSphere>) onChanged;
//   final double? maxWidth;
//
//   const SettingsDialog({
//     required this.selectedMetos,
//     required this.selectedSpheres,
//     required this.onChanged,
//     this.maxWidth
//   });
//
//   @override
//   State<StatefulWidget> createState() => SettingsDialogState();
//
// }
//
// class SettingsDialogState extends State<SettingsDialog>{
//
//   Set<Meto> get selectedMetos => widget.selectedMetos;
//   Set<KonspektSphere> get selectedSpheres => widget.selectedSpheres;
//   void Function(Set<Meto>, Set<KonspektSphere>) get onChanged => widget.onChanged;
//   double? get maxWidth => widget.maxWidth;
//
//   @override
//   Widget build(BuildContext context){
//
//     Widget child = Padding(
//       padding: EdgeInsets.all(Dimen.defMarg),
//       child: Material(
//           borderRadius: BorderRadius.circular(AppCard.bigRadius),
//           clipBehavior: Clip.hardEdge,
//           color: background_(context),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//
//               AppBarX(
//                 titleWidget: Text(
//                   'Filtry',
//                   style: AppTextStyle(color: iconEnab_(context)),
//                 ),
//                 iconTheme: IconThemeData(color: iconEnab_(context)),
//               ),
//
//               Padding(
//                 padding: EdgeInsets.all(Dimen.sideMarg),
//                 child: KonspektsHarcerskieFilterWidget(
//                   selectedMetos,
//                   selectedSpheres,
//                   (selectedMetos, selectedSpheres){
//                     onChanged(selectedMetos, selectedSpheres);
//                     setState(() {});
//                   },
//                 ),
//               ),
//
//             ],
//           )
//       ),
//     );
//
//     if(maxWidth != null)
//       child = ConstrainedBox(
//         constraints: BoxConstraints(maxWidth: maxWidth!),
//         child: child,
//       );
//
//     return Center(child: child);
//
//   }
//
// }