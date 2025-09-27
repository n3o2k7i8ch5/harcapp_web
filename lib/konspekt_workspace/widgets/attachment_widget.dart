import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_button.dart';
import 'package:harcapp_core/comm_widgets/app_dropdown.dart';
import 'package:harcapp_core/comm_widgets/app_text_field_hint.dart';
import 'package:harcapp_core/comm_widgets/title_show_row_widget.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/harcthought/common/file_format.dart';
import 'package:harcapp_core/harcthought/common/file_format_selector_row_widget.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/konspekt_workspace/models/konspekt_data.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class AttachmentWidget extends StatefulWidget{

  final KonspektAttachmentData data;
  final void Function() onChange;
  final VoidCallback? onRemove;

  const AttachmentWidget({super.key, required this.data, required this.onChange, this.onRemove});

  @override
  State<StatefulWidget> createState() => _AttachmentWidgetState();

}

class _AttachmentWidgetState extends State<AttachmentWidget>{

  TextEditingController get titleController => widget.data.titleController;
  Map<FileFormat, PlatformFile?> get pickedFiles => widget.data.pickedFiles;
  Map<FileFormat, String?> get pickedUrls => widget.data.pickedUrls;

  Set<FileFormat> get selectedFormats{
    Set<FileFormat> data = {};
    data.addAll(pickedFiles.keys);
    data.addAll(pickedUrls.keys);
    return data;
  }

  bool get printInfoEnabled => widget.data.printInfoEnabled;
  set printInfoEnabled(bool value) => widget.data.printInfoEnabled = value;

  KonspektAttachmentPrintSide get printSide => widget.data.printSide;
  set printSide(KonspektAttachmentPrintSide value) => widget.data.printSide = value;

  KonspektAttachmentPrintColor get printColor => widget.data.printColor;
  set printColor(KonspektAttachmentPrintColor value) => widget.data.printColor = value;

  Future<bool> _pickFor(FileFormat format) async {
    if (format.isUrl) {
      final controller = TextEditingController(text: pickedUrls[format] ?? '');
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
        setState(() => pickedUrls[format] = url);
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
      setState(() => pickedFiles[format] = result.files.single);
      return true;
    }
    return false;
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
                  controller: titleController,
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
          ...selectedFormats.map((format) => Padding(
            padding: EdgeInsets.only(bottom: Dimen.defMarg),
            child: AttachmentFileRow(
              fileFormat: format,
              pickedName: format.isUrl
                  ? pickedUrls[format]
                  : pickedFiles[format]?.name,
              onRemove: (){
                setState((){
                  pickedFiles.remove(format);
                  pickedUrls.remove(format);
                });
              },
            ),
          )).toList(),

          // Add new format dropdown
          Align(
            alignment: Alignment.centerLeft,
            child: AppDropdown<FileFormat>(
              position: PopupMenuPosition.over,
              onSelected: (format) {
                _pickFor(format).then((picked){
                  if (picked)
                    setState(() =>
                      format.isUrl?
                      pickedUrls[format] = null:
                      pickedFiles[format] = null
                    );
                });
              },
              itemBuilder: (context) => FileFormat.values
                  .where((f) => !selectedFormats.contains(f))
                  .map((f) => AppDropdownButton<FileFormat>(context, f))
                  .toList(),
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

          SizedBox(height: Dimen.sideMarg),

          // Printing section (toggleable)
          if(!printInfoEnabled)
            SimpleButton.from(
              context: context,
              radius: AppCard.defRadius,
              padding: EdgeInsets.all(Dimen.defMarg),
              color: backgroundIcon_(context),
              margin: EdgeInsets.zero,
              text: 'Dodaj informacje o drukowaniu',
              onTap: () => setState(() => printInfoEnabled = true),
              icon: MdiIcons.printer,
              iconColor: iconEnab_(context),
            )
          else
            Material(
              borderRadius: BorderRadius.circular(AppCard.defRadius),
              color: backgroundIcon_(context),
              clipBehavior: Clip.hardEdge,
              child: Padding(
                padding: EdgeInsets.all(Dimen.defMarg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TitleShortcutRowWidget(
                            title: 'Jak drukować:',
                            textAlign: TextAlign.left,
                            icon: MdiIcons.printer,
                            iconColor: hintEnab_(context),
                            titleColor: hintEnab_(context),
                          ),
                        ),
                        AppButton(
                          icon: Icon(MdiIcons.close),
                          onTap: () => setState(() => printInfoEnabled = false),
                        ),
                      ],
                    ),

                    SizedBox(height: Dimen.defMarg),

                    Row(
                      children: [

                        Expanded(
                          child: AppDropdown<KonspektAttachmentPrintSide>(
                            position: PopupMenuPosition.over,
                            onSelected: (val){
                              widget.onChange.call();
                              setState(() => printSide = val);
                            },
                            itemBuilder: (context) => KonspektAttachmentPrintSide.values
                              .map((value) => AppDropdownButton<KonspektAttachmentPrintSide>(
                                context,
                                value,
                              )).toList(),
                            borderRadius: BorderRadius.circular(AppCard.defRadius),
                            child: SimpleButton.from(
                              context: context,
                              radius: AppCard.defRadius,
                              padding: EdgeInsets.all(Dimen.defMarg),
                              textColor: iconEnab_(context),
                              color: background_(context),
                              margin: EdgeInsets.zero,
                              text: printSide.displayName,
                              fontWeight: weightNormal,
                              onTap: null,
                              icon: printSide.icon,
                              iconColor: iconEnab_(context),
                              iconLeading: true,
                            ),
                          ),
                        ),

                        SizedBox(width: Dimen.defMarg),

                        Expanded(
                          child: AppDropdown<KonspektAttachmentPrintColor>(
                            position: PopupMenuPosition.over,
                            onSelected: (val) => setState(() => printColor = val),
                            itemBuilder: (context) => KonspektAttachmentPrintColor.values
                                .map((value) => AppDropdownButton<KonspektAttachmentPrintColor>(
                              context,
                              value,
                            ))
                                .toList(),
                            borderRadius: BorderRadius.circular(AppCard.defRadius),
                            child: SimpleButton.from(
                              context: context,
                              radius: AppCard.defRadius,
                              padding: EdgeInsets.all(Dimen.defMarg),
                              textColor: iconEnab_(context),
                              color: background_(context),
                              margin: EdgeInsets.zero,
                              text: printColor.displayName,
                              fontWeight: weightNormal,
                              onTap: null,
                              icon: printColor.icon,
                              iconColor: iconEnab_(context),
                              iconLeading: true,
                            ),
                          ),
                        )

                      ],
                    ),

                  ],
                ),
              ),
            )

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