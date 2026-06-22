import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Loads runtime configuration from `web/config.json` (served at `/config.json`).
///
/// Used for values that must not be hard-coded in source but are needed at
/// startup — e.g. the HuggingFace token for the on-device language model.
/// Loading at runtime (instead of a compile-time `--dart-define`) means the
/// app works the same no matter how it is launched (IDE, CLI, …).
///
/// On web the file is served from the app root, so it is publicly readable —
/// do NOT put truly secret values here for a public deployment.
class RuntimeConfig {
  RuntimeConfig._();

  static Map<String, dynamic> _values = const {};

  /// Fetches `config.json` once. Safe to call when the file is absent — missing
  /// file / parse errors are swallowed and [getString] just returns null.
  static Future<void> load() async {
    try {
      // Resolve against the origin root (leading slash) so a deep-link path in
      // Uri.base doesn't break the lookup.
      final response = await http.get(Uri.base.resolve('/config.json'));
      if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) _values = decoded;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('RuntimeConfig: config.json not loaded ($e)');
    }
  }

  /// Returns the non-empty string value for [key], or null.
  static String? getString(String key) {
    final value = _values[key];
    return value is String && value.isNotEmpty ? value : null;
  }
}
