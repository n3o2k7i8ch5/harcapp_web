import 'package:flutter/foundation.dart';
import 'package:harcapp_web/konspekt_workspace/content_check/on_device_text_checker.dart';
import 'package:harcapp_web/konspekt_workspace/content_check/narration_check.dart';

/// A kind of on-device check that can be run on a piece of text.
enum ContentCheck { language, narration }

/// Standard check sets per field kind — the single place that says "what is
/// checked where". The page builds [CheckTarget]s using these.
class KonspektChecks {
  static const Set<ContentCheck> intro = {ContentCheck.language};
  static const Set<ContentCheck> prose = {
    ContentCheck.language,
    ContentCheck.narration,
  };
}

/// One field to check: a human label, its (plain) text, and which checks apply.
class CheckTarget {
  final String label;
  final String text;
  final Set<ContentCheck> checks;

  const CheckTarget(this.label, this.text, this.checks);
}

/// Result for one checked field. A `null` result means that check wasn't run.
class CheckOutcome {
  final String label;
  final LangCheckResult? lang;
  final NarrationCheckResult? narration;

  const CheckOutcome(this.label, {this.lang, this.narration});

  bool get hasIssue =>
      lang == LangCheckResult.notPolish ||
      narration == NarrationCheckResult.personalForm;
}

/// Outcome of a whole run: an [error] to show, or the per-field [outcomes].
class CheckRunResult {
  final String? error;
  final List<CheckOutcome> outcomes;

  const CheckRunResult({this.error, this.outcomes = const []});
}

/// Drives the single global "check correctness" action: downloads the model
/// once (on first use), runs the configured checks over a list of [CheckTarget]s
/// and returns per-field [CheckOutcome]s. Exposes download/checking state for
/// the FAB; holds no per-field widgets — results are shown in one summary.
class KonspektCheckController extends ChangeNotifier {
  final OnDeviceTextChecker _checker = OnDeviceTextChecker.instance;

  bool _downloading = false;
  double? _downloadProgress; // 0..1, or null while indeterminate
  bool _checking = false;

  bool get downloading => _downloading;
  double? get downloadProgress => _downloadProgress;
  bool get checking => _checking;
  bool get busy => _downloading || _checking;

  /// [confirmDownload] is invoked (to show a confirmation dialog) only when the
  /// ~700 MB model isn't downloaded yet; return false to cancel.
  Future<CheckRunResult> run({
    required List<CheckTarget> targets,
    required Future<bool> Function() confirmDownload,
  }) async {
    if (busy) return const CheckRunResult();

    final checkable = targets
        .where((t) =>
            t.checks.isNotEmpty &&
            t.text.trim().length >= OnDeviceTextChecker.minChars)
        .toList();
    if (checkable.isEmpty) {
      return const CheckRunResult(error: 'Za mało tekstu do sprawdzenia.');
    }

    if (!_checker.isReady) {
      final already = await _checker.isDownloaded();
      if (!already) {
        final confirmed = await confirmDownload();
        if (!confirmed) return const CheckRunResult();
      }

      _downloading = true;
      _downloadProgress = already ? null : 0;
      notifyListeners();
      final loaded = await _checker.prepare(
        onProgress: (p) {
          _downloadProgress = p / 100;
          notifyListeners();
        },
      );
      _downloading = false;
      notifyListeners();
      if (!loaded) {
        return const CheckRunResult(error: 'Nie udało się pobrać modelu sprawdzania.');
      }
    }

    _checking = true;
    notifyListeners();
    final outcomes = <CheckOutcome>[];
    try {
      for (final t in checkable) {
        final text = t.text.trim();
        final lang = t.checks.contains(ContentCheck.language)
            ? await _checker.isPolish(text)
            : null;
        final narration = t.checks.contains(ContentCheck.narration)
            ? await checkRoleNarration(text)
            : null;
        outcomes.add(CheckOutcome(t.label, lang: lang, narration: narration));
      }
    } finally {
      _checking = false;
      notifyListeners();
    }
    return CheckRunResult(outcomes: outcomes);
  }
}
