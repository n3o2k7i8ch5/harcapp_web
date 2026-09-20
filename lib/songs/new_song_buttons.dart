import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_web/songs/left_panel/song_list_view.dart';
import 'package:provider/provider.dart';

import 'providers.dart';


/// Duży, pionowy przycisk "dodaj piosenkę" - jeden na każdy [NewSongType].
/// Ikonę, napis i akcję bierze z samego typu.
class NewSongButton extends StatelessWidget{

  static const double iconSize = 32.0;

  final NewSongType type;

  const NewSongButton(this.type, {super.key});

  Widget _button(BuildContext context, {bool enabled = true}) => SimpleButton.from(
      context: context,
      color: backgroundIcon_(context),
      icon: type.icon,
      iconSize: iconSize,
      text: type.text,
      direction: Axis.vertical,
      textColor: enabled?iconEnab_(context):iconDisab_(context),
      onTap: enabled?() => type.handle(context):null
  );

  @override
  Widget build(BuildContext context){
    // Przykładowa piosenka wymaga wczytanego śpiewnika - dopóki się ładuje,
    // przycisk jest wyszarzony.
    if(type == NewSongType.newSongExample)
      return Consumer<SimilarSongProvider>(
        builder: (context, prov, child) => _button(context, enabled: prov.loaded),
      );

    return _button(context);
  }

}
