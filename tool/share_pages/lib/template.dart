import 'dart:io';

class ShareTemplate {
  final String _html;
  ShareTemplate._(this._html);

  static ShareTemplate load(String path) =>
      ShareTemplate._(File(path).readAsStringSync());

  String render({
    required String pageUrl,
    required String pageTitle,
    required String pageDescription,
    required String coverUrl,
  }) {
    final t = _escape(pageTitle);
    final d = _escape(_singleLine(pageDescription));
    final u = _escape(pageUrl);
    final c = _escape(coverUrl);

    String out = _html;
    out = out.replaceFirst(RegExp(r'<title>[^<]*</title>'), '<title>$t</title>');
    out = out.replaceFirst(
        RegExp(r'<meta name="description" content="[^"]*">'),
        '<meta name="description" content="$d">');
    out = out.replaceFirst(
        RegExp(r'<link rel="canonical" href="[^"]*">'),
        '<link rel="canonical" href="$u">');
    out = out.replaceFirst(
        RegExp(r'<meta property="og:title" content="[^"]*">'),
        '<meta property="og:title" content="$t">');
    out = out.replaceFirst(
        RegExp(r'<meta property="og:description" content="[^"]*">'),
        '<meta property="og:description" content="$d">');
    out = out.replaceFirst(
        RegExp(r'<meta property="og:url" content="[^"]*">'),
        '<meta property="og:url" content="$u">');
    out = out.replaceFirst(
        RegExp(r'<meta property="og:image" content="[^"]*">'),
        '<meta property="og:image" content="$c">');
    out = out.replaceFirst(
        RegExp(r'<meta name="twitter:title" content="[^"]*">'),
        '<meta name="twitter:title" content="$t">');
    out = out.replaceFirst(
        RegExp(r'<meta name="twitter:description" content="[^"]*">'),
        '<meta name="twitter:description" content="$d">');
    out = out.replaceFirst(
        RegExp(r'<meta name="twitter:image" content="[^"]*">'),
        '<meta name="twitter:image" content="$c">');
    return out;
  }
}

void writePage(String buildDir, String relPath, String content) {
  final file = File('$buildDir/$relPath/index.html');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

String _escape(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

String _singleLine(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
