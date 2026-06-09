import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/session.dart';

class SessionStore {
  static const _key = 'speakeasy_sessions';
  static const _activeKey = 'speakeasy_active_session';

  Future<List<InspectionSession>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return InspectionSession.decodeList(raw);
  }

  Future<void> saveAll(List<InspectionSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, InspectionSession.encodeList(sessions));
  }

  Future<InspectionSession?> loadActive() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activeKey);
    if (raw == null) return null;
    return InspectionSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveActive(InspectionSession? session) async {
    final prefs = await SharedPreferences.getInstance();
    if (session == null) {
      await prefs.remove(_activeKey);
      return;
    }
    await prefs.setString(_activeKey, jsonEncode(session.toJson()));
  }

  Future<void> upsert(InspectionSession session) async {
    final all = await loadAll();
    final idx = all.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      all[idx] = session;
    } else {
      all.insert(0, session);
    }
    await saveAll(all);
  }
}