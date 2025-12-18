import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import 'attachment_embed.dart';

/// Unicode Line Separator - creates a visual line break without starting a new paragraph.
const String softLineBreak = '\u2028';

/// Suffix used to identify attachment links in HTML.
const String _attachmentSuffix = '@attachment';

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
  int _listIndent = 0;

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
    final itemConverter = _ListItemConverter(_listIndent);
    itemConverter.processNodes(li.nodes);

    final content = itemConverter.ops;
    _trimTrailingSoftBreaks(content);

    // Add the main content of this list item
    ops.addAll(content);
    _addNewline(listType: listType, align: itemConverter.alignment, indent: _listIndent > 0 ? _listIndent : null);

    // Process nested lists
    for (final child in li.nodes) {
      if (child is dom.Element && (child.localName == 'ul' || child.localName == 'ol')) {
        _listIndent++;
        _processList(child, child.localName == 'ul' ? 'bullet' : 'ordered');
        _listIndent--;
      }
    }
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
    if (href != null && href.endsWith(_attachmentSuffix)) {
      final id = href.substring(0, href.length - _attachmentSuffix.length);
      final title = element.text.trim();
      final embed = AttachmentEmbed(id: id, title: title.isNotEmpty ? title : id);
      ops.add({'insert': embed.toEmbeddable().toJson()});
    } else if (href != null) {
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

  void _addNewline({String? listType, String? align, int? indent}) {
    final attrs = <String, dynamic>{};
    if (listType != null) attrs['list'] = listType;
    if (align != null) attrs['align'] = align;
    if (indent != null && indent > 0) attrs['indent'] = indent;
    ops.add(_newlineOp(attrs));
  }
}

/// Processes content inside a `<li>` element.
/// Multiple `<p>` tags are joined with soft breaks instead of creating separate list items.
/// Nested lists are skipped here and handled by the parent converter.
class _ListItemConverter {
  final List<Map<String, dynamic>> ops = [];
  final int _currentIndent;
  String? alignment;
  bool _isFirstParagraph = true;

  _ListItemConverter(this._currentIndent);

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
      case 'ul' || 'ol':
        // Skip nested lists - they are handled by the parent converter
        break;
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
    if (href != null && href.endsWith(_attachmentSuffix)) {
      final id = href.substring(0, href.length - _attachmentSuffix.length);
      final title = element.text.trim();
      final embed = AttachmentEmbed(id: id, title: title.isNotEmpty ? title : id);
      ops.add({'insert': embed.toEmbeddable().toJson()});
    } else if (href != null) {
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

  /// Stack of list types at each nesting level (e.g., ['ordered', 'bullet'])
  final List<String> _listStack = [];
  bool _paragraphOpen = false;

  _DeltaToHtmlConverter(this.ops);

  String convert() {
    for (int i = 0; i < ops.length; i++) {
      _processOp(i);
    }
    _closeAllLists();
    _closeParagraph();
    return _buffer.toString();
  }

  void _processOp(int index) {
    final op = ops[index] as Map<String, dynamic>;
    final insert = op['insert'];

    if (insert is Map) {
      _handleEmbed(insert.cast<String, dynamic>(), index);
      return;
    }

    if (insert is! String) return;

    final attrs = op['attributes'] as Map<String, dynamic>?;

    if (insert == '\n') {
      _handleLineEnd(attrs, index);
    } else {
      _handleText(insert, attrs, index);
    }
  }

  void _handleEmbed(Map<String, dynamic> embed, int index) {
    if (embed.containsKey(attachmentEmbedType)) {
      final data = embed[attachmentEmbedType] as Map<dynamic, dynamic>?;
      if (data != null) {
        final id = data['id'] as String? ?? '';
        final title = data['title'] as String? ?? id;
        final align = _peekNextAlign(index);
        _openParagraph(align);
        _buffer.write('<a href="${_escapeHtml(id)}$_attachmentSuffix">${_escapeHtml(title)}</a>');
      }
    }
  }

  void _handleLineEnd(Map<String, dynamic>? attrs, int index) {
    final listType = attrs?['list'] as String?;
    final indent = (attrs?['indent'] as int?) ?? 0;

    if (listType != null) {
      _handleListLineEnd(listType, indent, index);
    } else {
      _closeAllLists();
      _closeParagraph();
    }
  }

  void _handleListLineEnd(String listType, int indent, int index) {
    final targetDepth = indent + 1; // indent 0 = depth 1, indent 1 = depth 2, etc.
    
    _closeParagraph();
    
    // Close lists if we're going to a shallower level
    while (_listStack.length > targetDepth) {
      _buffer.write('</li>');
      final closingType = _listStack.removeLast();
      _buffer.write(closingType == 'bullet' ? '</ul>' : '</ol>');
    }
    
    // Close and reopen if list type changed at current level
    if (_listStack.length == targetDepth && _listStack.last != listType) {
      _buffer.write('</li>');
      final closingType = _listStack.removeLast();
      _buffer.write(closingType == 'bullet' ? '</ul>' : '</ol>');
    }
    
    // Open new lists to reach target depth
    while (_listStack.length < targetDepth) {
      _buffer.write(listType == 'bullet' ? '<ul>' : '<ol>');
      _buffer.write('<li>');
      _listStack.add(listType);
    }

    // Check what comes next
    final nextAttrs = _peekNextLineAttrs(index + 1);
    final nextListType = nextAttrs?['list'] as String?;
    final nextIndent = (nextAttrs?['indent'] as int?) ?? 0;
    
    if (nextListType != null && nextIndent == indent && nextListType == listType) {
      // Next item is at same level and type - close current li and open new one
      _buffer.write('</li><li>');
    } else if (nextListType != null && nextIndent < indent) {
      // Next item is at shallower level - close this li and close nested lists down to next level
      _buffer.write('</li>');
      final nextTargetDepth = nextIndent + 1;
      while (_listStack.length > nextTargetDepth) {
        final closingType = _listStack.removeLast();
        _buffer.write(closingType == 'bullet' ? '</ul>' : '</ol>');
        _buffer.write('</li>');
      }
      _buffer.write('<li>');
    } else if (nextListType != null && nextIndent > indent) {
      // Next item is nested - don't close the li yet, nested list will go inside
    }
  }

  void _handleText(String text, Map<String, dynamic>? attrs, int index) {
    final nextAttrs = _peekNextLineAttrs(index);
    final listType = nextAttrs?['list'] as String?;
    final indent = (nextAttrs?['indent'] as int?) ?? 0;
    final align = nextAttrs?['align'] as String?;

    if (listType != null) {
      final targetDepth = indent + 1;
      
      // If we need to go deeper, open nested lists
      while (_listStack.length < targetDepth) {
        _buffer.write(listType == 'bullet' ? '<ul>' : '<ol>');
        _buffer.write('<li>');
        _listStack.add(listType);
      }
    } else if (listType == null && _listStack.isNotEmpty) {
      _closeAllLists();
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

  void _closeAllLists() {
    while (_listStack.isNotEmpty) {
      _closeParagraph();
      _buffer.write('</li>');
      final closingType = _listStack.removeLast();
      _buffer.write(closingType == 'bullet' ? '</ul>' : '</ol>');
    }
  }

  Map<String, dynamic>? _peekNextLineAttrs(int startIndex) {
    for (int i = startIndex; i < ops.length; i++) {
      final op = ops[i] as Map<String, dynamic>;
      if (op['insert'] == '\n') {
        return op['attributes'] as Map<String, dynamic>?;
      }
    }
    return null;
  }

  String? _peekNextAlign(int startIndex) {
    return _peekNextLineAttrs(startIndex)?['align'] as String?;
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
