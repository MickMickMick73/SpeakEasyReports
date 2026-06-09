import fs from 'fs';
import path from 'path';

import { sanitizeTranscript } from './transcriptQuality.js';

function safeName(value) {
  return String(value ?? 'unknown')
    .replace(/[^a-zA-Z0-9._-]+/g, '-')
    .replace(/-+/g, '-')
    .slice(0, 64);
}

function formatTimestamp(iso) {
  if (!iso) return '—';
  return new Date(iso).toLocaleString('en-AU', {
    dateStyle: 'medium',
    timeStyle: 'short',
  });
}

function formatOffset(ms) {
  const totalSeconds = Math.max(0, Math.floor(ms / 1000));
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${minutes}:${String(seconds).padStart(2, '0')}`;
}

function escapeHtml(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function copySessionMedia(sessionId, uploadsDir, targetDir) {
  const sourceDir = path.join(uploadsDir, sessionId);
  if (!fs.existsSync(sourceDir)) return [];

  const copied = [];
  const mediaDir = path.join(targetDir, 'media');
  fs.mkdirSync(mediaDir, { recursive: true });

  for (const fileName of fs.readdirSync(sourceDir)) {
    const source = path.join(sourceDir, fileName);
    if (!fs.statSync(source).isFile()) continue;
    const dest = path.join(mediaDir, fileName);
    fs.copyFileSync(source, dest);
    copied.push({ fileName, relativePath: `media/${fileName}` });
  }

  return copied;
}

function findCopiedFile(mediaId, copiedMedia) {
  return copiedMedia.find((file) => file.fileName.includes(mediaId));
}

function resolveVideoTranscript(videoItem, voiceLog) {
  const sanitized = sanitizeTranscript(videoItem.transcript);
  if (sanitized) {
    return {
      text: sanitized,
      segments: videoItem.transcriptSegments ?? [],
      source: videoItem.transcriptSource ?? 'video-audio',
    };
  }

  if (videoItem.transcriptSource && videoItem.transcriptSource !== 'device') {
    return {
      text: '',
      segments: videoItem.transcriptSegments ?? [],
      source: videoItem.transcriptSource,
      noSpeechDetected: videoItem.noSpeechDetected ?? false,
      speechRatio: videoItem.speechRatio,
    };
  }

  if (!videoItem.recordingStartedAt) {
    return { text: '', segments: [], source: 'none' };
  }

  const start = new Date(videoItem.recordingStartedAt).getTime();
  const end = new Date(videoItem.recordingEndedAt ?? videoItem.createdAt).getTime();

  const entries = (voiceLog ?? []).filter((entry) => {
    if (entry.command && entry.command !== 'unknown') return false;
    const timestamp = new Date(entry.createdAt).getTime();
    return timestamp >= start - 1000 && timestamp <= end + 5000;
  });

  if (!entries.length) {
    return { text: '', segments: [], source: 'none' };
  }

  const text = sanitizeTranscript(entries.map((entry) => entry.transcript).join(' '));
  if (!text) {
    return { text: '', segments: [], source: 'none' };
  }

  return {
    text,
    segments: entries.map((entry) => ({
      text: entry.transcript,
      offsetMs: Math.max(0, new Date(entry.createdAt).getTime() - start),
    })),
    source: 'voice-log-fallback',
  };
}

function buildTranscriptHtml(transcript) {
  if (!transcript.text) {
    return `<p class="transcript-empty">No narration was captured in this recording. Tap Record and speak immediately — recording starts straight away (no voice prompt first). Describe damage, components, and issues while filming.</p>`;
  }

  const segmentHtml =
    transcript.segments.length > 0
      ? `<div class="transcript-segments">${transcript.segments
          .map(
            (segment) => `
          <div class="segment">
            <span class="segment-time">${formatOffset(segment.offsetMs)}</span>
            <span class="segment-text">${escapeHtml(segment.text)}</span>
          </div>`
          )
          .join('')}</div>`
      : '';

  return `
    <div class="transcript-body">
      <p class="transcript-summary">${escapeHtml(transcript.text)}</p>
      ${segmentHtml}
      <p class="transcript-source">Source: ${escapeHtml(transcript.source)}</p>
    </div>`;
}

const INSPECTION_TYPE_LABELS = {
  general: 'General Inspection',
  plumbing: 'Plumbing Inspection',
  electrical: 'Electrical Inspection',
  building: 'Building Inspection',
};

function inspectionTypeLabel(type) {
  return INSPECTION_TYPE_LABELS[type] ?? type ?? 'Inspection';
}

function reportFieldRows(manifest) {
  const fields = manifest.reportFields ?? {};
  return Object.entries(fields)
    .filter(([, value]) => String(value ?? '').trim())
    .map(
      ([key, value]) => `
      <tr>
        <th>${escapeHtml(key)}</th>
        <td>${escapeHtml(value)}</td>
      </tr>`
    )
    .join('');
}

function buildHtmlReport(manifest, copiedMedia) {
  const issues = manifest.issues ?? [];
  const recommendations = manifest.recommendations ?? [];
  const voiceLog = manifest.voiceLog ?? [];
  const media = manifest.media ?? [];
  const photos = media.filter((item) => item.type === 'photo');
  const videos = media.filter((item) => item.type === 'video');
  const jobReference = manifest.jobReference ?? manifest.vehicleId ?? '—';
  const inspectionTitle = inspectionTypeLabel(manifest.inspectionType);
  const customFieldRows = reportFieldRows(manifest);

  const issueRows = issues
    .map(
      (issue) => `
      <tr>
        <td>${escapeHtml(issue.description)}</td>
        <td>${escapeHtml(issue.component ?? '—')}</td>
        <td>${escapeHtml(issue.severity ?? '—')}</td>
        <td>${escapeHtml(issue.source ?? '—')}</td>
      </tr>`
    )
    .join('');

  const photoBlocks = photos
    .map((item, index) => {
      const copied = findCopiedFile(item.id, copiedMedia);
      const imageHtml = copied
        ? `<img class="photo" src="${escapeHtml(copied.relativePath)}" alt="Inspection photo ${index + 1}" />`
        : `<p class="missing-media">Photo file not available locally.</p>`;

      return `
      <article class="photo-card">
        <h3>Photo ${index + 1}</h3>
        <p class="meta-line">Captured ${formatTimestamp(item.createdAt)}</p>
        ${imageHtml}
        ${item.issueNote ? `<p class="note">${escapeHtml(item.issueNote)}</p>` : ''}
      </article>`;
    })
    .join('');

  const videoBlocks = videos
    .map((item, index) => {
      const copied = findCopiedFile(item.id, copiedMedia);
      const transcript = resolveVideoTranscript(item, voiceLog);
      const videoHtml = copied
        ? `<video class="inspection-video" controls preload="metadata" src="${escapeHtml(copied.relativePath)}"></video>`
        : `<p class="missing-media">Video file not available locally.</p>`;

      return `
      <article class="video-card">
        <h3>Video recording ${index + 1}</h3>
        <p class="meta-line">Recorded ${formatTimestamp(item.recordingStartedAt ?? item.createdAt)}${
          item.recordingEndedAt ? ` · ended ${formatTimestamp(item.recordingEndedAt)}` : ''
        }</p>
        ${videoHtml}
        <div class="transcript-panel">
          <h4>Technician narration (speech-to-text)</h4>
          ${buildTranscriptHtml(transcript)}
        </div>
      </article>`;
    })
    .join('');

  const recommendationRows = recommendations
    .map(
      (rec) => `
      <tr>
        <td>${escapeHtml(rec.description)}</td>
        <td>${escapeHtml(rec.priority ?? '—')}</td>
      </tr>`
    )
    .join('');

  const voiceRows = voiceLog
    .map(
      (entry) => `
      <tr>
        <td>${formatTimestamp(entry.createdAt)}</td>
        <td>${escapeHtml(entry.transcript)}</td>
        <td>${escapeHtml(entry.command ?? '—')}</td>
      </tr>`
    )
    .join('');

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>${escapeHtml(inspectionTitle)} — ${escapeHtml(manifest.clientName || jobReference)}</title>
  <style>
    body { font-family: Segoe UI, Arial, sans-serif; margin: 32px; color: #0f172a; background: #f8fafc; }
    h1 { color: #1d4ed8; margin-bottom: 4px; }
    h2 { color: #1e3a8a; margin-top: 0; }
    h3 { margin-bottom: 6px; color: #0f172a; }
    h4 { margin: 16px 0 8px; color: #1d4ed8; }
    .meta { color: #475569; margin-bottom: 24px; }
    .section { margin-top: 32px; }
    table { width: 100%; border-collapse: collapse; margin: 16px 0 28px; background: #fff; }
    th, td { border: 1px solid #cbd5e1; padding: 8px 10px; text-align: left; vertical-align: top; }
    th { background: #e2e8f0; }
    .photo-card, .video-card {
      background: #fff;
      border: 1px solid #cbd5e1;
      border-radius: 12px;
      padding: 18px;
      margin-bottom: 20px;
      box-shadow: 0 1px 3px rgba(15, 23, 42, 0.08);
    }
    .photo { max-width: 100%; border-radius: 8px; border: 1px solid #e2e8f0; }
    .inspection-video { width: 100%; max-width: 960px; border-radius: 8px; background: #000; }
    .meta-line { color: #64748b; margin-bottom: 12px; }
    .note { color: #334155; font-style: italic; }
    .transcript-panel {
      margin-top: 16px;
      background: #eff6ff;
      border: 1px solid #bfdbfe;
      border-radius: 10px;
      padding: 16px;
    }
    .transcript-summary {
      font-size: 16px;
      line-height: 1.6;
      margin: 0 0 12px;
      color: #0f172a;
      white-space: pre-wrap;
    }
    .transcript-segments { display: grid; gap: 8px; }
    .segment { display: grid; grid-template-columns: 56px 1fr; gap: 10px; align-items: start; }
    .segment-time { color: #2563eb; font-weight: 700; font-size: 13px; }
    .segment-text { color: #1e293b; line-height: 1.5; }
    .transcript-source, .transcript-empty { color: #64748b; font-size: 12px; margin-top: 10px; }
    .missing-media { color: #b45309; }
    .grid { display: grid; gap: 20px; }
  </style>
</head>
<body>
  <h1>${escapeHtml(inspectionTitle)}</h1>
  <p class="meta">
    <strong>Client:</strong> ${escapeHtml(manifest.clientName || '—')}<br />
    <strong>Site:</strong> ${escapeHtml(manifest.siteAddress || '—')}<br />
    <strong>Job reference:</strong> ${escapeHtml(jobReference)}<br />
    <strong>Inspector:</strong> ${escapeHtml(manifest.technicianName)}<br />
    <strong>Device:</strong> ${escapeHtml(manifest.deviceModel)} (${escapeHtml(manifest.deviceId)})<br />
    <strong>Started:</strong> ${formatTimestamp(manifest.startedAt)}<br />
    <strong>Ended:</strong> ${formatTimestamp(manifest.endedAt)}<br />
    <strong>Manifest hash:</strong> ${escapeHtml(manifest.manifestHash ?? '—')}
  </p>

  ${customFieldRows ? `<div class="section"><h2>Inspection notes</h2><table><tbody>${customFieldRows}</tbody></table></div>` : ''}

  <div class="section">
    <h2>Video recordings (${videos.length})</h2>
    <div class="grid">${videoBlocks || '<p>No video recordings in this assessment.</p>'}</div>
  </div>

  <div class="section">
    <h2>Photos (${photos.length})</h2>
    <div class="grid">${photoBlocks || '<p>No photos in this assessment.</p>'}</div>
  </div>

  <div class="section">
    <h2>Findings (${issues.length})</h2>
    <table>
      <thead><tr><th>Description</th><th>Area</th><th>Severity</th><th>Source</th></tr></thead>
      <tbody>${issueRows || '<tr><td colspan="4">No findings recorded</td></tr>'}</tbody>
    </table>
  </div>

  <div class="section">
    <h2>Recommendations (${recommendations.length})</h2>
    <table>
      <thead><tr><th>Description</th><th>Priority</th></tr></thead>
      <tbody>${recommendationRows || '<tr><td colspan="2">No recommendations recorded</td></tr>'}</tbody>
    </table>
  </div>

  <div class="section">
    <h2>Full voice log (${voiceLog.length})</h2>
    <table>
      <thead><tr><th>Time</th><th>Transcript</th><th>Command</th></tr></thead>
      <tbody>${voiceRows || '<tr><td colspan="3">No voice entries</td></tr>'}</tbody>
    </table>
  </div>
</body>
</html>`;
}

export function generateDesktopReport({ manifest, reportsDir, uploadsDir }) {
  const folderBase = manifest.jobReference ?? manifest.vehicleId ?? manifest.sessionId;
  const folderName = `${safeName(folderBase)}_${safeName(manifest.sessionId).slice(0, 8)}`;
  const reportFolder = path.join(reportsDir, folderName);
  if (fs.existsSync(reportFolder)) {
    fs.rmSync(reportFolder, { recursive: true, force: true });
  }
  fs.mkdirSync(reportFolder, { recursive: true });

  const copiedMedia = copySessionMedia(manifest.sessionId, uploadsDir, reportFolder);

  const report = {
    generatedAt: new Date().toISOString(),
    sessionId: manifest.sessionId,
    vehicleId: manifest.vehicleId,
    jobReference: manifest.jobReference ?? manifest.vehicleId,
    inspectionType: manifest.inspectionType ?? 'general',
    clientName: manifest.clientName ?? '',
    clientEmail: manifest.clientEmail ?? '',
    siteAddress: manifest.siteAddress ?? '',
    reportFields: manifest.reportFields ?? {},
    technicianName: manifest.technicianName,
    deviceId: manifest.deviceId,
    deviceModel: manifest.deviceModel,
    appVersion: manifest.appVersion,
    startedAt: manifest.startedAt,
    endedAt: manifest.endedAt,
    location: manifest.location,
    manifestHash: manifest.manifestHash,
    issueCount: manifest.issues?.length ?? 0,
    recommendationCount: manifest.recommendations?.length ?? 0,
    mediaCount: manifest.media?.length ?? 0,
    voiceLogCount: manifest.voiceLog?.length ?? 0,
    issues: manifest.issues ?? [],
    recommendations: manifest.recommendations ?? [],
    media: manifest.media ?? [],
    voiceLog: manifest.voiceLog ?? [],
    copiedMedia,
    videoTranscripts: (manifest.media ?? [])
      .filter((item) => item.type === 'video')
      .map((item) => ({
        mediaId: item.id,
        ...resolveVideoTranscript(item, manifest.voiceLog),
      })),
  };

  const jsonPath = path.join(reportFolder, 'report.json');
  const htmlPath = path.join(reportFolder, 'report.html');
  fs.writeFileSync(jsonPath, JSON.stringify(report, null, 2));
  fs.writeFileSync(htmlPath, buildHtmlReport(manifest, copiedMedia));

  return {
    reportFolder,
    reportJson: jsonPath,
    reportHtml: htmlPath,
    reportFolderName: folderName,
  };
}