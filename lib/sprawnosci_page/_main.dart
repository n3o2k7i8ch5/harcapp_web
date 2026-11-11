import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/harcthought/harcapp_links.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/comm_widgets/title_show_row_widget.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:harcapp_web/common/page_loading_widget.dart';
import 'package:go_router/go_router.dart';

import 'package:harcapp_core/comm_widgets/tab_bar.dart';
import 'package:harcapp_core/folder/folder_tab.dart';
import 'package:harcapp_core/folder/folder_tab_indicator.dart';
import 'package:harcapp_web/common/page_width_bar.dart';
import 'package:sprawnosci_data/sprawnosci_assets.dart' show SprawBookSlug;
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:harcapp_core/comm_classes/text_utils.dart';
import 'package:harcapp_core/comm_widgets/search_field.dart';
import 'package:harcapp_web/consts.dart';
import 'repository.dart';


class _FamilyRef {
  final String groupSlug;
  final SprawFamily family;
  _FamilyRef({required this.groupSlug, required this.family});
}

class _FamilyCard extends StatelessWidget {

  /// Narrowest a card gets before the grid drops a column.
  static const double minWidth = 300;
  static const int maxColumns = 3;

  /// The same in any number of columns — as tall as in three columns on a
  /// full-width page, so a single column doesn't stretch cards into empty space.
  static const double height = 290;

  /// How many cards fit side by side in [width]: up to [maxColumns], down to
  /// one on narrow windows.
  static int columnsFor(double width) =>
      ((width + Dimen.sideMarg)/(minWidth + Dimen.sideMarg)).floor().clamp(1, maxColumns);

  final _FamilyRef ref;
  final String bookSlug;

  const _FamilyCard({
    required this.ref,
    required this.bookSlug,
  });

  @override
  Widget build(BuildContext context) {
    final f = ref.family;
    return SimpleButton(
      radius: AppCard.bigRadius,
      color: cardEnab_(context),
      onTap: () => context.go(HarcappLinks.sprawnosciFamilyPath(bookSlug, ref.groupSlug, f.slug)),
      child: Padding(
        padding: const EdgeInsets.all(Dimen.sideMarg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TitleShortcutRowWidget(
              title: f.name,
              titleColor: iconEnab_(context),
              textAlign: TextAlign.left,
            ),

            if (f.tags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: f.tags.map(
                  (t) => Text(
                      t,
                      style: AppTextStyle(
                          fontSize: Dimen.textSizeNormal,
                          fontWeight: weightHalfBold,
                          color: textDisab_(context)
                      )
                  )
                ).toList(),
              ),

            const SizedBox(height: Dimen.sideMarg),

            Expanded(
              child: Wrap(
                spacing: Dimen.sideMarg,
                runSpacing: Dimen.sideMarg,
                children: [
                  for (final it in f.items)
                    SizedBox(
                      width: 52.5,
                      height: 52.5,
                      child: it.iconPath.isEmpty
                          ? Icon(Icons.verified, color: iconEnab_(context))
                          : SvgPicture.asset(
                              it.iconPath,
                              fit: BoxFit.contain,
                              colorFilter: ColorFilter.mode(iconEnab_(context), BlendMode.srcIn),
                            ),
                    ),
                ],
              ),
            )

          ],
        ),
      ),
    );
  }
}

class SprawnosciPage extends StatefulWidget {
  final String? initialBookSlug;
  
  const SprawnosciPage({
    super.key,
    this.initialBookSlug,
  });

  @override
  State<SprawnosciPage> createState() => _SprawnosciPageState();
}

class _SprawnosciPageState extends State<SprawnosciPage> {
  final SprawnosciRepositoryNew _repo = SprawnosciRepositoryNew();
  late String _selectedBook;
  // A search per book, kept while switching between them.
  final Map<String, TextEditingController> _searches = {};

  TextEditingController _searchFor(String bookSlug) =>
      _searches.putIfAbsent(bookSlug, () => TextEditingController());

  /// By the family's name, tags and its badges' names.
  static bool _matches(SprawFamily f, String query) =>
      query.isEmpty ||
      [f.name, ...f.tags, for (final it in f.items) it.name]
          .any((t) => searchableString(t).contains(query));

  @override
  void dispose() {
    for (final c in _searches.values) c.dispose();
    super.dispose();
  }
  // All books at once, so the page shows complete — names, tabs and badges —
  // and switching books needs no more loading.
  late final Future<List<SprawBook>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _selectedBook = widget.initialBookSlug ?? SprawnosciBooks.defaultBookSlug;
    _booksFuture = _repo.loadWebBooks();
  }

  @override
  void didUpdateWidget(SprawnosciPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialBookSlug != oldWidget.initialBookSlug)
      _selectedBook = widget.initialBookSlug ?? SprawnosciBooks.defaultBookSlug;
  }

  /// The book tabs — the same folder tabs as in the other sections.
  Widget _buildBookTabs(List<SprawBook> books, int index) {
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
            length: books.length,
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
                if (i != index)
                  context.go(HarcappLinks.sprawnosciBookPath(books[i].slug));
              },
              tabs: [
                for (final book in books)
                  FolderTwoLineTab(
                    leading: Icon(
                      SprawBookSlug.fromName(book.slug)?.icon ?? MdiIcons.trophyOutline,
                      size: Dimen.iconSize,
                      color: iconEnab_(context),
                    ),
                    text: book.name,
                    subText: 'Liczba sprawności: ${book.groups.expand((g) => g.families).expand((f) => f.items).length}',
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => BaseScaffold(
      backgroundColor: background_(context),
      body: FutureBuilder<List<SprawBook>>(
        future: _booksFuture,
        initialData: _repo.loadedWebBooks,
        builder: (context, snap) {
          if (snap.hasError)
            return Center(child: SelectableText('Błąd: ${snap.error}'));

          if (!snap.hasData)
            return const PageLoadingWidget('Wczytywanie sprawności…');

          final books = snap.data!;
          int index = books.indexWhere((b) => b.slug == _selectedBook);
          if (index < 0) index = 0;
          final book = books[index];

          return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBookTabs(books, index),
            Expanded(
              child: Builder(
                builder: (context) {

                  final TextEditingController search = _searchFor(book.slug);
                  final String query = searchableString(search.text);
                  final groups = [
                    for (final group in book.groups)
                      (group, [
                        for (final f in group.families)
                          if (_matches(f, query))
                            _FamilyRef(groupSlug: group.slug, family: f)
                      ]),
                  ].where((g) => g.$2.isNotEmpty).toList();

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final double margin = pageMargin(context);
                      return Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Stack(
                            children: [

                              if (groups.isEmpty)
                                Center(
                                  child: Text(
                                    'Brak sprawności pasujących do wyszukiwania',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyle(color: hintEnab_(context)),
                                  ),
                                )
                              else
                                ListView.separated(
                                  padding: EdgeInsets.only(
                                    top: margin + Dimen.iconFootprint + margin,
                                    left: margin,
                                    right: margin,
                                  ),
                                  itemCount: groups.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: Dimen.sideMarg),
                                  itemBuilder: (context, index) {
                                    final (group, fams) = groups[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: Dimen.sideMarg),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          TitleShortcutRowWidget(title: group.name, textAlign: TextAlign.left),
                                          LayoutBuilder(
                                            builder: (context, constraints) => GridView.builder(
                                                shrinkWrap: true,
                                                physics: const NeverScrollableScrollPhysics(),
                                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: _FamilyCard.columnsFor(constraints.maxWidth),
                                                  crossAxisSpacing: Dimen.sideMarg,
                                                  mainAxisSpacing: Dimen.sideMarg,
                                                  mainAxisExtent: _FamilyCard.height,
                                                ),
                                                itemCount: fams.length,
                                                itemBuilder: (context, i) => _FamilyCard(
                                                  ref: fams[i],
                                                  bookSlug: book.slug,
                                                )
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                              // Each book has its own search.
                              Positioned(
                                top: margin,
                                left: margin,
                                right: margin,
                                child: SearchField(
                                  key: ValueKey(book.slug),
                                  controller: search,
                                  hint: 'Szukaj',
                                  margin: EdgeInsets.zero,
                                  onChanged: (_) => setState(() {}),
                                  onTextCleared: () => setState(() {}),
                                ),
                              ),

                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ]
          );
        },
      )
  );
}
