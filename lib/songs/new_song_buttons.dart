import 'package:flutter/cupertino.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_web/songs/left_panel/song_list_view.dart';
import 'package:provider/provider.dart';

import 'providers.dart';


class ImportSongsButton extends StatelessWidget{

  @override
  Widget build(BuildContext context) => SimpleButton.from(
      context: context,
      color: backgroundIcon_(context),
      icon: NewSongType.importSongs.icon,
      iconSize: 32.0,
      text: NewSongType.importSongs.displayName,
      direction: Axis.vertical,
      onTap: () => handleImportSongsTap(context)
  );

}

class NewExampleSongButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Consumer<SimilarSongProvider>(
      builder: (context, prov, child) => SimpleButton.from(
          textColor: prov.allSongs == null?iconDisab_(context):iconEnab_(context),
          color: backgroundIcon_(context),
          icon: NewSongType.newSongExample.icon,
          iconSize: 32.0,
          text: NewSongType.newSongExample.displayName,
          direction: Axis.vertical,
          onTap: prov.allSongs == null?null:() => handleExampleSongTap(context)
      )
  );

}

class NewEmptySongButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SimpleButton.from(
      context: context,
      color: backgroundIcon_(context),
      icon: NewSongType.newSongEmpty.icon,
      iconSize: 32.0,
      text: NewSongType.newSongEmpty.displayName,
      direction: Axis.vertical,
      onTap: () => handleNewSongEmptyTap(context)
  );

}

class NewSongFromCodeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SimpleButton.from(
      context: context,
      color: backgroundIcon_(context),
      icon: NewSongType.newSongFromCode.icon,
      iconSize: 32.0,
      text: NewSongType.newSongFromCode.displayName,
      direction: Axis.vertical,
      onTap: () => handleNewSongFromCode(context)
  );

}