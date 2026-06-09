# Data Models — SpeakEasy Reports

Mirror of InspectPro v3 `AssessmentSession` for FlutterFlow App State / local DB.

## Session (JSON)

```json
{
  "id": "uuid",
  "jobReference": "Smith Plumbing",
  "inspectionType": "general",
  "clientName": "Smith Plumbing",
  "clientEmail": "client@example.com",
  "siteAddress": "12 Main St",
  "reportFields": {
    "jobDescription": "Annual inspection",
    "summary": "Annual inspection"
  },
  "workflowStep": "setup",
  "status": "active",
  "syncStatus": "pending",
  "startedAt": "2026-06-08T10:00:00.000Z",
  "endedAt": null,
  "issues": [],
  "recommendations": [],
  "media": [],
  "voiceLog": [],
  "localReportHtmlUri": null,
  "localReportPdfUri": null,
  "manifestHash": null,
  "syncError": null
}
```

### Status enums
- `status`: `idle` | `active` | `review` | `saved`
- `workflowStep`: `setup` | `inspecting` | `review` | `deliver`
- `syncStatus`: `idle` | `pending` | `uploading` | `complete` | `failed`

### Media item

```json
{
  "id": "uuid",
  "type": "photo",
  "localPath": "/path/to/file.jpg",
  "contentHash": "sha256hex",
  "createdAt": "ISO",
  "transcript": "",
  "transcriptSegments": [{ "text": "...", "offsetMs": 0 }],
  "recordingStartedAt": null,
  "recordingEndedAt": null,
  "narrationAudioId": null,
  "uploadStatus": "pending"
}
```

Types: `photo` | `video` | `audio`

### Issue

```json
{ "id": "uuid", "description": "Cracked tile in bathroom", "severity": "medium" }
```

## Inspection types

| id | title |
|----|-------|
| general | General inspection |
| plumbing | Plumbing |
| electrical | Electrical |
| building | Building |

## Settings defaults

```json
{
  "inspectorName": "",
  "companyName": "",
  "companyPhone": "",
  "companyEmail": "",
  "defaultEmailSubject": "{{inspectionType}} Report — {{siteAddress}}",
  "defaultEmailBody": "Hi {{clientName}},\n\nPlease find attached...",
  "apiBaseUrl": "http://192.168.1.94:3001",
  "localServerEnabled": true,
  "appearanceDark": true,
  "useBigKeyboard": true
}
```

## Manifest (sent to PC)

Built at push time — exclude `audio` media from array; link via `narrationAudioId` on video.

Required fields: `sessionId`, `clientName`, `siteAddress`, `inspectionType`, `media[]`, `manifestHash`, `createdAt`.