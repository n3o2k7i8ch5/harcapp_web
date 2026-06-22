/// Non-web stub for [WebLlm] (WebLLM only runs in a browser). Lets VM tests
/// compile and import the checker; inference methods are no-ops here.
class WebLlm {
  WebLlm._();
  static final WebLlm instance = WebLlm._();

  bool get isReady => false;

  /// Whether this platform can run WebLLM (needs WebGPU). Never on non-web.
  Future<bool> isSupported() async => false;

  Future<bool> hasModelInCache(String modelId) async => false;

  Future<bool> load(
    String modelId, {
    void Function(double progress, String text)? onProgress,
  }) async =>
      false;

  Future<String?> chat(String prompt) async => null;
}
