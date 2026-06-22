import 'package:harcapp_web/konspekt_workspace/content_check/on_device_text_checker.dart';
import 'package:harcapp_web/konspekt_workspace/content_check/narration_check.dart';

/// One labelled example for the Gemma checker evaluation.
class ContentEvalCase {
  final String text;
  final LangCheckResult expectedLang;

  /// null = don't evaluate narration for this case (e.g. non-Polish text).
  final NarrationCheckResult? expectedNarration;

  const ContentEvalCase(
    this.text, {
    required this.expectedLang,
    this.expectedNarration,
  });
}

/// Labelled dataset for evaluating [OnDeviceTextChecker] + konspekt narration.
///
/// The texts intentionally DIFFER from the few-shot examples baked into the
/// narration prompt, so the eval measures generalization, not memorization.
const List<ContentEvalCase> contentEvalCases = [
  // --- Polish, role-based narration (good) ---
  ContentEvalCase(
    'Prowadzący wita uczestników i krótko przedstawia cel zbiórki.',
    expectedLang: LangCheckResult.polish,
    expectedNarration: NarrationCheckResult.rolesBased,
  ),
  ContentEvalCase(
    'Uczestnicy w parach wykonują ćwiczenie, a prowadzący chodzi i pomaga.',
    expectedLang: LangCheckResult.polish,
    expectedNarration: NarrationCheckResult.rolesBased,
  ),
  ContentEvalCase(
    'Prowadzący czyta zagadkę, uczestnicy zgłaszają się z odpowiedziami.',
    expectedLang: LangCheckResult.polish,
    expectedNarration: NarrationCheckResult.rolesBased,
  ),

  // --- Polish, personal "we/you" forms (bad) ---
  ContentEvalCase(
    'Robimy krótką rozgrzewkę, a potem wprowadzamy zasady gry terenowej.',
    expectedLang: LangCheckResult.polish,
    expectedNarration: NarrationCheckResult.personalForm,
  ),
  ContentEvalCase(
    'Siema, na start dzielimy się na dwie drużyny i zaczynamy zabawę.',
    expectedLang: LangCheckResult.polish,
    expectedNarration: NarrationCheckResult.personalForm,
  ),
  ContentEvalCase(
    'Podzielcie się na grupy i wymyślcie okrzyk, potem go zaprezentujcie.',
    expectedLang: LangCheckResult.polish,
    expectedNarration: NarrationCheckResult.personalForm,
  ),

  // --- Not Polish (narration not evaluated) ---
  ContentEvalCase(
    'The leader divides the participants into small groups.',
    expectedLang: LangCheckResult.notPolish,
  ),
  ContentEvalCase(
    'Der Leiter teilt die Teilnehmer in kleine Gruppen ein.',
    expectedLang: LangCheckResult.notPolish,
  ),
  ContentEvalCase(
    'El líder divide a los participantes en grupos pequeños.',
    expectedLang: LangCheckResult.notPolish,
  ),
];

/// Result of running [runContentEval].
class ContentEvalResult {
  final String report;
  final double langAccuracy;
  final double narrationAccuracy;

  const ContentEvalResult(this.report, this.langAccuracy, this.narrationAccuracy);
}

/// Runs every case in [contentEvalCases] through [OnDeviceTextChecker] (which must
/// already be prepared) and returns a human-readable report plus the language /
/// narration accuracies.
Future<ContentEvalResult> runContentEval() async {
  final checker = OnDeviceTextChecker.instance;
  var langOk = 0, langTotal = 0;
  var narrOk = 0, narrTotal = 0;
  final report = StringBuffer('\n=== Eval ===\n');

  for (final c in contentEvalCases) {
    final lang = await checker.isPolish(c.text);
    langTotal++;
    final langPass = lang == c.expectedLang;
    if (langPass) langOk++;

    var narrCol = '';
    if (c.expectedNarration != null) {
      final narration = await checkRoleNarration(c.text);
      narrTotal++;
      final narrPass = narration == c.expectedNarration;
      if (narrPass) narrOk++;
      narrCol = ' | narr ${narrPass ? '✓' : '✗'} '
          '(got=${narration.name}, exp=${c.expectedNarration!.name})';
    }

    report.writeln(
      '${langPass ? '✓' : '✗'} lang (got=${lang.name}, '
      'exp=${c.expectedLang.name})$narrCol\n    «${c.text}»',
    );
  }

  final langAccuracy = langTotal == 0 ? 1.0 : langOk / langTotal;
  final narrationAccuracy = narrTotal == 0 ? 1.0 : narrOk / narrTotal;
  report
    ..writeln('---')
    ..writeln('language:  $langOk/$langTotal '
        '(${(langAccuracy * 100).toStringAsFixed(0)}%)')
    ..writeln('narration: $narrOk/$narrTotal '
        '(${(narrationAccuracy * 100).toStringAsFixed(0)}%)');

  return ContentEvalResult(report.toString(), langAccuracy, narrationAccuracy);
}
