const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('speakeasy', {
  getConnectionInfo: () => ipcRenderer.invoke('get-connection-info'),
  fetchHealth: () => ipcRenderer.invoke('fetch-health'),
  fetchReports: () => ipcRenderer.invoke('fetch-reports'),
  openReportsFolder: () => ipcRenderer.invoke('open-reports-folder'),
  openLinkFolder: () => ipcRenderer.invoke('open-link-folder'),
  openDashboard: () => ipcRenderer.invoke('open-dashboard'),
  restartServer: () => ipcRenderer.invoke('restart-server'),
  onApiLog: (callback) => ipcRenderer.on('api-log', (_e, msg) => callback(msg)),
  onApiStopped: (callback) => ipcRenderer.on('api-stopped', (_e, code) => callback(code)),
});