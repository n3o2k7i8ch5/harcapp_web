import 'package:flutter/material.dart';
import 'package:harcapp_core/colors.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';

class ColorPackGraphite extends ColorPack{

  const ColorPackGraphite();

  @override
  String get name => 'ColorPackGraphite';

  @override
  Color get appBarTextEnabled => Colors.white;

  @override
  Color get appBarTextDisabled => Colors.white70;

  @override
  Color get textDrawer => Colors.white70;

  @override
  Color get hintDrawer => Colors.white30;

  @override
  Color get accentColor => Colors.indigo;

  @override
  Color get darkColor => Color.fromARGB(255, 55, 55, 65);

  @override
  Color get lightColor => Color.fromARGB(255, 95, 95, 105);

  @override
  Color get mainColor => Color.fromARGB(255, 75, 75, 85);

  @override
  Color get accentIconColor => Colors.white;

  @override
  Color get iconEnabled => AppColors.icon_enabled;

  @override
  Color get iconDisabled => AppColors.icon_disabled;

  @override
  Color get drawerIconColor => Colors.white;

  @override
  Color get drawerIconDisabled => Colors.white54;
}