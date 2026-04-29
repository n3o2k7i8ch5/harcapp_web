import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:harcapp_web/consts.dart';

class RozwazaniaEwangelicznePage extends StatelessWidget {

  const RozwazaniaEwangelicznePage({super.key});

  @override
  Widget build(BuildContext context) => BaseScaffold(
    backgroundColor: background_(context),
    body: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: defPageWidth),
        child: Padding(
          padding: const EdgeInsets.all(Dimen.sideMarg),
          child: Text(
            'Rozważania ewangeliczne',
            style: AppTextStyle(
              fontSize: 24.0,
              color: iconEnab_(context),
              fontWeight: weightBold,
            ),
          ),
        ),
      ),
    ),
  );

}
