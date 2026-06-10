import '../models/session.dart';
import '../models/settings.dart';

class ReportBuilder {
  static String applyPlaceholders(String template, InspectionSession session, AppSettings settings) {
    final type = inspectionTypeLabel(session.inspectionType);
    return template
        .replaceAll('{{clientName}}', session.clientName)
        .replaceAll('{{siteAddress}}', session.siteAddress)
        .replaceAll('{{inspectionType}}', type)
        .replaceAll('{{inspectorName}}', settings.inspectorName)
        .replaceAll('{{companyName}}', settings.companyName)
        .replaceAll('{{jobReference}}', session.clientName);
  }

  static String buildEmailSubject(InspectionSession session, AppSettings settings) {
    return applyPlaceholders(settings.defaultEmailSubject, session, settings);
  }

  static String _fullTranscript(MediaItem video) {
    final segments = video.transcriptSegments
        .map((segment) => segment.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final joinedSegments = segments.join(' ');
    final direct = video.transcript.trim();
    if (joinedSegments.isNotEmpty) return joinedSegments;
    return direct;
  }

  static String buildNarrationSection(InspectionSession session) {
    final videos = session.media.where((m) => m.type == 'video').toList();
    if (videos.isEmpty) return '';

    final buffer = StringBuffer('\n\n--- Technician narration ---\n');
    for (var i = 0; i < videos.length; i++) {
      final video = videos[i];
      final transcript = _fullTranscript(video);
      buffer.writeln('\nRecording ${i + 1}:');
      buffer.writeln(transcript.isEmpty ? '(No narration captured for this recording.)' : transcript);
    }
    return buffer.toString();
  }

  static String buildEmailBody(InspectionSession session, AppSettings settings) {
    final intro = applyPlaceholders(settings.defaultEmailBody, session, settings);
    final note = session.jobDescription.trim();
    final noteBlock = note.isEmpty ? '' : '\n\nJob note:\n$note';
    return '$intro$noteBlock${buildNarrationSection(session)}';
  }

  static String buildPlainTextReport(InspectionSession session, AppSettings settings) {
    final type = inspectionTypeLabel(session.inspectionType);
    final photos = session.media.where((m) => m.type == 'photo').length;
    final videos = session.media.where((m) => m.type == 'video').length;
    final buffer = StringBuffer();

    if (settings.companyName.trim().isNotEmpty) {
      buffer.writeln(settings.companyName.trim());
      buffer.writeln();
    }
    buffer.writeln(type);
    buffer.writeln('Client: ${session.clientName}');
    buffer.writeln('Site: ${session.siteAddress}');
    if (settings.inspectorName.trim().isNotEmpty) {
      buffer.writeln('Inspector: ${settings.inspectorName.trim()}');
    }
    if (session.jobDescription.trim().isNotEmpty) {
      buffer.writeln('\nJob note:\n${session.jobDescription.trim()}');
    }
    buffer.writeln('\nMedia: $photos photos, $videos videos');
    buffer.write(buildNarrationSection(session));
    return buffer.toString().trim();
  }

  static String buildHtmlReport(InspectionSession session, AppSettings settings) {
    final type = inspectionTypeLabel(session.inspectionType);
    final company = _escape(settings.companyName.trim());
    final client = _escape(session.clientName);
    final site = _escape(session.siteAddress);
    final inspector = _escape(settings.inspectorName.trim());
    final jobNote = session.jobDescription.trim();

    final videos = session.media.where((m) => m.type == 'video').toList();
    final photos = session.media.where((m) => m.type == 'photo').toList();

    final videoBlocks = videos.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final item = entry.value;
      final transcript = _fullTranscript(item);
      final segmentBlocks = item.transcriptSegments
          .map((segment) => segment.text.trim())
          .where((text) => text.isNotEmpty)
          .map((text) => '<p class="transcript-segment">${_escape(text)}</p>')
          .join();
      final narration = transcript.isEmpty
          ? '<p class="transcript-empty">No narration was captured in this recording.</p>'
          : (segmentBlocks.isNotEmpty
              ? '<div class="transcript-segments">$segmentBlocks</div>'
              : '<p class="transcript-summary">${_escape(transcript)}</p>');
      return '''
      <article class="video-card">
        <h3>Technician narration — recording $index</h3>
        <div class="transcript-panel">$narration</div>
        <p class="meta-line">Video available on request (${_escape(item.id.substring(0, 8))}…)</p>
      </article>''';
    }).join();

    final photoBlocks = photos.asMap().entries.map((entry) {
      final index = entry.key + 1;
      return '''
      <article class="photo-card">
        <h3>Photo $index</h3>
        <p class="meta-line">Captured during inspection</p>
      </article>''';
    }).join();

    final companyHeader = company.isNotEmpty ? '<p class="company">$company</p>' : '';

    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${_escape(type)} — $client</title>
  <style>
    html, body { height: auto; min-height: 100%; overflow-y: auto; -webkit-overflow-scrolling: touch; }
    body { font-family: -apple-system, Segoe UI, Arial, sans-serif; margin: 0; padding: 20px; color: #0f172a; background: #f8fafc; line-height: 1.5; }
    .company { font-size: 14px; font-weight: 700; color: #1d4ed8; letter-spacing: 0.04em; text-transform: uppercase; margin: 0 0 8px; }
    h1 { color: #1d4ed8; margin: 0 0 4px; font-size: 22px; }
    h2 { color: #1e3a8a; margin: 24px 0 8px; font-size: 17px; }
    h3 { margin: 0 0 8px; color: #0f172a; font-size: 15px; }
    .meta { color: #475569; margin-bottom: 16px; font-size: 14px; }
    .section { margin-top: 20px; }
    .job-note { background: #fff; border: 1px solid #cbd5e1; border-radius: 10px; padding: 14px; white-space: pre-wrap; }
    .photo-card, .video-card { background: #fff; border: 1px solid #cbd5e1; border-radius: 12px; padding: 16px; margin-bottom: 14px; }
    .transcript-panel { background: #eff6ff; border: 1px solid #bfdbfe; border-radius: 10px; padding: 14px; margin-top: 8px; }
    .transcript-summary { font-size: 16px; line-height: 1.65; margin: 0; white-space: pre-wrap; color: #0f172a; }
    .transcript-segments { display: grid; gap: 10px; }
    .transcript-segment { margin: 0; white-space: pre-wrap; line-height: 1.65; color: #0f172a; }
    .transcript-empty { color: #64748b; font-size: 14px; margin: 0; }
    .meta-line { color: #64748b; font-size: 12px; margin: 8px 0 0; }
    .grid { display: grid; gap: 12px; }
  </style>
</head>
<body>
  $companyHeader
  <h1>${_escape(type)}</h1>
  <p class="meta">
    <strong>Client:</strong> $client<br />
    <strong>Site:</strong> $site<br />
    ${inspector.isNotEmpty ? '<strong>Inspector:</strong> $inspector<br />' : ''}
  </p>
  ${jobNote.isNotEmpty ? '<div class="section"><h2>Job note</h2><div class="job-note">${_escape(jobNote)}</div></div>' : ''}
  <div class="section">
    <h2>Technician narration (${videos.length})</h2>
    <div class="grid">${videoBlocks.isEmpty ? '<p class="transcript-empty">No video recordings in this inspection.</p>' : videoBlocks}</div>
  </div>
  <div class="section">
    <h2>Photos (${photos.length})</h2>
    <div class="grid">${photoBlocks.isEmpty ? '<p class="transcript-empty">No photos in this inspection.</p>' : photoBlocks}</div>
  </div>
</body>
</html>''';
  }

  static String _escape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }
}