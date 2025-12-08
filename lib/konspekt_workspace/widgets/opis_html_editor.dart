import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_bar.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/harcthought/common/file_format.dart';
import 'package:harcapp_core/harcthought/common/file_format_selector_row_widget.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/konspekt_workspace/models/konspekt_data.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'attachment_embed.dart';
import 'quill_html_converter.dart';

class OpisHtmlEditor extends StatefulWidget {
  final double? radius;
  final Color? background;
  final TextEditingController controller;
  final List<KonspektAttachmentData>? attachments;

  const OpisHtmlEditor({super.key, this.radius, this.background, required this.controller, this.attachments});

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
        borderRadius: BorderRadius.circular(widget.radius??AppCard.defRadius),
        color: widget.background??backgroundIcon_(context),
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

    final embed = AttachmentEmbed(id: attachment.effectiveId, title: attachment.displayTitle);
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
            placeholder: 'Opis:',
            customStyles: DefaultStyles(
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
            ),
            expands: false,
            scrollable: true,
            padding: EdgeInsets.zero,
            autoFocus: false,
            onKeyPressed: _handleShiftEnter,
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
                                            if (att.effectiveId.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                att.effectiveId,
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