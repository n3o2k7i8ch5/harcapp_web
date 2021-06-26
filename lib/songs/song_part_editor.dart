
import 'package:flutter/material.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core_own_song/common.dart';
import 'package:harcapp_core_own_song/page_widgets/common_song_part_editor.dart';
import 'package:harcapp_core_own_song/page_widgets/error_widget.dart';


const double TEXT_FIELD_TOP_PADD = Dimen.TEXT_FIELD_PADD - 7;

class SongPartEditor extends StatelessWidget{

  final SongPart? part;
  final Function()? onSongPartChanged;
  final Function()? onCheckPressed;

  const SongPartEditor(this.part, {this.onSongPartChanged, this.onCheckPressed});

  @override
  Widget build(BuildContext context) {
    return SongPartEditorTemplate(
      part!,
      isRefren: part!.isRefren(context),
      onTextChanged: onSongPartChanged,
      onChordsChanged: onSongPartChanged,
      onShiftChanged: onSongPartChanged,
      topBuilder: (context, state) => ButtonsWidget(
        state,
        onCheckPressed: onCheckPressed
      ),
      bottomBuilder: (context, state) => ErrorListWidget(state, true),
    );
  }

}
