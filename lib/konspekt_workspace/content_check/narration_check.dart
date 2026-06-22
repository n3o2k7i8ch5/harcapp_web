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

@visibleForTesting
String narrationPrompt(String text) =>
    'Oceniasz styl opisu kroku konspektu zbiórki harcerskiej.\n'
    'Zasada: opis ma mówić KTO wykonuje czynność, używając ról „prowadzący" '
    'i „uczestnicy" w trzeciej osobie. Formy pierwszej osoby liczby mnogiej '
    '(„robimy", „dzielimy", „wprowadzamy", „zaczynamy") albo drugiej osoby '
    '(„zróbcie", „podzielcie") są NIEpoprawne.\n'
    'Odpowiadaj tylko jednym słowem: TAK (styl poprawny) albo NIE (niepoprawny).\n\n'
    'Przykłady:\n'
    'Tekst: „Prowadzący dzieli uczestników na grupy."\n'
    'Odpowiedź: TAK\n'
    'Tekst: „Robimy na początku podział uczestników na grupy."\n'
    'Odpowiedź: NIE\n'
    'Tekst: „Uczestnicy wykonują zadanie, a prowadzący obserwuje."\n'
    'Odpowiedź: TAK\n'
    'Tekst: „Na początku dzielimy się na grupy i zaczynamy grę."\n'
    'Odpowiedź: NIE\n\n'
    'Tekst: „$text"\n'
    'Odpowiedź:';

/// Maps a raw model response to a [NarrationCheckResult].
@visibleForTesting
NarrationCheckResult interpretNarration(String? raw) {
  final yn = OnDeviceTextChecker.parseYesNo(raw);
  if (yn == null) return NarrationCheckResult.unknown;
  return yn ? NarrationCheckResult.rolesBased : NarrationCheckResult.personalForm;
}
