import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/comm_widgets/title_show_row_widget.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class WorkspaceTitleWidget extends StatelessWidget{

  static const double height = Dimen.ICON_FOOTPRINT;

  final TextAlign textAlign;
  final bool showDuplicated;

  const WorkspaceTitleWidget({this.textAlign = TextAlign.start, this.showDuplicated = true, Key? key}):super(key: key);

  @override
  Widget build(BuildContext context) => Consumer<AllSongsProvider>(
      builder: (context, prov, child) =>
          TitleShortcutRowWidget(
            title: 'Zarządzaj piosenkami (${prov.length})',
            textAlign: textAlign,
            trailing: showDuplicated?Consumer<SongFileNameDupErrProvider>(
                builder: (context, prov, child) => AnimatedOpacity(
                  opacity: prov.count==0?0:1,
                  duration: Duration(milliseconds: 300),
                  child: SimpleButton.from(
                      textColor: Colors.red,
                      icon: MdiIcons.alertCircleOutline,
                      text: '${prov.count}',
                      onTap: () => AppScaffold.showMessage(
                        context,
                        'Liczba piosenek o takiej samej nazwie: ${prov.count}.'
                            '\nMowa o: ${prov.lclIds.map((s) => '<b>$s</b>').join(', ')}',
                      )
                  ),
                )
            ):null,
          )
  );

}