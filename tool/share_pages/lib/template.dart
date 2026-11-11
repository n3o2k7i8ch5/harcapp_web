import 'dart:io';

import 'package:html_unescape/html_unescape.dart';

class ShareTemplate {
  final String _html;
  ShareTemplate._(this._html);

  static ShareTemplate load(String path) =>
      ShareTemplate._(File(path).readAsStringSync());

  /// Canonical URLs of the rendered pages meant for search engines, in render
  /// order — written into sitemap.xml after all pages are generated.
  final Set<String> sitemapUrls = {};

  /// [content] is the page's text as HTML (build it with [HtmlText]); it goes
  /// into the template's #seo-content block, which search engines read and
  /// users never see (they get the Flutter app). Without it the block gets just
  /// the title and description.
  String render({
    required String pageUrl,
    required String pageTitle,
    required String pageDescription,
    required String coverUrl,
    String? content,
    bool inSitemap = true,
  }) {
    final t = _escape(pageTitle);
    final d = _escape(_singleLine(pageDescription));
    final u = _escape(pageUrl);
    final c = _escape(coverUrl);

    if (inSitemap) sitemapUrls.add(pageUrl);

    final body = content ??
        (HtmlText()
              ..h1(pageTitle)
              ..p(pageDescription))
            .toString();

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
    out = out.replaceFirstMapped(
        RegExp(r'<!-- seo-content:start -->[\s\S]*?<!-- seo-content:end -->'),
        (_) => '<!-- seo-content:start -->\n'
            '  <div id="seo-content">\n$body  </div>\n'
            '  <!-- seo-content:end -->');
    return out;
  }
}

/// Builds the plain HTML text of a page. Every input is text (HTML in it, as in
/// konspekt steps, is reduced to text), so nothing from the data can break the
/// page.
class HtmlText {
  final StringBuffer _b = StringBuffer();

  void h1(String text) => _tag('h1', text);
  void h2(String text) => _tag('h2', text);
  void h3(String text) => _tag('h3', text);

  void p(String? text) {
    if (text == null) return;
    for (final para in htmlToText(text).split('\n')) {
      _tag('p', para);
    }
  }

  void list(Iterable<String> items, {bool ordered = false}) {
    final texts = items.map(htmlToText).where((t) => t.isNotEmpty).toList();
    if (texts.isEmpty) return;
    final tag = ordered ? 'ol' : 'ul';
    _b.writeln('    <$tag>');
    for (final t in texts) {
      _b.writeln('      <li>${_escape(_singleLine(t))}</li>');
    }
    _b.writeln('    </$tag>');
  }

  void link(String href, String text) =>
      _b.writeln('    <p><a href="${_escape(href)}">${_escape(text)}</a></p>');

  void _tag(String tag, String text) {
    final t = _singleLine(htmlToText(text));
    if (t.isNotEmpty) _b.writeln('    <$tag>${_escape(t)}</$tag>');
  }

  @override
  String toString() => _b.toString();
}

final _unescape = HtmlUnescape();

/// HTML (or plain text) → plain text; block ends become line breaks.
String htmlToText(String s) {
  s = s.replaceAll(
      RegExp(r'<br\s*/?>|</(p|div|li|h\d)>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'<[^>]*>'), '');
  s = _unescape.convert(s);
  return s
      .split('\n')
      .map(_singleLine)
      .where((l) => l.isNotEmpty)
      .join('\n');
}

/// Writes the page served at [path] (as in a link, possibly URL-encoded).
void writePage(String buildDir, String path, String content) {
  path = Uri.decodeFull(path);
  if (path.startsWith('/')) path = path.substring(1);
  final file = File('$buildDir/$path/index.html');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

/// Writes [buildDir]/sitemap.xml listing [urls]. Returns their number.
int writeSitemap(String buildDir, Iterable<String> urls) {
  final b = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<!-- Generated by tool/share_pages at deploy. -->')
    ..writeln(
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');
  for (final u in urls) {
    b.writeln('  <url><loc>${_escape(u)}</loc></url>');
  }
  b.writeln('</urlset>');
  File('$buildDir/sitemap.xml').writeAsStringSync(b.toString());
  return urls.length;
}

String _escape(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

String _singleLine(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
