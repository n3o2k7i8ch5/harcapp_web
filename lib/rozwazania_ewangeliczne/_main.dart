import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/text_utils.dart';
import 'package:harcapp_core/comm_widgets/bottom_sheet.dart';
import 'package:harcapp_core/comm_widgets/search_field.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/comm_widgets/tab_bar.dart';
import 'package:harcapp_core/folder/folder_tab.dart';
import 'package:harcapp_core/folder/folder_tab_indicator.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/harcthought/apel_ewan/apel_ewan.dart';
import 'package:harcapp_core/harcthought/apel_ewan/apel_ewan_persistent_folder.dart';
import 'package:harcapp_core/harcthought/apel_ewan/apel_ewan_print_bottom_sheet.dart';
import 'package:harcapp_core/harcthought/apel_ewan/apel_ewan_thumbnail_widget.dart';
import 'package:harcapp_core/harcthought/harcapp_links.dart';
import 'package:harcapp_core/harcthought/harcapp_share_button.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:harcapp_web/consts.dart';
import 'package:harcapp_web/router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

int _initialIndexFor(List<ApelEwanPersistentFolder> folders, String? slug) {
  if (slug == null) return 0;
  final idx = folders.indexWhere((f) => f.slug == slug);
  return idx < 0 ? 0 : idx;
}

class RozwazaniaEwangelicznePage extends StatefulWidget {

  final String? folderSlug;

  const RozwazaniaEwangelicznePage({super.key, this.folderSlug});

  @override
  State<RozwazaniaEwangelicznePage> createState() => _RozwazaniaEwangelicznePageState();
}

class _RozwazaniaEwangelicznePageState extends State<RozwazaniaEwangelicznePage>
    with SingleTickerProviderStateMixin {

  late final List<ApelEwanPersistentFolder> _folders;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _folders = ApelEwanPersistentFolder.all;
    _tabController = TabController(
      length: _folders.length,
      initialIndex: _initialIndexFor(_folders, widget.folderSlug),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    final slug = _folders[index].slug;
    final targetUrl = pathRozwazaniaEwangelicznegoFolder.replaceAll(':folder', slug);
    final currentUrl = GoRouterState.of(context).uri.toString();
    if (currentUrl == targetUrl) return;
    context.go(targetUrl);
  }

  @override
  Widget build(BuildContext context) {
    final Color barColor = cardEnab_(context);
    const Color bodyColor = Colors.black;

    return BaseScaffold(
      backgroundColor: bodyColor,
      body: Column(
        children: [

          Material(
            color: barColor,
            child: LayoutBuilder(
              builder: (context, constraints) => Center(
                child: SizedBox(
                  width: constraints.maxWidth > defPageWidth
                      ? defPageWidth
                      : constraints.maxWidth,
                  child: TabBarX(
                    controller: _tabController,
                    isScrollable: true,
                    indicator: FolderTabIndicator(color: bodyColor),
                    indicatorSize: TabBarIndicatorSize.tab,
                    splashBorderRadius: FolderTabIndicator.defBorderRadius,
                    overlayColor: WidgetStateProperty.all(
                        Colors.white.withValues(alpha: 0.08)),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white,
                    onTap: _onTabTap,
                    tabs: [
                      for (final folder in _folders)
                        FolderTab(
                          iconKey: folder.iconKey,
                          colorsKey: folder.colorsKey,
                          folderName: folder.name,
                          countText: 'Liczba rozważań: ${folder.apelEwans.length}',
                          countTextStyle: const AppTextStyle(fontWeight: weightNormal),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: Material(
              color: bodyColor,
              child: TabBarView(
                controller: _tabController,
                children: [
                  for (final folder in _folders)
                    _ApelEwanGrid(folder: folder),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApelEwanGrid extends StatefulWidget {

  static const double thumbnailSize = 140;
  static const double spacing = Dimen.sideMarg;
  static const double gridSpacing = Dimen.iconMarg;

  final ApelEwanPersistentFolder folder;

  const _ApelEwanGrid({required this.folder});

  @override
  State<_ApelEwanGrid> createState() => _ApelEwanGridState();
}

class _ApelEwanGridState extends State<_ApelEwanGrid> {

  late List<ApelEwan> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.folder.apelEwans;
  }

  void _onSearchChanged(String text) {
    final query = searchableString(text);
    if (query.isEmpty) {
      setState(() => _filtered = widget.folder.apelEwans);
      return;
    }

    final results = <ApelEwan>[];
    for (final apel in widget.folder.apelEwans) {
      if (searchableString(apel.siglum).contains(query)) {
        results.add(apel);
        continue;
      }
      for (final v in apel.variants.values) {
        final shortTitle = v.shortTitle;
        if (searchableString(v.title).contains(query) ||
            (shortTitle != null && searchableString(shortTitle).contains(query))) {
          results.add(apel);
          break;
        }
      }
    }
    setState(() => _filtered = results);
  }

  void _openApel(BuildContext context, ApelEwan apel) {
    final url = pathRozwazaniaEwangelicznegoApel
        .replaceAll(':folder', widget.folder.slug)
        .replaceAll(':apel', apel.dirName);
    context.push(url);
  }

  void _openPdfBottomSheet(BuildContext context) {
    final folder = widget.folder;
    showScrollBottomSheet(
      context: context,
      builder: (ctx) => ApelEwanPrintBottomSheet(
        folder: folder,
        textColor: folder.colorsData.avgColor,
        iconColor: folder.colorsData.colorStart,
        iconEndColor: folder.colorsData.colorEnd,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final folder = widget.folder;
    final folderUrl = HarcappLinks.apelEwanFolderOf(folder, short: true);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: defPageWidth),
        child: Column(
          children: [

            Padding(
              padding: const EdgeInsets.only(top: _ApelEwanGrid.spacing),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final collapsed = constraints.maxWidth < 500;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      HarcappShareButton(
                        url: folderUrl,
                        subject: folder.name,
                        color: cardEnab_(context),
                        collapsed: collapsed,
                      ),
                      const SizedBox(width: Dimen.defMarg),
                      SimpleButton.from(
                        context: context,
                        color: cardEnab_(context),
                        icon: MdiIcons.filePdfBox,
                        text: collapsed ? null : 'Pobierz PDF',
                        onTap: () => _openPdfBottomSheet(context),
                      ),
                    ],
                  );
                },
              ),
            ),

            Expanded(
              child: Stack(
                children: [

                  Positioned.fill(
                    top: _ApelEwanGrid.spacing + Dimen.iconFootprint / 2,
                    child: GridView.builder(
                      padding: const EdgeInsets.only(
                        top: _ApelEwanGrid.spacing + Dimen.iconFootprint / 2,
                        bottom: _ApelEwanGrid.spacing,
                      ),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: _ApelEwanGrid.thumbnailSize,
                        crossAxisSpacing: _ApelEwanGrid.gridSpacing,
                        mainAxisSpacing: _ApelEwanGrid.gridSpacing,
                        childAspectRatio: 1,
                      ),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final apel = _filtered[index];
                        return ApelEwanThumbnailWidget(
                          apel,
                          variantId: widget.folder.variantId,
                          onTap: (_, _) => _openApel(context, apel),
                        );
                      },
                    ),
                  ),

                  Positioned(
                    top: _ApelEwanGrid.spacing,
                    left: 0,
                    right: 0,
                    child: SearchField(
                      hint: 'Szukaj...',
                      margin: EdgeInsets.zero,
                      onChanged: _onSearchChanged,
                      onTextCleared: () => _onSearchChanged(''),
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
