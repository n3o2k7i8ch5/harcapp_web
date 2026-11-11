import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/values/dimen.dart';

/// Shown in place of a page while its content loads — the app's loading
/// dots (as in dialogs and articles) with what is loading.
class PageLoadingWidget extends StatelessWidget {

  final String text;

  const PageLoadingWidget(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpinKitChasingDots(color: textDisab_(context), size: 2*Dimen.iconSize),
        const SizedBox(height: 2*Dimen.sideMarg),
        Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyle(
            fontSize: Dimen.textSizeBig,
            fontWeight: weightHalfBold,
            color: textDisab_(context),
          ),
        ),
      ],
    ),
  );

}
