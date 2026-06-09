# API Contract — SpeakEasy PC Server

Base URL: `http://{LAN_IP}:3001`  
Compatible with InspectPro v3 mobile sync.

## GET /health

Response:
```json
{
  "ok": true,
  "app": "SpeakEasyReports",
  "version": "1.0.0",
  "mode": "local",
  "phoneApiUrl": "http://192.168.1.94:3001",
  "lanIp": "192.168.1.94",
  "port": 3001
}
```

## POST /api/uploads/presign

Request:
```json
{
  "sessionId": "uuid",
  "files": [
    {
      "mediaId": "uuid",
      "fileName": "video-abc123",
      "contentType": "video/mp4",
      "contentHash": "sha256..."
    }
  ]
}
```

Response:
```json
{
  "uploads": [
    {
      "mediaId": "uuid",
      "uploadUrl": "http://192.168.1.94:3001/api/uploads/file/{sessionId}/{fileName}",
      "remoteUrl": "local://...",
      "contentType": "video/mp4"
    }
  ]
}
```

## PUT {uploadUrl}

Raw file bytes. Header: `Content-Type` matching presign.

## POST /api/uploads/manifest

Request:
```json
{ "manifest": { /* SessionManifest */ } }
```

Response:
```json
{
  "remoteUrl": "local://manifests/{sessionId}.json",
  "reportFolder": "ClientName_abc12345",
  "reportHtml": "...",
  "transcripts": [{ "mediaId": "...", "transcript": "...", "source": "local-whisper" }]
}
```

## GET /api/reports

Response:
```json
{
  "reports": [
    {
      "folder": "Client_abc12345",
      "clientName": "Smith",
      "siteAddress": "12 Main St",
      "inspectionType": "general",
      "generatedAt": "ISO",
      "mediaCount": 3
    }
  ]
}
```

## FlutterFlow test action

```
GET [apiBaseUrl]/health → status 200 && body.ok == true
```