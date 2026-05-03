import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/common.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/harcthought/harcapp_links.dart';
import 'package:harcapp_core/harcthought/harcapp_share_button.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt_save_pdf_content.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt_sphere_duch_levels_info_dialog.dart';
import 'package:harcapp_core/harcthought/konspekts/widgets/base_konspekt_widget.dart';
import 'package:harcapp_core/harcthought/konspekts/widgets/cover_widget.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:harcapp_web/consts.dart';
import 'package:harcapp_web/konspekts/konspekty_tabs_row.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../common/download_file.dart';

class KonspektsPage extends StatefulWidget {

  static const double defPaddingVal = 32.0;

  final String itemPathTemplate;
  final List<Konspekt> allKonspekts;
  final Konspekt? selectedKonspekt;
  final Widget Function(bool isDrawer, Konspekt? selectedKonspekt) tableOfContentBuilder;
  final bool openDrawerIfCollapsed;

  const KonspektsPage(this.itemPathTemplate, this.allKonspekts, {this.selectedKonspekt, required this.tableOfContentBuilder, this.openDrawerIfCollapsed = true, Key? key}): super(key: key);

  @override
  State<StatefulWidget> createState() => _KonspektsPageState();

}

class _KonspektsPageState extends State<KonspektsPage> {

  static const double collapseWidth = 920;

  String get itemPathTemplate => widget.itemPathTemplate;
  List<Konspekt> get allKonspekts => widget.allKonspekts;
  Konspekt? get selectedKonspekt => widget.selectedKonspekt;
  Widget Function(bool isDrawer, Konspekt? selectedKonspekt) get tableOfContentBuilder => widget.tableOfContentBuilder;
  bool get openDrawerIfCollapsed => widget.openDrawerIfCollapsed;

  late GlobalKey<ScaffoldState> scaffoldKey;
  late ScrollController scrollController;
  late ValueNotifier<double> notifier;

  bool _hasScrolled = false;

  TimeOfDay? startTime;

  void selectKonspekt(Konspekt konspekt) => context.go(itemPathTemplate.replaceAll(":name", konspekt.name));

  void _handleScrollChanged() {
    final offset = scrollController.offset;
    notifier.value = offset;

    final hasScrolled = offset > 0;
    if (hasScrolled != _hasScrolled) {
      setState(() {
        _hasScrolled = hasScrolled;
      });
    }
  }

  Future<void> tryOpenDrawerIfCollapsed() async {
    if(!openDrawerIfCollapsed || MediaQuery.of(context).size.width>collapseWidth)
      return;

    if(selectedKonspekt != null)
      return;

    await Future.delayed(Duration.zero);

    scaffoldKey.currentState?.openDrawer();
  }

  @override
  void initState() {
    scaffoldKey = GlobalKey();
    scrollController = ScrollController();
    notifier = ValueNotifier(0);

    scrollController.addListener(_handleScrollChanged);

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

        final bool workspaceAlwaysVisible = constraints.maxWidth > collapseWidth;
        final bool narrow = constraints.maxWidth < _KonspektLeadingWidget.narrowCoverThreshold;

        return BaseScaffold(
          scaffoldKey: scaffoldKey,
          backgroundColor: cardEnab_(context),
          drawer: workspaceAlwaysVisible
              ? null
              : Drawer(
                  backgroundColor: background_(context),
                  width: drawerWidth,
                  child: tableOfContentBuilder(true, selectedKonspekt),
                ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const KonspektyTabsRow(),
              Expanded(
                child: Stack(
                  children: [
                    Material(
                      color: background_(context),
                      borderRadius: narrow
                          ? BorderRadius.zero
                          : const BorderRadius.only(
                              topLeft: Radius.circular(AppCard.defRadius),
                              topRight: Radius.circular(AppCard.defRadius),
                            ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                          if (workspaceAlwaysVisible)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: KonspektsPage.defPaddingVal,
                                left: KonspektsPage.defPaddingVal,
                              ),
                              child: SizedBox(
                                width: drawerWidth,
                                child: tableOfContentBuilder(false, selectedKonspekt),
                              ),
                            ),

                          Expanded(
                            child: Center(
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: defPageWidth),
                                child: selectedKonspekt == null
                                    ? _ClickHereWidget(workspaceAlwaysVisible)
                                    :
                                BaseKonspektWidget(
                                  selectedKonspekt!,
                                  withAppBar: false,
                                  onDuchLevelInfoTap: () => openKonspektSphereDuchLevelsInfoDialog(context, maxWidth: defPageWidth),
                                  maxDialogWidth: defPageWidth,
                                  oneLineMultiDuration: true,
                                  controller: scrollController,
                                  leading: _KonspektLeadingWidget(
                                    konspekt: selectedKonspekt!,
                                    notifier: notifier,
                                    startTime: startTime,
                                  ),
                                  oneLineSummary: false,
                                  thumbnailWidth: drawerWidth,
                                  thumbnailBackground: cardEnab_(context),
                                  thumbnailRadius: AppCard.defRadius,
                                  onThumbnailTap: (konspekt) => selectKonspekt(konspekt),
                                  showStepGroupBorder: true,
                                  showStepGroupBackground: true,
                                  onStartTimeChanged: (startTime, stepsTimeTable) => setState((){
                                    this.startTime = startTime;
                                  }),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_hasScrolled)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.15),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
  );

}

class _KonspektLeadingWidget extends StatelessWidget {
  static const double narrowCoverThreshold = 600;

  final Konspekt konspekt;
  final ValueNotifier<double> notifier;
  final TimeOfDay? startTime;

  const _KonspektLeadingWidget({
    required this.konspekt,
    required this.notifier,
    required this.startTime,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, parentConstraints) {
      final bool narrow = parentConstraints.maxWidth < narrowCoverThreshold;
      final double sidePadding = narrow ? 0 : BaseKonspektWidget.horizontalPadding;

      return Padding(
        padding: EdgeInsets.only(top: narrow ? 0 : KonspektsPage.defPaddingVal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            Padding(
              padding: EdgeInsets.symmetric(horizontal: sidePadding),
              child: LayoutBuilder(
                builder: (context, constraints) => AspectRatio(
                  aspectRatio: 1000 / 450,
                  child: Material(
                    elevation: AppCard.defElevation,
                    borderRadius: BorderRadius.circular(narrow ? 0 : AppCard.defRadius),
                    clipBehavior: Clip.hardEdge,
                    child: AnimatedBuilder(
                      animation: notifier,
                      child: Stack(
                        fit: StackFit.expand,
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: AspectRatio(
                              aspectRatio: 1000 / 667,
                              child: KonspektCoverWidget(konspekt),
                            ),
                          ),
                        ],
                      ),
                      builder: (context, child) => narrow
                          ? child!
                          : Transform.translate(
                              offset: Offset(0, -max(0.0, min(notifier.value / 1.3, constraints.maxWidth / 1000 * (667 - 450)))),
                              child: child,
                            ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: KonspektsPage.defPaddingVal),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: BaseKonspektWidget.horizontalPadding),
              child: Row(
                mainAxisAlignment: narrow ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  HarcappShareButton.simpleButton(
                    url: HarcappLinks.konspektOf(konspekt),
                    subject: konspekt.title,
                    color: cardEnab_(context),
                    radius: AppCard.defRadius,
                    margin: EdgeInsets.zero,
                    collapsed: narrow,
                  ),
                  if (narrow)
                    SizedBox(width: Dimen.defMarg)
                  else
                    Spacer(),
                  SimpleButton.from(
                    context: context,
                    color: cardEnab_(context),
                    radius: AppCard.defRadius,
                    margin: EdgeInsets.zero,
                    icon: MdiIcons.trayArrowDown,
                    text: narrow ? null : 'Pobierz .hrcpknspkt',
                    onTap: () async => downloadFileFromBytes(
                      fileName: 'konspekt_${konspekt.name}.hrcpknspkt',
                      bytes: (await konspekt.toHrcpknspktData()).toTarBytes(),
                    ),
                  ),
                  SizedBox(width: Dimen.defMarg),
                  SimpleButton.from(
                    context: context,
                    color: cardEnab_(context),
                    radius: AppCard.defRadius,
                    margin: EdgeInsets.zero,
                    icon: MdiIcons.filePdfBox,
                    text: narrow ? null : 'Pobierz PDF',
                    onTap: () => showKonspektSavePdfDialog(
                      context,
                      konspekt,
                      startTime: startTime,
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
      );
    },
  );
}

class _ClickHereWidget extends StatelessWidget {

  final bool workspaceAlwaysVisible;

  const _ClickHereWidget(this.workspaceAlwaysVisible);

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
                  'Chcesz przeglądać inspiracje\nna pracę harcerską?',
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

