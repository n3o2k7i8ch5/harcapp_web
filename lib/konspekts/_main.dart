import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/common.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core/harcthought/konspekts/base_konspekt_widget.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt_sphere_duch_levels_info_dialog.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt_sphere_duch_mechanisms_info_dialog.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt_to_pdf/konspekt_to_pdf.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:harcapp_web/consts.dart';
import 'package:harcapp_web/konspekts/table_of_content_widget.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../common/download_file.dart';

class KonspektsPage extends StatefulWidget{

  static const double defPaddingVal = 32.0;

  final String itemPathTemplate;
  final List<Konspekt> allKonspekts;
  final Konspekt? selectedKonspekt;
  final bool openDrawerIfCollapsed;

  const KonspektsPage(this.itemPathTemplate, this.allKonspekts, {this.selectedKonspekt, this.openDrawerIfCollapsed = true, Key? key}): super(key: key);

  @override
  State<StatefulWidget> createState() => KonspektsPageState();

}

class KonspektsPageState extends State<KonspektsPage>{

  static const double collapseWidth = 920;

  String get itemPathTemplate => widget.itemPathTemplate;
  List<Konspekt> get allKonspekts => widget.allKonspekts;
  Konspekt? get selectedKonspekt => widget.selectedKonspekt;
  bool get openDrawerIfCollapsed => widget.openDrawerIfCollapsed;

  late GlobalKey<ScaffoldState> scaffoldKey;
  late ScrollController scrollController;
  late ValueNotifier<double> notifier;

  void selectKonspekt(Konspekt konspekt) => context.go(itemPathTemplate.replaceAll(":name", konspekt.name));

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

        bool workspaceAlwaysVisible = constraints.maxWidth>collapseWidth;

        return BaseScaffold(
          scaffoldKey: scaffoldKey,
          backgroundColor: background_(context),
          drawer: workspaceAlwaysVisible?
          null:
          Drawer(
            backgroundColor: background_(context),
            child: TableOfContentWidget(
              allKonspekts: allKonspekts,
              selectedKonspekt: selectedKonspekt,
              padding: const EdgeInsets.all(Dimen.defMarg),
              onItemTap: (Konspekt konspekt){
                selectKonspekt(konspekt);
                Navigator.pop(context);
              },
              withBackButton: true,
            ),
            width: drawerWidth,
          ),
          body: Row(
            children: [

              if(workspaceAlwaysVisible)
                Padding(
                  padding: EdgeInsets.only(
                    top: KonspektsPage.defPaddingVal,
                    left: KonspektsPage.defPaddingVal
                  ),
                  child: SizedBox(
                    width: drawerWidth,
                    child: TableOfContentWidget(
                      allKonspekts: allKonspekts,
                      selectedKonspekt: selectedKonspekt,
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimen.defMarg,
                        vertical: KonspektsPage.defPaddingVal
                      ),
                      onItemTap: (Konspekt konspekt) => selectKonspekt(konspekt)
                    ),
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
                        onDuchMechanismInfoTap: () => openKonspektSphereDuchMechanismsInfoDialog(context, maxWidth: defPageWidth),
                        maxDialogWidth: defPageWidth,
                        oneLineMultiDuration: true,
                        controller: scrollController,
                        leading: Padding(
                            padding: EdgeInsets.only(top: KonspektsPage.defPaddingVal),
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
                                                          child: Image.asset(
                                                            selectedKonspekt!.coverPath,
                                                            fit: BoxFit.cover,
                                                            alignment: Alignment.topCenter,
                                                          )
                                                      )
                                                  )

                                                ],
                                              ),
                                              builder: (BuildContext context, Widget? child) => Transform.translate(
                                                offset: Offset(0, -min(notifier.value/1.3, constraints.maxWidth/1000*(667-450))),
                                                child: child,
                                              )
                                          )
                                      )
                                  ),
                                ),

                                SizedBox(height: KonspektsPage.defPaddingVal),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: SimpleButton.from(
                                      context: context,
                                      color: cardEnab_(context),
                                      radius: AppCard.defRadius,
                                      margin: EdgeInsets.zero,
                                      icon: MdiIcons.filePdfBox,
                                      text: 'Pobierz jako PDF',
                                      onTap: () async {
                                        AppScaffold.showMessage(context, 'Przygotowywanie pliku PDF...');
                                        Uint8List bytes = await konspektToPdf(selectedKonspekt!);
                                        downloadFileFromBytes(
                                            fileName: 'Konspekt - ${selectedKonspekt!.title}.pdf',
                                            bytes: bytes
                                        );
                                      }
                                  ),
                                )

                              ],
                            )
                        ),
                        oneLineSummary: false,
                      )
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
                  'Chcesz przeglądać inspiracje\nna pracę harcerską?',
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