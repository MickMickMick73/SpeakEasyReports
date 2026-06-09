const { app, BrowserWindow, ipcMain, shell } = require('electron');
const path = require('path');
const { spawn } = require('child_process');
const fs = require('fs');
const os = require('os');
const QRCode = require('qrcode');

const PORT = 3001;
let mainWindow = null;
let apiProcess = null;

function getLanIp() {
  const nets = os.networkInterfaces();
  for (const entries of Object.values(nets)) {
    for (const entry of entries ?? []) {
      if (entry.family === 'IPv4' && !entry.internal) return entry.address;
    }
  }
  return '127.0.0.1';
}

function projectRoot() {
  return path.join(__dirname, '..');
}

function reportsDir() {
  return path.join(projectRoot(), 'reports');
}

function startApiServer() {
  if (apiProcess) return;

  const apiDir = path.join(projectRoot(), 'api');
  const lanIp = getLanIp();
  const env = {
    ...process.env,
    PUBLIC_BASE_URL: `http://${lanIp}:${PORT}`,
    SKIP_VIDEO_TRANSCRIPTION: '1',
    PATH: process.env.PATH,
  };

  const nodeCmd = process.platform === 'win32' ? 'node.exe' : 'node';
  apiProcess = spawn(nodeCmd, ['src/index.js'], {
    cwd: apiDir,
    env,
    stdio: ['ignore', 'pipe', 'pipe'],
    shell: false,
  });

  apiProcess.stdout.on('data', (chunk) => {
    const text = chunk.toString();
    if (mainWindow && !mainWindow.isDestroyed()) {
      mainWindow.webContents.send('api-log', text);
    }
  });

  apiProcess.stderr.on('data', (chunk) => {
    const text = chunk.toString();
    if (mainWindow && !mainWindow.isDestroyed()) {
      mainWindow.webContents.send('api-log', text);
    }
  });

  apiProcess.on('exit', (code) => {
    apiProcess = null;
    if (mainWindow && !mainWindow.isDestroyed()) {
      mainWindow.webContents.send('api-stopped', code);
    }
  });
}

function stopApiServer() {
  if (!apiProcess) return;
  apiProcess.kill();
  apiProcess = null;
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1180,
    height: 820,
    minWidth: 960,
    minHeight: 640,
    title: 'SpeakEasy Reports',
    backgroundColor: '#0b1220',
    autoHideMenuBar: true,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  mainWindow.loadFile(path.join(__dirname, 'renderer', 'index.html'));
}

app.whenReady().then(() => {
  fs.mkdirSync(reportsDir(), { recursive: true });
  startApiServer();
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  stopApiServer();
  if (process.platform !== 'darwin') app.quit();
});

app.on('before-quit', () => stopApiServer());

ipcMain.handle('get-connection-info', async () => {
  const lanIp = getLanIp();
  const apiUrl = `http://${lanIp}:${PORT}`;
  const connectUrl = `${apiUrl}/connect`;
  const qrDataUrl = await QRCode.toDataURL(connectUrl, {
    margin: 1,
    width: 220,
    color: { dark: '#0f172a', light: '#ffffff' },
  });
  return {
    lanIp,
    port: PORT,
    apiUrl,
    connectUrl,
    healthUrl: `${apiUrl}/health`,
    reportsDir: reportsDir(),
    linkDir: path.join(projectRoot(), 'link-share'),
    qrDataUrl,
    serverRunning: Boolean(apiProcess),
  };
});

ipcMain.handle('fetch-health', async () => {
  const lanIp = getLanIp();
  const url = `http://127.0.0.1:${PORT}/health`;
  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(2500) });
    const data = await res.json();
    return { ok: res.ok, data };
  } catch (error) {
    return { ok: false, error: error.message, url: `http://${lanIp}:${PORT}/health` };
  }
});

ipcMain.handle('fetch-reports', async () => {
  try {
    const res = await fetch(`http://127.0.0.1:${PORT}/api/reports`, {
      signal: AbortSignal.timeout(5000),
    });
    return await res.json();
  } catch (error) {
    return { reports: [], error: error.message };
  }
});

ipcMain.handle('open-reports-folder', () => {
  shell.openPath(reportsDir());
});

ipcMain.handle('open-link-folder', () => {
  const dir = path.join(projectRoot(), 'link-share');
  fs.mkdirSync(dir, { recursive: true });
  shell.openPath(dir);
});

ipcMain.handle('open-dashboard', () => {
  shell.openExternal(`http://localhost:${PORT}`);
});

ipcMain.handle('restart-server', () => {
  stopApiServer();
  startApiServer();
  return { restarted: true };
});