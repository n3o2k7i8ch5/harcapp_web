import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/harcthought/harcapp_links.dart';
import 'package:harcapp_core/harcthought/poradnik/poradnik.dart';
import 'package:harcapp_core/harcthought/poradnik/poradnik_page_count_pill.dart';
import 'package:harcapp_core/harcthought/poradnik/poradnik_thumbnail_widget.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:harcapp_web/consts.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

class PoradnikPage extends StatelessWidget {

  static const double defPaddingVal = 32.0;

  final Poradnik poradnik;

  const PoradnikPage(this.poradnik, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => BaseScaffold(
    backgroundColor: background_(context),
    body: Stack(
      fit: StackFit.expand,
      children: [

        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: 60,
              sigmaY: 60,
              tileMode: TileMode.clamp,
            ),
            child: Image.asset(
              'packages/harcapp_core/assets/poradnik/${poradnik.name}/cover_raw.webp',
              fit: BoxFit.cover,
            ),
          ),
        ),

        Positioned.fill(
          child: Container(
            color: background_(context).withValues(alpha: 0.6),
          ),
        ),

        SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(defPaddingVal),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: defPageWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  Align(
                    alignment: Alignment.centerLeft,
                    child: SimpleButton.from(
                      context: context,
                      color: cardEnab_(context),
                      icon: MdiIcons.arrowLeft,
                      text: 'Wszystkie poradniki',
                      margin: EdgeInsets.zero,
                      onTap: () => context.canPop()
                          ? context.pop()
                          : context.go(HarcappLinks.poradnikListTemplate),
                    ),
                  ),

                  SizedBox(height: defPaddingVal),

                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [

                        PoradnikThumbnailWidget(
                          poradnik,
                          width: 100*6,
                          height: 141*6,
                          elevation: AppCard.bigElevation,
                        ),

                        SizedBox(height: 2*Dimen.defMarg),

                        PoradnikPageCountPill(poradnik.pageCount),

                      ],
                    ),
                  ),

                  SizedBox(height: defPaddingVal),

                  Text(
                    poradnik.description,
                    style: AppTextStyle(
                      fontSize: Dimen.textSizeBig,
                      color: iconEnab_(context),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),

      ],
    ),
  );

}
