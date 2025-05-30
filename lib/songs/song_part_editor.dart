import 'package:flutter/material.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/song_book/song_editor/widgets/error_widget.dart';
import 'package:harcapp_core/song_book/song_editor/widgets/song_part_editor_template/song_part_editor_template.dart';


const double TEXT_FIELD_TOP_PADD = Dimen.TEXT_FIELD_PADD - 7;

class SongPartEditor extends StatefulWidget{

  final String initText;
  final String initChords;
  final bool initShifted;

  final bool isRefren;
  final Function(String, int)? onTextChanged;
  final Function(String, int)? onChordsChanged;
  final Function(bool)? onShiftedChanged;

  const SongPartEditor({this.initText = '', this.initChords = '', this.initShifted = false, this.isRefren = false, this.onTextChanged, this.onChordsChanged, this.onShiftedChanged});

  @override
  State<StatefulWidget> createState() => SongPartEditorState();

}

class SongPartEditorState extends State<SongPartEditor>{

  String get initText => widget.initText;
  String get initChord => widget.initChords;
  bool get initShifted => widget.initShifted;
  bool get isRefren => widget.isRefren;
  Function(String, int)? get onTextChanged => widget.onTextChanged;
  Function(String, int)? get onChordsChanged => widget.onChordsChanged;
  Function(bool)? get onShiftedChanged => widget.onShiftedChanged;

  late bool showErrBar;

  @override
  void initState() {
    showErrBar = true;
    super.initState();
  }

  @override
  Widget build(BuildContext context) => SongPartEditorTemplate(
    initText: initText,
    initChord: initChord,
    initShifted: initShifted,
    isRefren: isRefren,
    onTextChanged: onTextChanged,
    onChordsChanged: onChordsChanged,
    onShiftedChanged: onShiftedChanged,
    bottomBuilder: (context, state) => Column(
      children: [
        ButtonsWidget(
          isRefren: isRefren,
          onCheckPressed: () => Navigator.pop(context),
          onAlertTap: () => setState(() => showErrBar = !showErrBar),
          onChordsChanged: onChordsChanged,
        ),
        ErrorListWidget(showErrBar),
      ],
    ),
  );

}
