import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/common.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/harcthought/poradnik/poradnik.dart';
import 'package:harcapp_core/harcthought/poradnik/poradnik_thumbnail_widget.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class PoradniksPage extends StatefulWidget{

  static const double defPaddingVal = 32.0;

  final String itemPathTemplate;
  final List<Poradnik> allPoradniks;
  final Poradnik? selectedPoradnik;
  final Widget Function(bool isDrawer, Poradnik? selectedPoradnik) tableOfContentBuilder;
  final bool openDrawerIfCollapsed;

  const PoradniksPage(this.itemPathTemplate, this.allPoradniks, {this.selectedPoradnik, required this.tableOfContentBuilder, this.openDrawerIfCollapsed = true, Key? key}): super(key: key);

  @override
  State<StatefulWidget> createState() => PoradniksPageState();

}

class PoradniksPageState extends State<PoradniksPage>{

  static const double collapseWidth = 920;

  String get itemPathTemplate => widget.itemPathTemplate;
  List<Poradnik> get allPoradniks => widget.allPoradniks;
  Poradnik? get selectedPoradnik => widget.selectedPoradnik;
  Widget Function(bool isDrawer, Poradnik? selectedPoradnik) get tableOfContentBuilder => widget.tableOfContentBuilder;
  bool get openDrawerIfCollapsed => widget.openDrawerIfCollapsed;

  late GlobalKey<ScaffoldState> scaffoldKey;
  late ScrollController scrollController;
  late ValueNotifier<double> notifier;

  void selectPoradnik(Poradnik poradnik) => context.go(itemPathTemplate.replaceAll(":name", poradnik.name));

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

        List<PoradnikThumbnailWidget> poradnikWidgets = allPoradniks.map((poradnik) => PoradnikThumbnailWidget(
          poradnik,
          width: 100*3,
          height: 141*3,
          elevation: AppCard.bigElevation,
        )).toList();

        return BaseScaffold(
          scaffoldKey: scaffoldKey,
          backgroundColor: background_(context),
          body: Row(
            children: [

              Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.all(PoradniksPage.defPaddingVal),
                  child: Wrap(
                    spacing: PoradniksPage.defPaddingVal,
                    runSpacing: PoradniksPage.defPaddingVal,
                    alignment: WrapAlignment.start,
                    children: poradnikWidgets,
                  ),
                )
              )

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
                    fontWeight: weight.halfBold
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
                          fontWeight: weight.halfBold
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