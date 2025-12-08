import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

enum AppThemeMode { system, light, dark }

class ThemeModeProvider extends ChangeNotifier {
  static ThemeModeProvider of(BuildContext context) =>
      Provider.of<ThemeModeProvider>(context, listen: false);

  AppThemeMode _mode = AppThemeMode.system;

  AppThemeMode get mode => _mode;

  set mode(AppThemeMode value) {
    _mode = value;
    notifyListeners();
  }

  bool get isDark {
    switch (_mode) {
      case AppThemeMode.light:
        return false;
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.system:
        final brightness =
            SchedulerBinding.instance.platformDispatcher.platformBrightness;
        return brightness == Brightness.dark;
    }
  }

  void toggle() {
    if (_mode == AppThemeMode.system) {
      mode = isDark ? AppThemeMode.light : AppThemeMode.dark;
    } else if (_mode == AppThemeMode.light) {
      mode = AppThemeMode.dark;
    } else {
      mode = AppThemeMode.light;
    }
  }

  void setSystem() {
    mode = AppThemeMode.system;
  }
}
