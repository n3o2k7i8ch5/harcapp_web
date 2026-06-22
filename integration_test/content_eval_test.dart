// LLM-backed evaluation of OnDeviceTextChecker against a labelled dataset
// (shared with content_eval.dart).
//
// This runs the REAL on-device model, so it needs a browser (WebGPU/MediaPipe)
// and a HuggingFace token, and downloads the ~700 MB model on first run.
//
// NOTE: `flutter test -d chrome` does NOT support web integration tests; this
// file requires `flutter drive` + chromedriver. For a quick manual run without
// that setup, use the standalone entrypoint instead:
//
//   flutter run -d chrome -t integration_test/content_eval_app.dart
//
// With chromedriver set up, run via flutter drive against this target, passing
// --dart-define=HUGGINGFACE_TOKEN=hf_xxx (or rely on web/config.json).
//
// Asserts lenient thresholds (the 1B int4 model is not perfect, especially on
// narration style). Skips rather than fails if the model can't load.

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:harcapp_web/konspekt_workspace/content_check/on_device_text_checker.dart';
import 'package:harcapp_web/common/runtime_config.dart';
import 'content_eval.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gemma classifies a labelled dataset accurately', (tester) async {
    await RuntimeConfig.load();
    const define = String.fromEnvironment('HUGGINGFACE_TOKEN');
    OnDeviceTextChecker.instance.runtimeToken =
        RuntimeConfig.getString('HUGGINGFACE_TOKEN') ??
            (define.isEmpty ? null : define);
    await FlutterGemma.initialize(inferenceEngines: const [MediaPipeEngine()]);

    final ready = await OnDeviceTextChecker.instance.prepare();
    if (!ready) {
      markTestSkipped('Gemma model unavailable (token / WebGPU?).');
      return;
    }

    final result = await runContentEval();
    debugPrint(result.report);

    expect(result.langAccuracy, greaterThanOrEqualTo(0.85),
        reason: 'language detection accuracy too low\n${result.report}');
    expect(result.narrationAccuracy, greaterThanOrEqualTo(0.66),
        reason: 'narration-style accuracy too low\n${result.report}');
  }, timeout: const Timeout(Duration(minutes: 6)));
}
