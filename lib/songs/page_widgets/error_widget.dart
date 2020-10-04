
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:harcapp_web/common/app_card.dart';
import 'package:harcapp_web/common/dimen.dart';
import 'package:harcapp_web/songs/core_own_song/errors.dart';
import 'package:provider/provider.dart';

import 'common_song_part_editor.dart';

class ErrorListWidget extends StatelessWidget{

  final SongPartEditorTemplateState parent;
  final showErrBar;
  const ErrorListWidget(this.parent, this.showErrBar);

  @override
  Widget build(BuildContext context) {
    return Consumer2<ErrorProvider<ChordsMissingError>, ErrorProvider<TextTooLongError>>(
        builder: (context, chordsMissingErrorProv, textTooLongErrorProv, child) {

          List<ErrorInfoLine> errorLines = [];

          int chordsMissingErrIdx = 0;
          int textTooLongErrIdx = 0;

          int idx = 0;
          while(!(
              chordsMissingErrIdx >= chordsMissingErrorProv.length &&
                  textTooLongErrIdx >= textTooLongErrorProv.length
          )){
            SongEditError err = chordsMissingErrorProv.errorAt(idx);
            if(err != null){
              chordsMissingErrIdx++;
              errorLines.add(ErrorInfoLine(err));
            }

            err = textTooLongErrorProv.errorAt(idx);
            if(err != null){
              textTooLongErrIdx++;
              errorLines.add(ErrorInfoLine(err));
            }

            idx++;
          }

          return AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOutQuad,
            constraints: BoxConstraints(maxHeight: showErrBar?140:0,),
            child: ListView(
                shrinkWrap: true,
                physics: BouncingScrollPhysics(),
                children: errorLines
            ),
          );

        });
  }

}

class ErrorInfoLine extends StatelessWidget{

  final SongEditError error;

  const ErrorInfoLine(this.error);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Container(
        height: Dimen.ICON_SIZE,
        width: Dimen.ICON_SIZE,
        child: AppCard(
          elevation: 0,
          color: error.color,
          radius: 100,
        ),
      ),
      title: Text(error.text),
      trailing: Text('${error.line + 1}'),
    );
  }

}
