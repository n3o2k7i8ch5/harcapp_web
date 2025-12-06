import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/router.dart';

class KonspektyTabsRow extends StatelessWidget {
  const KonspektyTabsRow({super.key});

  static const double tabRadius = AppCard.bigRadius;

  @override
  Widget build(BuildContext context) {
    final String uri = GoRouterState.of(context).uri.toString();

    Widget buildTab(String text, String path) {
      final bool selected = uri.startsWith(path);
      return Expanded(
        child: GestureDetector(
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
              horizontal: Dimen.defMarg,
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyle(
                color: selected ? iconEnab_(context) : hintEnab_(context),
                fontWeight: selected ? weightBold : weightHalfBold,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        buildTab('Dla harcerzy', pathKonspektyHarcerskie),
        SizedBox(width: 2),
        buildTab('Kształceniowe', pathKonspektyKsztalcenie),
        SizedBox(width: 2),
        buildTab('Edytor konspektu', pathWarsztatKonspektow),
      ],
    );
  }
}
