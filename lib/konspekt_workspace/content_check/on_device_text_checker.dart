import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

/// Outcome of a Polish-language check on a piece of text.
enum LangCheckResult {
  /// The text looks like Polish.
  polish,

  /// The text does NOT look like Polish.
  notPolish,

  /// Could not be determined (model unavailable, error, too little text…).
  unknown,
}

/// On-device (in-browser, via flutter_gemma + MediaPipe/WebGPU) yes/no text
/// checker backed by a small Gemma model.
///
/// This is the generic engine: it owns the model lifecycle and runs a prompt to
/// a TAK/NIE answer ([ask] / [parseYesNo]). The only built-in check is the
/// domain-agnostic [isPolish]; domain-specific checks (e.g. konspekt narration
/// style) live in their own layer and call [ask] with their own prompt.
///
/// The Gemma `.task` model (~700 MB) is NOT downloaded automatically — call
/// [prepare] (e.g. after the user confirms the download) first. Once loaded it
/// is kept in memory; all checks are serialized (the session is single-lane).
class OnDeviceTextChecker {
  OnDeviceTextChecker._();
  static final OnDeviceTextChecker instance = OnDeviceTextChecker._();

  /// Web-optimised Gemma 3 1B IT `.task` model (int4).
  static const String _modelUrl =
      'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4-web.task';

  /// HuggingFace access token for the gated Gemma model, provided at compile
  /// time with `--dart-define=HUGGINGFACE_TOKEN=hf_xxx`. Used as a fallback when
  /// [runtimeToken] is not set.
  static const String _hfToken = String.fromEnvironment('HUGGINGFACE_TOKEN');

  /// HuggingFace token loaded at runtime (e.g. from `web/config.json`). When
  /// set, it takes precedence over the compile-time [_hfToken]. Assign during
  /// app startup before the first check.
  String? runtimeToken;

  /// Effective token to use for the (gated) download, or null if none.
  String? get _token {
    if (runtimeToken != null && runtimeToken!.isNotEmpty) return runtimeToken;
    return _hfToken.isEmpty ? null : _hfToken;
  }

  /// Approximate on-disk/download size of the model, in bytes.
  static const int modelSizeBytes = 700383232;

  /// Human-readable model size, e.g. for a download-confirmation dialog.
  static String get modelSizeLabel =>
      '${(modelSizeBytes / (1024 * 1024)).round()} MB';

  /// Minimum number of (plain-text) characters before a check is worthwhile.
  static const int minChars = 12;

  /// Filename used by flutter_gemma to track the installed model.
  static String get _modelFilename => Uri.parse(_modelUrl).pathSegments.last;

  InferenceModel? _model;
  Future<InferenceModel?>? _loading;

  /// A single reused inference session. On MediaPipe web, createSession is
  /// idempotent per model (returns a cached session) and closing it kills the
  /// underlying LlmInference, so we create ONE session and reuse it for every
  /// check (clearing its query buffer between prompts) rather than per-check
  /// create+close.
  InferenceModelSession? _session;

  /// Serializes inference calls — sessions are single-lane.
  Future<void> _queue = Future.value();

  /// Whether the model is loaded in memory and ready to run checks now.
  bool get isReady => _model != null;

  /// Whether the model file is already downloaded/cached, so triggering a check
  /// would NOT require the big (~700 MB) download. Loaded-in-memory counts too.
  Future<bool> isDownloaded() async {
    if (_model != null) return true;
    try {
      return await FlutterGemma.isModelInstalled(_modelFilename);
    } catch (_) {
      return false;
    }
  }

  /// Downloads (if needed) and loads the model, reporting download progress as
  /// a percentage 0..100 via [onProgress]. Returns true once the model is ready.
  ///
  /// Each call is a fresh attempt: a previous failure (e.g. a transient network
  /// error) does NOT permanently disable the feature — the user can retry.
  Future<bool> prepare({void Function(int percent)? onProgress}) async {
    if (_model != null) return true;
    final model = await (_loading ??= _load(onProgress: onProgress));
    return model != null;
  }

  Future<InferenceModel?> _load({void Function(int percent)? onProgress}) async {
    try {
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
        fileType: ModelFileType.task,
      )
          .fromNetwork(_modelUrl, token: _token)
          .withProgress((p) => onProgress?.call(p))
          .install();

      _model = await FlutterGemma.getActiveModel(
        maxTokens: 1024,
        preferredBackend: PreferredBackend.gpu,
      );
      return _model;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('OnDeviceTextChecker: model load failed: $e\n$st');
      }
      return null;
    } finally {
      _loading = null;
    }
  }

  /// Returns whether [text] is written in Polish. Requires the model to be
  /// loaded (call [prepare] first); short / blank input or a not-ready model
  /// resolves to [LangCheckResult.unknown] without running (or downloading) it.
  Future<LangCheckResult> isPolish(String text) async =>
      interpretPolish(await ask(text, polishPrompt));

  /// Runs a Gemma check on [text] using [buildPrompt] and returns the raw model
  /// response, or null if the model is not ready / text is too short / on error.
  /// Calls are serialized so only one inference runs at a time. Domain-specific
  /// checks build their own prompt and interpret the raw answer with [parseYesNo].
  Future<String?> ask(String text, String Function(String) buildPrompt) {
    final trimmed = text.trim();
    if (trimmed.length < minChars) return Future.value(null);
    if (_model == null) return Future.value(null);

    final result = _queue.then((_) => _run(buildPrompt(trimmed)));
    // Keep the queue alive regardless of this call's success/failure.
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<String?> _run(String prompt) async {
    final model = _model;
    if (model == null) return null;

    try {
      final session = _session ??=
          await model.createSession(temperature: 0.1, topK: 1);
      // Reuse one session: clear any prior prompt so this check is independent.
      await session.clearQueryChunks();
      await session.addQueryChunk(Message.text(text: prompt, isUser: true));
      return await session.getResponse();
    } catch (e) {
      if (kDebugMode) debugPrint('OnDeviceTextChecker: inference failed: $e');
      // Session may be in a bad state — drop it so the next call recreates.
      _session = null;
      return null;
    }
  }

  // ===== Pure prompt builder + interpreters (unit-testable) =====

  @visibleForTesting
  static String polishPrompt(String text) =>
      'Czy poniższy tekst jest napisany po polsku? '
      'Odpowiadaj tylko jednym słowem: TAK albo NIE.\n\n'
      'Przykłady:\n'
      'Tekst: „Prowadzący wita zbiórkę i przedstawia plan."\n'
      'Odpowiedź: TAK\n'
      'Tekst: „The leader greets the troop and explains the plan."\n'
      'Odpowiedź: NIE\n'
      'Tekst: „Der Leiter begrüßt die Gruppe und erklärt den Plan."\n'
      'Odpowiedź: NIE\n\n'
      'Tekst: „$text"\n'
      'Odpowiedź:';

  /// Maps a raw model response to a [LangCheckResult].
  @visibleForTesting
  static LangCheckResult interpretPolish(String? raw) {
    final yn = parseYesNo(raw);
    if (yn == null) return LangCheckResult.unknown;
    return yn ? LangCheckResult.polish : LangCheckResult.notPolish;
  }

  /// Parses a yes/no model response: true for "TAK", false for "NIE". Uses the
  /// FIRST of the two words to appear — small models often answer correctly with
  /// the first word, then ramble (or, after few-shot prompts, continue the
  /// example pattern), so a later occurrence of the other word must not flip or
  /// void the answer. Returns null only if neither word appears (or input null).
  static bool? parseYesNo(String? raw) {
    if (raw == null) return null;
    final upper = raw.toUpperCase();
    final yes = RegExp(r'\bTAK\b').firstMatch(upper)?.start;
    final no = RegExp(r'\bNIE\b').firstMatch(upper)?.start;
    if (yes == null && no == null) return null;
    if (yes == null) return false;
    if (no == null) return true;
    return yes < no;
  }
}
