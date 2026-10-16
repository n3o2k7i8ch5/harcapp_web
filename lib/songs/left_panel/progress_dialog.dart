import 'dart:async';

import 'package:flutter/material.dart' hide DialogRoute;
import 'package:flutter/scheduler.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/dialog/base.dart';
import 'package:harcapp_core/comm_widgets/dialog/route.dart';
import 'package:harcapp_core/values/dimen.dart';

/// Postęp długiej roboty: co się właśnie dzieje i ile z tego za nami.
///
/// Na webie nie ma drugiego wątku dla kodu Darta, więc jedyny sposób, żeby
/// strona żyła, to **oddawać go co chwilę** — i to właśnie robi [advance].
/// Z tego samego powodu okno nie może tylko wisieć nad zamrożoną stroną:
/// pasek rośnie dokładnie wtedy, gdy wątek wraca do przeglądarki.
class ProgressReport extends ChangeNotifier{

  /// Po tylu milisekundach roboty oddajemy wątek. Tyle samo bierze
  /// `SongIndex.inSlices` — poniżej tego klatki i tak nie da się utrzymać,
  /// a powyżej widać zacinanie.
  static const Duration slice = Duration(milliseconds: 12);

  String _text;
  int _done = 0;
  int? _total;
  final Stopwatch _sinceYield = Stopwatch()..start();

  ProgressReport(this._text);

  String get text => _text;

  int get done => _done;
  int? get total => _total;

  /// `null`, gdy nie wiadomo, ile tego jest — wtedy pasek leci bez końca.
  double? get fraction =>
      _total == null || _total == 0? null: _done/_total!;

  /// Nowy etap: inny podpis i licznik od zera. Bez [total] pasek jest
  /// bez końca — tak podajemy roboty, których nie da się pokroić.
  void step(String text, {int? total}){
    _text = text;
    _done = 0;
    _total = total;
    notifyListeners();
  }

  /// Oddaje wątek **na pewno** i czeka na odmalowaną klatkę — przed robotą,
  /// której nie da się pokroić, żeby nowy podpis zdążył się pokazać.
  Future<void> settle() async {
    _sinceYield.reset();
    notifyListeners();
    await SchedulerBinding.instance.endOfFrame;
  }

  /// Kolejne [count] sztuk za nami. Co [slice] oddaje wątek, żeby okno
  /// zdążyło się odmalować; poza tym nic nie kosztuje.
  Future<void> advance([int count = 1]) async {
    _done += count;
    if(_sinceYield.elapsed < slice) return;
    _sinceYield.reset();
    notifyListeners();
    await Future<void>.delayed(Duration.zero);
  }

}

/// Bez animacji wejścia: okno ma być widoczne od razu, a nie wtedy, gdy
/// robota już trwa i nie ma kto rysować klatek.
class _ProgressRoute extends DialogRoute{

  _ProgressRoute({required super.builder}): super(dismissible: false);

  @override
  Duration get transitionDuration => Duration.zero;

}

/// Puszcza [work] pod oknem postępu i zamyka je, cokolwiek się stanie.
/// [work] dostaje [ProgressReport] — ma nim mówić, na czym stoi, i przez
/// jego [ProgressReport.advance] oddawać wątek.
Future<T> runWithProgress<T>(
    BuildContext context,
    { required String text,
      required Future<T> Function(ProgressReport progress) work }) async {

  ProgressReport progress = ProgressReport(text);
  NavigatorState navigator = Navigator.of(context);

  _ProgressRoute route = _ProgressRoute(
    builder: (context) => Padding(
      padding: const EdgeInsets.all(Dimen.sideMarg),
      child: BaseDialog(
        maxWidth: ProgressDialog.width,
        child: ProgressDialog(progress: progress),
      ),
    ),
  );

  navigator.push(route);

  // Jedna klatka wstawia okno do drzewa i je maluje. Dopiero potem wolno
  // zacząć — pierwszy etap bywa nie do pokrojenia i wtedy to jedyna okazja.
  await SchedulerBinding.instance.endOfFrame;

  try {
    return await work(progress);
  } finally {
    if(route.isActive) navigator.removeRoute(route);
    progress.dispose();
  }

}

class ProgressDialog extends StatelessWidget{

  static const double width = 400;

  final ProgressReport progress;

  const ProgressDialog({required this.progress, super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Dimen.sideMarg),
    child: ListenableBuilder(
      listenable: progress,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              Expanded(
                child: Text(
                  progress.text,
                  style: AppTextStyle(
                      fontSize: Dimen.textSizeBig,
                      color: textEnab_(context)
                  ),
                ),
              ),

              if(progress.total != null)
                Padding(
                  padding: const EdgeInsets.only(left: Dimen.defMarg),
                  child: Text(
                    '${progress.done} z ${progress.total}',
                    style: AppTextStyle(color: hintEnab_(context)),
                  ),
                )

            ],
          ),

          const SizedBox(height: Dimen.sideMarg),

          ClipRRect(
            borderRadius: BorderRadius.circular(Dimen.defMarg),
            child: LinearProgressIndicator(
              value: progress.fraction,
              minHeight: Dimen.defMarg,
              backgroundColor: backgroundIcon_(context),
              color: iconEnab_(context),
            ),
          )

        ],
      ),
    ),
  );

}
