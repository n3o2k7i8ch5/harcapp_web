import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/comm_widgets/title_show_row_widget.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:go_router/go_router.dart';

import 'repository.dart';


class _FamilyRef {
  final String groupSlug;
  final SprawFamily family;
  _FamilyRef({required this.groupSlug, required this.family});
}

class _FamilyCard extends StatelessWidget {
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
      onTap: () => context.go('/sprawnosci/$bookSlug/${ref.groupSlug}/${f.slug}'),
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
  Future<SprawBook>? _future;
  String _search = '';
  Future<SprawBook>? _bookCFuture;
  Future<SprawBook>? _bookDFuture;
  
  @override
  void initState() {
    super.initState();
    _selectedBook = widget.initialBookSlug ?? SprawnosciBooks.defaultBookSlug;
    _future = _repo.loadBook(_selectedBook);
    // Preload book names for sidebar options
    _bookCFuture = _repo.loadBook(SprawnosciBooks.bookCHarcC);
    _bookDFuture = _repo.loadBook(SprawnosciBooks.bookCHarcD);
  }

  Widget _buildBookOption(String bookId, String title) => SizedBox(
    width: double.infinity,
    child: Material(
      color: _selectedBook == bookId ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedBook = bookId;
          });
          _future = _repo.loadBook(_selectedBook);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: _selectedBook == bookId ? FontWeight.bold : FontWeight.normal,
              color: _selectedBook == bookId ? Colors.blue : Colors.grey[800],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildSidebar() {
    return Container(
      width: 320,
      color: background_(context),
      padding: const EdgeInsets.all(Dimen.sideMarg),
      child: Padding(
        padding: EdgeInsets.only(top: Dimen.sideMarg),
        child: _buildBookSelector(),
      )
    );
  }
  
  Widget _buildBookSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<SprawBook>(
          future: _bookCFuture,
          builder: (context, snap) => _buildBookOption(
            SprawnosciBooks.bookCHarcC,
            snap.data?.name ?? SprawnosciBooks.bookCHarcC,
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<SprawBook>(
          future: _bookDFuture,
          builder: (context, snap) => _buildBookOption(
            SprawnosciBooks.bookCHarcD,
            snap.data?.name ?? SprawnosciBooks.bookCHarcD,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => BaseScaffold(
      backgroundColor: background_(context),
      body: Row(
          children: [
            _buildSidebar(),
            Expanded(
              child: FutureBuilder<SprawBook>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done)
                    return const Center(child: CircularProgressIndicator());

                  if (snap.hasError)
                    return Center(child: SelectableText('Błąd: ${snap.error}'));

                  final book = snap.data!;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: ListView.separated(
                        padding: const EdgeInsets.only(
                          top: Dimen.sideMarg, // topGap + searchHeight + Dimen.sideMarg, // leave space for search and a small gap
                          left: Dimen.sideMarg,
                          right: Dimen.sideMarg,
                        ),
                        itemCount: book.groups.length + 1,
                        separatorBuilder: (context, index) => index == 0 ? Container(): const SizedBox(height: Dimen.sideMarg),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // Header with centered book name
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4*Dimen.sideMarg),
                              child: Center(
                                child: SelectableText(
                                  book.name,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: hintEnab_(context),
                                  ),
                                ),
                              ),
                            );
                          }
                          final group = book.groups[index - 1];
                          // Apply search filter per group
                          final List<_FamilyRef> famsInGroup = [
                            for (final f in group.families)
                              _FamilyRef(groupSlug: group.slug, family: f)
                          ];
                          final List<_FamilyRef> famsFiltered = _search.trim().isEmpty
                              ? famsInGroup
                              : famsInGroup.where((ref) {
                            final f = ref.family;
                            final phrase = _search.trim().toLowerCase();
                            final inName = f.name.toLowerCase().contains(phrase);
                            final inTags = f.tags.any((t) => t.toLowerCase().contains(phrase.replaceAll('#', '')));
                            return inName || inTags;
                          }).toList();

                          if (famsFiltered.isEmpty) return const SizedBox.shrink();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: Dimen.sideMarg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                TitleShortcutRowWidget(title: group.name, textAlign: TextAlign.left),
                                GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: Dimen.sideMarg,
                                      mainAxisSpacing: Dimen.sideMarg,
                                      childAspectRatio: 1.2,
                                    ),
                                    itemCount: famsFiltered.length,
                                    itemBuilder: (context, i) => _FamilyCard(
                                      ref: famsFiltered[i],
                                      bookSlug: _selectedBook,
                                    )
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );

                  // Fixed search bar at the top with a gap
                  // Positioned(
                  //   top: topGap,
                  //   left: searchHorizontalPadding,
                  //   right: searchHorizontalPadding,
                  //   child: Material(
                  //     elevation: AppCard.bigElevation,
                  //     borderRadius: BorderRadius.circular(AppCard.bigRadius - 4),
                  //     color: cardEnab_(context),
                  //     child: SizedBox(
                  //       height: searchHeight,
                  //       child: Row(
                  //         children: [
                  //           Padding(
                  //             padding: const EdgeInsets.symmetric(horizontal: Dimen.sideMarg),
                  //             child: Icon(MdiIcons.magnify, color: hintEnab_(context)),
                  //           ),
                  //           Expanded(
                  //             child: TextField(
                  //               style: AppTextStyle(color: iconEnab_(context)),
                  //               decoration: InputDecoration(
                  //                 hintText: 'Szukaj sprawności',
                  //                 hintStyle: AppTextStyle(color: textDisab_(context)),
                  //                 border: InputBorder.none,
                  //               ),
                  //               onChanged: (v) => setState(() => _search = v),
                  //             ),
                  //           ),
                  //           const SizedBox(width: Dimen.sideMarg),
                  //         ],
                  //       ),
                  //     ),
                  //   ),
                  // ),
                },
              ),
            ),
          ]
      )
  );
}
