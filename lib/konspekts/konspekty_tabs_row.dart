import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class KonspektyTabsRow extends StatelessWidget {
  const KonspektyTabsRow({super.key});

  static const double tabRadius = AppCard.bigRadius;

  @override
  Widget build(BuildContext context) {
    final String uri = GoRouterState.of(context).uri.toString();

    Widget buildTab(String text, String path, IconData icon) {
      final bool selected = uri.startsWith(path);

      return GestureDetector(
        onTap: () {
          if (!selected) context.go(path);
        },
        child: Container(
          decoration: BoxDecoration(
            color: selected ? background_(context) : backgroundIcon_(context),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(tabRadius),
              topRight: Radius.circular(tabRadius),
            ),
          ),
          padding: EdgeInsets.symmetric(
            vertical: Dimen.iconMarg,
            horizontal: 1.5 * Dimen.sideMarg,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: Dimen.iconSize,
                color: selected ? iconEnab_(context) : hintEnab_(context),
              ),
              SizedBox(width: Dimen.iconMarg),
              Text(
                text,
                textAlign: TextAlign.center,
                style: AppTextStyle(
                  color: selected ? iconEnab_(context) : hintEnab_(context),
                  fontWeight: selected ? weightBold : weightHalfBold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      key: PageStorageKey<String>('konspekty_tabs_scroll'),
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(width: Dimen.sideMarg),
          buildTab('Dla harcerzy', pathKonspektyHarcerskie, MdiIcons.tent),
          SizedBox(width: 1),
          buildTab('Kształceniowe', pathKonspektyKsztalcenie, MdiIcons.schoolOutline),
          SizedBox(width: 1),
          buildTab('Edytor konspektu', pathWarsztatKonspektow, MdiIcons.fileDocumentEditOutline),
          SizedBox(width: Dimen.sideMarg),
        ],
      ),
    );
  }
}
