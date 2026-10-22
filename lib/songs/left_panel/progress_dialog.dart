import 'dart:async';

import 'package:flutter/material.dart' hide DialogRoute;
import 'package:flutter/scheduler.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/dialog/base.dart';
import 'package:harcapp_core/comm_widgets/dialog/route.dart';
import 'package:harcapp_core/values/dimen.dart';

/// Bez animacji wejścia: okno ma być widoczne od razu, a nie wtedy, gdy
/// robota już trwa i nie ma kto rysować klatek.
class _ProgressRoute extends DialogRoute{

  _ProgressRoute({required super.builder}): super(dismissible: false);

  @override
  Duration get transitionDuration => Duration.zero;

}

/// Puszcza [work] pod oknem z podpisem [text] i zamyka je, cokolwiek się
/// stanie.
///
/// Na krótką robotę jednym ciągiem (rozbiór pliku, zapis warsztatu) — na
/// webie przez ten czas strona i tak stoi, a okno mówi, że nie zawisła.
/// Dlatego najpierw czekamy na jedną odmalowaną klatkę: bez niej okno
/// pojawiłoby się dopiero po robocie.
Future<T> runWithProgress<T>(
    BuildContext context,
    { required String text,
      required T Function() work }) async {

  NavigatorState navigator = Navigator.of(context);

  _ProgressRoute route = _ProgressRoute(
    builder: (context) => Padding(
      padding: const EdgeInsets.all(Dimen.sideMarg),
      child: BaseDialog(
        maxWidth: ProgressDialog.width,
        child: ProgressDialog(text: text),
      ),
    ),
  );

  navigator.push(route);
  await SchedulerBinding.instance.endOfFrame;

  try {
    return work();
  } finally {
    if(route.isActive) navigator.removeRoute(route);
  }

}

class ProgressDialog extends StatelessWidget{

  static const double width = 400;

  final String text;

  const ProgressDialog({required this.text, super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Dimen.sideMarg),
    child: Row(
      children: [

        SizedBox(
          width: Dimen.iconSize,
          height: Dimen.iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: iconEnab_(context),
          ),
        ),

        const SizedBox(width: Dimen.sideMarg),

        Expanded(
          child: Text(
            text,
            style: AppTextStyle(
                fontSize: Dimen.textSizeBig,
                color: textEnab_(context)
            ),
          ),
        )

      ],
    ),
  );

}
