import 'package:flutter/material.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/harcthought/poradnik/data.dart';
import 'package:harcapp_core/harcthought/poradnik/poradnik.dart';
import 'package:harcapp_core/harcthought/poradnik/poradnik_thumbnail_widget.dart';

class TableOfContentPoradnikWidget extends StatefulWidget{

  final Poradnik? selectedPoradnik;
  final EdgeInsets? padding;
  final void Function(Poradnik)? onItemTap;
  final bool withBackButton;

  const TableOfContentPoradnikWidget({
    required this.selectedPoradnik,
    this.padding,
    this.onItemTap,
    this.withBackButton = false,
  });

  @override
  State<StatefulWidget> createState() => TableOfContentPoradnikWidgetState();

}

class TableOfContentPoradnikWidgetState extends State<TableOfContentPoradnikWidget>{

  Poradnik? get selectedPoradnik => widget.selectedPoradnik;
  EdgeInsets? get padding => widget.padding;
  void Function(Poradnik)? get onItemTap => widget.onItemTap;
  bool get withBackButton => widget.withBackButton;
  
  @override
  void initState() {

    super.initState();
  }

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: (padding??EdgeInsets.zero).add(EdgeInsets.only(top: Dimen.iconFootprint/2)),
    itemBuilder: (context, index) => SizedBox(
      height: 140,
      child: PoradnikThumbnailWidget(
        allPoradniks[index],
      ),
    ),
    separatorBuilder: (context, index) => SizedBox(height: Dimen.defMarg),
    itemCount: allPoradniks.length,
  );
}
