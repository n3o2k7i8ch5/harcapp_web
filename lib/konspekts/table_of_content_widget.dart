import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_widgets/app_button.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_bar.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/harcthought/konspekts/filter/konspekt_filters.dart';
import 'package:harcapp_core/harcthought/konspekts/filter/konspekt_filters_widget.dart';
import 'package:harcapp_core/harcthought/konspekts/filter/search_field_bottom_filters_indicators.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt_tile_widget.dart';
import 'package:harcapp_web/consts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class KonspektSearchProvider<T extends KonspektFilters> extends ChangeNotifier {

  static of<T extends KonspektFilters>(BuildContext context) => Provider.of<KonspektSearchProvider<T>>(context, listen: false);
  static runSearch_<T extends KonspektFilters>(BuildContext context, T filters) => of<T>(context).runSearch(filters);

  List<Konspekt> _konspekts = [];
  final List<Konspekt> Function(T) search;

  List<Konspekt> get konspekts => _konspekts;

  KonspektSearchProvider({List<Konspekt>? konspekts, required this.search}): _konspekts = List.of(konspekts??[]);
  
  set konspekts(List<Konspekt> konspekts) {
    _konspekts = konspekts;
    notifyListeners();
  }

  void runSearch(T filters){
    _konspekts.clear();
    _konspekts.addAll(search(filters));
    notifyListeners();
  }
  
}

class KonspektSearchWrapper<T extends KonspektFilters> extends StatelessWidget {

  final List<Konspekt> initKonspekts;
  final List<Konspekt> Function(T) runSearch;
  final Widget Function(BuildContext) builder;

  const KonspektSearchWrapper({super.key, required this.initKonspekts, required this.runSearch, required this.builder});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) => KonspektSearchProvider<T>(konspekts: initKonspekts, search: runSearch),
    builder: (context, _) => builder(context),
  );

}

class TableOfContentWidget<T extends KonspektFilters> extends StatefulWidget{

  final Konspekt? selectedKonspekt;
  final T filters;
  final KonspektFiltersWidget Function(KonspektSearchProvider<T>) filtersWidgetBuilder;
  final SearchFieldBottomFilterIndicatorsWidget searchFieldBottomFilterIndicatorsWidget;
  final EdgeInsets? padding;
  final void Function(Konspekt)? onItemTap;
  final bool withBackButton;

  const TableOfContentWidget({
    required this.selectedKonspekt,
    required this.filters,
    required this.filtersWidgetBuilder,
    required this.searchFieldBottomFilterIndicatorsWidget,
    this.padding,
    this.onItemTap,
    this.withBackButton = false,
  });

  @override
  State<StatefulWidget> createState() => TableOfContentWidgetState<T>();

}

class TableOfContentWidgetState<T extends KonspektFilters> extends State<TableOfContentWidget<T>>{

  Konspekt? get selectedKonspekt => widget.selectedKonspekt;
  T get filters => widget.filters;
  KonspektFiltersWidget Function(KonspektSearchProvider<T>) get filtersWidgetBuilder => widget.filtersWidgetBuilder;
  SearchFieldBottomFilterIndicatorsWidget get searchFieldBottomFilterIndicatorsWidget => widget.searchFieldBottomFilterIndicatorsWidget;
  EdgeInsets? get padding => widget.padding;
  void Function(Konspekt)? get onItemTap => widget.onItemTap;
  bool get withBackButton => widget.withBackButton;

  late TextEditingController controller;

  @override
  void initState() {
    controller = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [

      Padding(
        padding: EdgeInsets.only(top: Dimen.iconFootprint/2 + (filters.hideSearchFieldBottom?0:35.0)),
        child: Consumer<KonspektSearchProvider<T>>(
          builder: (context, prov, _) => ListView.separated(
            padding: (padding??EdgeInsets.zero).add(EdgeInsets.only(top: Dimen.iconFootprint/2)),
            itemBuilder: (context, index) {
              final isSelected = prov.konspekts[index] == selectedKonspekt;
              return Container(
                height: KonspektTileWidget.defHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppCard.defRadius),
                ),
                child: KonspektTileWidget(
                  prov.konspekts[index],
                  radius: AppCard.defRadius,
                  background: isSelected?cardEnab_(context):cardEnab_(context).withValues(alpha: 0.5),
                  elevation: isSelected?AppCard.bigElevation:0,
                  onTap: () => onItemTap?.call(prov.konspekts[index]),
                ),
              );
            },
            separatorBuilder: (context, index) => SizedBox(height: Dimen.defMarg),
            itemCount: prov.konspekts.length,
          ),
        )
      ),

      Positioned(
        top: 0,
        right: 0,
        left: 0,
        child: Material(
          elevation: AppCard.bigElevation,
          borderRadius: BorderRadius.circular(AppCard.bigRadius - 4),
          color: cardEnab_(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              Row(
                children: [

                  if(filters.isNotEmpty)
                    AppButton(
                      icon: Icon(MdiIcons.close),
                      onTap: (){
                        filters.clear();
                        controller.clear();
                        KonspektSearchProvider.runSearch_(context, filters);
                        setState(() {});
                      },
                    )
                  else if(withBackButton)
                    AppButton(
                      icon: Icon(MdiIcons.arrowLeft),
                      onTap: () => Navigator.pop(context),
                    )
                  else
                    Padding(
                      padding: EdgeInsets.all(Dimen.iconMarg),
                      child: Icon(MdiIcons.magnify, color: hintEnab_(context)),
                    ),

                  Expanded(
                    child: TextField(
                      style: AppTextStyle(),
                      controller: controller,
                      decoration: InputDecoration(
                          hintText: 'Szukaj',
                          hintStyle: AppTextStyle(color: hintEnab_(context)),
                          border: InputBorder.none
                      ),
                      onChanged: (text){
                        filters.phrase = text;
                        KonspektSearchProvider.runSearch_(context, filters);
                        setState(() {});
                      },
                    ),
                  ),

                  AppButton(
                    icon: Icon(MdiIcons.cogOutline),
                    onTap: () async {
                      KonspektSearchProvider<T> provider = KonspektSearchProvider.of<T>(context);
                      await showDialog(
                        context: context,
                        builder: (context) => FiltersDialog<T>(
                          filters: filters,
                          filtersWidget: filtersWidgetBuilder(provider),
                          maxWidth: songDialogWidth,
                        )
                      );
                    },
                  )

                ],
              ),

              if(!filters.hideSearchFieldBottom)
                searchFieldBottomFilterIndicatorsWidget,

            ],
          )
        ),
      ),

    ],
  );

}

class FiltersDialog<T extends KonspektFilters> extends StatelessWidget{

  final T filters;
  final KonspektFiltersWidget filtersWidget;
  final double? maxWidth;

  const FiltersDialog({
    required this.filters,
    required this.filtersWidget,
    this.maxWidth
  });

  @override
  Widget build(BuildContext context){

    Widget child = Padding(
      padding: EdgeInsets.all(Dimen.defMarg),
      child: Material(
          borderRadius: BorderRadius.circular(AppCard.bigRadius),
          clipBehavior: Clip.hardEdge,
          color: background_(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [

              AppBarX(title: 'Filtry'),

              Padding(
                padding: EdgeInsets.all(Dimen.sideMarg),
                child: filtersWidget,
              ),

            ],
          )
      ),
    );

    if(maxWidth != null)
      child = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: child,
      );

    return Center(child: child);

  }

}