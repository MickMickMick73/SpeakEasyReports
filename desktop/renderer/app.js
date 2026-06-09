const apiUrlEl = document.getElementById('apiUrl');
const qrImage = document.getElementById('qrImage');
const serverStatus = document.getElementById('serverStatus');
const testResult = document.getElementById('testResult');
const reportsBody = document.getElementById('reportsBody');

let currentApiUrl = '';

function setView(name) {
  document.querySelectorAll('.view').forEach((v) => v.classList.remove('active'));
  document.querySelectorAll('.nav-btn').forEach((b) => b.classList.remove('active'));
  document.getElementById(`view-${name}`)?.classList.add('active');
  document.querySelector(`[data-view="${name}"]`)?.classList.add('active');
  if (name === 'reports') loadReports();
  if (name === 'link') loadLink();
}

document.querySelectorAll('.nav-btn').forEach((btn) => {
  btn.addEventListener('click', () => setView(btn.dataset.view));
});

async function loadConnectionInfo() {
  const info = await window.speakeasy.getConnectionInfo();
  currentApiUrl = info.apiUrl;
  apiUrlEl.textContent = info.apiUrl;
  const linkUrlEl = document.getElementById('linkUrl');
  if (linkUrlEl) linkUrlEl.textContent = info.connectUrl ? info.connectUrl.replace('/connect', '/link') : `${info.apiUrl}/link`;
  qrImage.src = info.qrDataUrl;
  serverStatus.textContent = info.serverRunning ? '● Server running' : '○ Server stopped';
  serverStatus.className = `status-pill ${info.serverRunning ? 'ok' : 'warn'}`;
}

async function testConnection() {
  testResult.textContent = 'Testing…';
  testResult.className = 'hint';
  const result = await window.speakeasy.fetchHealth();
  if (result.ok && result.data?.ok) {
    testResult.textContent = `Connected — SpeakEasy API v${result.data.version || '1.0.0'} (${result.data.mode} mode)`;
    testResult.className = 'hint ok';
    serverStatus.textContent = '● Server running';
    serverStatus.className = 'status-pill ok';
  } else {
    testResult.textContent = `Could not reach server. ${result.error || 'Is port 3001 free?'}`;
    testResult.className = 'hint err';
  }
}

async function loadReports() {
  reportsBody.innerHTML = '<tr><td colspan="5" class="empty">Loading…</td></tr>';
  const data = await window.speakeasy.fetchReports();
  const reports = data.reports || [];
  if (!reports.length) {
    reportsBody.innerHTML =
      '<tr><td colspan="5" class="empty">No reports yet. Finish an inspection on your phone and tap Push to PC.</td></tr>';
    return;
  }
  reportsBody.innerHTML = reports
    .map((r) => {
      const label = r.clientName || r.jobReference || r.folder;
      const when = r.generatedAt ? new Date(r.generatedAt).toLocaleString() : '—';
      const href = `http://localhost:3001/reports/${encodeURIComponent(r.folder)}/report.html`;
      return `<tr>
        <td><strong>${escapeHtml(label)}</strong></td>
        <td>${escapeHtml(r.siteAddress || '—')}</td>
        <td>${escapeHtml(r.inspectionType || '—')}</td>
        <td>${when}</td>
        <td><button class="link-btn" data-href="${href}">Open report</button></td>
      </tr>`;
    })
    .join('');

  reportsBody.querySelectorAll('.link-btn').forEach((btn) => {
    btn.addEventListener('click', () => window.open(btn.dataset.href, '_blank'));
  });
}

function escapeHtml(text) {
  return String(text)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

document.getElementById('copyUrlBtn').addEventListener('click', async () => {
  await navigator.clipboard.writeText(currentApiUrl);
  testResult.textContent = 'API URL copied to clipboard.';
  testResult.className = 'hint ok';
});

document.getElementById('testBtn').addEventListener('click', testConnection);
document.getElementById('restartBtn').addEventListener('click', async () => {
  await window.speakeasy.restartServer();
  setTimeout(async () => {
    await loadConnectionInfo();
    await testConnection();
  }, 1500);
});
document.getElementById('refreshReportsBtn').addEventListener('click', loadReports);
document.getElementById('openFolderBtn').addEventListener('click', () => window.speakeasy.openReportsFolder());
document.getElementById('openWebBtn').addEventListener('click', () => window.speakeasy.openDashboard());

async function loadLink() {
  const statusEl = document.getElementById('linkStatus');
  const body = document.getElementById('linkFilesBody');
  if (!statusEl || !body) return;
  statusEl.textContent = 'Checking link service…';
  try {
    const res = await fetch('http://127.0.0.1:3001/api/link/status');
    const data = await res.json();
    if (!res.ok || !data.ok) throw new Error('Link API unavailable');
    statusEl.textContent = `Connected · ${data.fileCount} shared file(s)`;
    if (!data.files?.length) {
      body.innerHTML = '<tr><td colspan="3" class="empty">No files yet. Upload from phone Link app or drop files into link-share folder.</td></tr>';
      return;
    }
    body.innerHTML = data.files
      .map((f) => {
        const when = new Date(f.modifiedAt).toLocaleString();
        const kb = Math.max(1, Math.round(f.bytes / 1024));
        return `<tr><td>${escapeHtml(f.name)}</td><td>${kb} KB</td><td>${when}</td></tr>`;
      })
      .join('');
  } catch (error) {
    statusEl.textContent = `Link offline — ${error.message}`;
    body.innerHTML = '<tr><td colspan="3" class="empty">Start SpeakEasy-Link.bat or SpeakEasy-PC.bat first.</td></tr>';
  }
}

document.getElementById('openLinkBtn')?.addEventListener('click', () => {
  const url = document.getElementById('linkUrl')?.textContent;
  if (url) window.open(url, '_blank');
});
document.getElementById('openLinkFolderBtn')?.addEventListener('click', () => window.speakeasy.openLinkFolder());

window.speakeasy.onApiStopped(() => {
  serverStatus.textContent = '○ Server stopped';
  serverStatus.className = 'status-pill warn';
});

loadConnectionInfo();
setTimeout(testConnection, 2000);
setInterval(loadReports, 20000);