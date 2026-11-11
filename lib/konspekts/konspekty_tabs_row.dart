import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/tab_bar.dart';
import 'package:harcapp_core/folder/folder_tab.dart';
import 'package:harcapp_core/folder/folder_tab_indicator.dart';
import 'package:harcapp_core/harcthought/harc_forms/data.dart';
import 'package:harcapp_core/harcthought/harcapp_links.dart';
import 'package:harcapp_core/harcthought/konspekts/data/harcerskie/all.dart';
import 'package:harcapp_core/harcthought/konspekts/data/ksztalcenie/all.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/common/page_width_bar.dart';
import 'package:harcapp_web/router.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

/// Tabs of the konspekty section (forms, both konspekt categories, the
/// editor) — the same folder tabs as in the other sections (rozważania,
/// artykuły). Each tab is its own route.
class KonspektyTabsRow extends StatelessWidget {
  const KonspektyTabsRow({super.key});

  static final List<_KonspektyTab> _tabs = [
    _KonspektyTab(
      'Formy',
      'Liczba form: ${allForms.length}',
      MdiIcons.creation,
      [pathKonspektyFormy, HarcappLinks.formaListTemplateShort],
    ),
    _KonspektyTab(
      'Dla harcerzy',
      'Liczba konspektów: ${allHarcerskieKonspekts.length}',
      MdiIcons.tent,
      [
        pathKonspektyHarcerskie,
        HarcappLinks.konspektCategoryListPath(KonspektCategory.harcerskie, short: true),
      ],
    ),
    _KonspektyTab(
      'Kształceniowe',
      'Liczba konspektów: ${allKsztalcenieKonspekts.length}',
      MdiIcons.schoolOutline,
      [
        pathKonspektyKsztalcenie,
        HarcappLinks.konspektCategoryListPath(KonspektCategory.ksztalcenie, short: true),
      ],
    ),
    _KonspektyTab(
      'Edytor konspektu',
      'Napisz własny konspekt',
      MdiIcons.fileDocumentEditOutline,
      [pathWarsztatKonspektow],
    ),
  ];

  // Konspekty harcerskie, where /konspekty itself leads.
  static const int _defaultIndex = 1;

  static int _indexOf(String path) {
    for (int i = 0; i < _tabs.length; i++) {
      if (_tabs[i].matches(path)) return i;
    }
    return _defaultIndex;
  }

  @override
  Widget build(BuildContext context) {
    final int index = _indexOf(GoRouterState.of(context).uri.path);
    final Color barColor = cardEnab_(context);
    final Color labelColor = textEnab_(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 8, color: barColor),
        PageWidthBar(
          backgroundColor: barColor,
          child: DefaultTabController(
            key: ValueKey(index),
            length: _tabs.length,
            initialIndex: index,
            child: TabBarX(
              isScrollable: true,
              indicator: FolderTabIndicator(color: background_(context)),
              indicatorSize: TabBarIndicatorSize.tab,
              splashBorderRadius: FolderTabIndicator.defBorderRadius,
              overlayColor:
                  WidgetStateProperty.all(labelColor.withValues(alpha: 0.08)),
              labelColor: labelColor,
              unselectedLabelColor: labelColor,
              onTap: (i) {
                if (i != index) context.go(_tabs[i].paths.first);
              },
              tabs: [
                for (final tab in _tabs)
                  FolderTwoLineTab(
                    leading: Icon(tab.icon, size: Dimen.iconSize, color: iconEnab_(context)),
                    text: tab.text,
                    subText: tab.subText,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _KonspektyTab {
  final String text;
  final String subText;
  final IconData icon;

  /// The tab's route first, then other paths under which it is selected
  /// (short forms of the links).
  final List<String> paths;

  const _KonspektyTab(this.text, this.subText, this.icon, this.paths);

  bool matches(String path) => paths.any((p) =>
      path == p || path.startsWith('$p/'));
}
