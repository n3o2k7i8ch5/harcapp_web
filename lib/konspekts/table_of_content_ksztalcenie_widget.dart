import 'package:flutter/material.dart';
import 'package:harcapp_core/harcthought/konspekts/data/ksztalcenie/all.dart';
import 'package:harcapp_core/harcthought/konspekts/filter/konspekt_filters.dart';
import 'package:harcapp_core/harcthought/konspekts/filter/konspekt_filters_widget.dart';
import 'package:harcapp_core/harcthought/konspekts/filter/run_search.dart';
import 'package:harcapp_core/harcthought/konspekts/filter/search_field_bottom_filters_indicators.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_web/konspekts/table_of_content_widget.dart';

class TableOfContentKsztalcenieWidget extends StatefulWidget{

  final Konspekt? selectedKonspekt;
  final EdgeInsets? padding;
  final void Function(Konspekt)? onItemTap;
  final bool withBackButton;

  const TableOfContentKsztalcenieWidget({
    required this.selectedKonspekt,
    this.padding,
    this.onItemTap,
    this.withBackButton = false,
  });

  @override
  State<StatefulWidget> createState() => TableOfContentKsztalcenieWidgetState();

}

class TableOfContentKsztalcenieWidgetState extends State<TableOfContentKsztalcenieWidget>{

  Konspekt? get selectedKonspekt => widget.selectedKonspekt;
  EdgeInsets? get padding => widget.padding;
  void Function(Konspekt)? get onItemTap => widget.onItemTap;
  bool get withBackButton => widget.withBackButton;

  late List<Konspekt> searchedKonspekts;
  late KonspektKsztalcenieFilters filters;
  late TextEditingController controller;

  bool get hideSearchFieldBottom => filters.hideSearchFieldBottom;

  @override
  void initState() {
    controller = TextEditingController();
    filters = KonspektKsztalcenieFilters();

    super.initState();
  }

  @override
  Widget build(BuildContext context) => KonspektSearchWrapper<KonspektKsztalcenieFilters>(
      initKonspekts: allKsztalcenieKonspekts,
      runSearch: runKonspektsKsztalcenieSearch,
      builder: (context) => TableOfContentWidget<KonspektKsztalcenieFilters>(
        selectedKonspekt: selectedKonspekt,
        filters: filters,
        filtersWidgetBuilder: (searchProvider) => KonspektKsztalcenieFiltersWidget(
          filters,
          onChanged: (filters){
            searchProvider.runSearch(filters);
            setState(() => this.filters = filters);
          }
        ),
        searchFieldBottomFilterIndicatorsWidget: SearchFieldBottomKsztalcenieFilterIndicatorsWidget(
            filters
        ),
        padding: padding,
        onItemTap: onItemTap,
        withBackButton: withBackButton,
      )
  );
}
