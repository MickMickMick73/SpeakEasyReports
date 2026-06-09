import express from 'express';

const PATTERNS = [
  { pattern: /hydraulic|hose|cylinder/i, component: 'Hydraulics', severity: 'high' },
  { pattern: /track|undercarriage|sprocket/i, component: 'Undercarriage', severity: 'high' },
  { pattern: /engine|coolant|overheat/i, component: 'Engine', severity: 'high' },
  { pattern: /electrical|wiring|battery|alternator/i, component: 'Electrical', severity: 'medium' },
  { pattern: /brake|steering/i, component: 'Brakes/Steering', severity: 'high' },
  { pattern: /tire|tyre|wheel/i, component: 'Wheels', severity: 'medium' },
  { pattern: /crack|fracture|broken/i, component: 'Structure', severity: 'high' },
  { pattern: /leak|leaking|oil|fluid/i, component: 'Fluids', severity: 'medium' },
  { pattern: /wear|worn|damaged/i, component: 'General wear', severity: 'medium' },
];

function extractFromTranscript(transcript) {
  const lines = transcript
    .split(/\n|\.|;/)
    .map((line) => line.trim())
    .filter((line) => line.length >= 8);

  const issues = [];
  const seen = new Set();

  for (const line of lines) {
    const key = line.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);

    const match = PATTERNS.find((item) => item.pattern.test(line));
    issues.push({
      description: line,
      component: match?.component,
      severity: match?.severity ?? 'medium',
      confidence: match ? 0.8 : 0.65,
    });
  }

  return issues.slice(0, 12);
}

export function createIssuesRouter() {
  const router = express.Router();

  router.post('/extract', (req, res) => {
    const { transcript } = req.body ?? {};
    if (!transcript || typeof transcript !== 'string') {
      return res.status(400).json({ error: 'transcript is required' });
    }

    const issues = extractFromTranscript(transcript);
    res.json({ issues });
  });

  return router;
}