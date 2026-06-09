import express from 'express';
import fs from 'fs';
import multer from 'multer';
import path from 'path';
import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

import { generateDesktopReport } from '../services/reportGenerator.js';
import { enrichManifestWithVideoTranscripts } from '../services/videoTranscription.js';

function useS3() {
  return Boolean(process.env.AWS_ACCESS_KEY_ID && process.env.AWS_SECRET_ACCESS_KEY);
}

function createS3Client(region) {
  return new S3Client({ region });
}

function extensionForContentType(contentType) {
  if (contentType?.includes('video')) return '.mp4';
  if (contentType?.includes('audio')) return '.m4a';
  if (contentType?.includes('png')) return '.png';
  return '.jpg';
}

export function createUploadsRouter({ dataDir, uploadsDir, reportsDir, publicBaseUrl }) {
  const router = express.Router();

  router.post('/presign', async (req, res) => {
    try {
      const { sessionId, storageProvider, bucket, region, files } = req.body ?? {};
      const requestBaseUrl =
        process.env.PUBLIC_BASE_URL ?? `${req.protocol}://${req.get('host')}`;

      if (!sessionId || !Array.isArray(files) || files.length === 0) {
        return res.status(400).json({ error: 'sessionId and files are required' });
      }

      if (storageProvider === 'sharepoint') {
        return res.status(501).json({ error: 'SharePoint uploads are not implemented yet' });
      }

      const uploads = [];

      if (useS3()) {
        const s3 = createS3Client(region ?? process.env.AWS_REGION ?? 'ap-southeast-2');
        const targetBucket = bucket ?? process.env.S3_BUCKET;
        if (!targetBucket) {
          return res.status(400).json({ error: 'S3 bucket is required' });
        }

        for (const file of files) {
          const ext = extensionForContentType(file.contentType);
          const key = `assessments/${sessionId}/${file.fileName ?? file.mediaId}${ext}`;
          const command = new PutObjectCommand({
            Bucket: targetBucket,
            Key: key,
            ContentType: file.contentType ?? 'application/octet-stream',
          });
          const uploadUrl = await getSignedUrl(s3, command, { expiresIn: 3600 });
          const remoteUrl = `s3://${targetBucket}/${key}`;
          uploads.push({
            mediaId: file.mediaId,
            uploadUrl,
            remoteUrl,
            contentType: file.contentType ?? 'application/octet-stream',
          });
        }
      } else {
        for (const file of files) {
          const ext = extensionForContentType(file.contentType);
          const fileName = `${file.mediaId}${ext}`;
          const sessionDir = path.join(uploadsDir, sessionId);
          fs.mkdirSync(sessionDir, { recursive: true });
          const uploadUrl = `${requestBaseUrl}/api/uploads/file/${sessionId}/${fileName}`;
          const remoteUrl = `local://${sessionId}/${fileName}`;
          uploads.push({
            mediaId: file.mediaId,
            uploadUrl,
            remoteUrl,
            contentType: file.contentType ?? 'application/octet-stream',
          });
        }
      }

      res.json({ uploads });
    } catch (error) {
      console.error('presign error', error);
      res.status(500).json({ error: 'Failed to create upload URLs' });
    }
  });

  function saveUploadedFile(req, res) {
    try {
      const { sessionId, fileName } = req.params;
      const sessionDir = path.join(uploadsDir, sessionId);
      fs.mkdirSync(sessionDir, { recursive: true });
      const target = path.join(sessionDir, fileName);
      const body = req.file?.buffer ?? req.body;
      const size = body?.length ?? 0;
      console.log(`[upload] ${req.method} ${sessionId}/${fileName} bytes=${size} ip=${req.ip}`);
      if (!size) {
        return res.status(400).json({ error: 'Empty upload body — photo did not arrive from phone' });
      }
      fs.writeFileSync(target, body);
      res.status(200).json({ ok: true, path: target, bytes: size });
    } catch (error) {
      console.error('file upload error', error);
      res.status(500).json({ error: 'Failed to save file' });
    }
  }

  const rawUpload = express.raw({ type: '*/*', limit: '200mb' });
  router.put('/file/:sessionId/:fileName', rawUpload, saveUploadedFile);
  router.post('/file/:sessionId/:fileName', rawUpload, saveUploadedFile);

  const memoryUpload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 200 * 1024 * 1024 } });
  router.post('/media/:sessionId/:fileName', memoryUpload.single('file'), saveUploadedFile);

  router.post('/manifest', async (req, res) => {
    try {
      const { storageProvider, bucket, region, manifest } = req.body ?? {};
      if (!manifest?.sessionId) {
        return res.status(400).json({ error: 'manifest.sessionId is required' });
      }

      if (storageProvider === 'sharepoint') {
        return res.status(501).json({ error: 'SharePoint manifest upload is not implemented yet' });
      }

      const manifestDir = path.join(dataDir, 'manifests');
      fs.mkdirSync(manifestDir, { recursive: true });
      const localPath = path.join(manifestDir, `${manifest.sessionId}.json`);
      fs.writeFileSync(localPath, JSON.stringify(manifest, null, 2));

      let enrichedManifest = manifest;
      let transcriptResults = [];
      if (process.env.SKIP_VIDEO_TRANSCRIPTION === '1') {
        console.log('Skipping video transcription (SKIP_VIDEO_TRANSCRIPTION=1)');
      } else {
        console.log('Transcribing video narration from uploaded files...');
        const enriched = await enrichManifestWithVideoTranscripts(manifest, uploadsDir);
        enrichedManifest = enriched.manifest;
        transcriptResults = enriched.transcriptResults;
      }
      fs.writeFileSync(localPath, JSON.stringify(enrichedManifest, null, 2));

      const report = generateDesktopReport({
        manifest: enrichedManifest,
        reportsDir,
        uploadsDir,
      });
      console.log(`Report saved: ${report.reportFolder}`);

      if (useS3()) {
        const s3 = createS3Client(region ?? process.env.AWS_REGION ?? 'ap-southeast-2');
        const targetBucket = bucket ?? process.env.S3_BUCKET;
        if (!targetBucket) {
          return res.status(400).json({ error: 'S3 bucket is required' });
        }
        const key = `assessments/${manifest.sessionId}/manifest.json`;
        await s3.send(
          new PutObjectCommand({
            Bucket: targetBucket,
            Key: key,
            Body: JSON.stringify(manifest),
            ContentType: 'application/json',
          })
        );
        return res.json({
          remoteUrl: `s3://${targetBucket}/${key}`,
          reportFolder: report.reportFolderName,
          reportJson: report.reportJson,
          reportHtml: report.reportHtml,
          transcripts: transcriptResults,
        });
      }

      res.json({
        remoteUrl: `local://manifests/${manifest.sessionId}.json`,
        reportFolder: report.reportFolderName,
        reportJson: report.reportJson,
        reportHtml: report.reportHtml,
        transcripts: transcriptResults,
      });
    } catch (error) {
      console.error('manifest error', error);
      res.status(500).json({ error: 'Failed to upload manifest' });
    }
  });

  return router;
}