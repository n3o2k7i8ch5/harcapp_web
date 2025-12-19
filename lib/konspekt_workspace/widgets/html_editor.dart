import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' as html_widget;
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_bar.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/harcthought/common/file_format.dart';
import 'package:harcapp_core/harcthought/common/file_format_selector_row_widget.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/konspekt_workspace/models/konspekt_attachment_data.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'attachment_embed.dart';
import 'quill_html_converter.dart';

enum _DebugViewMode { editor, delta, html, preview }

class HtmlEditor extends StatefulWidget {
  final double? radius;
  final Color? background;
  final TextEditingController controller;
  final String? placeholder;
  final List<KonspektAttachmentData>? attachments;
  final bool showToolbar;
  final bool showDebugButtons;
  final VoidCallback? onChanged;

  const HtmlEditor({super.key, this.radius, this.background, required this.controller, this.placeholder, this.attachments, this.showToolbar = true, this.showDebugButtons = true, this.onChanged});

  @override
  State<HtmlEditor> createState() => _HtmlEditorState();
}

class _HtmlEditorState extends State<HtmlEditor> {
  static const _editorMinHeight = 100.0;
  static const _editorMaxHeight = 500.0;

  late final QuillController _quillController;
  late final ScrollController _scrollController;
  late final FocusNode _focusNode;
  _DebugViewMode _debugViewMode = _DebugViewMode.editor;

  @override
  void initState() {
    super.initState();
    _quillController = _createQuillController(widget.controller.text);
    _scrollController = ScrollController();
    _focusNode = FocusNode();
    _quillController.document.changes.listen((event) {
      _handleListFormatChange(event);
      _syncToTextController();
      widget.onChanged?.call();
    });
    // Sync immediately to normalize HTML (e.g., convert soft breaks to <br>)
    _syncToTextController();
  }

  /// When list formatting is applied to a line that contains soft line breaks
  /// and that line was NOT previously a list item, convert soft breaks to hard
  /// newlines so only the segment at cursor becomes a list item.
  void _handleListFormatChange(DocChange event) {
    final change = event.change;
    if (change.isEmpty) return;
    
    // Check if this change applies list formatting
    Attribute? listAttribute;
    for (final op in change.toList()) {
      final attrs = op.attributes;
      if (attrs != null && attrs.containsKey('list')) {
        final listValue = attrs['list'];
        if (listValue == 'ordered') {
          listAttribute = Attribute.ol;
        } else if (listValue == 'bullet') {
          listAttribute = Attribute.ul;
        } else if (listValue == 'checked') {
          listAttribute = Attribute.checked;
        } else if (listValue == 'unchecked') {
          listAttribute = Attribute.unchecked;
        }
        break;
      }
    }
    if (listAttribute == null) return;
    
    // Find the line where list was applied
    final selection = _quillController.selection;
    final doc = _quillController.document;
    
    final lineResult = doc.queryChild(selection.baseOffset);
    final line = lineResult.node;
    if (line is! Line) return;
    
    // Get the plain text of this line (without trailing \n)
    final plainText = line.toPlainText();
    final textWithoutNewline = plainText.endsWith('\n') 
        ? plainText.substring(0, plainText.length - 1) 
        : plainText;
    
    // Only process if line contains soft breaks
    if (!textWithoutNewline.contains(softLineBreak)) return;
    
    // Check if this is a pure format change (clicking list button), not a delete/backspace
    // A format change on existing content uses retain with attributes and NO delete operations
    bool hasDelete = false;
    bool hasRetainWithListAttr = false;
    for (final op in change.toList()) {
      if (op.isDelete) {
        hasDelete = true;
        break;
      }
      if (op.isRetain && op.attributes != null && op.attributes!.containsKey('list')) {
        hasRetainWithListAttr = true;
      }
    }
    // Only process if this is a pure format change (no delete = not backspace)
    if (hasDelete || !hasRetainWithListAttr) return;
    
    // Find which segment the cursor is in
    final lineStart = line.documentOffset;
    final cursorOffsetInLine = selection.baseOffset - lineStart;
    
    // Split at soft breaks and find cursor segment
    final parts = textWithoutNewline.split(softLineBreak);
    if (parts.length <= 1) return;
    
    int currentOffset = 0;
    int cursorSegmentIndex = parts.length - 1; // default to last
    for (int i = 0; i < parts.length; i++) {
      final segmentEnd = currentOffset + parts[i].length;
      if (cursorOffsetInLine <= segmentEnd) {
        cursorSegmentIndex = i;
        break;
      }
      currentOffset = segmentEnd + 1; // +1 for the soft break
    }
    
    // Build new text: parts before cursor segment, then \n, then cursor segment, then \n, then parts after
    final beforeCursor = parts.sublist(0, cursorSegmentIndex).join(softLineBreak);
    final cursorPart = parts[cursorSegmentIndex];
    final afterCursor = parts.sublist(cursorSegmentIndex + 1).join(softLineBreak);
    
    // Remove list attribute first
    _quillController.document.format(lineStart, 0, Attribute.clone(listAttribute, null));
    
    // Build replacement text
    final buffer = StringBuffer();
    int listPartStart = 0;
    
    if (beforeCursor.isNotEmpty) {
      buffer.write(beforeCursor);
      buffer.write('\n');
      listPartStart = beforeCursor.length + 1;
    }
    
    buffer.write(cursorPart);
    
    if (afterCursor.isNotEmpty) {
      buffer.write('\n');
      buffer.write(afterCursor);
    }
    
    final newText = buffer.toString();
    
    _quillController.replaceText(
      lineStart,
      textWithoutNewline.length,
      newText,
      TextSelection.collapsed(offset: lineStart + listPartStart + cursorPart.length),
    );
    
    // Apply list to the cursor segment only
    _quillController.document.format(lineStart + listPartStart, 0, listAttribute);
  }

  @override
  void didUpdateWidget(covariant HtmlEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _quillController.document = _parseHtml(widget.controller.text);
    }
  }

  @override
  void dispose() {
    _quillController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  QuillController _createQuillController(String html) => QuillController(
        document: _parseHtml(html),
        selection: const TextSelection.collapsed(offset: 0),
      );

  Document _parseHtml(String html) {
    if (html.trim().isEmpty) return Document();
    try {
      return Document.fromJson(htmlToDeltaOps(html));
    } catch (_) {
      return Document()..insert(0, html);
    }
  }

  void _syncToTextController() {
    widget.controller.text = deltaOpsToHtml(
      _quillController.document.toDelta().toJson(),
    );
  }

  KeyEventResult? _handleKeyPressed(KeyEvent event, Node? node) {
    final shiftEnter = _handleShiftEnter(event, node);
    if (shiftEnter != null) return shiftEnter;

    final backspaceUnlist = _handleBackspaceUnlist(event, node);
    if (backspaceUnlist != null) return backspaceUnlist;

    return null;
  }

  KeyEventResult? _handleShiftEnter(KeyEvent event, Node? node) {
    final isShiftEnter = event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        HardwareKeyboard.instance.isShiftPressed;

    if (!isShiftEnter) return null;

    final selection = _quillController.selection;
    _quillController.replaceText(
      selection.baseOffset,
      selection.extentOffset - selection.baseOffset,
      softLineBreak,
      TextSelection.collapsed(offset: selection.baseOffset + 1),
    );
    return KeyEventResult.handled;
  }

  /// Handles Backspace at the start of a list item to remove list formatting.
  KeyEventResult? _handleBackspaceUnlist(KeyEvent event, Node? node) {
    if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.backspace) return null;

    final selection = _quillController.selection;
    if (!selection.isCollapsed) return null;

    // Find the current line
    Line? line = node is Line ? node : null;
    if (line == null) {
      final childNode = _quillController.document.queryChild(selection.baseOffset).node;
      if (childNode is Line) line = childNode;
    }
    if (line == null) return null;

    // Handle boundary case: queryChild may return previous line
    int posInLine = selection.baseOffset - line.documentOffset;
    if (posInLine == line.length) {
      line = line.nextLine;
      if (line == null) return null;
      posInLine = selection.baseOffset - line.documentOffset;
    }

    // Only handle if cursor is at start of a list item
    if (posInLine != 0) return null;
    final listAttr = line.style.attributes[Attribute.list.key];
    if (listAttr == null) return null;

    // Remove list (and indent if present) from this line only
    _quillController.document.format(line.documentOffset, 0, Attribute.clone(listAttr, null));
    final indentAttr = line.style.attributes[Attribute.indent.key];
    if (indentAttr != null) {
      _quillController.document.format(line.documentOffset, 0, Attribute.clone(indentAttr, null));
    }

    _quillController.updateSelection(selection, ChangeSource.local);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Material(
        borderRadius: BorderRadius.circular(widget.radius??AppCard.defRadius),
        color: widget.background??backgroundIcon_(context),
        child: Padding(
          padding: EdgeInsets.all(Dimen.defMarg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.showToolbar) ...[
                _buildToolbar(context),
                const SizedBox(height: Dimen.defMarg),
              ],
              _buildEditorOrDebugView(context),
              if (widget.showDebugButtons) ...[
                const SizedBox(height: Dimen.defMarg),
                _buildDebugButtons(context),
              ],
            ],
          ),
        ),
      );

  Widget _buildEditorOrDebugView(BuildContext context) {
    switch (_debugViewMode) {
      case _DebugViewMode.editor:
        return _buildEditor(context);
      case _DebugViewMode.delta:
        return _buildDebugDeltaView(context);
      case _DebugViewMode.html:
        return _buildDebugHtmlView(context);
      case _DebugViewMode.preview:
        return _buildPreviewView(context);
    }
  }

  Widget _buildDebugButtons(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _DebugModeButton(
            label: 'Edytor',
            icon: Icons.edit,
            isSelected: _debugViewMode == _DebugViewMode.editor,
            onTap: () => setState(() => _debugViewMode = _DebugViewMode.editor),
          ),
          const SizedBox(width: Dimen.defMarg),
          _DebugModeButton(
            label: 'Delta',
            icon: MdiIcons.codeBraces,
            isSelected: _debugViewMode == _DebugViewMode.delta,
            onTap: () => setState(() => _debugViewMode = _DebugViewMode.delta),
          ),
          const SizedBox(width: Dimen.defMarg),
          _DebugModeButton(
            label: 'HTML',
            icon: MdiIcons.languageHtml5,
            isSelected: _debugViewMode == _DebugViewMode.html,
            onTap: () => setState(() => _debugViewMode = _DebugViewMode.html),
          ),
          const Spacer(),
          _DebugModeButton(
            label: 'Podgląd',
            icon: Icons.visibility,
            isSelected: _debugViewMode == _DebugViewMode.preview,
            onTap: () => setState(() => _debugViewMode = _DebugViewMode.preview),
          ),
        ],
      );

  Widget _buildDebugDeltaView(BuildContext context) {
    final delta = _quillController.document.toDelta().toJson();
    final buffer = StringBuffer();
    for (var i = 0; i < delta.length; i++) {
      final op = delta[i];
      final insert = op['insert'];
      final attrs = op['attributes'];
      
      String insertStr;
      if (insert is String) {
        insertStr = insert
            .replaceAll('\n', '\\n')
            .replaceAll(softLineBreak, '\\u2028');
      } else {
        insertStr = insert.toString();
      }
      
      buffer.write('[$i] insert: "$insertStr"');
      if (attrs != null) {
        buffer.write(', attrs: $attrs');
      }
      buffer.writeln();
    }
    
    return _buildDebugTextContainer(context, buffer.toString());
  }

  Widget _buildDebugHtmlView(BuildContext context) {
    final html = deltaOpsToHtml(_quillController.document.toDelta().toJson());
    return _buildDebugTextContainer(context, html);
  }

  Widget _buildPreviewView(BuildContext context) {
    final html = deltaOpsToHtml(_quillController.document.toDelta().toJson());
    return Container(
      constraints: const BoxConstraints(
        minHeight: _editorMinHeight,
        maxHeight: _editorMaxHeight,
      ),
      decoration: BoxDecoration(
        color: background_(context),
        borderRadius: BorderRadius.circular(AppCard.defRadius),
      ),
      padding: EdgeInsets.all(Dimen.defMarg),
      child: SingleChildScrollView(
        child: html_widget.HtmlWidget(
          html,
          textStyle: TextStyle(
            fontSize: Dimen.textSizeBig,
            color: textEnab_(context),
          ),
        ),
      ),
    );
  }

  Widget _buildDebugTextContainer(BuildContext context, String text) => Container(
        constraints: const BoxConstraints(
          minHeight: _editorMinHeight,
          maxHeight: _editorMaxHeight,
        ),
        decoration: BoxDecoration(
          color: background_(context),
          borderRadius: BorderRadius.circular(AppCard.defRadius),
        ),
        padding: EdgeInsets.all(Dimen.defMarg),
        child: SingleChildScrollView(
          child: SelectableText(
            text,
            style: TextStyle(
              fontSize: Dimen.textSizeSmall,
              color: textEnab_(context),
              fontFamily: 'monospace',
            ),
          ),
        ),
      );

  Widget _buildToolbar(BuildContext context) => Material(
        color: backgroundIcon_(context),
        borderRadius: BorderRadius.circular(AppCard.defRadius),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              QuillSimpleToolbar(
                controller: _quillController,
                config: QuillSimpleToolbarConfig(
                  buttonOptions: QuillSimpleToolbarButtonOptions(
                    base: QuillToolbarBaseButtonOptions(
                      iconTheme: QuillIconTheme(
                        iconButtonSelectedData: IconButtonData(
                          style: ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(
                              iconEnab_(context),
                            ),
                            foregroundColor: WidgetStatePropertyAll(
                              background_(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  showBoldButton: true,
                  showItalicButton: true,
                  showUnderLineButton: true,
                  showStrikeThrough: false,
                  showInlineCode: false,
                  showColorButton: false,
                  showBackgroundColorButton: false,
                  showClearFormat: false,
                  showAlignmentButtons: true,
                  showHeaderStyle: false,
                  showListNumbers: true,
                  showListBullets: true,
                  showListCheck: false,
                  showCodeBlock: false,
                  showQuote: false,
                  showIndent: false,
                  showLink: false,
                  showUndo: false,
                  showRedo: false,
                  showDirection: false,
                  showSearchButton: false,
                  showSubscript: false,
                  showSuperscript: false,
                  showClipboardCut: false,
                  showClipboardCopy: false,
                  showClipboardPaste: false,
                  showFontFamily: false,
                  showFontSize: false,
                ),
              ),
              if (widget.attachments != null)
                _AttachmentButton(
                  attachments: widget.attachments!,
                  onAttachmentSelected: _insertAttachmentLink,
                ),
            ],
          ),
        ),
      );

  void _insertAttachmentLink(KonspektAttachmentData attachment) {
    final selection = _quillController.selection;
    final index = selection.baseOffset;
    final length = selection.extentOffset - selection.baseOffset;

    final embed = AttachmentEmbed(id: attachment.name, title: attachment.displayTitle);
    _quillController.replaceText(
      index,
      length,
      embed.toEmbeddable(),
      TextSelection.collapsed(offset: index + 1),
    );
  }

  Widget _buildEditor(BuildContext context) => Container(
        constraints: const BoxConstraints(
          minHeight: _editorMinHeight,
          maxHeight: _editorMaxHeight,
        ),
        decoration: BoxDecoration(
          color: background_(context),
          borderRadius: BorderRadius.circular(AppCard.defRadius),
        ),
        padding: EdgeInsets.all(Dimen.defMarg),
        child: QuillEditor(
          controller: _quillController,
          scrollController: _scrollController,
          focusNode: _focusNode,
          config: QuillEditorConfig(
            placeholder: widget.placeholder,
            customStyles: DefaultStyles(
              paragraph: DefaultTextBlockStyle(
                AppTextStyle(
                  fontSize: Dimen.textSizeBig,
                  color: textEnab_(context),
                ),
                HorizontalSpacing.zero,
                VerticalSpacing.zero,
                VerticalSpacing.zero,
                null,
              ),
              placeHolder: DefaultTextBlockStyle(
                AppTextStyle(
                  fontSize: Dimen.textSizeBig,
                  color: hintEnab_(context),
                ),
                HorizontalSpacing.zero,
                VerticalSpacing.zero,
                VerticalSpacing.zero,
                null,
              ),
              lists: DefaultListBlockStyle(
                AppTextStyle(
                  fontSize: Dimen.textSizeBig,
                  color: textEnab_(context),
                ),
                HorizontalSpacing.zero,
                const VerticalSpacing(8, 12),
                const VerticalSpacing(6, 2),
                null,
                null,
              ),
            ),
            expands: false,
            scrollable: true,
            padding: EdgeInsets.zero,
            autoFocus: false,
            onKeyPressed: _handleKeyPressed,
            onLaunchUrl: (_) {},
            embedBuilders: [
              AttachmentEmbedBuilder(),
            ],
          ),
        ),
      );
}

class _AttachmentButton extends StatelessWidget {
  final List<KonspektAttachmentData> attachments;
  final void Function(KonspektAttachmentData attachment) onAttachmentSelected;

  const _AttachmentButton({
    required this.attachments,
    required this.onAttachmentSelected,
  });

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(MdiIcons.paperclip),
        tooltip: 'Wstaw link do załącznika',
        onPressed: () => _showAttachmentDialog(context),
      );

  Future<void> _showAttachmentDialog(BuildContext context) async {
    final KonspektAttachmentData? selected = await showDialog<KonspektAttachmentData>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: EdgeInsets.all(Dimen.defMarg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Material(
            borderRadius: BorderRadius.circular(AppCard.bigRadius),
            color: background_(dialogContext),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppBarX(
                    backgroundColor: backgroundIcon_(dialogContext),
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppCard.bigRadius),
                      ),
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: iconEnab_(dialogContext),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                    title: 'Wybierz załącznik',
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(Dimen.sideMarg),
                      child: attachments.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  MdiIcons.paperclip,
                                  size: 48,
                                  color: hintEnab_(dialogContext),
                                ),
                                SizedBox(height: Dimen.defMarg),
                                Text(
                                  'Brak załączników do dodania',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyle(
                                    color: hintEnab_(dialogContext),
                                    fontSize: Dimen.textSizeBig,
                                  ),
                                ),
                              ],
                            )
                          : SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: attachments.map((att) {
                                  final Set<FileFormat> formats = {
                                    ...att.pickedFiles.keys,
                                    ...att.pickedUrls.keys,
                                  };

                                  return Padding(
                                    padding: EdgeInsets.only(bottom: Dimen.defMarg),
                                    child: SimpleButton(
                                      color: backgroundIcon_(dialogContext),
                                      radius: AppCard.defRadius,
                                      clipBehavior: Clip.hardEdge,
                                      onTap: () => Navigator.of(dialogContext).pop(att),
                                      child: Padding(
                                        padding: EdgeInsets.all(Dimen.defMarg),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              att.displayTitle,
                                              style: AppTextStyle(
                                                color: iconEnab_(dialogContext),
                                                fontSize: Dimen.textSizeBig,
                                                fontWeight: weightHalfBold,
                                                fontStyle: att.hasTitle
                                                    ? FontStyle.normal
                                                    : FontStyle.italic,
                                              ),
                                            ),
                                            if (att.name.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                att.name,
                                                style: AppTextStyle(
                                                  color: hintEnab_(dialogContext),
                                                  fontSize: Dimen.textSizeSmall,
                                                ),
                                              ),
                                            ],
                                            if (formats.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: formats
                                                    .map((format) => Padding(
                                                          padding: EdgeInsets.only(
                                                              right: Dimen.defMarg / 2),
                                                          child: FileFormatWidget(format),
                                                        ))
                                                    .toList(),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (selected != null) {
      onAttachmentSelected(selected);
    }
  }
}

class _DebugModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _DebugModeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SimpleButton(
        padding: EdgeInsets.symmetric(
          horizontal: Dimen.defMarg * 1.5,
          vertical: Dimen.defMarg,
        ),
        color: isSelected ? iconEnab_(context) : backgroundIcon_(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? background_(context) : textEnab_(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyle(
                fontSize: Dimen.textSizeSmall,
                color: isSelected ? background_(context) : textEnab_(context),
              ),
            ),
          ],
        ),
        onTap: onTap,
      );
}