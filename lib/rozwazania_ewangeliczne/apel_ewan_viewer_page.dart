import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/bottom_sheet.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/harcthought/apel_ewan/apel_ewan.dart';
import 'package:harcapp_core/harcthought/apel_ewan/apel_ewan_persistent_folder.dart';
import 'package:harcapp_core/harcthought/apel_ewan/apel_ewan_print_bottom_sheet.dart';
import 'package:harcapp_core/harcthought/apel_ewan/apel_ewan_widget.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:harcapp_web/consts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ApelEwanViewerPage extends StatelessWidget {

  final ApelEwanPersistentFolder folder;
  final ApelEwan initialApel;

  const ApelEwanViewerPage({
    required this.folder,
    required this.initialApel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final apels = folder.apelEwans;
    int initialIndex = apels.indexWhere((a) => a.dirName == initialApel.dirName);
    if (initialIndex < 0) initialIndex = 0;

    return DefaultTabController(
      length: apels.length,
      initialIndex: initialIndex,
      child: BaseScaffold(
        backgroundColor: background_(context),
        floatingActionButton: FloatingActionButton(
          backgroundColor: folder.colorsData.avgColor,
          tooltip: 'Eksportuj do PDF',
          onPressed: () => showScrollBottomSheet(
            context: context,
            builder: (context) => ApelEwanPrintBottomSheet(
              folder: folder,
              textColor: folder.colorsData.avgColor,
              iconColor: folder.colorsData.colorStart,
              iconEndColor: folder.colorsData.colorEnd,
            ),
          ),
          child: Icon(MdiIcons.filePdfBox),
        ),
        body: Column(
          children: [

            Material(
              color: cardEnab_(context),
              child: TabBar(
                isScrollable: true,
                labelColor: iconEnab_(context),
                unselectedLabelColor: hintEnab_(context),
                indicatorColor: accent_(context),
                tabs: [
                  for (final apel in apels)
                    Tab(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimen.defMarg),
                        child: Text(
                          apel.siglum,
                          style: const AppTextStyle(
                            fontSize: Dimen.textSizeNormal,
                            fontWeight: weightHalfBold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                physics: const BouncingScrollPhysics(),
                children: [
                  for (final apel in apels)
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(Dimen.sideMarg),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: defPageWidth),
                          child: ApelEwanWidget(
                            apel,
                            initVariantId: folder.variantId,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}
