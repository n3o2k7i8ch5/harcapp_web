
import 'package:flutter/widgets.dart';
import 'package:harcapp_web/common/app_text_style.dart';
import 'package:harcapp_web/common/color_pack.dart';
import 'package:harcapp_web/common/core_comm_widgets/simple_button.dart';
import 'package:harcapp_web/common/dimen.dart';
import 'package:harcapp_web/songs/core_own_song/common.dart';
import 'package:harcapp_web/songs/core_own_song/providers.dart';
import 'package:harcapp_web/songs/core_song_management/song_element.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class AddButtonsWidget extends StatelessWidget{

  final Function onPressed;
  const AddButtonsWidget({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        Expanded(
          child: SimpleButton(
            padding: EdgeInsets.all(Dimen.MARG_ICON),
            onTap: (){
              SongPartsProvider prov = Provider.of<SongPartsProvider>(context, listen: false);
              prov.add(SongPart.from(SongElement.empty()));
              if(onPressed!=null) onPressed();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(MdiIcons.musicBox, color: accentColor(context)),
                SizedBox(width: Dimen.MARG_ICON),
                Text('Zwrotka', style: AppTextStyle(fontSize: Dimen.TEXT_SIZE_BIG))
              ],
            ),
          ),
        ),

        Expanded(
          child: SimpleButton(
            padding: EdgeInsets.all(Dimen.MARG_ICON),
            onTap: (){
              SongPartsProvider prov = Provider.of<SongPartsProvider>(context, listen: false);
              RefrenPartProvider refPart = Provider.of<RefrenPartProvider>(context, listen: false);
              prov.add(SongPart.from(refPart.element));
              if(onPressed!=null) onPressed();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(MdiIcons.musicBoxOutline, color: accentColor(context)),
                SizedBox(width: Dimen.MARG_ICON),
                Text('Refren', style: AppTextStyle(fontSize: Dimen.TEXT_SIZE_BIG))
              ],
            ),
          ),
        )

      ],
    );
  }

}