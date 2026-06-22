import 'package:flutter_test/flutter_test.dart';
import 'package:harcapp_web/konspekt_workspace/content_check/on_device_text_checker.dart';
import 'package:harcapp_web/konspekt_workspace/content_check/narration_check.dart';

// Covers the pure, deterministic parts: prompt construction and interpreting
// the model's raw TAK/NIE response. The inference itself needs WebGPU/MediaPipe
// (browser) — see integration_test/content_eval_test.dart.
void main() {
  group('parseYesNo', () {
    test('plain TAK / NIE', () {
      expect(OnDeviceTextChecker.parseYesNo('TAK'), isTrue);
      expect(OnDeviceTextChecker.parseYesNo('NIE'), isFalse);
    });

    test('is case-insensitive', () {
      expect(OnDeviceTextChecker.parseYesNo('tak'), isTrue);
      expect(OnDeviceTextChecker.parseYesNo('Nie'), isFalse);
    });

    test('tolerates surrounding text, punctuation and whitespace', () {
      expect(OnDeviceTextChecker.parseYesNo('  TAK.\n'), isTrue);
      expect(OnDeviceTextChecker.parseYesNo('Odpowiedź: TAK'), isTrue);
      expect(OnDeviceTextChecker.parseYesNo('Nie, to nie jest polski.'), isFalse);
    });

    test('empty / whitespace-only → null (the empty-turn case we hit live)', () {
      expect(OnDeviceTextChecker.parseYesNo(''), isNull);
      expect(OnDeviceTextChecker.parseYesNo('\n'), isNull);
      expect(OnDeviceTextChecker.parseYesNo('   '), isNull);
    });

    test('null → null', () {
      expect(OnDeviceTextChecker.parseYesNo(null), isNull);
    });

    test('when both appear, the FIRST one wins (model answers then rambles)', () {
      expect(OnDeviceTextChecker.parseYesNo('TAK. (a nie NIE)'), isTrue);
      expect(OnDeviceTextChecker.parseYesNo('NIE, zdecydowanie nie TAK'), isFalse);
      // Long rambling few-shot-style continuation: first answer is the real one.
      expect(
        OnDeviceTextChecker.parseYesNo(' TAK\nTekst: „...".\nOdpowiedź: NIE'),
        isTrue,
      );
    });

    test('ignores a <think> reasoning block (Qwen3-style)', () {
      // The think block contains both words; only the answer after it counts.
      expect(
        OnDeviceTextChecker.parseYesNo(
            '<think>czy TAK czy NIE? chyba nie po polsku</think> NIE'),
        isFalse,
      );
      expect(
        OnDeviceTextChecker.parseYesNo('<think>hmm NIE... a może</think>\nTAK'),
        isTrue,
      );
      // Unterminated think (reasoning cut off) → no real answer → null.
      expect(
        OnDeviceTextChecker.parseYesNo('<think>zastanawiam się czy TAK'),
        isNull,
      );
    });

    test('neither word → null', () {
      expect(OnDeviceTextChecker.parseYesNo('być może'), isNull);
    });

    test('does not match TAK/NIE embedded in a larger word', () {
      expect(OnDeviceTextChecker.parseYesNo('TAKsówka'), isNull);
      expect(OnDeviceTextChecker.parseYesNo('NIEduży'), isNull);
    });
  });

  group('interpretPolish (language name → result)', () {
    test('Polish names → polish', () {
      expect(OnDeviceTextChecker.interpretPolish('polski'), LangCheckResult.polish);
      expect(OnDeviceTextChecker.interpretPolish('Język: polski'), LangCheckResult.polish);
      expect(OnDeviceTextChecker.interpretPolish('Polish'), LangCheckResult.polish);
    });
    test('other languages → notPolish', () {
      expect(OnDeviceTextChecker.interpretPolish('angielski'), LangCheckResult.notPolish);
      expect(OnDeviceTextChecker.interpretPolish('niemiecki'), LangCheckResult.notPolish);
      expect(OnDeviceTextChecker.interpretPolish('hiszpański'), LangCheckResult.notPolish);
    });
    test('empty / null → unknown', () {
      expect(OnDeviceTextChecker.interpretPolish(''), LangCheckResult.unknown);
      expect(OnDeviceTextChecker.interpretPolish('   '), LangCheckResult.unknown);
      expect(OnDeviceTextChecker.interpretPolish(null), LangCheckResult.unknown);
    });
    test('ignores a <think> block before the answer', () {
      expect(
        OnDeviceTextChecker.interpretPolish('<think>hmm to chyba polski</think> angielski'),
        LangCheckResult.notPolish,
      );
      expect(
        OnDeviceTextChecker.interpretPolish('<think>english? no</think>\npolski'),
        LangCheckResult.polish,
      );
    });
  });

  group('interpretNarration (konspekt domain)', () {
    test('maps yes/no/unknown', () {
      expect(interpretNarration('TAK'), NarrationCheckResult.rolesBased);
      expect(interpretNarration('NIE'), NarrationCheckResult.personalForm);
      expect(interpretNarration(''), NarrationCheckResult.unknown);
      expect(interpretNarration(null), NarrationCheckResult.unknown);
    });
  });

  group('prompts', () {
    test('embed the text to check', () {
      const text = 'Prowadzący dzieli uczestników na grupy.';
      expect(OnDeviceTextChecker.polishPrompt(text), contains(text));
      expect(narrationPrompt(text), contains(text));
    });

    test('end with a cue so greedy decoding emits the answer, not an empty turn',
        () {
      // Language prompt asks for the language name; narration asks TAK/NIE.
      expect(OnDeviceTextChecker.polishPrompt('abc').trimRight(),
          endsWith('Język:'));
      expect(narrationPrompt('abc').trimRight(), endsWith('Odpowiedź:'));
    });

    test('narration prompt names both roles and the discouraged forms', () {
      final p = narrationPrompt('abc');
      expect(p, contains('prowadzący'));
      expect(p, contains('uczestnicy'));
      expect(p, contains('robimy'));
    });
  });
}
