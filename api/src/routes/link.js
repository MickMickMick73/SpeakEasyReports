import express from 'express';
import fs from 'fs';
import multer from 'multer';
import path from 'path';

const NOTES_FILE = 'shared-notes.md';

function safeName(name) {
  return String(name ?? 'file')
    .replace(/[^a-zA-Z0-9._-]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 120) || 'file';
}

export function createLinkRouter({ linkDir, lanIp, port }) {
  const router = express.Router();
  fs.mkdirSync(linkDir, { recursive: true });

  const notesPath = path.join(linkDir, NOTES_FILE);
  if (!fs.existsSync(notesPath)) {
    fs.writeFileSync(
      notesPath,
      '# Shared notes\n\nEdit from phone or PC. Saves automatically.\n',
      'utf8'
    );
  }

  const upload = multer({
    storage: multer.diskStorage({
      destination: (_req, _file, cb) => cb(null, linkDir),
      filename: (_req, file, cb) => cb(null, `${Date.now()}-${safeName(file.originalname)}`),
    }),
    limits: { fileSize: 250 * 1024 * 1024 },
  });

  router.get('/status', (_req, res) => {
    const files = fs
      .readdirSync(linkDir)
      .filter((name) => name !== NOTES_FILE)
      .map((name) => {
        const full = path.join(linkDir, name);
        const stat = fs.statSync(full);
        return {
          name,
          bytes: stat.size,
          modifiedAt: stat.mtime.toISOString(),
          url: `/api/link/files/${encodeURIComponent(name)}`,
        };
      })
      .sort((a, b) => b.modifiedAt.localeCompare(a.modifiedAt));

    res.json({
      ok: true,
      service: 'SpeakEasy Link',
      apiUrl: `http://${lanIp}:${port}`,
      linkDir,
      fileCount: files.length,
      files,
      notes: fs.readFileSync(notesPath, 'utf8'),
      notesUpdatedAt: fs.statSync(notesPath).mtime.toISOString(),
    });
  });

  router.get('/files/:name', (req, res) => {
    const name = safeName(path.basename(req.params.name));
    const full = path.join(linkDir, name);
    if (!fs.existsSync(full) || !fs.statSync(full).isFile()) {
      return res.status(404).json({ error: 'File not found' });
    }
    res.download(full, name);
  });

  router.post('/upload', upload.single('file'), (req, res) => {
    if (!req.file) {
      return res.status(400).json({ error: 'No file received' });
    }
    res.json({
      ok: true,
      name: req.file.filename,
      bytes: req.file.size,
      url: `/api/link/files/${encodeURIComponent(req.file.filename)}`,
    });
  });

  router.put('/notes', express.text({ type: '*/*', limit: '1mb' }), (req, res) => {
    const body = typeof req.body === 'string' ? req.body : '';
    fs.writeFileSync(notesPath, body, 'utf8');
    res.json({ ok: true, bytes: body.length, updatedAt: new Date().toISOString() });
  });

  router.delete('/files/:name', (req, res) => {
    const name = safeName(path.basename(req.params.name));
    if (name === NOTES_FILE) {
      return res.status(400).json({ error: 'Cannot delete shared notes file' });
    }
    const full = path.join(linkDir, name);
    if (!fs.existsSync(full)) {
      return res.status(404).json({ error: 'File not found' });
    }
    fs.unlinkSync(full);
    res.json({ ok: true, deleted: name });
  });

  return router;
}

export function createLinkPhoneApp({ lanIp, port }) {
  const apiUrl = `http://${lanIp}:${port}`;
  return (_req, res) => {
    res.type('html').send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
  <meta name="apple-mobile-web-app-capable" content="yes" />
  <meta name="apple-mobile-web-app-title" content="SpeakEasy Link" />
  <title>SpeakEasy Link</title>
  <style>
    * { box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; margin: 0; background: #0b1220; color: #e2e8f0; }
    header { padding: 16px; background: linear-gradient(135deg, #1e3a8a, #0ea5e9); }
    h1 { margin: 0; font-size: 20px; }
    .sub { margin: 6px 0 0; font-size: 13px; opacity: 0.9; }
    main { padding: 14px; display: grid; gap: 12px; }
    .card { background: #111827; border: 1px solid #334155; border-radius: 14px; padding: 14px; }
    .label { font-size: 11px; text-transform: uppercase; letter-spacing: 0.08em; color: #38bdf8; margin-bottom: 8px; }
    .pill { display: inline-block; padding: 6px 10px; border-radius: 999px; font-size: 12px; font-weight: 700; }
    .ok { background: #052e16; color: #86efac; border: 1px solid #166534; }
    .bad { background: #450a0a; color: #fca5a5; border: 1px solid #991b1b; }
    button, .btn { width: 100%; border: 0; border-radius: 12px; padding: 12px; font-size: 15px; font-weight: 700; margin-top: 8px; }
    .primary { background: #0ea5e9; color: #fff; }
    .secondary { background: #1e293b; color: #e2e8f0; border: 1px solid #475569; }
    textarea { width: 100%; min-height: 120px; border-radius: 12px; border: 1px solid #475569; background: #0f172a; color: #e2e8f0; padding: 12px; font: inherit; }
    .file { padding: 10px 0; border-bottom: 1px solid #1e293b; font-size: 14px; }
    .file:last-child { border-bottom: 0; }
    .muted { color: #94a3b8; font-size: 12px; }
    input[type=file] { width: 100%; color: #cbd5e1; }
  </style>
</head>
<body>
  <header>
    <h1>SpeakEasy Link</h1>
    <p class="sub">Standalone phone ↔ PC bridge. No inspection required.</p>
  </header>
  <main>
    <div class="card">
      <div class="label">Connection</div>
      <div id="status" class="pill bad">Checking…</div>
      <button class="primary" id="testBtn">Test connection</button>
    </div>

    <div class="card">
      <div class="label">Push file to PC</div>
      <input type="file" id="fileInput" />
      <button class="primary" id="uploadBtn">Upload to PC</button>
      <p class="muted" id="uploadMsg"></p>
    </div>

    <div class="card">
      <div class="label">Shared notes (edit on the fly)</div>
      <textarea id="notes"></textarea>
      <button class="secondary" id="saveNotesBtn">Save notes to PC</button>
      <p class="muted" id="notesMsg"></p>
    </div>

    <div class="card">
      <div class="label">Files on PC</div>
      <div id="files"><p class="muted">Loading…</p></div>
      <button class="secondary" id="refreshBtn">Refresh</button>
    </div>
  </main>
  <script>
    const API = ${JSON.stringify(apiUrl)};
    const statusEl = document.getElementById('status');
    const filesEl = document.getElementById('files');
    const notesEl = document.getElementById('notes');

    async function testConnection() {
      statusEl.className = 'pill bad';
      statusEl.textContent = 'Testing…';
      try {
        const res = await fetch(API + '/api/link/status', { signal: AbortSignal.timeout(3000) });
        const data = await res.json();
        if (res.ok && data.ok) {
          statusEl.className = 'pill ok';
          statusEl.textContent = 'Connected · ' + data.fileCount + ' shared file(s)';
          notesEl.value = data.notes ?? '';
          renderFiles(data.files ?? []);
          return true;
        }
        statusEl.textContent = 'Unexpected response';
      } catch (e) {
        statusEl.textContent = 'Offline — ' + (e.name === 'TimeoutError' ? 'timed out' : e.message);
      }
      return false;
    }

    function renderFiles(files) {
      if (!files.length) {
        filesEl.innerHTML = '<p class="muted">No files yet. Upload from phone or drop into the PC link folder.</p>';
        return;
      }
      filesEl.innerHTML = files.map((f) => {
        const href = API + f.url;
        const kb = Math.max(1, Math.round(f.bytes / 1024));
        return '<div class="file"><a href="' + href + '" download>' + f.name + '</a><br><span class="muted">' + kb + ' KB</span></div>';
      }).join('');
    }

    document.getElementById('testBtn').onclick = testConnection;
    document.getElementById('refreshBtn').onclick = testConnection;

    document.getElementById('uploadBtn').onclick = async () => {
      const input = document.getElementById('fileInput');
      const msg = document.getElementById('uploadMsg');
      if (!input.files?.length) {
        msg.textContent = 'Choose a file first.';
        return;
      }
      msg.textContent = 'Uploading…';
      const form = new FormData();
      form.append('file', input.files[0]);
      try {
        const res = await fetch(API + '/api/link/upload', { method: 'POST', body: form });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || 'Upload failed');
        msg.textContent = 'Uploaded ' + data.name + ' (' + data.bytes + ' bytes)';
        await testConnection();
      } catch (e) {
        msg.textContent = 'Upload failed: ' + e.message;
      }
    };

    document.getElementById('saveNotesBtn').onclick = async () => {
      const msg = document.getElementById('notesMsg');
      msg.textContent = 'Saving…';
      try {
        const res = await fetch(API + '/api/link/notes', {
          method: 'PUT',
          headers: { 'Content-Type': 'text/plain' },
          body: notesEl.value,
        });
        const data = await res.json();
        if (!res.ok) throw new Error('Save failed');
        msg.textContent = 'Saved to PC at ' + new Date(data.updatedAt).toLocaleTimeString();
      } catch (e) {
        msg.textContent = 'Save failed: ' + e.message;
      }
    };

    testConnection();
    setInterval(testConnection, 8000);
  </script>
</body>
</html>`);
  };
}