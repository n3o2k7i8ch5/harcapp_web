
import 'package:flutter/material.dart';
import 'package:harcapp_web/common/dimen.dart';
import 'package:harcapp_web/songs/page_widgets/common_song_part_editor.dart';
import 'package:harcapp_web/songs/page_widgets/error_widget.dart';

import 'core_own_song/common.dart';


const double TEXT_FIELD_TOP_PADD = Dimen.TEXT_FIELD_PADD - 7;

class SongPartEditor extends StatelessWidget{

  final SongPart part;
  final Function() onSongPartChanged;

  const SongPartEditor(this.part, {this.onSongPartChanged});

  @override
  Widget build(BuildContext context) {
    return SongPartEditorTemplate(
      part,
      isRefren: part.isRefren(context),
      onTextChanged: onSongPartChanged,
      onChordsChanged: onSongPartChanged,
      onShiftChanged: onSongPartChanged,
      topBuilder: (context, state) => ButtonsWidget(state),
      bottomBuilder: (context, state) => ErrorListWidget(state, true),
    );
  }

}
