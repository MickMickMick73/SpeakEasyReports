import fs from 'fs';
import path from 'path';

export function createDashboardRouter({ reportsDir, lanIp, port }) {
  return (_req, res) => {
    const phoneApiUrl = `http://${lanIp}:${port}`;

    res.type('html').send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>SpeakEasy Reports — PC</title>
  <style>
    * { box-sizing: border-box; }
    body { font-family: "Segoe UI", system-ui, sans-serif; margin: 0; background: #0b1220; color: #e2e8f0; }
    header { background: linear-gradient(135deg, #1e3a8a, #0ea5e9); padding: 28px 32px; }
    header h1 { margin: 0 0 6px; font-size: 28px; font-weight: 800; }
    header p { margin: 0; opacity: 0.92; font-size: 15px; }
    main { max-width: 1040px; margin: 0 auto; padding: 24px 32px 48px; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 16px; margin-bottom: 28px; }
    .card { background: #111827; border: 1px solid #334155; border-radius: 16px; padding: 20px; }
    .card h2 { margin: 0 0 10px; font-size: 12px; color: #38bdf8; text-transform: uppercase; letter-spacing: 0.08em; }
    .card p, .card li { font-size: 14px; line-height: 1.55; color: #cbd5e1; }
    .url { font-family: Consolas, monospace; background: #0f172a; border: 1px solid #475569; padding: 10px 12px; border-radius: 10px; font-size: 14px; word-break: break-all; margin-top: 10px; color: #f8fafc; }
    .ok { color: #4ade80; font-weight: 700; }
    table { width: 100%; border-collapse: collapse; background: #111827; border-radius: 16px; overflow: hidden; border: 1px solid #334155; }
    th, td { padding: 12px 14px; text-align: left; border-bottom: 1px solid #1e293b; font-size: 14px; }
    th { background: #1e293b; font-size: 11px; text-transform: uppercase; color: #94a3b8; letter-spacing: 0.06em; }
    a { color: #38bdf8; font-weight: 600; text-decoration: none; }
    a:hover { text-decoration: underline; }
    .empty { color: #94a3b8; padding: 24px; text-align: center; }
    .steps { background: #172554; border: 1px solid #1d4ed8; border-radius: 14px; padding: 18px 20px; margin-bottom: 24px; }
    .steps ol { margin: 8px 0 0; padding-left: 20px; }
    .steps li { margin-bottom: 6px; }
  </style>
</head>
<body>
  <header>
    <h1>SpeakEasy Reports</h1>
    <p>Office archive server — receive inspections from your phone and view reports with video + transcripts.</p>
  </header>
  <main>
    <div class="steps">
      <strong>Connect your phone (FlutterFlow app)</strong>
      <ol>
        <li>Phone and PC on the <strong>same Wi‑Fi</strong></li>
        <li>In SpeakEasy app → <strong>Settings</strong> → paste the API URL below</li>
        <li>Tap <strong>Test connection</strong>, then finish an inspection and <strong>Push to PC</strong></li>
      </ol>
    </div>

    <div class="grid">
      <div class="card">
        <h2>Server status</h2>
        <p class="ok">● Running on port ${port}</p>
        <p>Reports folder:</p>
        <div class="url">${reportsDir}</div>
      </div>
      <div class="card">
        <h2>Phone API URL</h2>
        <p>Copy into SpeakEasy app Settings:</p>
        <div class="url" id="apiUrl">${phoneApiUrl}</div>
      </div>
      <div class="card">
        <h2>Health check</h2>
        <p>Phone tests: <span class="url" style="margin-top:0;display:inline;padding:4px 8px">GET /health</span></p>
        <p style="margin-top:10px">Use the SpeakEasy Desktop app for QR setup and push status.</p>
      </div>
    </div>

    <h2 style="font-size:20px;margin-bottom:12px">Synced reports</h2>
    <div id="reports">Loading…</div>
  </main>
  <script>
    async function loadReports() {
      const el = document.getElementById('reports');
      try {
        const res = await fetch('/api/reports');
        const data = await res.json();
        if (!data.reports?.length) {
          el.innerHTML = '<p class="empty">No reports yet. Push from your phone after finishing an inspection.</p>';
          return;
        }
        const rows = data.reports.map((r) => {
          const label = r.clientName || r.jobReference || r.folder;
          const meta = [r.inspectionType, r.siteAddress].filter(Boolean).join(' · ');
          const when = r.generatedAt ? new Date(r.generatedAt).toLocaleString() : '—';
          const html = '/reports/' + encodeURIComponent(r.folder) + '/report.html';
          return '<tr><td><a href="' + html + '" target="_blank">' + label + '</a><br><small style="color:#94a3b8">' + meta + '</small></td><td>' + when + '</td><td>' + (r.mediaCount ?? '—') + '</td></tr>';
        }).join('');
        el.innerHTML = '<table><thead><tr><th>Report</th><th>Generated</th><th>Media</th></tr></thead><tbody>' + rows + '</tbody></table>';
      } catch (e) {
        el.innerHTML = '<p class="empty">Could not load reports.</p>';
      }
    }
    loadReports();
    setInterval(loadReports, 12000);
  </script>
</body>
</html>`);
  };
}