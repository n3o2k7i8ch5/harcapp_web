import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/comm_widgets/title_show_row_widget.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class WorkspaceTitleWidget extends StatelessWidget{

  static const double height = Dimen.iconFootprint;

  final TextAlign textAlign;
  final bool showDuplicated;

  const WorkspaceTitleWidget({this.textAlign = TextAlign.start, this.showDuplicated = true, Key? key}):super(key: key);

  @override
  Widget build(BuildContext context) => Consumer<AllSongsProvider>(
      builder: (context, allSongsProv, child) =>
          Row(
            children: [

              IntrinsicWidth(
                child: TitleShortcutRowWidget(
                  title: 'Piosenki (${allSongsProv.length})',
                  textAlign: textAlign,
                ),
              ),

              if(showDuplicated)
                Consumer<SongFileNameDupErrProvider>(
                    builder: (context, prov, child) => AnimatedOpacity(
                      opacity: prov.count==0?0:1,
                      duration: Duration(milliseconds: 300),
                      child: SimpleButton.from(
                          textColor: Colors.red,
                          icon: MdiIcons.alertCircleOutline,
                          text: '${prov.count}',
                          onTap: prov.count==0?null:() => AppScaffold.showMessage(
                            context,
                            'Liczba piosenek o takiej samej nazwie: ${prov.count}.'
                                '\nMowa o: ${prov.lclIds.map((s) => '<b>$s</b>').join(', ')}',
                          )
                      ),
                    )
                ),

              Expanded(child: Container()),

              if(allSongsProv.length>0)
                SimpleButton.from(
                    context: context,
                    onTap: () => AppScaffold.showMessage(context,
                      'Przytrzymaj, by usunąć wszystkie piosenki',
                    ),
                    onLongPress: (){
                      allSongsProv.clear();
                      SongFileNameDupErrProvider.of(context).checkAllDups(context);
                    },
                    icon: MdiIcons.close,
                    text: 'Zeruj'
                )

            ],
          )
  );

}