import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import 'attachment_embed.dart';

/// Unicode Line Separator - creates a visual line break without starting a new paragraph.
const String softLineBreak = '\u2028';

/// Suffix used to identify attachment links in HTML.
const String _attachmentSuffix = '@attachment';

// =============================================================================
// Shared HTML→Delta processing mixin
// =============================================================================

/// Mixin providing common HTML element processing for Delta conversion.
mixin _HtmlElementProcessor {
  List<Map<String, dynamic>> get ops;

  void processNodes(List<dom.Node> nodes, [Map<String, dynamic>? inlineAttrs]) {
    for (final node in nodes) {
      if (node is dom.Text) {
        final text = node.text;
        if (!_isIgnorableWhitespace(text)) {
          _addText(text.replaceAll('\n', softLineBreak), inlineAttrs);
        }
      } else if (node is dom.Element) {
        _processElement(node, inlineAttrs);
      }
    }
  }

  void _processElement(dom.Element element, Map<String, dynamic>? inlineAttrs);

  void _processFormattingElement(dom.Element element, Map<String, dynamic>? inlineAttrs) {
    switch (element.localName) {
      case 'br':
        _addText(softLineBreak, inlineAttrs);
      case 'b' || 'strong':
        processNodes(element.nodes, _mergeAttrs(inlineAttrs, {'bold': true}));
      case 'i' || 'em':
        processNodes(element.nodes, _mergeAttrs(inlineAttrs, {'italic': true}));
      case 'u':
        processNodes(element.nodes, _mergeAttrs(inlineAttrs, {'underline': true}));
      case 's' || 'strike':
        processNodes(element.nodes, _mergeAttrs(inlineAttrs, {'strike': true}));
      case 'a':
        _processLink(element, inlineAttrs);
      default:
        processNodes(element.nodes, inlineAttrs);
    }
  }

  void _processLink(dom.Element element, Map<String, dynamic>? inlineAttrs) {
    final href = element.attributes['href'];
    if (href == null) {
      processNodes(element.nodes, inlineAttrs);
    } else if (href.endsWith(_attachmentSuffix)) {
      final id = href.substring(0, href.length - _attachmentSuffix.length);
      final title = element.text.trim();
      ops.add({'insert': AttachmentEmbed(id: id, title: title.isNotEmpty ? title : id).toEmbeddable().toJson()});
    } else {
      processNodes(element.nodes, _mergeAttrs(inlineAttrs, {'link': href}));
    }
  }

  void _addText(String text, [Map<String, dynamic>? attrs]) {
    if (text.isEmpty) return;
    ops.add(attrs != null && attrs.isNotEmpty
        ? {'insert': text, 'attributes': Map<String, dynamic>.from(attrs)}
        : {'insert': text});
  }
}

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

class _HtmlToDeltaConverter with _HtmlElementProcessor {
  @override
  final List<Map<String, dynamic>> ops;
  int _listIndent = 0;

  _HtmlToDeltaConverter(this.ops);

  @override
  void _processElement(dom.Element element, Map<String, dynamic>? inlineAttrs) {
    switch (element.localName) {
      case 'p':
        processNodes(element.nodes, inlineAttrs);
        _addNewline(align: _extractAlignment(element));
      case 'ul':
        _processList(element, 'bullet');
      case 'ol':
        _processList(element, 'ordered');
      default:
        _processFormattingElement(element, inlineAttrs);
    }
  }

  void _processList(dom.Element list, String listType) {
    _ensurePrecedingNewline();
    for (final child in list.nodes) {
      if (child is dom.Element && child.localName == 'li') {
        _processListItem(child, listType);
      }
    }
  }

  void _ensurePrecedingNewline() {
    if (ops.isEmpty) return;
    final lastInsert = ops.last['insert'];
    if (lastInsert is String && !lastInsert.endsWith('\n') && !lastInsert.endsWith(softLineBreak)) {
      ops.add(_newlineOp());
    }
  }

  void _processListItem(dom.Element li, String listType) {
    final itemConverter = _ListItemConverter();
    itemConverter.processNodes(li.nodes);

    ops.addAll(itemConverter.ops);
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
class _ListItemConverter with _HtmlElementProcessor {
  @override
  final List<Map<String, dynamic>> ops = [];
  String? alignment;
  bool _isFirstParagraph = true;

  @override
  void _processElement(dom.Element element, Map<String, dynamic>? inlineAttrs) {
    switch (element.localName) {
      case 'p':
        if (!_isFirstParagraph && ops.isNotEmpty) _addText(softLineBreak);
        _isFirstParagraph = false;
        alignment ??= _extractAlignment(element);
        processNodes(element.nodes, inlineAttrs);
      case 'ul' || 'ol':
        break; // Skip nested lists - handled by parent
      default:
        _processFormattingElement(element, inlineAttrs);
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

    // Handle single or multiple newlines
    if (insert == '\n') {
      _handleLineEnd(attrs, index, isLastNewlineInOp: true);
    } else if (_isOnlyNewlines(insert)) {
      // Multiple newlines with list attribute = multiple list items (some empty)
      for (int j = 0; j < insert.length; j++) {
        final isLast = j == insert.length - 1;
        _handleLineEnd(attrs, index, isLastNewlineInOp: isLast);
      }
    } else {
      _handleText(insert, attrs, index);
    }
  }

  bool _isOnlyNewlines(String text) {
    return text.isNotEmpty && text.replaceAll('\n', '').isEmpty;
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

  void _handleLineEnd(Map<String, dynamic>? attrs, int index, {required bool isLastNewlineInOp}) {
    final listType = attrs?['list'] as String?;
    final indent = (attrs?['indent'] as int?) ?? 0;

    if (listType != null) {
      _handleListLineEnd(listType, indent, index, isLastNewlineInOp: isLastNewlineInOp);
    } else {
      _closeAllLists();
      _closeParagraph();
    }
  }

  void _handleListLineEnd(String listType, int indent, int index, {required bool isLastNewlineInOp}) {
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
    
    // Only check if next text will close the list when this is the last \n in the op
    // For multi-newline ops like "\n\n", intermediate \n should always open new li
    final nextTextWillCloseList = isLastNewlineInOp ? _peekNextTextWillCloseList(index + 1) : false;
    
    if (nextListType != null && nextIndent == indent && nextListType == listType && !nextTextWillCloseList) {
      // Next item is at same level and type - close current li and open new one
      // Check if current li is empty (no paragraph was opened) - if so, add <br> for visibility
      if (!_paragraphOpen) {
        _buffer.write('<br>');
      }
      _buffer.write('</li><li>');
    } else if (nextListType != null && nextIndent < indent && !nextTextWillCloseList) {
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
  
  bool _peekNextTextWillCloseList(int startIndex) {
    for (int i = startIndex; i < ops.length; i++) {
      final op = ops[i] as Map<String, dynamic>;
      final insert = op['insert'];
      if (insert is String) {
        if (insert == '\n') return false; // This is a line ending, not text
        // Text will close the list if:
        // 1. It starts with soft break (and has content after)
        // 2. It contains hard newline in the MIDDLE (not at start)
        //    Text starting with \n is handled by _handleText which skips the empty first part
        if (insert.startsWith(softLineBreak)) {
          final textWithoutLeadingBreaks = insert.replaceAll(RegExp('^$softLineBreak+'), '');
          if (textWithoutLeadingBreaks.isNotEmpty) return true;
        }
        // Check for \n in middle (not at start)
        final textWithoutLeadingNewlines = insert.replaceAll(RegExp(r'^\n+'), '');
        if (textWithoutLeadingNewlines.contains('\n')) return true;
        return false;
      }
    }
    return false;
  }

  void _handleText(String text, Map<String, dynamic>? attrs, int index) {
    // If text contains hard newlines, split and process each part separately
    // The part before the last \n should be in paragraphs, only the last part
    // should potentially be in a list (based on the next line's attributes)
    if (text.contains('\n')) {
      final parts = text.split('\n');
      for (int i = 0; i < parts.length; i++) {
        final part = parts[i];
        final isLastPart = i == parts.length - 1;
        
        if (isLastPart) {
          // Last part - process normally with list detection
          if (part.isNotEmpty) {
            _handleTextSegment(part, attrs, index);
          }
        } else {
          // Not last part - this is a complete line
          // Skip empty parts at the beginning (e.g., text starting with \n)
          // to avoid creating empty list items or paragraphs
          if (part.isEmpty && i == 0) {
            continue;
          }
          if (_listStack.isNotEmpty) {
            _closeAllLists();
          }
          if (part.isNotEmpty) {
            _openParagraph(null);
            _writeFormattedText(part, attrs);
          }
          _closeParagraph();
        }
      }
      return;
    }
    
    _handleTextSegment(text, attrs, index);
  }

  void _handleTextSegment(String text, Map<String, dynamic>? attrs, int index) {
    // If text starts with soft break and we're in a list, close the list first
    // This prevents empty list items when text like "\u2028After list..." follows a list
    // But only if the text has more content after the soft break(s)
    if (text.startsWith(softLineBreak) && _listStack.isNotEmpty) {
      final textWithoutLeadingBreaks = text.replaceAll(RegExp('^$softLineBreak+'), '');
      if (textWithoutLeadingBreaks.isNotEmpty) {
        _closeAllLists();
        _openParagraph(null);
        _writeFormattedText(text, attrs);
        return;
      }
      // If text is only soft breaks, treat as <br> in current context (list item)
    }
    
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
    // Convert both soft line breaks and literal newlines to <br>
    var result = _escapeHtml(text).replaceAll(softLineBreak, '<br>').replaceAll('\n', '<br>');

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

final _alignmentRegex = RegExp(r'text-align:\s*(center|right|justify)');

String? _extractAlignment(dom.Element element) {
  final style = element.attributes['style'];
  if (style == null) return null;
  final match = _alignmentRegex.firstMatch(style);
  return match?.group(1);
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

    // Don't merge if either contains a hard newline (line ending)
    // Soft line breaks (softLineBreak) can be merged
    if (lastInsert is String &&
        currentInsert is String &&
        !lastInsert.contains('\n') &&
        !currentInsert.contains('\n') &&
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
