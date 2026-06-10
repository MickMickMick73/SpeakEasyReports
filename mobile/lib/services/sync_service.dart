import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../models/session.dart';
import '../models/settings.dart';

class SyncService {
  Future<bool> testConnection(String apiBaseUrl) async {
    final url = _normalize(apiBaseUrl);
    try {
      final linkRes = await http.get(Uri.parse('$url/api/link/status')).timeout(const Duration(seconds: 4));
      if (linkRes.statusCode == 200) {
        final linkBody = jsonDecode(linkRes.body) as Map<String, dynamic>;
        if (linkBody['ok'] == true) return true;
      }
      final res = await http.get(Uri.parse('$url/health')).timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) return false;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> pushSession(InspectionSession session, AppSettings settings) async {
    final base = _normalize(settings.apiBaseUrl);
    final manifest = _buildManifest(session, settings);
    final files = <Map<String, dynamic>>[];

    for (final item in session.media) {
      final file = File(item.localPath);
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      final hash = sha256.convert(bytes).toString();
      item.contentHash = hash;
      files.add({
        'mediaId': item.id,
        'fileName': '${item.type}-${item.id}',
        'contentType': item.type == 'photo' ? 'image/jpeg' : 'video/mp4',
        'contentHash': hash,
        'path': item.localPath,
      });
    }

    final presignRes = await http.post(
      Uri.parse('$base/api/uploads/presign'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sessionId': session.id,
        'files': files
            .map((f) => {
                  'mediaId': f['mediaId'],
                  'fileName': f['fileName'],
                  'contentType': f['contentType'],
                  'contentHash': f['contentHash'],
                })
            .toList(),
      }),
    );
    if (presignRes.statusCode >= 400) {
      throw Exception('Presign failed: ${presignRes.body}');
    }

    final presign = jsonDecode(presignRes.body) as Map<String, dynamic>;
    final uploads = (presign['uploads'] as List<dynamic>).cast<Map<String, dynamic>>();

    for (final upload in uploads) {
      final local = files.firstWhere((f) => f['mediaId'] == upload['mediaId']);
      final bytes = await File(local['path'] as String).readAsBytes();
      final putRes = await http.put(
        Uri.parse(upload['uploadUrl'] as String),
        headers: {'Content-Type': upload['contentType'] as String},
        body: bytes,
      );
      if (putRes.statusCode >= 400) {
        throw Exception('Upload failed for ${upload['mediaId']}');
      }
    }

    final manifestRes = await http.post(
      Uri.parse('$base/api/uploads/manifest'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'manifest': manifest}),
    );
    if (manifestRes.statusCode >= 400) {
      throw Exception('Manifest failed: ${manifestRes.body}');
    }

    return jsonDecode(manifestRes.body) as Map<String, dynamic>;
  }

  Map<String, dynamic> _buildManifest(InspectionSession session, AppSettings settings) {
    final manifest = <String, dynamic>{
      'sessionId': session.id,
      'vehicleId': session.clientName,
      'jobReference': session.projectName.isNotEmpty ? session.projectName : session.clientName,
      'projectName': session.projectName,
      'inspectionType': session.inspectionType.name,
      'clientName': session.clientName,
      'clientEmail': session.clientEmail,
      'siteAddress': session.siteAddress,
      'companyName': settings.companyName,
      'reportFields': {
        'jobDescription': session.jobDescription,
        'summary': session.jobDescription,
      },
      'technicianName': settings.inspectorName,
      'deviceId': 'flutter',
      'deviceModel': 'SpeakEasy Flutter',
      'appVersion': '3.14.0',
      'startedAt': session.startedAt.toIso8601String(),
      'endedAt': session.endedAt?.toIso8601String(),
      'issues': [],
      'recommendations': [],
      'voiceLog': [],
      'media': session.media
          .map((m) => {
                'id': m.id,
                'type': m.type,
                'contentHash': m.contentHash,
                'createdAt': session.startedAt.toIso8601String(),
                'transcript': m.transcript,
                'transcriptSegments': m.transcript.trim().isNotEmpty
                    ? <Map<String, dynamic>>[]
                    : m.transcriptSegments.map((s) => s.toJson()).toList(),
                'recordingStartedAt': m.recordingStartedAt,
                'recordingEndedAt': m.recordingEndedAt,
              })
          .toList(),
      'createdAt': DateTime.now().toIso8601String(),
    };
    final payload = jsonEncode(manifest);
    manifest['manifestHash'] = sha256.convert(utf8.encode(payload)).toString();
    return manifest;
  }

  String _normalize(String url) => url.trim().replaceAll(RegExp(r'/+$'), '');
}