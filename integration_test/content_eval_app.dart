// Standalone eval entrypoint: runs the Gemma checker over a labelled dataset
// in a REAL browser (so MediaPipe/WebGPU + web/index.html scripts are present)
// and prints accuracy. Use this instead of an integration test, since
// `flutter test -d chrome` doesn't support web integration tests.
//
// Run:
//   flutter run -d chrome -t integration_test/content_eval_app.dart
//
// The HuggingFace token is read from web/config.json (same as the app). Watch
// the flutter run console for the "=== Eval ===" report; it's also shown
// on the page.

import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:harcapp_web/konspekt_workspace/content_check/on_device_text_checker.dart';
import 'package:harcapp_web/common/runtime_config.dart';

import 'content_eval.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RuntimeConfig.load();
  final token = RuntimeConfig.getString('HUGGINGFACE_TOKEN');
  OnDeviceTextChecker.instance.runtimeToken = token;
  // Eval loads the model into memory each run (no Cache API). Avoids the 700 MB
  // cache.put — which fails under ephemeral/automated Chrome profiles — and
  // keeps the eval independent of any previously cached model.
  await FlutterGemma.initialize(
    inferenceEngines: const [MediaPipeEngine()],
    webStorageMode: WebStorageMode.none,
  );

  runApp(const _EvalApp());
}

class _EvalApp extends StatefulWidget {
  const _EvalApp();

  @override
  State<_EvalApp> createState() => _EvalAppState();
}

class _EvalAppState extends State<_EvalApp> {
  String _status = 'Ładowanie modelu (~700 MB przy pierwszym razie)…';

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final ready = await OnDeviceTextChecker.instance.prepare(
      onProgress: (p) {
        if (mounted) setState(() => _status = 'Pobieranie modelu: $p%');
      },
    );
    if (!mounted) return;
    if (!ready) {
      setState(() => _status =
          'Nie udało się załadować modelu (token w web/config.json? WebGPU?).');
      return;
    }
    setState(() => _status = 'Sprawdzanie…');
    final result = await runContentEval();
    // Printed to the flutter run console.
    debugPrint(result.report);
    if (!mounted) return;
    setState(() => _status = result.report);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: SelectableText(
                _status,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              ),
            ),
          ),
        ),
      );
}
