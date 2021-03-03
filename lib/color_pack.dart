import 'package:flutter/material.dart';
import 'package:harcapp_core/colors.dart';

abstract class ColorPack{

  const ColorPack();

  String get name;

  Color get appBar => darkColor;
  Color get appBarTextEnabled => Colors.white;
  Color get appBarTextDisabled => Colors.white70;

  Color get disabled => AppColors.text_def_disab;

  Color get textEnabled => AppColors.text_def_enab;
  Color get textDisabled => AppColors.text_def_disab;

  Color get textDrawer => AppColors.text_def_enab;
  Color get hintDrawer => AppColors.text_def_disab;

  Color get hintEnabled => AppColors.text_hint_enab;

  Color get defCardEnabled => AppColors.white_dark;//Colors.white;
  Color get defCardDisabled => Color.fromARGB(255, 235, 235, 235);
  Color get defCardElevation => Colors.black;

  Color get colorCard => mainColor;
  Color get colorBackground => darkColor;

  Color get background => Colors.white;
  Color get backgroundIcon => Colors.black.withOpacity(0.05);

  Color get mainColor;
  Color get lightColor;
  Color get darkColor;
  Color get accentColor;
  Color get accentIconColor;
  Color get iconEnabled;
  Color get iconDisabled;
  Color get drawerIconColor => Colors.black54;
  Color get drawerIconDisabled => Colors.black26;

  bool operator == (Object other) => other is ColorPack && name == other.name;
  int get hashCode => name.hashCode;
}

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