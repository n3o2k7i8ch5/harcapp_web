# Vendored flutter_gemma_mediapipe 1.0.1 (patched)

Local copy of `flutter_gemma_mediapipe` 1.0.1, wired in via
`dependency_overrides:` in the project pubspec.yaml. Goes together with the
vendored `flutter_gemma` core (see `third_party/flutter_gemma/PATCH.md`).

## Why

On MediaPipe web, `WebInferenceModel.createSession()` is idempotent per model —
it caches the session and returns the same one on later calls. Closing that
session (`session.close()`) disposes the underlying `LlmInference`, but a
subsequent `createSession()` still returns the cached, now-dead session. The
next `getResponse()` then crashes:

    INTERNAL: RET_CHECK failure ... stream "text_in" which is not a graph input stream

So the only safe pattern for many one-shot prompts is to reuse ONE session
rather than create+close per prompt. But `getResponse()` deliberately does NOT
clear its buffered `_promptParts` on success (InferenceChat relies on that
accumulation to carry conversation context), so reusing a session would
concatenate every prompt.

## The patch (search `PATCH (harcapp)`)

`lib/src/web/web_inference_model.dart`, `WebModelSession` — added:

```dart
@override
Future<void> clearQueryChunks() async => _promptParts.clear();
```

(overrides the no-op default added to `InferenceModelSession` in the core
package). The app's `GemmaLanguageChecker` keeps one session and calls
`clearQueryChunks()` before each prompt, so each check is independent. Chat
semantics are untouched (harcapp doesn't use `InferenceChat`).

## Upgrading

Re-apply on any version bump, or drop both overrides once upstream fixes the
create-after-close behavior.
