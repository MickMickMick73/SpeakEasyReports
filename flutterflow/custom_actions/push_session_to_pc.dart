// SpeakEasy Reports — FlutterFlow Custom Action
// Dependencies: http ^1.2.0, crypto ^3.0.0
//
// Implements the same 3-step sync as InspectPro v3:
//   1. POST /api/uploads/presign
//   2. PUT each file to uploadUrl
//   3. POST /api/uploads/manifest
//
// Pass apiBaseUrl from App State (Settings).

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> pushSessionToPc({
  required String apiBaseUrl,
  required Map<String, dynamic> manifest,
  required List<Map<String, dynamic>> localFiles,
}) async {
  final base = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');

  final presignRes = await http.post(
    Uri.parse('$base/api/uploads/presign'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'sessionId': manifest['sessionId'],
      'files': localFiles
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
    return {'ok': false, 'step': 'presign', 'error': presignRes.body};
  }
  final presign = jsonDecode(presignRes.body) as Map<String, dynamic>;
  final uploads = (presign['uploads'] as List).cast<Map<String, dynamic>>();

  for (final upload in uploads) {
    final local = localFiles.firstWhere((f) => f['mediaId'] == upload['mediaId']);
    final bytes = await File(local['path'] as String).readAsBytes();
    final putRes = await http.put(
      Uri.parse(upload['uploadUrl'] as String),
      headers: {'Content-Type': upload['contentType'] as String},
      body: bytes,
    );
    if (putRes.statusCode >= 400) {
      return {'ok': false, 'step': 'upload', 'mediaId': upload['mediaId']};
    }
  }

  final manifestRes = await http.post(
    Uri.parse('$base/api/uploads/manifest'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'manifest': manifest}),
  );
  if (manifestRes.statusCode >= 400) {
    return {'ok': false, 'step': 'manifest', 'error': manifestRes.body};
  }

  return {'ok': true, 'result': jsonDecode(manifestRes.body)};
}

String sha256Hex(List<int> bytes) {
  return sha256.convert(bytes).toString();
}