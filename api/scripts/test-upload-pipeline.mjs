import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { randomUUID } from 'crypto';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const API_BASE = process.env.API_BASE_URL ?? 'http://127.0.0.1:3001';
const ROOT = path.join(__dirname, '..', '..');

function findSampleVideo() {
  const candidates = [
    path.join(ROOT, 'reports', 'New-inspection_21dec591', 'media', 'd84cc422-9d88-417e-b728-8d99702c03c6.mp4'),
    path.join(ROOT, 'reports', 'DOZER-7_a600779c', 'media', 'd61edf22-272c-42f3-9e15-a9f2ba4c1137.mp4'),
  ];
  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) return candidate;
  }
  throw new Error('No sample mp4 found in reports folder — run after at least one synced inspection.');
}

async function assertOk(response, label) {
  if (!response.ok) {
    const detail = await response.text().catch(() => '');
    throw new Error(`${label} failed (${response.status}): ${detail.slice(0, 200)}`);
  }
}

async function main() {
  const sessionId = randomUUID();
  const mediaId = randomUUID();
  const sampleVideo = findSampleVideo();
  const bytes = fs.readFileSync(sampleVideo);

  console.log(`API: ${API_BASE}`);
  console.log(`Session: ${sessionId}`);
  console.log(`Sample video: ${sampleVideo} (${(bytes.length / 1024 / 1024).toFixed(2)} MB)`);

  const health = await fetch(`${API_BASE}/health`);
  await assertOk(health, 'Health check');
  const healthJson = await health.json();
  console.log('Health:', healthJson);

  const presignRes = await fetch(`${API_BASE}/api/uploads/presign`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      sessionId,
      files: [
        {
          mediaId,
          fileName: `video-${mediaId}`,
          contentType: 'video/mp4',
          contentHash: 'test-hash',
        },
      ],
    }),
  });
  await assertOk(presignRes, 'Presign');
  const { uploads } = await presignRes.json();
  const upload = uploads[0];
  console.log('Presigned URL:', upload.uploadUrl);

  const putRes = await fetch(upload.uploadUrl, {
    method: 'PUT',
    headers: { 'Content-Type': upload.contentType },
    body: bytes,
  });
  await assertOk(putRes, 'PUT upload');
  console.log('Video uploaded.');

  const manifest = {
    sessionId,
    vehicleId: 'PIPELINE-TEST',
    jobReference: 'pipeline-test',
    inspectionType: 'plumbing',
    clientName: 'Local Test',
    siteAddress: 'Dev machine',
    reportFields: {},
    technicianName: 'Automated',
    deviceId: 'test-device',
    deviceModel: 'node',
    appVersion: 'test',
    startedAt: new Date().toISOString(),
    endedAt: new Date().toISOString(),
    issues: [],
    recommendations: [],
    voiceLog: [],
    media: [
      {
        id: mediaId,
        type: 'video',
        contentHash: 'test-hash',
        createdAt: new Date().toISOString(),
        remoteUrl: upload.remoteUrl,
        recordingStartedAt: new Date().toISOString(),
        recordingEndedAt: new Date().toISOString(),
        transcript: '',
        transcriptSegments: [],
      },
    ],
    createdAt: new Date().toISOString(),
    manifestHash: 'pipeline-test-hash',
  };

  const manifestRes = await fetch(`${API_BASE}/api/uploads/manifest`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ manifest }),
  });
  await assertOk(manifestRes, 'Manifest upload');
  const manifestJson = await manifestRes.json();
  console.log('Report folder:', manifestJson.reportFolder);
  console.log('Transcripts:', manifestJson.transcripts?.length ?? 0);

  const reportsDir = healthJson.reportsDir ?? path.join(ROOT, 'reports');
  const reportPath = path.join(reportsDir, manifestJson.reportFolder, 'report.json');
  if (!fs.existsSync(reportPath)) {
    throw new Error(`Expected report at ${reportPath}`);
  }

  const report = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
  const video = report.media?.find((item) => item.id === mediaId);
  if (!video) {
    throw new Error('Uploaded video missing from generated report');
  }

  console.log('Pipeline OK — video in report, transcript source:', video.transcriptSource ?? 'none');
  if (video.transcript?.trim()) {
    console.log('Transcript preview:', video.transcript.slice(0, 120));
  }
}

main().catch((error) => {
  console.error('Pipeline test failed:', error.message);
  process.exit(1);
});