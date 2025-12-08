import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/values/dimen.dart';

import 'quill_html_converter.dart';

class OpisHtmlEditor extends StatefulWidget {
  final TextEditingController controller;

  const OpisHtmlEditor({super.key, required this.controller});

  @override
  State<OpisHtmlEditor> createState() => _OpisHtmlEditorState();
}

class _OpisHtmlEditorState extends State<OpisHtmlEditor> {
  static const _editorMinHeight = 100.0;
  static const _editorMaxHeight = 500.0;

  late final QuillController _quillController;
  late final ScrollController _scrollController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _quillController = _createQuillController(widget.controller.text);
    _scrollController = ScrollController();
    _focusNode = FocusNode();
    _quillController.document.changes.listen((_) => _syncToTextController());
  }

  @override
  void didUpdateWidget(covariant OpisHtmlEditor oldWidget) {
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

  @override
  Widget build(BuildContext context) => Material(
        borderRadius: BorderRadius.circular(AppCard.defRadius),
        color: backgroundIcon_(context),
        child: Padding(
          padding: EdgeInsets.all(Dimen.defMarg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildToolbar(context),
              const SizedBox(height: Dimen.defMarg),
              _buildEditor(context),
            ],
          ),
        ),
      );

  Widget _buildToolbar(BuildContext context) => Material(
        color: backgroundIcon_(context),
        borderRadius: BorderRadius.circular(AppCard.defRadius),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: QuillSimpleToolbar(
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
              showAlignmentButtons: false,
              showLeftAlignment: true,
              showCenterAlignment: true,
              showRightAlignment: true,
              showJustifyAlignment: true,
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
        ),
      );

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
            placeholder: 'Opis:',
            expands: false,
            scrollable: true,
            padding: EdgeInsets.zero,
            autoFocus: false,
            onKeyPressed: _handleShiftEnter,
          ),
        ),
      );
}