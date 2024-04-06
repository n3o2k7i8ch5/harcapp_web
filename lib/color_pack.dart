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
  Color get accent => Colors.indigo;

  @override
  Color get iconEnabled => AppColors.icon_enabled;

  @override
  Color get iconDisabled => AppColors.icon_disabled;

  @override
  ColorPack? get darkEquivalent => this;

}