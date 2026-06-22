import 'package:flutter/foundation.dart';
import 'package:harcapp_web/konspekt_workspace/content_check/webllm.dart';

/// Outcome of a Polish-language check on a piece of text.
enum LangCheckResult {
  /// The text looks like Polish.
  polish,

  /// The text does NOT look like Polish.
  notPolish,

  /// Could not be determined (model unavailable, error, too little text…).
  unknown,
}

/// On-device (in-browser, WebGPU via WebLLM) yes/no text checker.
///
/// Generic engine: owns the model lifecycle and runs a prompt to a TAK/NIE
/// answer ([ask] / [parseYesNo]). Built-in [isPolish] is domain-agnostic;
/// domain-specific checks (e.g. konspekt narration) live in their own layer and
/// call [ask] with their own prompt.
///
/// The model (Qwen3-1.7B, an ungated MLC build — NO HuggingFace token) is
/// downloaded on the first [prepare] and kept in memory. Checks are serialized.
class OnDeviceTextChecker {
  OnDeviceTextChecker._();
  static final OnDeviceTextChecker instance = OnDeviceTextChecker._();

  /// WebLLM prebuilt model id. Qwen3-1.7B: ungated (no token needed), strong
  /// enough for both checks. Swap for another MLC id to trade size for quality.
  static const String _modelId = 'Qwen3-1.7B-q4f16_1-MLC';

  /// Human-readable model size, e.g. for a download-confirmation dialog.
  static const String modelSizeLabel = '~1.1 GB';

  /// Minimum number of (plain-text) characters before a check is worthwhile.
  static const int minChars = 12;

  Future<bool>? _loading;

  /// Serializes inference calls — one at a time.
  Future<void> _queue = Future.value();

  /// Whether the model is loaded and ready to run checks now.
  bool get isReady => WebLlm.instance.isReady;

  /// Whether the model is already cached in the browser, so a check won't
  /// trigger the (~1 GB) download. Loaded-in-memory counts too.
  Future<bool> isDownloaded() async {
    if (WebLlm.instance.isReady) return true;
    return WebLlm.instance.hasModelInCache(_modelId);
  }

  /// Downloads (if needed) and loads the model, reporting download progress as
  /// a percentage 0..100 via [onProgress]. Returns true once ready. Each call is
  /// a fresh attempt — a previous failure does not permanently disable retry.
  Future<bool> prepare({void Function(int percent)? onProgress}) {
    if (WebLlm.instance.isReady) return Future.value(true);
    return _loading ??= _load(onProgress: onProgress);
  }

  Future<bool> _load({void Function(int percent)? onProgress}) async {
    try {
      return await WebLlm.instance.load(
        _modelId,
        onProgress: (p, _) => onProgress?.call((p * 100).round()),
      );
    } finally {
      _loading = null;
    }
  }

  /// Returns whether [text] is written in Polish. Requires the model to be
  /// loaded (call [prepare] first); short / blank input or a not-ready model
  /// resolves to [LangCheckResult.unknown] without running (or downloading) it.
  Future<LangCheckResult> isPolish(String text) async =>
      interpretPolish(await ask(text, polishPrompt));

  /// Runs a check on [text] using [buildPrompt]; returns the raw model response,
  /// or null if the model is not ready / text is too short / on error. Calls are
  /// serialized. Domain checks build their own prompt + interpret with [parseYesNo].
  Future<String?> ask(String text, String Function(String) buildPrompt) {
    final trimmed = text.trim();
    if (trimmed.length < minChars) return Future.value(null);
    if (!WebLlm.instance.isReady) return Future.value(null);

    // Thinking stays ON (the model reasons in a <think> block, which the
    // interpreters strip); generation is uncapped so the answer follows.
    final result = _queue.then((_) => WebLlm.instance.chat(buildPrompt(trimmed)));
    // Keep the queue alive regardless of this call's success/failure.
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  // ===== Pure prompt builder + interpreters (unit-testable) =====

  // Language check: ask the model to NAME the language (with few-shot), not a
  // yes/no "is it Polish?". The yes/no framing made small models almost always
  // answer "TAK" (~67% acc); naming the language is near-perfect (Gemma 3 1B
  // and Qwen3-1.7B both 100% on the eval set).
  @visibleForTesting
  static String polishPrompt(String text) =>
      'Określ język poniższego tekstu. Odpowiedz tylko jednym słowem — nazwą języka.\n\n'
      'Tekst: „The leader greets the troop."\nJęzyk: angielski\n'
      'Tekst: „Der Leiter begrüßt die Gruppe."\nJęzyk: niemiecki\n'
      'Tekst: „Prowadzący wita zbiórkę."\nJęzyk: polski\n\n'
      'Tekst: „$text"\nJęzyk:';

  /// Maps the model's "name the language" answer to a [LangCheckResult]:
  /// mentions Polish → polish; any other named language → notPolish; empty →
  /// unknown.
  @visibleForTesting
  static LangCheckResult interpretPolish(String? raw) {
    if (raw == null) return LangCheckResult.unknown;
    final low = _withoutThink(raw).toLowerCase();
    if (low.contains('polsk') || low.contains('polish')) {
      return LangCheckResult.polish;
    }
    // A named (non-Polish) language → notPolish; nothing usable → unknown.
    return RegExp(r'[a-ząćęłńóśżź]').hasMatch(low)
        ? LangCheckResult.notPolish
        : LangCheckResult.unknown;
  }

  /// Strips a reasoning model's <think>…</think> block (Qwen3 etc.), including
  /// an unterminated one (reasoning cut off mid-way), so its musings can't be
  /// mistaken for the answer.
  static String _withoutThink(String raw) {
    var text = raw.replaceAll(
        RegExp(r'<think(?:ing)?>.*?</think(?:ing)?>',
            dotAll: true, caseSensitive: false),
        '');
    final open = text.toLowerCase().indexOf('<think');
    if (open != -1) text = text.substring(0, open);
    return text;
  }

  /// Parses a yes/no model response: true for "TAK", false for "NIE". Uses the
  /// FIRST of the two words to appear — small models often answer correctly with
  /// the first word, then ramble (or, after few-shot prompts, continue the
  /// example pattern), so a later occurrence of the other word must not flip or
  /// void the answer. Returns null only if neither word appears (or input null).
  static bool? parseYesNo(String? raw) {
    if (raw == null) return null;
    final upper = _withoutThink(raw).toUpperCase();
    final yes = RegExp(r'\bTAK\b').firstMatch(upper)?.start;
    final no = RegExp(r'\bNIE\b').firstMatch(upper)?.start;
    if (yes == null && no == null) return null;
    if (yes == null) return false;
    if (no == null) return true;
    return yes < no;
  }
}
