# Vendored flutter_gemma 1.0.1 (patched)

This is a local copy of `flutter_gemma` 1.0.1 from pub.dev, wired in via
`dependency_overrides` in the project `pubspec.yaml`.

## Why

The modular split in 1.0.0 introduced a web-only regression. On web,
`WebModelSourceResolver.forActiveModel()` builds a **fresh** `WebModelManager`
whose active model is only populated by `ensureInitialized()` (it rehydrates the
active-model identity from `SharedPreferences`). But
`resolveActiveInferenceModel()` read `activeInferenceModel` **synchronously,
without awaiting `ensureInitialized()`**, so on the first `createSession()` after
an install the active model was always `null`:

```
Bad state: No active inference model set. Use FlutterGemma.installModel() first.
```

A retry doesn't help: `createSession` nulls its `_initCompleter` on error and
the fresh manager is never initialized in this code path.

## The patches (search `PATCH (harcapp)`)

1. **`lib/core/model_management/managers/web_model_manager.dart`** — the real
   fix. Made `WebModelManager` a true singleton (`factory WebModelManager()`
   returns one shared `_instance`). Upstream, both `FlutterGemmaWeb` and
   `WebModelSourceResolver.forActiveModel()` did `WebModelManager()` and got
   SEPARATE instances; the active model set by `install()` lived only in the
   `FlutterGemmaWeb` instance, so the resolver's fresh instance saw none. With a
   shared instance the resolver reads the in-memory active model directly.

2. **`lib/web/web_model_source.dart`**, `resolveActiveInferenceModel()` — added
   `await _modelManager.ensureInitialized();` before reading the active model
   (defensive: ensures rehydrate-from-prefs has run; harmless with the singleton
   but correct on its own).

3. **`lib/flutter_gemma_interface.dart`**, `InferenceModelSession` — added a
   `Future<void> clearQueryChunks() async {}` default (no-op). Lets a caller
   reuse ONE session for many independent one-shot prompts. Needed because on
   MediaPipe web, closing a session and calling createSession again returns a
   cached, now-dead LlmInference (→ "text_in is not a graph input stream").
   Overridden in the vendored `flutter_gemma_mediapipe` (see its PATCH.md).

## Upgrading

If you bump `flutter_gemma`, re-apply this one-line patch on the new version (or
drop the override entirely once upstream fixes it), then re-copy here.
