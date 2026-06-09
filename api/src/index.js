import cors from 'cors';
import express from 'express';
import fs from 'fs';
import os from 'os';
import path from 'path';
import { fileURLToPath } from 'url';

import { createConnectRouter, createConnectionJsonHandler } from './routes/connect.js';
import { createLinkPhoneApp, createLinkRouter } from './routes/link.js';
import { createDashboardRouter } from './routes/dashboard.js';
import { createIssuesRouter } from './routes/issues.js';
import { createReportsRouter } from './routes/reports.js';
import { createSyncLogger } from './middleware/syncLogger.js';
import { createUploadsRouter } from './routes/uploads.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PORT = Number(process.env.PORT ?? 3001);
const HOST = process.env.HOST ?? '0.0.0.0';
const DATA_DIR = path.join(__dirname, '..', 'data');
const UPLOADS_DIR = path.join(DATA_DIR, 'uploads');
const REPORTS_DIR = path.join(__dirname, '..', '..', 'reports');
const LINK_DIR = path.join(__dirname, '..', '..', 'link-share');

fs.mkdirSync(UPLOADS_DIR, { recursive: true });
fs.mkdirSync(REPORTS_DIR, { recursive: true });
fs.mkdirSync(LINK_DIR, { recursive: true });

const syncLogger = createSyncLogger(DATA_DIR);

const app = express();
app.use(cors());
app.use(syncLogger.middleware);
app.use(express.json({ limit: '2mb' }));

function getLanIp() {
  const nets = os.networkInterfaces();
  for (const entries of Object.values(nets)) {
    for (const entry of entries ?? []) {
      if (entry.family === 'IPv4' && !entry.internal) {
        return entry.address;
      }
    }
  }
  return 'localhost';
}

const lanIp = getLanIp();
const publicBaseUrl = process.env.PUBLIC_BASE_URL ?? `http://${lanIp}:${PORT}`;

app.get('/health', (_req, res) => {
  res.json({
    ok: true,
    app: 'SpeakEasyReports',
    version: '1.0.0',
    mode: process.env.AWS_ACCESS_KEY_ID ? 's3' : 'local',
    reportsDir: REPORTS_DIR,
    phoneApiUrl: publicBaseUrl,
    lanIp,
    port: PORT,
  });
});

app.get('/connect', createConnectRouter({ lanIp, port: PORT }));
app.get('/link', createLinkPhoneApp({ lanIp, port: PORT }));
app.use('/api/link', createLinkRouter({ linkDir: LINK_DIR, lanIp, port: PORT }));
app.get('/connection.json', createConnectionJsonHandler({ lanIp, port: PORT, reportsDir: REPORTS_DIR }));
app.get('/', createDashboardRouter({ reportsDir: REPORTS_DIR, lanIp, port: PORT }));
app.use('/reports', express.static(REPORTS_DIR, { fallthrough: true }));

app.use(
  '/api/uploads',
  createUploadsRouter({
    dataDir: DATA_DIR,
    uploadsDir: UPLOADS_DIR,
    reportsDir: REPORTS_DIR,
    publicBaseUrl,
  })
);
app.use('/api/issues', createIssuesRouter());
app.use('/api/reports', createReportsRouter({ reportsDir: REPORTS_DIR }));

app.get('/api/debug/sync', (_req, res) => {
  const uploadSessions = fs.existsSync(UPLOADS_DIR)
    ? fs.readdirSync(UPLOADS_DIR).map((sessionId) => {
        const dir = path.join(UPLOADS_DIR, sessionId);
        const files = fs.existsSync(dir)
          ? fs.readdirSync(dir).map((name) => {
              const full = path.join(dir, name);
              return { name, bytes: fs.statSync(full).size };
            })
          : [];
        return { sessionId, files };
      })
    : [];

  const manifestCount = fs.existsSync(path.join(DATA_DIR, 'manifests'))
    ? fs.readdirSync(path.join(DATA_DIR, 'manifests')).length
    : 0;

  res.json({
    ok: true,
    uploadSessions,
    manifestCount,
    reportCount: fs.existsSync(REPORTS_DIR) ? fs.readdirSync(REPORTS_DIR).length : 0,
    recent: syncLogger.getRecent(),
    logPath: syncLogger.logPath,
  });
});

const server = app.listen(PORT, HOST, () => {
  console.log(`SpeakEasyReports PC: http://localhost:${PORT}`);
  console.log(`API listening on http://${HOST}:${PORT}`);
  console.log(`Phone Settings URL: http://${lanIp}:${PORT}`);
  console.log(`Storage mode: ${process.env.AWS_ACCESS_KEY_ID ? 'S3' : 'local filesystem'}`);
  console.log(`Reports folder: ${REPORTS_DIR}`);
});

server.on('error', (error) => {
  if (error.code === 'EADDRINUSE') {
    console.error(`Port ${PORT} is already in use. Close the other server window first.`);
  } else {
    console.error('API server error:', error.message);
  }
  process.exit(1);
});