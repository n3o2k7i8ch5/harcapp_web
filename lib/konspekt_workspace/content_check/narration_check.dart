import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:harcapp_web/konspekt_workspace/content_check/on_device_text_checker.dart';

/// Outcome of the konspekt narration-style check (participants/leader roles vs.
/// personal "we"/"you" forms).
enum NarrationCheckResult {
  /// Describes actions via roles in the third person ("Prowadzący…",
  /// "Uczestnicy…") — the desired style.
  rolesBased,

  /// Uses 1st/2nd person plural forms ("robimy", "wprowadzamy", "zróbcie").
  personalForm,

  /// Could not be determined.
  unknown,
}

/// Domain-specific check: does [text] describe actions via the
/// participants/leader roles ("Prowadzący…/Uczestnicy…") in the third person,
/// rather than 1st/2nd person plural forms ("robimy", "zróbcie")? Runs on the
/// shared [OnDeviceTextChecker]; same readiness / short-input rules as its checks.
Future<NarrationCheckResult> checkRoleNarration(String text) async =>
    interpretNarration(await OnDeviceTextChecker.instance.ask(text, narrationPrompt));

// Asks the model to NAME the grammatical person (not a yes/no "is the style ok?"
// — that made small models always answer TAK). Naming maps cleanly: third
// person (role-based) = good, first/second person plural = the "we/you" forms we
// flag. Few-shot examples are deliberately NOT from the eval/test dataset.
@visibleForTesting
String narrationPrompt(String text) =>
    'Określ, w której osobie gramatycznej napisany jest poniższy opis kroku '
    'konspektu. Odpowiedz tylko jednym słowem: „trzecia", „pierwsza" albo „druga".\n'
    '- trzecia: mowa o rolach, co robią (prowadzący, uczestnicy) — '
    '„Prowadzący...", „Uczestnicy..."\n'
    '- pierwsza: autor pisze o sobie/grupie „my" — czasowniki na -my '
    '(robimy, idziemy)\n'
    '- druga: zwrot „wy"/rozkaz — czasowniki na -cie (zróbcie, ustawcie)\n\n'
    'Tekst: „Prowadzący zapala świecę i opowiada legendę."\nOsoba: trzecia\n'
    'Tekst: „Najpierw śpiewamy piosenkę, a potem malujemy plakat."\nOsoba: pierwsza\n'
    'Tekst: „Ustawcie się w kole i policzcie do dziesięciu."\nOsoba: druga\n'
    'Tekst: „Uczestnicy rysują plakat, a prowadzący rozdaje materiały."\nOsoba: trzecia\n\n'
    'Tekst: „$text"\nOsoba:';

/// Maps the model's "name the grammatical person" answer: third person →
/// rolesBased (good); first/second person plural → personalForm; else unknown.
@visibleForTesting
NarrationCheckResult interpretNarration(String? raw) {
  if (raw == null) return NarrationCheckResult.unknown;
  // Strip a reasoning block (Qwen3 <think>…</think>, incl. an unterminated one)
  // so musings can't be mistaken for the answer.
  var text = raw.replaceAll(
      RegExp(r'<think(?:ing)?>.*?</think(?:ing)?>',
          dotAll: true, caseSensitive: false),
      '');
  final open = text.toLowerCase().indexOf('<think');
  if (open != -1) text = text.substring(0, open);
  final low = text.toLowerCase();

  // A model may weigh options aloud ("to nie pierwsza, lecz trzecia"); the FINAL
  // answer is the LAST grammatical person it names — take the latest mention.
  int lastOf(List<String> needles) =>
      needles.map((n) => low.lastIndexOf(n)).fold(-1, math.max);
  final roles = lastOf(['trzec', 'third']); // third person → role-based (good)
  final personal = lastOf(['pierw', 'drug', 'first', 'second']);
  if (roles < 0 && personal < 0) return NarrationCheckResult.unknown;
  return roles >= personal
      ? NarrationCheckResult.rolesBased
      : NarrationCheckResult.personalForm;
}
