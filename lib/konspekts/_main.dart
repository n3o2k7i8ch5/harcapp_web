import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/comm_classes/app_navigator.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/common.dart';
import 'package:harcapp_core/comm_widgets/app_bar.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/comm_widgets/dialog/dialog.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt_sphere_duch_levels_info_dialog.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt_to_pdf/konspekt_to_pdf.dart';
import 'package:harcapp_core/harcthought/konspekts/widgets/base_konspekt_widget.dart';
import 'package:harcapp_core/harcthought/konspekts/widgets/cover_widget.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:harcapp_web/consts.dart';
import 'package:harcapp_web/konspekts/konspekty_tabs_row.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../common/download_file.dart';

class KonspektsPage extends StatefulWidget{

  static const double defPaddingVal = 32.0;

  final String itemPathTemplate;
  final List<Konspekt> allKonspekts;
  final Konspekt? selectedKonspekt;
  final Widget Function(bool isDrawer, Konspekt? selectedKonspekt) tableOfContentBuilder;
  final bool openDrawerIfCollapsed;

  const KonspektsPage(this.itemPathTemplate, this.allKonspekts, {this.selectedKonspekt, required this.tableOfContentBuilder, this.openDrawerIfCollapsed = true, Key? key}): super(key: key);

  @override
  State<StatefulWidget> createState() => KonspektsPageState();

}

class KonspektsPageState extends State<KonspektsPage>{

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

        bool workspaceAlwaysVisible = constraints.maxWidth>collapseWidth;

        Widget downloadHrcpknspktButton = SimpleButton.from(
            context: context,
            color: cardEnab_(context),
            radius: AppCard.defRadius,
            margin: EdgeInsets.zero,
            icon: MdiIcons.trayArrowDown,
            text: 'Pobierz surowe dane',
            onTap: () async => downloadFileFromBytes(
                fileName: 'konspekt_${selectedKonspekt!.name}.hrcpknspkt',
                bytes: (await selectedKonspekt!.toHrcpknspktData()).toBytes()
            )
        );

        Widget downloadPdfButton = SimpleButton.from(
            context: context,
            color: cardEnab_(context),
            radius: AppCard.defRadius,
            margin: EdgeInsets.zero,
            icon: MdiIcons.filePdfBox,
            text: 'Pobierz jako PDF',
            onTap: () async {
              openDialog(
                  context: context,
                  builder: (context) => DownloadPDFOptionsDialog(
                    selectedKonspekt!,
                    startTime,
                  )
              );
            }
        );

        return BaseScaffold(
          scaffoldKey: scaffoldKey,
          backgroundColor: cardEnab_(context),
          drawer: workspaceAlwaysVisible?
          null:
          Drawer(
            backgroundColor: background_(context),
            child: tableOfContentBuilder(true, selectedKonspekt),
            width: drawerWidth,
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
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppCard.defRadius),
                        topRight: Radius.circular(AppCard.defRadius),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        children: [

                          if(workspaceAlwaysVisible)
                            Padding(
                              padding: EdgeInsets.only(
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
                                constraints: BoxConstraints(maxWidth: defPageWidth),
                                child:
                                selectedKonspekt == null?
                                ClickHereWidget(workspaceAlwaysVisible):
                                BaseKonspektWidget(
                                  selectedKonspekt!,
                                  withAppBar: false,
                                  onDuchLevelInfoTap: () => openKonspektSphereDuchLevelsInfoDialog(context, maxWidth: defPageWidth),
                                  maxDialogWidth: defPageWidth,
                                  oneLineMultiDuration: true,
                                  controller: scrollController,
                                  leading: Padding(
                                      padding: EdgeInsets.only(
                                        top: KonspektsPage.defPaddingVal,
                                        left: BaseKonspektWidget.horizontalPadding,
                                        right: BaseKonspektWidget.horizontalPadding,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [

                                          LayoutBuilder(
                                            builder: (BuildContext context, BoxConstraints constraints) => AspectRatio(
                                                aspectRatio: 1000/450,
                                                child: Material(
                                                    elevation: AppCard.defElevation,
                                                    borderRadius: BorderRadius.circular(AppCard.defRadius),
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
                                                                    aspectRatio: 1000/667,
                                                                    child: KonspektCoverWidget(selectedKonspekt!)
                                                                )
                                                            )

                                                          ],
                                                        ),
                                                        builder: (BuildContext context, Widget? child) => Transform.translate(
                                                          offset: Offset(0, -max(0.0, min(notifier.value/1.3, constraints.maxWidth/1000*(667-450)))),
                                                          child: child,
                                                        )
                                                    )
                                                )
                                            ),
                                          ),

                                          SizedBox(height: KonspektsPage.defPaddingVal),

                                          Row(
                                            children: [
                                              Expanded(child: Container()),
                                              downloadHrcpknspktButton,
                                              SizedBox(width: Dimen.defMarg),
                                              downloadPdfButton,
                                            ],
                                          ),

                                        ],
                                      )
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

class DownloadPDFOptionsDialog extends StatefulWidget{

  final Konspekt konspekt;
  final TimeOfDay? startTime;

  const DownloadPDFOptionsDialog(this.konspekt, this.startTime);

  @override
  State<StatefulWidget> createState() => DownloadPDFOptionsDialogState();
  
}

class DownloadPDFOptionsDialogState extends State<DownloadPDFOptionsDialog>{

  late bool withCover;
  late bool withMetadata;
  late bool withAims;
  late bool withMaterials;
  TimeOfDay? startTime;
  List<TimeOfDay>? stepsTimeTable;
  late bool buildingPdf;

  @override
  void initState() {
    withCover = true;
    withMetadata = true;
    withAims = true;
    withMaterials = true;
    buildingPdf = false;
    startTime = widget.startTime;
    if(startTime != null)
      stepsTimeTable = widget.konspekt.stepsTimeTable(startTime!, expandStepGroups: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 500,
      child: Material(
        color: background_(context),
        clipBehavior: Clip.hardEdge,
        borderRadius: BorderRadius.circular(AppCard.bigRadius),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppBarX(title: 'Właściwości pliku PDF'),
            Padding(
              padding: EdgeInsets.all(Dimen.sideMarg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppCard.defRadius),
                      color: cardEnab_(context)
                    ),
                    child: SwitchListTile(
                      title: Text('Zdjęcie okładki', style: AppTextStyle(color: iconEnab_(context))),
                      value: withCover,
                      onChanged: (value) => setState(() => withCover = value),
                      activeThumbColor: accent_(context),
                    ),
                  ),

                  SizedBox(height: Dimen.sideMarg),

                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppCard.defRadius),
                        color: cardEnab_(context)
                    ),
                    child: SwitchListTile(
                      title: Text('Metodyki, autor, czas, skrót', style: AppTextStyle(color: iconEnab_(context))),
                      value: withMetadata,
                      onChanged: (value) => setState(() => withMetadata = value),
                      activeThumbColor: accent_(context),
                    ),
                  ),

                  SizedBox(height: Dimen.sideMarg),

                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppCard.defRadius),
                        color: cardEnab_(context)
                    ),
                    child: SwitchListTile(
                      title: Text('Cele', style: AppTextStyle(color: iconEnab_(context))),
                      value: withAims,
                      onChanged: (value) => setState(() => withAims = value),
                      activeThumbColor: accent_(context),
                    ),
                  ),

                  SizedBox(height: Dimen.sideMarg),

                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppCard.defRadius),
                        color: cardEnab_(context)
                    ),
                    child: SwitchListTile(
                      title: Text('Lista materiałów', style: AppTextStyle(color: iconEnab_(context))),
                      value: withMaterials,
                      onChanged: (value) => setState(() => withMaterials = value),
                      activeThumbColor: accent_(context),
                    ),
                  ),

                  if(widget.konspekt.anySteps)
                    SizedBox(height: Dimen.sideMarg),

                  if(widget.konspekt.anySteps)
                    StartTimeButton(
                      widget.konspekt,
                      startTime: startTime,
                      expandStepGroups: true,
                      onStartTimeChanged: (startTime, stepsTimeTable) =>
                        setState(() {
                          this.startTime = startTime;
                          this.stepsTimeTable = stepsTimeTable;
                        })
                    ),

                ],
              ),
            ),

            SimpleButton.from(
                iconWidget:
                buildingPdf?
                SpinKitChasingDots(color: textDisab_(context), size: Dimen.iconSize):
                null,

                icon: buildingPdf?null:MdiIcons.printer,
                color: cardEnab_(context),
                textColor: buildingPdf?iconDisab_(context):iconEnab_(context),
                margin: EdgeInsets.zero,
                radius: 0,
                text: buildingPdf?'Przygotowywanie pliku PDF...':'Pobierz PDF',
                onTap: buildingPdf?null:() async {
                  setState(() => buildingPdf = true);
                  try {
                    Uint8List bytes = await konspektToPdf(
                      widget.konspekt,
                      withCover: withCover,
                      withMetadata: withMetadata,
                      withAims: withAims,
                      withMaterials: withMaterials,
                      stepsTimeTable: stepsTimeTable,
                    );
                    downloadFileFromBytes(
                        fileName: 'Konspekt - ${widget.konspekt.title}.pdf',
                        bytes: bytes
                    );
                    popPage(context);

                  }catch (e){
                    AppScaffold.showMessage(context, text: 'Coś poszło nie tak: ${e.toString()}');
                  } finally{
                    setState(() => buildingPdf = false);
                  }

                }
            )

          ],
        ),
      ),
    ),
  );

}