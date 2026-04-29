import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/tab_bar.dart';
import 'package:harcapp_core/folder/folder_tab.dart';
import 'package:harcapp_core/folder/folder_tab_indicator.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/harcthought/apel_ewan/apel_ewan.dart';
import 'package:harcapp_core/harcthought/apel_ewan/apel_ewan_persistent_folder.dart';
import 'package:harcapp_core/harcthought/apel_ewan/apel_ewan_widget.dart';
import 'package:harcapp_web/consts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ApelEwanViewerPage extends StatefulWidget {

  final ApelEwanPersistentFolder folder;
  final ApelEwan initialApel;

  const ApelEwanViewerPage({
    required this.folder,
    required this.initialApel,
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

  @override
  void initState() {
    super.initState();
    int initialIndex = apels.indexWhere((a) => a.dirName == widget.initialApel.dirName);
    if (initialIndex < 0) initialIndex = 0;

    pageController = PageController(initialPage: initialIndex);
    tabController = TabController(
      length: apels.length,
      initialIndex: initialIndex,
      vsync: this,
    );
    tabController.addListener(_handleTabChange);
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
    if (tabController.index == index) return;
    tabController.animateTo(index);
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
    const Color bodyColor = Colors.black;

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
      ),
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
                    controller: tabController,
                    isScrollable: true,
                    indicator: FolderTabIndicator(color: bodyColor),
                    indicatorSize: TabBarIndicatorSize.tab,
                    splashBorderRadius: FolderTabIndicator.defBorderRadius,
                    overlayColor: WidgetStateProperty.all(
                        Colors.white.withValues(alpha: 0.08)),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white,
                    tabs: [
                      for (final apel in apels)
                        FolderBaseTab(text: apel.siglum),
                    ],
                  ),
                ),
              ),
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
                      child: ApelEwanWidget(
                        apel,
                        initVariantId: widget.folder.variantId,
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
