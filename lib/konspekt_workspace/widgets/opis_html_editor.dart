import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

class OpisHtmlEditor extends StatefulWidget {
  final TextEditingController controller;

  const OpisHtmlEditor({super.key, required this.controller});

  @override
  State<OpisHtmlEditor> createState() => _OpisHtmlEditorState();
}

class _OpisHtmlEditorState extends State<OpisHtmlEditor> {
  late final QuillController _quillController;

  @override
  void initState() {
    super.initState();
    _quillController = _createController(widget.controller.text);
    _quillController.document.changes.listen((_) {
      _syncToTextController();
    });
  }

  @override
  void didUpdateWidget(covariant OpisHtmlEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jeśli zewnętrzny controller się zmienił (np. wczytano nowy konspekt),
    // zaktualizuj zawartość edytora
    if (oldWidget.controller != widget.controller) {
      final newDoc = _htmlToDelta(widget.controller.text);
      _quillController.document = newDoc;
    }
  }

  @override
  void dispose() {
    _quillController.dispose();
    super.dispose();
  }

  QuillController _createController(String html) {
    final doc = _htmlToDelta(html);
    return QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  Document _htmlToDelta(String html) {
    if (html.trim().isEmpty) {
      return Document();
    }
    try {
      final delta = HtmlToDelta().convert(html);
      return Document.fromDelta(delta);
    } catch (_) {
      return Document();
    }
  }

  void _syncToTextController() {
    final delta = _quillController.document.toDelta();
    final ops = delta.toJson();
    final converter = QuillDeltaToHtmlConverter(
      List<Map<String, dynamic>>.from(ops),
      ConverterOptions.forEmail(),
    );
    widget.controller.text = converter.convert();
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
              // Toolbar
              Material(
                color: backgroundIcon_(context),
                borderRadius: BorderRadius.circular(AppCard.defRadius),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: QuillSimpleToolbar(
                    controller: _quillController,
                    config: const QuillSimpleToolbarConfig(
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
              ),

              const SizedBox(height: Dimen.defMarg),

              // Editor
              Container(
                constraints: const BoxConstraints(minHeight: 200),
                decoration: BoxDecoration(
                  color: background_(context),
                  borderRadius: BorderRadius.circular(AppCard.defRadius),
                ),
                padding: EdgeInsets.all(Dimen.defMarg),
                child: QuillEditor.basic(
                  controller: _quillController,
                  config: const QuillEditorConfig(
                    placeholder: 'Opis:',
                    expands: false,
                    scrollable: false,
                    padding: EdgeInsets.zero,
                    autoFocus: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}