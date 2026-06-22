import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:harcapp_web/konspekt_workspace/content_check/narration_check.dart';
import 'package:harcapp_web/konspekt_workspace/content_check/on_device_text_checker.dart';

// LLM-backed eval of the REAL prompts + parsing against a labelled dataset,
// using a local Ollama running Gemma 3 1B (matches the production web model) — so it runs as a NORMAL `flutter
// test` (VM + HTTP to localhost), no browser / WebGPU / chromedriver.
//
// Setup once:
//   brew install ollama && ollama serve &   # (or: brew services start ollama)
//   ollama pull gemma3:1b
//
// Then: flutter test test/content_check_model_eval_test.dart
//
// NOTE: this runs Gemma 3 1B via Ollama (a different quantization than the web
// `-int4-web.task` MediaPipe build the app ships), so it's representative of
// prompt quality, not a byte-exact replica of production. Skips if Ollama isn't
// running.

const _ollama = 'http://localhost:11434';
const _model = 'gemma3:1b';

/// One labelled scenario = input text + the GROUND-TRUTH answer we expect the
/// model to return. A null expectation means "don't run that check for this
/// text" (e.g. narration is irrelevant for non-Polish text).
///
/// Scoring: each non-null expectation is one graded item. The model's answer is
/// compared to it; accuracy = correct / total, computed separately for language
/// and narration. (See the asserts at the bottom for the pass thresholds.)
class _Case {
  final String text;
  final LangCheckResult? expectedLang;
  final NarrationCheckResult? expectedNarration;
  const _Case(this.text, {this.expectedLang, this.expectedNarration});
}

const _cases = <_Case>[
  // Polish + role-based narration ("prowadzący"/"uczestnicy") → both should PASS.
  _Case('Prowadzący wita uczestników i krótko przedstawia cel zbiórki.',
      expectedLang: LangCheckResult.polish,
      expectedNarration: NarrationCheckResult.rolesBased),
  _Case('Uczestnicy w parach wykonują ćwiczenie, a prowadzący chodzi i pomaga.',
      expectedLang: LangCheckResult.polish,
      expectedNarration: NarrationCheckResult.rolesBased),
  _Case('Prowadzący czyta zagadkę, uczestnicy zgłaszają się z odpowiedziami.',
      expectedLang: LangCheckResult.polish,
      expectedNarration: NarrationCheckResult.rolesBased),

  // Polish but "we/you" forms ("robimy"/"dzielimy się"/"podzielcie") →
  // language=polish, narration should be flagged as personalForm.
  _Case('Robimy krótką rozgrzewkę, a potem wprowadzamy zasady gry terenowej.',
      expectedLang: LangCheckResult.polish,
      expectedNarration: NarrationCheckResult.personalForm),
  _Case('Siema, na start dzielimy się na dwie drużyny i zaczynamy zabawę.',
      expectedLang: LangCheckResult.polish,
      expectedNarration: NarrationCheckResult.personalForm),
  _Case('Podzielcie się na grupy i wymyślcie okrzyk, potem go zaprezentujcie.',
      expectedLang: LangCheckResult.polish,
      expectedNarration: NarrationCheckResult.personalForm),

  // Not Polish → language=notPolish; narration not evaluated (null).
  _Case('The leader divides the participants into small groups.',
      expectedLang: LangCheckResult.notPolish),
  _Case('Der Leiter teilt die Teilnehmer in kleine Gruppen ein.',
      expectedLang: LangCheckResult.notPolish),
  _Case('El líder divide a los participantes en grupos pequeños.',
      expectedLang: LangCheckResult.notPolish),
];

Future<bool> _ollamaUp() async {
  try {
    final r = await http
        .get(Uri.parse('$_ollama/api/tags'))
        .timeout(const Duration(seconds: 2));
    return r.statusCode == 200;
  } catch (_) {
    return false;
  }
}

/// Sends [prompt] to the local model and returns its raw answer.
Future<String?> _ask(String prompt) async {
  final r = await http.post(
    Uri.parse('$_ollama/api/chat'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({
      'model': _model,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'stream': false,
      'options': {'temperature': 0.1, 'top_k': 1, 'num_predict': 16},
    }),
  );
  if (r.statusCode != 200) return null;
  return (jsonDecode(r.body)['message']?['content']) as String?;
}

void main() {
  test('content-check prompts: language + narration accuracy on a labelled '
      'dataset (real Gemma 3 1B via local Ollama)',
      () async {
    if (!await _ollamaUp()) {
      markTestSkipped('Ollama not running on :11434 — see file header.');
      return;
    }

    var langOk = 0, langTotal = 0, narrOk = 0, narrTotal = 0;
    final report = StringBuffer('\n=== model eval ($_model @ ollama) ===\n');

    for (final c in _cases) {
      var line = '';
      if (c.expectedLang != null) {
        final got = OnDeviceTextChecker.interpretPolish(
            await _ask(OnDeviceTextChecker.polishPrompt(c.text)));
        langTotal++;
        final ok = got == c.expectedLang;
        if (ok) langOk++;
        line += '${ok ? '✓' : '✗'} lang(got=${got.name},exp=${c.expectedLang!.name}) ';
      }
      if (c.expectedNarration != null) {
        final got = interpretNarration(await _ask(narrationPrompt(c.text)));
        narrTotal++;
        final ok = got == c.expectedNarration;
        if (ok) narrOk++;
        line += '| ${ok ? '✓' : '✗'} narr(got=${got.name},exp=${c.expectedNarration!.name})';
      }
      report.writeln('$line\n    «${c.text}»');
    }

    final langAcc = langOk / langTotal;
    final narrAcc = narrTotal == 0 ? 1.0 : narrOk / narrTotal;
    report
      ..writeln('---')
      ..writeln('language:  $langOk/$langTotal (${(langAcc * 100).round()}%)')
      ..writeln('narration: $narrOk/$narrTotal (${(narrAcc * 100).round()}%)');
    // ignore: avoid_print
    print(report);

    // Regression floors (Gemma 3 1B via Ollama: ~100% lang with the "name the
    // language" prompt, ~50% narr). Narration is the harder, fuzzier judgement
    // — the model stays lenient on "robimy"-style text — hence the low bar.
    // Raise as prompts/model improve.
    expect(langAcc, greaterThanOrEqualTo(0.9),
        reason: 'language accuracy regressed below baseline$report');
    expect(narrAcc, greaterThanOrEqualTo(0.4),
        reason: 'narration accuracy regressed below baseline$report');
  }, timeout: const Timeout(Duration(minutes: 4)));
}
