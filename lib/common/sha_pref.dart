import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class ShaPref {

  static late SharedPreferences _preferences;

  static bool isInitialized = false;

  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
    isInitialized = true;
  }

  static const String SHA_PREF_LAST_EDITED_SONGS = 'SHA_PREF_LAST_EDITED_SONGS';

  static String? Function(String key)? customGetStringOrNull;
  static String? getStringOrNull(String key) {
    try {
      if(customGetStringOrNull != null) return customGetStringOrNull!(key);
      return _preferences.getString(key);
    } catch (e){
      _preferences.remove(key);
      return null;
    }
  }

  static String getString(String key, String def) => getStringOrNull(key)??def;

  static FutureOr<void> Function(String key, String value)? customSetString;
  static Future<void> setString(String key, String value) async {
    if(customSetString != null) return await customSetString!(key, value);
    await _preferences.setString(key, value);
  }

  static FutureOr<void> Function(String key)? customRemove;
  static Future<void> remove(String key) async {
    if(customRemove != null) return await customRemove!(key);
    await _preferences.remove(key);
  }

}