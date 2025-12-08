import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_button.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'repository.dart';


class SprawnosciFamilyPage extends StatefulWidget {
  final String bookSlug;
  final String groupSlug;
  final String familySlug;
  const SprawnosciFamilyPage({
    required this.bookSlug,
    required this.groupSlug,
    required this.familySlug,
    super.key
  });

  @override
  State<SprawnosciFamilyPage> createState() => _SprawnosciFamilyPageState();
}

class _SprawnosciFamilyPageState extends State<SprawnosciFamilyPage> {
  Future<SprawBook>? _future;

  @override
  void initState() {
    super.initState();
    _future = SprawnosciRepositoryNew().loadBook(widget.bookSlug);
  }

  @override
  Widget build(BuildContext context) =>
      BaseScaffold(
        backgroundColor: background_(context),
        body: Align(
          alignment: Alignment.topCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: FutureBuilder<SprawBook>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done)
                  return const Center(child: CircularProgressIndicator());

                if (snap.hasError)
                  return Center(child: SelectableText('Błąd: ${snap.error}'));

                final book = snap.data!;
                final group = book.groups.firstWhere((g) =>
                g.slug == widget.groupSlug);
                final family = group.families.firstWhere((f) =>
                f.slug == widget.familySlug);
                final items = [...family.items]
                  ..sort((a, b) {
                    final byLevel = a.level.compareTo(b.level);
                    if (byLevel != 0) return byLevel;
                    return a.name.compareTo(b.name);
                  });

                return SingleChildScrollView(
                  child: SelectionArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: Dimen.sideMarg),

                        AppButton(
                          icon: Icon(MdiIcons.arrowLeft),
                          onTap: () => context.go('/sprawnosci/${widget.bookSlug}'),
                        ),
                        const SizedBox(height: Dimen.sideMarg),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: Dimen.sideMarg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [

                              Text(
                                  family.name,
                                  style: AppTextStyle(
                                      fontSize: Dimen.textSizeAppBar,
                                      fontWeight: FontWeight.w700,
                                      color: iconEnab_(context)
                                  )
                              ),

                              const SizedBox(height: Dimen.sideMarg),

                              if (family.tags.isNotEmpty)
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: family.tags
                                      .map((t) =>
                                      Text(
                                          t,
                                          style: AppTextStyle(
                                              fontSize: Dimen.textSizeBig,
                                              fontWeight: weightHalfBold,
                                              color: textDisab_(context)
                                          )
                                      )
                                  ).toList(),
                                ),

                              if (family.fragment.isNotEmpty) ...[
                                const SizedBox(height: Dimen.sideMarg),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        family.fragment,
                                        style: AppTextStyle(
                                          color: textEnab_(context),
                                          fontStyle: FontStyle.italic,
                                          fontSize: Dimen.textSizeBig,
                                        )
                                    ),
                                    if (family.fragmentAuthor.isNotEmpty) ...[
                                      const SizedBox(height: Dimen.sideMarg),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                            '— ${family.fragmentAuthor}',
                                            style: AppTextStyle(
                                              color: textEnab_(context),
                                              fontStyle: FontStyle.italic,
                                              fontSize: Dimen.textSizeBig,
                                            )
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],

                              const SizedBox(height: 3*Dimen.sideMarg),

                              // Render all items inline with spacing
                              ...[for (int i = 0; i < items.length; i++) ...[
                                Padding(
                                  padding: EdgeInsets.only(bottom: 3*Dimen.sideMarg),
                                  child: SprawItemWidget(item: items[i]),
                                ),
                              ]],

                            ],
                          ),
                        )


                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
}

class SprawItemWidget extends StatelessWidget {
  final SprawItem item;
  const SprawItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      SizedBox(
        width: 100,
        height: 100,
        child: item.iconPath.isEmpty
            ? Icon(Icons.verified, color: iconEnab_(context))
            : SvgPicture.asset(
                item.iconPath,
                colorFilter: ColorFilter.mode(iconEnab_(context), BlendMode.srcIn),
              ),
      ),
      const SizedBox(width: Dimen.sideMarg),

      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${item.name} ${'*' * item.level}',
              style: AppTextStyle(
                fontWeight: FontWeight.w700,
                color: iconEnab_(context),
                fontSize: Dimen.textSizeBig,
              ),
            ),

            SizedBox(height: Dimen.sideMarg),

            ...item.tasks.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(MdiIcons.circleSmall),
                  Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: (Dimen.iconSize - Dimen.textSizeBig)/2),
                        child: Text(
                            t,
                            style: AppTextStyle(
                                color: textEnab_(context),
                                fontSize: Dimen.textSizeBig
                            )
                        ),
                      )
                  ),
                ],
              ),
            )),

          ],
        ),
      )

    ],
  );
}
