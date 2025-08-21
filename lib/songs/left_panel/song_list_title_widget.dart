import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/comm_widgets/title_show_row_widget.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class SongListTileWidget extends StatelessWidget{

  static const double height = Dimen.iconFootprint;

  final TextAlign textAlign;
  final bool showDuplicated;
  final bool withBackButton;

  const SongListTileWidget({this.textAlign = TextAlign.start, this.showDuplicated = true, this.withBackButton = false, Key? key}):super(key: key);

  @override
  Widget build(BuildContext context) => Consumer<AllSongsProvider>(
      builder: (context, allSongsProv, child) =>
          Row(
            children: [

              if(withBackButton)
                IconButton(
                    icon: Icon(MdiIcons.arrowLeft),
                    onPressed: () => Navigator.pop(context)
                ),

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
                                '\nMowa o: ${prov.dupLclIds.map((s) => '<b>$s</b>').join(', ')}',
                          )
                      ),
                    )
                ),

              Expanded(child: Container()),

              SizedBox(height: Dimen.iconFootprint + 2*Dimen.defMarg),

              if(allSongsProv.length>0)
                SimpleButton.from(
                    context: context,
                    margin: EdgeInsets.symmetric(vertical: Dimen.defMarg),
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