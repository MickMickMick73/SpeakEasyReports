import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../models/session.dart';

typedef EmailCompressProgress = void Function(
  String step, {
  int elapsedSeconds,
  int maxSeconds,
  double? progress,
});

class EmailCompressException implements Exception {
  EmailCompressException(this.message);
  final String message;
  @override
  String toString() => message;
}

class EmailCompressResult {
  EmailCompressResult({
    required this.htmlPath,
    this.videoPath,
    required this.photoPaths,
    this.skippedVideoCount = 0,
    this.skippedPhotoCount = 0,
    this.videoOmitted = false,
  });

  final String htmlPath;
  final String? videoPath;
  final List<String> photoPaths;
  final int skippedVideoCount;
  final int skippedPhotoCount;
  final bool videoOmitted;
}

class EmailCompressService {
  static const maxVideoBytes = 22 * 1024 * 1024;
  static const maxPhotos = 5;
  static const targetPhotoBytes = 512 * 1024;
  static const maxVideoMinutesHint = '~5–6 minutes';

  Future<Directory> _workDir(String sessionId) async {
    final base = await getTemporaryDirectory();
    final dir = Directory('${base.path}/email-compress/$sessionId');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Attach original video when already small enough for email — no re-encoding.
  Future<String?> _videoForEmail(String sourcePath, Directory workDir) async {
    final file = File(sourcePath);
    if (!await file.exists()) return null;

    final size = await file.length();
    if (size > maxVideoBytes) return null;

    final ext = sourcePath.toLowerCase().endsWith('.mov') ? '.mov' : '.mp4';
    final dest = '${workDir.path}/email-video$ext';
    await file.copy(dest);
    return dest;
  }

  Future<String> _compressPhoto(String sourcePath, Directory workDir, int index) async {
    final bytes = await File(sourcePath).readAsBytes();
    if (bytes.length <= targetPhotoBytes) {
      final dest = '${workDir.path}/email-photo-$index.jpg';
      await File(sourcePath).copy(dest);
      return dest;
    }

    for (final quality in [85, 70, 55, 40]) {
      final result = await FlutterImageCompress.compressWithFile(
        sourcePath,
        minWidth: 1500,
        minHeight: 2000,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      if (result == null) continue;
      if (result.length <= targetPhotoBytes || quality == 40) {
        final dest = '${workDir.path}/email-photo-$index.jpg';
        await File(dest).writeAsBytes(result, flush: true);
        return dest;
      }
    }

    final dest = '${workDir.path}/email-photo-$index.jpg';
    await File(sourcePath).copy(dest);
    return dest;
  }

  Future<EmailCompressResult> prepareAttachments({
    required InspectionSession session,
    required String htmlReport,
    EmailCompressProgress? onProgress,
  }) async {
    final started = DateTime.now();
    void tick(String step, {double? progress}) {
      final elapsed = DateTime.now().difference(started).inSeconds;
      onProgress?.call(
        step,
        elapsedSeconds: elapsed,
        maxSeconds: 60,
        progress: progress,
      );
    }

    tick('Preparing report…');
    final workDir = await _workDir(session.id);
    final htmlPath = '${workDir.path}/report.html';
    await File(htmlPath).writeAsString(htmlReport);

    final videos = session.media.where((m) => m.type == 'video').toList();
    String? videoPath;
    var skippedVideos = 0;
    var videoOmitted = false;

    if (videos.isNotEmpty) {
      final first = videos.first;
      tick('Checking video for email…');
      videoPath = await _videoForEmail(first.localPath, workDir);
      if (videoPath == null && await File(first.localPath).exists()) {
        videoOmitted = true;
      }
      skippedVideos = videos.length > 1 ? videos.length - 1 : 0;
    }

    final photos = session.media.where((m) => m.type == 'photo').toList();
    final selected = photos.length > maxPhotos ? photos.sublist(photos.length - maxPhotos) : photos;
    final skippedPhotos = photos.length - selected.length;

    final photoPaths = <String>[];
    for (var i = 0; i < selected.length; i++) {
      final item = selected[i];
      if (!await File(item.localPath).exists()) continue;
      tick('Preparing photo ${i + 1} of ${selected.length}…', progress: (i + 1) / selected.length);
      photoPaths.add(await _compressPhoto(item.localPath, workDir, i));
    }

    tick('Opening Mail…', progress: 1);

    return EmailCompressResult(
      htmlPath: htmlPath,
      videoPath: videoPath,
      photoPaths: photoPaths,
      skippedVideoCount: skippedVideos,
      skippedPhotoCount: skippedPhotos,
      videoOmitted: videoOmitted,
    );
  }
}