import 'package:shared_preferences/shared_preferences.dart';

import '../models/settings.dart';

class SettingsStore {
  static const _key = 'speakeasy_settings';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return AppSettings();
    return AppSettings.decode(raw);
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, settings.encode());
  }
}