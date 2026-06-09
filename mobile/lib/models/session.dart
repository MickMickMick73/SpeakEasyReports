import 'dart:convert';

enum InspectionType { general, plumbing, electrical, building }

enum SyncStatus { idle, pending, uploading, complete, failed }

class TranscriptSegment {
  TranscriptSegment({required this.text, this.offsetMs = 0});
  final String text;
  final int offsetMs;

  Map<String, dynamic> toJson() => {'text': text, 'offsetMs': offsetMs};
  factory TranscriptSegment.fromJson(Map<String, dynamic> j) =>
      TranscriptSegment(text: j['text'] as String? ?? '', offsetMs: j['offsetMs'] as int? ?? 0);
}

class MediaItem {
  MediaItem({
    required this.id,
    required this.type,
    required this.localPath,
    this.transcript = '',
    this.transcriptSegments = const [],
    this.recordingStartedAt,
    this.recordingEndedAt,
    this.contentHash,
    this.uploadStatus = 'pending',
  });

  final String id;
  final String type; // photo | video
  final String localPath;
  String transcript;
  List<TranscriptSegment> transcriptSegments;
  String? recordingStartedAt;
  String? recordingEndedAt;
  String? contentHash;
  String uploadStatus;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'localPath': localPath,
        'transcript': transcript,
        'transcriptSegments': transcriptSegments.map((s) => s.toJson()).toList(),
        'recordingStartedAt': recordingStartedAt,
        'recordingEndedAt': recordingEndedAt,
        'contentHash': contentHash,
        'uploadStatus': uploadStatus,
      };

  factory MediaItem.fromJson(Map<String, dynamic> j) => MediaItem(
        id: j['id'] as String,
        type: j['type'] as String,
        localPath: j['localPath'] as String,
        transcript: j['transcript'] as String? ?? '',
        transcriptSegments: (j['transcriptSegments'] as List<dynamic>? ?? [])
            .map((e) => TranscriptSegment.fromJson(e as Map<String, dynamic>))
            .toList(),
        recordingStartedAt: j['recordingStartedAt'] as String?,
        recordingEndedAt: j['recordingEndedAt'] as String?,
        contentHash: j['contentHash'] as String?,
        uploadStatus: j['uploadStatus'] as String? ?? 'pending',
      );
}

class InspectionSession {
  InspectionSession({
    required this.id,
    required this.inspectionType,
    this.projectName = '',
    this.clientName = '',
    this.clientEmail = '',
    this.siteAddress = '',
    this.jobReference = '',
    this.jobDescription = '',
    this.syncStatus = SyncStatus.pending,
    this.syncError,
    DateTime? startedAt,
    this.endedAt,
    List<MediaItem>? media,
  })  : startedAt = startedAt ?? DateTime.now(),
        media = media ?? [];

  final String id;
  final InspectionType inspectionType;
  String projectName;
  String clientName;
  String clientEmail;
  String siteAddress;
  String jobReference;
  String jobDescription;
  SyncStatus syncStatus;
  String? syncError;
  final DateTime startedAt;
  DateTime? endedAt;
  final List<MediaItem> media;

  Map<String, dynamic> toJson() => {
        'id': id,
        'inspectionType': inspectionType.name,
        'projectName': projectName,
        'clientName': clientName,
        'clientEmail': clientEmail,
        'siteAddress': siteAddress,
        'jobReference': jobReference,
        'jobDescription': jobDescription,
        'syncStatus': syncStatus.name,
        'syncError': syncError,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'media': media.map((m) => m.toJson()).toList(),
      };

  factory InspectionSession.fromJson(Map<String, dynamic> j) => InspectionSession(
        id: j['id'] as String,
        inspectionType: InspectionType.values.byName(j['inspectionType'] as String? ?? 'general'),
        projectName: j['projectName'] as String? ?? '',
        clientName: j['clientName'] as String? ?? '',
        clientEmail: j['clientEmail'] as String? ?? '',
        siteAddress: j['siteAddress'] as String? ?? '',
        jobReference: j['jobReference'] as String? ?? '',
        jobDescription: j['jobDescription'] as String? ?? '',
        syncStatus: SyncStatus.values.byName(j['syncStatus'] as String? ?? 'pending'),
        syncError: j['syncError'] as String?,
        startedAt: DateTime.tryParse(j['startedAt'] as String? ?? '') ?? DateTime.now(),
        endedAt: j['endedAt'] != null ? DateTime.tryParse(j['endedAt'] as String) : null,
        media: (j['media'] as List<dynamic>? ?? [])
            .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static String encodeList(List<InspectionSession> sessions) =>
      jsonEncode(sessions.map((s) => s.toJson()).toList());

  static List<InspectionSession> decodeList(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => InspectionSession.fromJson(e as Map<String, dynamic>)).toList();
  }
}

String inspectionTypeLabel(InspectionType type) {
  switch (type) {
    case InspectionType.general:
      return 'General inspection';
    case InspectionType.plumbing:
      return 'Plumbing';
    case InspectionType.electrical:
      return 'Electrical';
    case InspectionType.building:
      return 'Building';
  }
}