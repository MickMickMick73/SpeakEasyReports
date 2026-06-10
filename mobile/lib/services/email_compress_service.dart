import 'dart:async';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

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
  static const videoCompressTimeoutSeconds = 120;

  Future<Directory> _workDir(String sessionId) async {
    final base = await getTemporaryDirectory();
    final dir = Directory('${base.path}/email-compress/$sessionId');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String?> _compressVideo(String sourcePath, Directory workDir, EmailCompressProgress? onProgress) async {
    await VideoCompress.setLogLevel(0);
    StreamSubscription<dynamic>? progressSub;
    if (onProgress != null) {
      progressSub = VideoCompress.compressProgress$.listen((progress) {
        onProgress('Compressing video…', progress: progress / 100.0);
      });
    }

    try {
      final info = await VideoCompress.compressVideo(
        sourcePath,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      ).timeout(const Duration(seconds: videoCompressTimeoutSeconds));

      if (info?.file == null) return null;

      var outPath = info!.file!.path;
      var size = await info.file!.length();

      if (size > maxVideoBytes) {
        onProgress?.call('Retrying video at lower quality…');
        final retry = await VideoCompress.compressVideo(
          sourcePath,
          quality: VideoQuality.LowQuality,
          deleteOrigin: false,
          includeAudio: true,
        ).timeout(const Duration(seconds: videoCompressTimeoutSeconds));
        if (retry?.file != null) {
          outPath = retry!.file!.path;
          size = await retry.file!.length();
        }
      }

      if (size > maxVideoBytes) {
        throw EmailCompressException(
          'Video too large for email (${(size / (1024 * 1024)).toStringAsFixed(1)} MB after compression). '
          'Record $maxVideoMinutesHint or less, or use Push to PC / Hotspot for full resolution.',
        );
      }

      final dest = '${workDir.path}/email-video.mp4';
      await File(outPath).copy(dest);
      return dest;
    } on TimeoutException {
      return null;
    } finally {
      await progressSub?.cancel();
    }
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
        maxSeconds: videoCompressTimeoutSeconds,
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
      if (await File(first.localPath).exists()) {
        tick('Compressing video…');
        videoPath = await _compressVideo(first.localPath, workDir, tick);
        if (videoPath == null) videoOmitted = true;
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
      tick('Compressing photo ${i + 1} of ${selected.length}…');
      photoPaths.add(await _compressPhoto(item.localPath, workDir, i));
    }

    tick('Ready to open Mail…', progress: 1);

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