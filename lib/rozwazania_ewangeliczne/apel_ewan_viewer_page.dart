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
  Widget build(BuildContext context) => BaseScaffold(
    backgroundColor: background_(context),
    floatingActionButton: FloatingActionButton(
      backgroundColor: widget.folder.colorsData.avgColor,
      tooltip: 'Eksportuj do PDF',
      onPressed: () => showScrollBottomSheet(
        context: context,
        builder: (context) => ApelEwanPrintBottomSheet(
          folder: widget.folder,
          textColor: widget.folder.colorsData.avgColor,
          iconColor: widget.folder.colorsData.colorStart,
          iconEndColor: widget.folder.colorsData.colorEnd,
        ),
      ),
      child: Icon(MdiIcons.filePdfBox),
    ),
    body: Column(
      children: [

        Material(
          color: cardEnab_(context),
          child: TabBar(
            controller: tabController,
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
