import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/text_utils.dart';
import 'package:harcapp_core/comm_widgets/dialog/app_dialog.dart';
import 'package:harcapp_core/comm_widgets/save_pdf_dialog.dart';
import 'package:harcapp_core/comm_widgets/search_field.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/comm_widgets/tab_bar.dart';
import 'package:harcapp_core/folder/folder_tab.dart';
import 'package:harcapp_core/folder/folder_tab_indicator.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/harcthought/apel_ewan/apel_ewan.dart';
import 'package:harcapp_core/harcthought/apel_ewan/apel_ewan_persistent_folder.dart';
import 'package:harcapp_core/harcthought/apel_ewan/apel_ewan_save_pdf_content.dart';
import 'package:harcapp_core/harcthought/apel_ewan/apel_ewan_thumbnail_widget.dart';
import 'package:harcapp_core/harcthought/harcapp_links.dart';
import 'package:harcapp_core/harcthought/harcapp_share_button.dart';
import 'package:harcapp_core/harcthought/konspekts/data/harcerskie/rozwazanie_ewangeliczne.dart';
import 'package:harcapp_core/harcthought/konspekts/widgets/html_widget.dart';
import 'package:harcapp_web/_common_classes/firebase.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:harcapp_web/common/page_width_bar.dart';
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
    final Color bodyColor = background_(context);
    final Color labelColor = textEnab_(context);

    return BaseScaffold(
      backgroundColor: bodyColor,
      body: Column(
        children: [

          Container(height: 8, color: barColor),

          PageWidthBar(
            backgroundColor: barColor,
            child: TabBarX(
              controller: _tabController,
              isScrollable: true,
              indicator: FolderTabIndicator(color: bodyColor),
              indicatorSize: TabBarIndicatorSize.tab,
              splashBorderRadius: FolderTabIndicator.defBorderRadius,
              overlayColor: WidgetStateProperty.all(
                  labelColor.withValues(alpha: 0.08)),
              labelColor: labelColor,
              unselectedLabelColor: labelColor,
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
    showSavePdfDialog(
      context: context,
      child: ApelEwanSavePdfContent(
        folder: widget.folder,
        onPdfGenerated: (f, selectedCount) {
          final slug = f is ApelEwanPersistentFolder ? f.slug : f.id;
          logAnalyticsEvent('apel_ewan_pdf_generated', {
            'source': 'web',
            'folder_id': f.id,
            'folder_slug': slug,
            'selected_count': selectedCount,
            'total_count': f.apelEwans.length,
          });
        },
      ),
    );
  }

  void _openHowItWorksDialog(BuildContext context) {
    openAppDialog(
      context: context,
      title: 'Jak to działa?',
      closable: true,
      scrollable: true,
      maxWidth: appDialogMaxWidth,
      child: KonspektHtmlWidget(
        rozwazanie_ewangeliczne,
        rozwEwanStandaloneDescription,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimen.sideMarg),
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

                      SimpleButton.from(
                        context: context,
                        color: cardEnab_(context),
                        icon: MdiIcons.informationOutline,
                        text: collapsed ? null : 'Jak to działa?',
                        onTap: () => _openHowItWorksDialog(context),
                      ),

                      Expanded(child: Container()),
                      
                      const SizedBox(width: Dimen.defMarg),
                      HarcappShareButton.simpleButton(
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
      ),
    );
  }
}
