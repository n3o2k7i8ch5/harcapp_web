import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/sha_pref.dart';
import 'package:harcapp_core/comm_widgets/save_pdf_dialog.dart';
import 'package:harcapp_core/comm_widgets/tab_bar.dart';
import 'package:harcapp_core/folder/folder_tab.dart';
import 'package:harcapp_core/folder/folder_tab_indicator.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/harcthought/apel_ewan/apel_ewan.dart';
import 'package:harcapp_core/harcthought/apel_ewan/apel_ewan_persistent_folder.dart';
import 'package:harcapp_core/harcthought/apel_ewan/apel_ewan_save_pdf_content.dart';
import 'package:harcapp_core/harcthought/apel_ewan/apel_ewan_widget.dart';
import 'package:harcapp_core/harcthought/harcapp_links.dart';
import 'package:harcapp_core/harcthought/harcapp_share_button.dart';
import 'package:harcapp_web/_common_classes/firebase.dart';
import 'package:harcapp_web/common/page_width_bar.dart';
import 'package:harcapp_web/consts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ApelEwanViewerPage extends StatefulWidget {

  final ApelEwanPersistentFolder folder;
  final ApelEwan initialApel;
  /// Variant id pinned by the URL (`?wariant=...`). When null the folder's
  /// default [ApelEwanPersistentFolder.variantId] is used.
  final String? initialVariantId;

  const ApelEwanViewerPage({
    required this.folder,
    required this.initialApel,
    this.initialVariantId,
    super.key,
  });

  @override
  State<ApelEwanViewerPage> createState() => _ApelEwanViewerPageState();
}

class _ApelEwanViewerPageState extends State<ApelEwanViewerPage>
    with SingleTickerProviderStateMixin {

  late final List<ApelEwan> apels = widget.folder.apelEwans;
  late final PageController pageController;
  late final TabController tabController;

  late String _currentVariantId;

  static String _variantPrefsKey(String slug) => 'apel_ewan_variant_$slug';

  @override
  void initState() {
    super.initState();
    int initialIndex = apels.indexWhere((a) => a.dirName == widget.initialApel.dirName);
    if (initialIndex < 0) initialIndex = 0;

    final saved = ShaPref.getStringOrNull(_variantPrefsKey(widget.folder.slug));
    _currentVariantId =
        widget.initialVariantId ?? saved ?? widget.folder.variantId;

    pageController = PageController(initialPage: initialIndex);
    tabController = TabController(
      length: apels.length,
      initialIndex: initialIndex,
      vsync: this,
    );
    tabController.addListener(_handleTabChange);
  }

  @override
  void didUpdateWidget(ApelEwanViewerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialVariantId != oldWidget.initialVariantId) {
      final resolved = widget.initialVariantId ?? widget.folder.variantId;
      if (resolved != _currentVariantId) {
        setState(() => _currentVariantId = resolved);
      }
    }
    if (widget.initialApel.dirName != oldWidget.initialApel.dirName) {
      final newIndex = apels.indexWhere(
        (a) => a.dirName == widget.initialApel.dirName,
      );
      if (newIndex >= 0 && newIndex != tabController.index) {
        tabController.animateTo(newIndex);
      }
    }
  }

  void _handleVariantChanged(ApelEwan apel, String newVariantId) {
    if (newVariantId == _currentVariantId) return;
    setState(() => _currentVariantId = newVariantId);
    ShaPref.setString(_variantPrefsKey(widget.folder.slug), newVariantId);
    // Preserve the URL form (short `/r/…` vs long `/rozwazania-ewangeliczne/…`)
    // the user arrived on, so picking a variant doesn't suddenly canonicalise it.
    final currentUri = GoRouterState.of(context).uri;
    final isShort = currentUri.pathSegments.isNotEmpty && currentUri.pathSegments.first == 'r';
    final newUrl = HarcappLinks.apelEwanItem(
      widget.folder.slug,
      apel.dirName,
      variantId: newVariantId,
      short: isShort,
    );
    // HarcappLinks builders include the host; strip to a router-relative path.
    final newUri = Uri.parse(newUrl);
    final relative = newUri.hasQuery ? '${newUri.path}?${newUri.query}' : newUri.path;
    context.replace(relative);
  }

  void _handleTabChange() {
    if (!tabController.indexIsChanging) return;
    final currentPage = pageController.hasClients
        ? pageController.page?.round() ?? tabController.previousIndex
        : tabController.previousIndex;
    if (currentPage == tabController.index) return;
    pageController.animateToPage(
      tabController.index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _handlePageChange(int index) {
    if (tabController.index != index) {
      tabController.animateTo(index);
    }
    _syncUrlToIndex(index);
  }

  void _syncUrlToIndex(int index) {
    if (index < 0 || index >= apels.length) return;
    final apel = apels[index];
    if (apel.dirName == widget.initialApel.dirName) return;
    final currentUri = GoRouterState.of(context).uri;
    final isShort = currentUri.pathSegments.isNotEmpty &&
        currentUri.pathSegments.first == 'r';
    final newUrl = HarcappLinks.apelEwanItem(
      widget.folder.slug,
      apel.dirName,
      variantId: _currentVariantId,
      short: isShort,
    );
    final newUri = Uri.parse(newUrl);
    final relative = newUri.hasQuery ? '${newUri.path}?${newUri.query}' : newUri.path;
    context.replace(relative);
  }

  @override
  void dispose() {
    tabController.removeListener(_handleTabChange);
    tabController.dispose();
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color barColor = cardEnab_(context);
    final Color bodyColor = background_(context);
    final Color labelColor = textEnab_(context);

    return Scaffold(
      backgroundColor: bodyColor,
      appBar: AppBar(
        backgroundColor: barColor,
        foregroundColor: iconEnab_(context),
        leading: IconButton(
          icon: Icon(MdiIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Wróć',
        ),
        title: Text(
          widget.folder.name,
          style: AppTextStyle(
            fontSize: Dimen.textSizeAppBar,
            fontWeight: weightBold,
            color: iconEnab_(context),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(MdiIcons.filePdfBox),
            tooltip: 'Pobierz PDF',
            onPressed: () => showSavePdfDialog(
              context: context,
              child: ApelEwanSavePdfContent(
                folder: widget.folder,
                onPdfGenerated: (f, selectedCount) {
                  if (f is! ApelEwanPersistentFolder) return;
                  logAnalyticsEvent('apel_ewan_pdf_generated', {
                    'source': 'web',
                    'folder_id': f.id,
                    'folder_slug': f.slug,
                    'selected_count': selectedCount,
                    'total_count': f.apelEwans.length,
                  });
                },
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [

          PageWidthBar(
            backgroundColor: barColor,
            child: TabBarX(
              controller: tabController,
              isScrollable: true,
              indicator: FolderTabIndicator(color: bodyColor),
              indicatorSize: TabBarIndicatorSize.tab,
              splashBorderRadius: FolderTabIndicator.defBorderRadius,
              overlayColor: WidgetStateProperty.all(
                  labelColor.withValues(alpha: 0.08)),
              labelColor: labelColor,
              unselectedLabelColor: labelColor,
              tabs: [
                for (final apel in apels)
                  FolderBaseTab(
                    text: apel.variantOrFirst(_currentVariantId).oneLineLabel,
                  ),
              ],
            ),
          ),

          Expanded(
            child: PageView.builder(
              controller: pageController,
              physics: const BouncingScrollPhysics(),
              itemCount: apels.length,
              onPageChanged: _handlePageChange,
              itemBuilder: (context, index) {
                final apel = apels[index];
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(Dimen.sideMarg),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: defPageWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: Dimen.sideMarg),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: HarcappShareButton.simpleButton(
                                url: HarcappLinks.apelEwanItemOf(
                                  widget.folder,
                                  apel,
                                  variantId: _currentVariantId,
                                  short: true,
                                ),
                                subject: apel.siglum,
                                color: cardEnab_(context),
                                margin: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          ApelEwanWidget(
                            apel,
                            initVariantId: _currentVariantId,
                            onVariantChanged: (newVariantId) =>
                                _handleVariantChanged(apel, newVariantId),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        ],
      ),
    );
  }
}
