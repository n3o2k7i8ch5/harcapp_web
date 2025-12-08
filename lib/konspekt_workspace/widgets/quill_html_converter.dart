import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// Unicode Line Separator - creates a visual line break without starting a new paragraph.
const String softLineBreak = '\u2028';

// =============================================================================
// HTML → Delta
// =============================================================================

/// Converts HTML string to Quill Delta operations.
///
/// Handles:
/// - Basic formatting: bold, italic, underline, strikethrough
/// - Links
/// - Paragraphs with alignment
/// - Ordered and unordered lists
/// - Soft line breaks (`<br>`) within list items
List<Map<String, dynamic>> htmlToDeltaOps(String html) {
  if (html.trim().isEmpty) {
    return [_newlineOp()];
  }

  final document = html_parser.parse(html);
  final ops = <Map<String, dynamic>>[];

  _HtmlToDeltaConverter(ops).processNodes(document.body?.nodes ?? []);
  _ensureTrailingNewline(ops);

  return _mergeAdjacentTextOps(ops);
}

void _ensureTrailingNewline(List<Map<String, dynamic>> ops) {
  if (ops.isEmpty) {
    ops.add(_newlineOp());
    return;
  }
  final lastInsert = ops.last['insert'];
  if (lastInsert is String && !lastInsert.endsWith('\n')) {
    ops.add(_newlineOp());
  }
}

Map<String, dynamic> _newlineOp([Map<String, dynamic>? attrs]) {
  if (attrs != null && attrs.isNotEmpty) {
    return {'insert': '\n', 'attributes': attrs};
  }
  return {'insert': '\n'};
}

class _HtmlToDeltaConverter {
  final List<Map<String, dynamic>> ops;

  _HtmlToDeltaConverter(this.ops);

  void processNodes(List<dom.Node> nodes, [Map<String, dynamic>? inlineAttrs]) {
    for (final node in nodes) {
      _processNode(node, inlineAttrs);
    }
  }

  void _processNode(dom.Node node, Map<String, dynamic>? inlineAttrs) {
    if (node is dom.Text) {
      _processTextNode(node, inlineAttrs);
    } else if (node is dom.Element) {
      _processElement(node, inlineAttrs);
    }
  }

  void _processTextNode(dom.Text node, Map<String, dynamic>? inlineAttrs) {
    final text = node.text;
    if (_isIgnorableWhitespace(text)) return;
    _addText(text, inlineAttrs);
  }

  void _processElement(dom.Element element, Map<String, dynamic>? inlineAttrs) {
    switch (element.localName) {
      case 'br':
        _addText(softLineBreak);
      case 'p':
        _processParagraph(element, inlineAttrs);
      case 'ul':
        _processList(element, 'bullet');
      case 'ol':
        _processList(element, 'ordered');
      case 'b' || 'strong':
        _processWithAttr(element, inlineAttrs, 'bold', true);
      case 'i' || 'em':
        _processWithAttr(element, inlineAttrs, 'italic', true);
      case 'u':
        _processWithAttr(element, inlineAttrs, 'underline', true);
      case 's' || 'strike':
        _processWithAttr(element, inlineAttrs, 'strike', true);
      case 'a':
        _processLink(element, inlineAttrs);
      default:
        processNodes(element.nodes, inlineAttrs);
    }
  }

  void _processParagraph(dom.Element element, Map<String, dynamic>? inlineAttrs) {
    final align = _extractAlignment(element);
    processNodes(element.nodes, inlineAttrs);
    _addNewline(align: align);
  }

  void _processList(dom.Element list, String listType) {
    for (final child in list.nodes) {
      if (child is dom.Element && child.localName == 'li') {
        _processListItem(child, listType);
      }
    }
  }

  void _processListItem(dom.Element li, String listType) {
    final itemConverter = _ListItemConverter();
    itemConverter.processNodes(li.nodes);

    final content = itemConverter.ops;
    _trimTrailingSoftBreaks(content);

    ops.addAll(content);
    _addNewline(listType: listType, align: itemConverter.alignment);
  }

  void _processWithAttr(
    dom.Element element,
    Map<String, dynamic>? inlineAttrs,
    String attrName,
    dynamic attrValue,
  ) {
    final newAttrs = _mergeAttrs(inlineAttrs, {attrName: attrValue});
    processNodes(element.nodes, newAttrs);
  }

  void _processLink(dom.Element element, Map<String, dynamic>? inlineAttrs) {
    final href = element.attributes['href'];
    if (href != null) {
      final newAttrs = _mergeAttrs(inlineAttrs, {'link': href});
      processNodes(element.nodes, newAttrs);
    } else {
      processNodes(element.nodes, inlineAttrs);
    }
  }

  void _addText(String text, [Map<String, dynamic>? attrs]) {
    if (text.isEmpty) return;
    if (attrs != null && attrs.isNotEmpty) {
      ops.add({'insert': text, 'attributes': Map<String, dynamic>.from(attrs)});
    } else {
      ops.add({'insert': text});
    }
  }

  void _addNewline({String? listType, String? align}) {
    final attrs = <String, dynamic>{};
    if (listType != null) attrs['list'] = listType;
    if (align != null) attrs['align'] = align;
    ops.add(_newlineOp(attrs));
  }
}

/// Processes content inside a `<li>` element.
/// Multiple `<p>` tags are joined with soft breaks instead of creating separate list items.
class _ListItemConverter {
  final List<Map<String, dynamic>> ops = [];
  String? alignment;
  bool _isFirstParagraph = true;

  void processNodes(List<dom.Node> nodes, [Map<String, dynamic>? inlineAttrs]) {
    for (final node in nodes) {
      _processNode(node, inlineAttrs);
    }
  }

  void _processNode(dom.Node node, Map<String, dynamic>? inlineAttrs) {
    if (node is dom.Text) {
      final text = node.text;
      if (_isIgnorableWhitespace(text)) return;
      _addText(text, inlineAttrs);
    } else if (node is dom.Element) {
      _processElement(node, inlineAttrs);
    }
  }

  void _processElement(dom.Element element, Map<String, dynamic>? inlineAttrs) {
    switch (element.localName) {
      case 'br':
        _addText(softLineBreak);
      case 'p':
        _processParagraphInListItem(element, inlineAttrs);
      case 'b' || 'strong':
        _processWithAttr(element, inlineAttrs, 'bold', true);
      case 'i' || 'em':
        _processWithAttr(element, inlineAttrs, 'italic', true);
      case 'u':
        _processWithAttr(element, inlineAttrs, 'underline', true);
      case 's' || 'strike':
        _processWithAttr(element, inlineAttrs, 'strike', true);
      case 'a':
        _processLink(element, inlineAttrs);
      default:
        processNodes(element.nodes, inlineAttrs);
    }
  }

  void _processParagraphInListItem(dom.Element element, Map<String, dynamic>? inlineAttrs) {
    if (!_isFirstParagraph && ops.isNotEmpty) {
      _addText(softLineBreak);
    }
    _isFirstParagraph = false;
    alignment ??= _extractAlignment(element);
    processNodes(element.nodes, inlineAttrs);
  }

  void _processWithAttr(
    dom.Element element,
    Map<String, dynamic>? inlineAttrs,
    String attrName,
    dynamic attrValue,
  ) {
    final newAttrs = _mergeAttrs(inlineAttrs, {attrName: attrValue});
    processNodes(element.nodes, newAttrs);
  }

  void _processLink(dom.Element element, Map<String, dynamic>? inlineAttrs) {
    final href = element.attributes['href'];
    if (href != null) {
      final newAttrs = _mergeAttrs(inlineAttrs, {'link': href});
      processNodes(element.nodes, newAttrs);
    } else {
      processNodes(element.nodes, inlineAttrs);
    }
  }

  void _addText(String text, [Map<String, dynamic>? attrs]) {
    if (text.isEmpty) return;
    if (attrs != null && attrs.isNotEmpty) {
      ops.add({'insert': text, 'attributes': Map<String, dynamic>.from(attrs)});
    } else {
      ops.add({'insert': text});
    }
  }
}

// =============================================================================
// Delta → HTML
// =============================================================================

/// Converts Quill Delta operations to HTML string.
///
/// Soft breaks (`\u2028`) are converted to `<br>` tags.
String deltaOpsToHtml(List<dynamic> ops) {
  return _DeltaToHtmlConverter(ops).convert();
}

class _DeltaToHtmlConverter {
  final List<dynamic> ops;
  final StringBuffer _buffer = StringBuffer();

  bool _inList = false;
  String _currentListType = '';
  bool _paragraphOpen = false;

  _DeltaToHtmlConverter(this.ops);

  String convert() {
    for (int i = 0; i < ops.length; i++) {
      _processOp(i);
    }
    _closeList();
    _closeParagraph();
    return _buffer.toString();
  }

  void _processOp(int index) {
    final op = ops[index] as Map<String, dynamic>;
    final insert = op['insert'];
    if (insert is! String) return;

    final attrs = op['attributes'] as Map<String, dynamic>?;

    if (insert == '\n') {
      _handleLineEnd(attrs, index);
    } else {
      _handleText(insert, attrs, index);
    }
  }

  void _handleLineEnd(Map<String, dynamic>? attrs, int index) {
    final listType = attrs?['list'] as String?;

    if (listType != null) {
      _handleListLineEnd(listType, index);
    } else {
      _closeList();
      _closeParagraph();
    }
  }

  void _handleListLineEnd(String listType, int index) {
    if (!_inList || _currentListType != listType) {
      _closeList();
      _buffer.write(listType == 'bullet' ? '<ul>' : '<ol>');
      _buffer.write('<li>');
      _inList = true;
      _currentListType = listType;
    }
    _closeParagraph();

    final nextListType = _peekNextListType(index + 1);
    if (nextListType == listType) {
      _buffer.write('</li><li>');
    }
  }

  void _handleText(String text, Map<String, dynamic>? attrs, int index) {
    final listType = _peekNextListType(index);
    final align = _peekNextAlign(index);

    if (listType != null && !_inList) {
      _buffer.write(listType == 'bullet' ? '<ul>' : '<ol>');
      _buffer.write('<li>');
      _inList = true;
      _currentListType = listType;
    } else if (listType == null && _inList) {
      _closeList();
    }

    _openParagraph(align);
    _writeFormattedText(text, attrs);
  }

  void _openParagraph(String? align) {
    if (_paragraphOpen) return;
    if (align != null) {
      _buffer.write('<p style="text-align:$align;">');
    } else {
      _buffer.write('<p>');
    }
    _paragraphOpen = true;
  }

  void _closeParagraph() {
    if (!_paragraphOpen) return;
    _buffer.write('</p>');
    _paragraphOpen = false;
  }

  void _closeList() {
    if (!_inList) return;
    _closeParagraph();
    _buffer.write('</li>');
    _buffer.write(_currentListType == 'bullet' ? '</ul>' : '</ol>');
    _inList = false;
    _currentListType = '';
  }

  String? _peekNextListType(int startIndex) {
    for (int i = startIndex; i < ops.length; i++) {
      final op = ops[i] as Map<String, dynamic>;
      if (op['insert'] == '\n') {
        return (op['attributes'] as Map<String, dynamic>?)?['list'] as String?;
      }
    }
    return null;
  }

  String? _peekNextAlign(int startIndex) {
    for (int i = startIndex; i < ops.length; i++) {
      final op = ops[i] as Map<String, dynamic>;
      if (op['insert'] == '\n') {
        return (op['attributes'] as Map<String, dynamic>?)?['align'] as String?;
      }
    }
    return null;
  }

  void _writeFormattedText(String text, Map<String, dynamic>? attrs) {
    var result = _escapeHtml(text).replaceAll(softLineBreak, '<br>');

    if (attrs == null || attrs.isEmpty) {
      _buffer.write(result);
      return;
    }

    if (attrs['bold'] == true) result = '<b>$result</b>';
    if (attrs['italic'] == true) result = '<i>$result</i>';
    if (attrs['underline'] == true) result = '<u>$result</u>';
    if (attrs['strike'] == true) result = '<s>$result</s>';

    final link = attrs['link'] as String?;
    if (link != null) result = '<a href="${_escapeHtml(link)}">$result</a>';

    _buffer.write(result);
  }
}

// =============================================================================
// Utilities
// =============================================================================

bool _isIgnorableWhitespace(String text) {
  return text.trim().isEmpty && text.contains('\n');
}

Map<String, dynamic> _mergeAttrs(Map<String, dynamic>? base, Map<String, dynamic> extra) {
  return {...?base, ...extra};
}

String? _extractAlignment(dom.Element element) {
  final style = element.attributes['style'] ?? '';
  if (style.contains('text-align:center') || style.contains('text-align: center')) {
    return 'center';
  }
  if (style.contains('text-align:right') || style.contains('text-align: right')) {
    return 'right';
  }
  if (style.contains('text-align:justify') || style.contains('text-align: justify')) {
    return 'justify';
  }
  return null;
}

void _trimTrailingSoftBreaks(List<Map<String, dynamic>> ops) {
  while (ops.isNotEmpty) {
    final last = ops.last['insert'];
    if (last == softLineBreak || last == '\n') {
      ops.removeLast();
    } else if (last is String && last.endsWith(softLineBreak)) {
      final trimmed = last.substring(0, last.length - 1);
      if (trimmed.isEmpty) {
        ops.removeLast();
      } else {
        ops.last['insert'] = trimmed;
      }
    } else {
      break;
    }
  }
}

List<Map<String, dynamic>> _mergeAdjacentTextOps(List<Map<String, dynamic>> ops) {
  if (ops.isEmpty) return ops;

  final merged = <Map<String, dynamic>>[];
  for (final op in ops) {
    if (merged.isEmpty) {
      merged.add(Map<String, dynamic>.from(op));
      continue;
    }

    final last = merged.last;
    final lastInsert = last['insert'];
    final currentInsert = op['insert'];

    if (lastInsert is String &&
        currentInsert is String &&
        _attrsEqual(last['attributes'], op['attributes'])) {
      merged.last['insert'] = lastInsert + currentInsert;
    } else {
      merged.add(Map<String, dynamic>.from(op));
    }
  }

  return merged;
}

bool _attrsEqual(dynamic a, dynamic b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  if (a is! Map || b is! Map) return false;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (a[key] != b[key]) return false;
  }
  return true;
}

String _escapeHtml(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}
