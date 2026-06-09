import express from 'express';
import fs from 'fs';
import path from 'path';

function safeName(value) {
  return String(value ?? 'unknown')
    .replace(/[^a-zA-Z0-9._-]+/g, '-')
    .replace(/-+/g, '-')
    .slice(0, 64);
}

export function createReportsRouter({ reportsDir }) {
  const router = express.Router();

  router.get('/', (_req, res) => {
    if (!fs.existsSync(reportsDir)) {
      return res.json({ reports: [] });
    }

    const reports = fs
      .readdirSync(reportsDir, { withFileTypes: true })
      .filter((entry) => entry.isDirectory())
      .map((entry) => {
        const folder = path.join(reportsDir, entry.name);
        const jsonPath = path.join(folder, 'report.json');
        let summary = { folder: entry.name };
        if (fs.existsSync(jsonPath)) {
          try {
            const data = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
            summary = {
              folder: entry.name,
              jobReference: data.jobReference ?? data.vehicleId,
              clientName: data.clientName,
              siteAddress: data.siteAddress,
              inspectionType: data.inspectionType,
              technicianName: data.technicianName,
              generatedAt: data.generatedAt,
              issueCount: data.issueCount,
              recommendationCount: data.recommendationCount,
              mediaCount: data.mediaCount,
            };
          } catch {
            // ignore parse errors
          }
        }
        return summary;
      })
      .sort((a, b) => (b.generatedAt ?? '').localeCompare(a.generatedAt ?? ''));

    res.json({ reports, reportsDir });
  });

  router.post('/ingest', (req, res) => {
    try {
      const {
        sessionId,
        jobReference = 'ingested',
        fileName = 'report.pdf',
        contentType = 'application/octet-stream',
        contentBase64,
      } = req.body ?? {};

      if (!sessionId) {
        return res.status(400).json({ error: 'sessionId is required' });
      }

      if (!contentBase64 || typeof contentBase64 !== 'string') {
        return res.status(400).json({ error: 'contentBase64 is required' });
      }

      const folderName = `${safeName(jobReference)}_${safeName(String(sessionId)).slice(0, 8)}`;
      const reportFolder = path.join(reportsDir, folderName);
      fs.mkdirSync(reportFolder, { recursive: true });

      const ext = path.extname(fileName) || (contentType.includes('html') ? '.html' : '.pdf');
      const targetName = ext === '.html' ? 'report.html' : ext === '.json' ? 'report.json' : 'report.pdf';
      const targetPath = path.join(reportFolder, targetName);
      fs.writeFileSync(targetPath, Buffer.from(contentBase64, 'base64'));

      const metaPath = path.join(reportFolder, 'ingest-meta.json');
      const meta = {
        ingestedAt: new Date().toISOString(),
        sessionId: String(sessionId),
        jobReference: String(jobReference),
        fileName: String(fileName),
        contentType,
        savedAs: targetName,
      };
      fs.writeFileSync(metaPath, JSON.stringify(meta, null, 2));

      res.json({
        ok: true,
        reportFolder: folderName,
        savedPath: targetPath,
      });
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Ingest failed' });
    }
  });

  return router;
}