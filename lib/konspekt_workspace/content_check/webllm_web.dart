import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';

// === JS interop bindings for window.webllm (the mlc-ai/web-llm ES module) ===

@JS('webLlmReady')
external JSPromise<JSAny?>? get _webLlmReady;

@JS('webllm')
external _WebllmNs get _ns;

extension type _WebllmNs(JSObject _) implements JSObject {
  external JSPromise<JSObject> CreateMLCEngine(
      JSString modelId, JSObject config);
  external JSPromise<JSBoolean> hasModelInCache(JSString modelId);
}

extension type _Engine(JSObject _) implements JSObject {
  external _Chat get chat;
}

extension type _Chat(JSObject _) implements JSObject {
  external _Completions get completions;
}

extension type _Completions(JSObject _) implements JSObject {
  external JSPromise<_Reply> create(JSObject request);
}

extension type _Reply(JSObject _) implements JSObject {
  external JSArray<_Choice> get choices;
}

extension type _Choice(JSObject _) implements JSObject {
  external _ReplyMsg get message;
}

extension type _ReplyMsg(JSObject _) implements JSObject {
  external JSString get content;
}

/// In-browser WebLLM engine. Loads an MLC model (ungated, WebGPU) and runs
/// one-shot chat completions. Same surface as the stub.
class WebLlm {
  WebLlm._();
  static final WebLlm instance = WebLlm._();

  _Engine? _engine;

  bool get isReady => _engine != null;

  /// Whether the browser actually supports WebGPU (present + a usable adapter).
  /// `navigator.gpu` can exist yet have no adapter (blocklisted GPU / headless),
  /// so we also try `requestAdapter()`.
  Future<bool> isSupported() async {
    try {
      final navigator = globalContext.getProperty<JSObject?>('navigator'.toJS);
      final gpu = navigator?.getProperty<JSObject?>('gpu'.toJS);
      if (gpu == null) return false;
      final adapter =
          await gpu.callMethod<JSPromise<JSAny?>>('requestAdapter'.toJS).toDart;
      return adapter != null;
    } catch (e) {
      if (kDebugMode) debugPrint('WebLlm.isSupported failed: $e');
      return false;
    }
  }

  Future<void> _awaitReady() async {
    final ready = _webLlmReady;
    if (ready != null) await ready.toDart;
  }

  /// Whether [modelId] is already in the browser cache (no big download needed).
  Future<bool> hasModelInCache(String modelId) async {
    try {
      await _awaitReady();
      final cached = await _ns.hasModelInCache(modelId.toJS).toDart;
      return cached.toDart;
    } catch (e) {
      if (kDebugMode) debugPrint('WebLlm.hasModelInCache failed: $e');
      return false;
    }
  }

  /// Downloads (if needed) + initialises the engine for [modelId], reporting
  /// download progress (0..1) via [onProgress]. Returns true once ready.
  Future<bool> load(
    String modelId, {
    void Function(double progress, String text)? onProgress,
  }) async {
    try {
      await _awaitReady();
      final config = JSObject();
      if (onProgress != null) {
        config.setProperty(
          'initProgressCallback'.toJS,
          ((JSObject report) {
            final p = report.getProperty<JSNumber?>('progress'.toJS);
            final t = report.getProperty<JSString?>('text'.toJS);
            onProgress(p?.toDartDouble ?? 0, t?.toDart ?? '');
          }).toJS,
        );
      }
      final engine = await _ns.CreateMLCEngine(modelId.toJS, config).toDart;
      _engine = _Engine(engine);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('WebLlm.load failed: $e');
      _engine = null;
      return false;
    }
  }

  /// Runs a single user-turn completion; returns the assistant text, or null.
  Future<String?> chat(String prompt) async {
    final engine = _engine;
    if (engine == null) return null;
    try {
      final message = JSObject();
      message.setProperty('role'.toJS, 'user'.toJS);
      message.setProperty('content'.toJS, prompt.toJS);

      final request = JSObject();
      request.setProperty('messages'.toJS, <JSObject>[message].toJS);
      request.setProperty('temperature'.toJS, 0.toJS);
      // No max_tokens cap — let the reasoning model (Qwen3) think as long as it
      // wants and finish with the answer; the parser strips the <think> block.

      final reply = await engine.chat.completions.create(request).toDart;
      final choices = reply.choices.toDart;
      if (choices.isEmpty) return null;
      final content = choices.first.message.content.toDart;
      if (kDebugMode) debugPrint('WebLlm.chat reply: ${content.length} chars: $content');
      return content;
    } catch (e) {
      if (kDebugMode) debugPrint('WebLlm.chat failed: $e');
      return null;
    }
  }
}
