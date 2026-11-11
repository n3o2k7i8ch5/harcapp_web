import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/common.dart';
import 'package:harcapp_core/comm_classes/text_utils.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/search_field.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/harcthought/poradnik/poradnik.dart';
import 'package:harcapp_core/harcthought/poradnik/poradnik_thumbnail_widget.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:harcapp_web/consts.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

class PoradniksPage extends StatefulWidget{

  final String itemPathTemplate;
  final List<Poradnik> allPoradniks;
  final Widget Function(bool isDrawer, Poradnik? selectedPoradnik) tableOfContentBuilder;
  final bool openDrawerIfCollapsed;

  const PoradniksPage(this.itemPathTemplate, this.allPoradniks, {required this.tableOfContentBuilder, this.openDrawerIfCollapsed = true, Key? key}): super(key: key);

  @override
  State<StatefulWidget> createState() => PoradniksPageState();

}

class PoradniksPageState extends State<PoradniksPage>{

  static const double collapseWidth = AppLayout.collapseWidth;

  String get itemPathTemplate => widget.itemPathTemplate;
  List<Poradnik> get allPoradniks => widget.allPoradniks;
  Widget Function(bool isDrawer, Poradnik? selectedPoradnik) get tableOfContentBuilder => widget.tableOfContentBuilder;
  bool get openDrawerIfCollapsed => widget.openDrawerIfCollapsed;

  late GlobalKey<ScaffoldState> scaffoldKey;
  late ScrollController scrollController;
  late ValueNotifier<double> notifier;
  late List<Poradnik> filtered;

  void onSearchChanged(String text) {
    final query = searchableString(text);
    setState(() => filtered = query.isEmpty
        ? allPoradniks
        : allPoradniks.where((p) => [p.title, p.description, p.coverTitle]
            .any((t) => t != null && searchableString(t).contains(query))).toList());
  }

  void selectPoradnik(Poradnik poradnik) => context.push(itemPathTemplate.replaceAll(":name", poradnik.name));

  Future<void> tryOpenDrawerIfCollapsed() async {
    if(!openDrawerIfCollapsed || MediaQuery.of(context).size.width>collapseWidth)
      return;

    await Future.delayed(Duration.zero);

    scaffoldKey.currentState?.openDrawer();
  }

  @override
  void initState() {
    scaffoldKey = GlobalKey();
    scrollController = ScrollController();
    notifier = ValueNotifier(0);

    scrollController.addListener(() => notifier.value = scrollController.offset);
    filtered = allPoradniks;

    post(tryOpenDrawerIfCollapsed);

    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints){

        const double thumbWidth = 100*3;
        final double pad = pageMargin(context);

        // Width of the covers' grid, so the search field lines up with it.
        final double available = (constraints.maxWidth - 2*pad).clamp(thumbWidth, defPageWidth);
        final int columns = ((available + pad)/(thumbWidth + pad)).floor().clamp(1, 100);
        final double gridWidth = columns*thumbWidth + (columns - 1)*pad;

        List<PoradnikThumbnailWidget> poradnikWidgets = filtered.map((poradnik) => PoradnikThumbnailWidget(
          poradnik,
          width: thumbWidth,
          height: 141*3,
          elevation: AppCard.bigElevation,
          onTap: () => selectPoradnik(poradnik),
        )).toList();

        return BaseScaffold(
          scaffoldKey: scaffoldKey,
          backgroundColor: background_(context),
          body: Stack(
            children: [

              Positioned.fill(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: pad,
                    right: pad,
                    bottom: pad,
                    top: pad + Dimen.iconFootprint + pad,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: gridWidth,
                      child: filtered.isEmpty
                          ? Text(
                              'Brak poradników pasujących do wyszukiwania',
                              textAlign: TextAlign.center,
                              style: AppTextStyle(color: hintEnab_(context)),
                            )
                          : Wrap(
                              spacing: pad,
                              runSpacing: pad,
                              alignment: WrapAlignment.start,
                              children: poradnikWidgets,
                            ),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: pad,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: gridWidth,
                    child: SearchField(
                      hint: 'Szukaj',
                      margin: EdgeInsets.zero,
                      onChanged: onSearchChanged,
                      onTextCleared: () => onSearchChanged(''),
                    ),
                  ),
                ),
              ),

            ],
          ),
        );
      }
  );

}

class ClickHereWidget extends StatelessWidget{

  final bool workspaceAlwaysVisible;

  const ClickHereWidget(this.workspaceAlwaysVisible);

  @override
  Widget build(BuildContext context) => Center(
    child: Material(
      color: cardEnab_(context),
      borderRadius: BorderRadius.circular(AppCard.bigRadius),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.all(Dimen.defMarg),
        child: SimpleButton(
          color: background_(context),
          borderRadius: BorderRadius.circular(AppCard.bigRadius - 4),
          clipBehavior: Clip.hardEdge,
          onTap: workspaceAlwaysVisible?
          null:
          () => Scaffold.of(context).openDrawer(),

          child: Padding(
            padding: EdgeInsets.all(40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  'Szukasz merytorycznego wsparcia\nw pracy harcerskiej?',
                  style: AppTextStyle(
                    fontSize: 20.0,
                    color: textDisab_(context),
                    fontWeight: weightHalfBold,
                  ),
                ),

                SizedBox(height: 20.0),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        workspaceAlwaysVisible?MdiIcons.arrowLeft:MdiIcons.gestureTap,
                        color: textDisab_(context),
                        size: 24.0
                    ),
                    SizedBox(width: Dimen.iconMarg),
                    Text(
                      workspaceAlwaysVisible?'Zerknij tam!':'Kliknij',
                      style: AppTextStyle(
                          fontSize: 20.0,
                          color: textDisab_(context),
                          fontWeight: weightHalfBold,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    ),
  );

}
