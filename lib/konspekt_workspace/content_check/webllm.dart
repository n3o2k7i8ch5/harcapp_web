// Thin wrapper over WebLLM (mlc-ai/web-llm) — in-browser WebGPU LLM inference.
// Web uses the dart:js_interop implementation; other platforms (e.g. the Dart
// VM used by `flutter test`) get a no-op stub so pure code (prompts, parsing)
// stays testable without a browser.
export 'webllm_stub.dart' if (dart.library.js_interop) 'webllm_web.dart';
