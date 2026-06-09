import fs from 'fs';
import path from 'path';

const MAX_ENTRIES = 200;

export function createSyncLogger(dataDir) {
  const logPath = path.join(dataDir, 'sync-log.jsonl');
  const entries = [];

  function append(entry) {
    const line = JSON.stringify({ ...entry, at: new Date().toISOString() });
    entries.push(entry);
    if (entries.length > MAX_ENTRIES) entries.shift();
    try {
      fs.mkdirSync(dataDir, { recursive: true });
      fs.appendFileSync(logPath, `${line}\n`);
    } catch {
      // ignore log write errors
    }
  }

  function middleware(req, res, next) {
    if (!req.path.startsWith('/api/uploads') && req.path !== '/health') {
      return next();
    }

    const started = Date.now();
    const contentLength = Number(req.headers['content-length'] ?? 0);

    res.on('finish', () => {
      append({
        method: req.method,
        path: req.path,
        status: res.statusCode,
        ms: Date.now() - started,
        contentLength,
        ip: req.ip,
        userAgent: req.headers['user-agent'] ?? '',
      });
    });

    next();
  }

  function getRecent(limit = 40) {
    return entries.slice(-limit).reverse();
  }

  return { middleware, getRecent, logPath };
}