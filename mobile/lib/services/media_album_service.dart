import 'package:gal/gal.dart';

import '../models/session.dart';

class MediaAlbumService {
  static const rootAlbum = 'SpeakEasyReports';

  String albumFor(InspectionSession session) {
    final raw = session.projectName.trim().isNotEmpty
        ? session.projectName.trim()
        : session.clientName.trim();
    final safe = raw.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '').trim();
    if (safe.isEmpty) return rootAlbum;
    return '$rootAlbum — $safe';
  }

  Future<bool> ensureAccess({bool toAlbum = true}) async {
    final hasAccess = await Gal.hasAccess(toAlbum: toAlbum);
    if (hasAccess) return true;
    return Gal.requestAccess(toAlbum: toAlbum);
  }

  Future<bool> saveMedia({
    required String path,
    required InspectionSession session,
    required bool isVideo,
  }) async {
    if (!await ensureAccess()) return false;
    final album = albumFor(session);
    if (isVideo) {
      await Gal.putVideo(path, album: album);
    } else {
      await Gal.putImage(path, album: album);
    }
    return true;
  }
}