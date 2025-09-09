import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_button.dart';
import 'package:harcapp_core/comm_widgets/app_text_field_hint.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/harcthought/common/file_format.dart';
import 'package:harcapp_core/harcthought/common/file_format_selector_row_widget.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class AttachmentWidget extends StatefulWidget{

  final VoidCallback? onRemove;

  const AttachmentWidget({super.key, this.onRemove});

  @override
  State<StatefulWidget> createState() => _AttachmentWidgetState();

}

class _AttachmentWidgetState extends State<AttachmentWidget>{

  final TextEditingController _nameController = TextEditingController();

  // Selected formats to display rows for (insertion-ordered).
  final Set<FileFormat> _selectedFormats = <FileFormat>{};

  // Picked file per format (for non-URL formats).
  final Map<FileFormat, PlatformFile?> _pickedFiles = <FileFormat, PlatformFile?>{};

  // Picked value for URL formats.
  final Map<FileFormat, String?> _pickedUrls = <FileFormat, String?>{};

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<bool> _pickFor(FileFormat format) async {
    if (_isUrl(format)) {
      final controller = TextEditingController(text: _pickedUrls[format] ?? '');
      String? url = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Podaj adres URL'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'https://...'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Anuluj')),
            TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text('OK')),
          ],
        ),
      );
      if (url != null && url.isNotEmpty) {
        setState(() => _pickedUrls[format] = url);
        return true;
      }
      return false;
    }

    // File-based picking
    final String ext = format.extension;
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [ext],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFiles[format] = result.files.single);
      return true;
    }
    return false;
  }

  bool _isUrl(FileFormat format){
    switch(format){
      case FileFormat.url:
      case FileFormat.urlPdf:
      case FileFormat.urlDocx:
      case FileFormat.urlPng:
      case FileFormat.urlWebp:
      case FileFormat.urlSvg:
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) => Material(
    borderRadius: BorderRadius.circular(AppCard.defRadius),
    color: backgroundIcon_(context),
    child: Padding(
      padding: EdgeInsets.all(Dimen.sideMarg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          Row(
            children: [
              Expanded(
                child: AppTextFieldHint(
                  hint: 'Nazwa załącznika:',
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),

              if(widget.onRemove != null)
                AppButton(
                  icon: Icon(MdiIcons.close),
                  onTap: widget.onRemove,
                )
            ],
          ),

          SizedBox(height: Dimen.sideMarg),

          // Selected formats rows
          ..._selectedFormats.map((format) => Padding(
            padding: EdgeInsets.only(bottom: Dimen.defMarg),
            child: AttachmentFileRow(
              fileFormat: format,
              pickedName: _isUrl(format)
                  ? _pickedUrls[format]
                  : _pickedFiles[format]?.name,
              onRemove: (){
                setState((){
                  _selectedFormats.remove(format);
                  _pickedFiles.remove(format);
                  _pickedUrls.remove(format);
                });
              },
            ),
          )).toList(),

          // Add new format dropdown
          Align(
            alignment: Alignment.centerLeft,
            child: PopupMenuButton<FileFormat>(
              splashRadius: AppCard.defRadius,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppCard.defRadius)),
              borderRadius: BorderRadius.circular(AppCard.defRadius),
              clipBehavior: Clip.hardEdge,
              menuPadding: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              onSelected: (format) async {
                final picked = await _pickFor(format);
                if (picked) setState(() => _selectedFormats.add(format));
              },
              itemBuilder: (context) => FileFormat.values
                  .where((f) => !_selectedFormats.contains(f))
                  .map((f) => PopupMenuItem<FileFormat>(
                        value: f,
                        padding: EdgeInsets.zero,
                        child: SimpleButton(
                          radius: AppCard.defRadius,
                          padding: EdgeInsets.all(Dimen.defMarg),
                          margin: EdgeInsets.zero,
                          onTap: null,
                          child: FileFormatWidget(f),
                        ),
                      ))
                  .toList(),
              color: background_(context),
              child: SimpleButton.from(
                context: context,
                radius: AppCard.defRadius,
                padding: EdgeInsets.all(Dimen.defMarg),
                color: backgroundIcon_(context),
                margin: EdgeInsets.zero,
                text: 'Dodaj format',
                onTap: null,
                icon: MdiIcons.chevronDown,
                iconColor: iconEnab_(context),
                iconLeading: false,
              ),
            ),
          ),

        ],
      ),
    ),
  );

}

class AttachmentFileRow extends StatelessWidget {
  final FileFormat fileFormat;
  final String? pickedName;
  final VoidCallback onRemove;

  const AttachmentFileRow({
    super.key,
    required this.fileFormat,
    required this.pickedName,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppCard.defRadius),
      color: backgroundIcon_(context)
    ),
    clipBehavior: Clip.hardEdge,
    child: Row(
      children: [

        SizedBox(width: (Dimen.iconFootprint - (Dimen.textSizeNormal + 2*Dimen.defMarg))/2),

        FileFormatWidget(fileFormat),

        SizedBox(width: Dimen.defMarg),

        Expanded(
          child: Text(
            pickedName ?? '',
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle(
              color: iconEnab_(context),
            ),
          ),
        ),

        SizedBox(width: Dimen.defMarg),

        AppButton(
          icon: Icon(MdiIcons.close),
          constraints: BoxConstraints(),
          onTap: onRemove,
        ),
      ],
    ),
  );
}