import 'package:flutter/material.dart';
import 'package:harcapp_core/values/colors.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';

class ColorPackGraphite extends ColorPack{

  const ColorPackGraphite();

  @override
  String get name => 'ColorPackGraphite';

  @override
  Color get accent => Colors.indigo;

  @override
  Color get iconEnabled => AppColors.iconEnab;

  @override
  Color get iconDisabled => AppColors.iconDisab;

  @override
  ColorPack? get darkEquivalent => this;

}