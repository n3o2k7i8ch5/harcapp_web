import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
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
import 'package:harcapp_web/main.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../common/download_file.dart';

class KonspektsPage extends StatefulWidget{

  static const double defPaddingVal = 32.0;

  final String itemPathTemplate;
  final List<Konspekt> allKonspekts;
  final Konspekt? selectedKonspekt;

  const KonspektsPage(this.itemPathTemplate, this.allKonspekts, {this.selectedKonspekt, Key? key}): super(key: key);

  @override
  State<StatefulWidget> createState() => KonspektsPageState();

}

class KonspektsPageState extends State<KonspektsPage>{

  String get itemPathTemplate => widget.itemPathTemplate;
  List<Konspekt> get allKonspekts => widget.allKonspekts;
  Konspekt? get selectedKonspekt => widget.selectedKonspekt;

  void selectKonspekt(Konspekt konspekt) => context.go(itemPathTemplate.replaceAll(":name", konspekt.name));

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints){

        bool workspaceAlwaysVisible = constraints.maxWidth>920;

        return BaseScaffold(
          backgroundColor: background_(context),
          drawer: workspaceAlwaysVisible?
          null:
          Drawer(
            backgroundColor: background_(context),
            child: TableOfContentWidget(
              allKonspekts: allKonspekts,
              selectedKonspekt: selectedKonspekt,
              padding: const EdgeInsets.all(Dimen.defMarg),
              onItemTap: (konspekt){
                selectKonspekt(konspekt);
                Navigator.pop(context);
              },
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
                      onItemTap: (konspekt) => selectKonspekt(konspekt)
                    ),
                  ),
                ),

              Expanded(
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 1000),
                      child:
                      selectedKonspekt == null?
                      ClickHereWidget(workspaceAlwaysVisible):
                      BaseKonspektWidget(
                        selectedKonspekt!,
                        withAppBar: false,
                        onDuchLevelInfoTap: () => openKonspektSphereDuchLevelsInfoDialog(context, maxWidth: defPageWidth),
                        onDuchMechanismInfoTap: () => openKonspektSphereDuchMechanismsInfoDialog(context, maxWidth: defPageWidth),
                        maxRelatedDialogWidth: dialogWidth,
                        oneLineMultiDuration: true,
                        leading: Padding(
                            padding: EdgeInsets.only(top: KonspektsPage.defPaddingVal),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [

                                Material(
                                  borderRadius: BorderRadius.circular(AppCard.defRadius),
                                  clipBehavior: Clip.hardEdge,
                                  child: Image.asset(
                                    selectedKonspekt!.coverPath,
                                    fit: BoxFit.cover,
                                    height: 500,
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