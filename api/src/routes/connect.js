export function createConnectRouter({ lanIp, port }) {
  const phoneApiUrl = `http://${lanIp}:${port}`;

  return (_req, res) => {
    res.type('html').send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>LAN Connect Hub</title>
  <style>
    * { box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; margin: 0; background: #0b1220; color: #e2e8f0; padding: 20px; }
    .card { background: #111827; border: 1px solid #334155; border-radius: 16px; padding: 18px; margin-bottom: 14px; }
    h1 { font-size: 22px; margin: 0 0 6px; }
    .sub { color: #94a3b8; font-size: 14px; line-height: 1.45; margin-bottom: 16px; }
    .label { font-size: 11px; text-transform: uppercase; letter-spacing: 0.08em; color: #38bdf8; margin-bottom: 8px; }
    .url { font-family: ui-monospace, Consolas, monospace; background: #0f172a; border: 2px solid #475569; border-radius: 12px; padding: 14px; font-size: 16px; word-break: break-all; }
    button { width: 100%; border: 0; border-radius: 12px; padding: 14px; font-size: 16px; font-weight: 700; margin-top: 10px; }
    .primary { background: #0ea5e9; color: #fff; }
    .secondary { background: #1e293b; color: #e2e8f0; border: 1px solid #475569; }
    .status { margin-top: 12px; padding: 12px; border-radius: 12px; font-size: 14px; line-height: 1.45; }
    .ok { background: #052e16; border: 1px solid #166534; color: #86efac; }
    .bad { background: #450a0a; border: 1px solid #991b1b; color: #fca5a5; }
    .wait { background: #172554; border: 1px solid #1d4ed8; color: #bfdbfe; }
    ol { margin: 8px 0 0; padding-left: 20px; }
    li { margin-bottom: 8px; font-size: 14px; line-height: 1.45; }
    .apps { display: grid; gap: 10px; }
    .app { background: #0f172a; border: 1px solid #334155; border-radius: 12px; padding: 12px; }
    .app strong { display: block; margin-bottom: 4px; }
    .note { font-size: 13px; color: #fbbf24; line-height: 1.45; }
  </style>
</head>
<body>
  <h1>LAN Connect Hub</h1>
  <p class="sub">Universal PC sync setup for InspectPro, SpeakEasy, and future field apps. This page does <strong>not</strong> install app updates — it only connects report sync.</p>

  <div class="card">
    <div class="label">API URL (copy into phone app Settings)</div>
    <div class="url" id="apiUrl">${phoneApiUrl}</div>
    <button class="primary" id="copyBtn">Copy API URL</button>
    <button class="secondary" id="testBtn">Test like the phone app</button>
    <div class="status wait" id="status">Tap “Test like the phone app” — same check InspectPro uses.</div>
  </div>

  <div class="card">
    <div class="label">What this connection is for</div>
    <ul>
      <li><strong>Report sync</strong> — push finished inspections from phone → PC</li>
      <li><strong>Not app updates</strong> — new app versions install via TestFlight, APK, or App Store</li>
    </ul>
    <p class="note">Expo Go used to auto-detect your PC IP while developing. Installed apps keep the last saved URL — update it here if your PC IP changed.</p>
  </div>

  <div class="card apps">
    <div class="label">Per-app steps</div>
    <div class="app">
      <strong>InspectPro (installed on iPhone)</strong>
      Settings → Local office server → API base URL → paste URL → Test API connection → Save
    </div>
    <div class="app">
      <strong>SpeakEasy Reports (Flutter)</strong>
      Settings → Office PC URL → paste URL → Test connection
    </div>
    <div class="app">
      <strong>Any future app</strong>
      Point sync settings to <code>${phoneApiUrl}</code> and test <code>GET /health</code>
    </div>
  </div>

  <script>
    const apiUrl = ${JSON.stringify(phoneApiUrl)};
    const statusEl = document.getElementById('status');

    document.getElementById('copyBtn').addEventListener('click', async () => {
      try {
        await navigator.clipboard.writeText(apiUrl);
        statusEl.className = 'status ok';
        statusEl.textContent = 'Copied. Open your field app Settings and paste the URL.';
      } catch {
        statusEl.className = 'status bad';
        statusEl.textContent = 'Could not copy — select and copy the URL box manually.';
      }
    });

    document.getElementById('testBtn').addEventListener('click', async () => {
      statusEl.className = 'status wait';
      statusEl.textContent = 'Testing GET /health (2.5s timeout, same as InspectPro)…';
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 2500);
      try {
        const res = await fetch(apiUrl + '/health', { signal: controller.signal });
        clearTimeout(timeout);
        const data = await res.json();
        if (res.ok && data.ok) {
          statusEl.className = 'status ok';
          statusEl.textContent = 'Phone can reach PC API. Paste URL into your app Settings if sync still fails there.';
        } else {
          statusEl.className = 'status bad';
          statusEl.textContent = 'Reachable but unexpected health response. HTTP ' + res.status;
        }
      } catch (err) {
        clearTimeout(timeout);
        statusEl.className = 'status bad';
        statusEl.textContent = 'Failed: ' + (err.name === 'AbortError' ? 'Timed out after 2.5s' : err.message);
      }
    });
  </script>
</body>
</html>`);
  };
}

export function createConnectionJsonHandler({ lanIp, port, reportsDir }) {
  return (_req, res) => {
    const apiUrl = `http://${lanIp}:${port}`;
    res.json({
      ok: true,
      service: 'LAN Connect Hub',
      apiUrl,
      healthUrl: `${apiUrl}/health`,
      connectUrl: `${apiUrl}/connect`,
      lanIp,
      port,
      reportsDir,
      compatibleApps: ['InspectPro', 'SpeakEasyReports'],
      purpose: 'inspection-report-sync',
      notFor: 'app-version-deployment',
    });
  };
}