import 'dart:io';

import 'package:flutter/foundation.dart';

import 'models/session.dart';
import 'models/settings.dart';
import 'services/session_store.dart';
import 'services/settings_store.dart';

class AppState extends ChangeNotifier {
  AppState() {
    _init();
  }

  final SettingsStore _settingsStore = SettingsStore();
  final SessionStore _sessionStore = SessionStore();

  AppSettings settings = AppSettings();
  List<InspectionSession> sessions = [];
  InspectionSession? activeSession;
  bool ready = false;
  String? lastQrConnectedUrl;

  Future<void> _init() async {
    settings = await _settingsStore.load();
    sessions = await _sessionStore.loadAll();
    activeSession = await _sessionStore.loadActive();
    ready = true;
    notifyListeners();
  }

  Future<void> saveSettings() async {
    await _settingsStore.save(settings);
    notifyListeners();
  }

  void markPcConnectedFromQr(String url) {
    lastQrConnectedUrl = url;
    notifyListeners();
  }

  void clearQrConnectedBanner() {
    lastQrConnectedUrl = null;
    notifyListeners();
  }

  Future<void> setActiveSession(InspectionSession? session) async {
    activeSession = session;
    await _sessionStore.saveActive(session);
    notifyListeners();
  }

  Future<void> saveSession(InspectionSession session) async {
    await _sessionStore.upsert(session);
    sessions = await _sessionStore.loadAll();
    if (activeSession?.id == session.id) {
      activeSession = session;
      await _sessionStore.saveActive(session);
    }
    notifyListeners();
  }

  Future<void> deleteSession(String sessionId) async {
    final matches = sessions.where((s) => s.id == sessionId);
    if (matches.isNotEmpty) {
      final session = matches.first;
      for (final media in session.media) {
        final file = File(media.localPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
    await _sessionStore.delete(sessionId);
    if (activeSession?.id == sessionId) {
      activeSession = null;
      await _sessionStore.saveActive(null);
    }
    sessions = await _sessionStore.loadAll();
    notifyListeners();
  }

  Future<void> deleteAllSessions() async {
    for (final session in sessions) {
      for (final media in session.media) {
        final file = File(media.localPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
    await _sessionStore.deleteAll();
    activeSession = null;
    await _sessionStore.saveActive(null);
    sessions = [];
    notifyListeners();
  }
}