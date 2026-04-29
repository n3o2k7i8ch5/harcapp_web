import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/folder_tab.dart';
import 'package:harcapp_core/comm_widgets/folder_tab_indicator.dart';
import 'package:harcapp_core/comm_widgets/tab_bar.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/harcthought/apel_ewan/apel_ewan.dart';
import 'package:harcapp_core/harcthought/apel_ewan/apel_ewan_persistent_folder.dart';
import 'package:harcapp_core/harcthought/apel_ewan/apel_ewan_thumbnail_widget.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:harcapp_web/consts.dart';
import 'package:harcapp_web/rozwazania_ewangeliczne/apel_ewan_viewer_page.dart';

class RozwazaniaEwangelicznePage extends StatelessWidget {

  const RozwazaniaEwangelicznePage({super.key});

  @override
  Widget build(BuildContext context) {
    final folders = ApelEwanPersistentFolder.all;

    return DefaultTabController(
      length: folders.length,
      child: BaseScaffold(
        backgroundColor: background_(context),
        body: Column(
          children: [

            Material(
              color: background_(context),
              child: TabBarX(
                isScrollable: true,
                indicator: FolderTabIndicator(context: context),
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  for (final folder in folders)
                    FolderTab(
                      iconKey: folder.iconKey,
                      colorsKey: folder.colorsKey,
                      folderName: folder.name,
                      countText: 'Liczba rozważań: ${folder.apelEwans.length}',
                    ),
                ],
              ),
            ),

            Expanded(
              child: Material(
                color: cardEnab_(context),
                child: TabBarView(
                  children: [
                    for (final folder in folders)
                      _ApelEwanGrid(folder: folder),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApelEwanGrid extends StatelessWidget {

  static const double thumbnailSize = 180;
  static const double spacing = Dimen.sideMarg;

  final ApelEwanPersistentFolder folder;

  const _ApelEwanGrid({required this.folder});

  void _openApel(BuildContext context, ApelEwan apel) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ApelEwanViewerPage(
        folder: folder,
        initialApel: apel,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: defPageWidth),
      child: GridView.builder(
        padding: const EdgeInsets.all(spacing),
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: thumbnailSize,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 1,
        ),
        itemCount: folder.apelEwans.length,
        itemBuilder: (context, index) {
          final apel = folder.apelEwans[index];
          return ApelEwanThumbnailWidget(
            apel,
            variantId: folder.variantId,
            onTap: (_, _) => _openApel(context, apel),
          );
        },
      ),
    ),
  );
}
