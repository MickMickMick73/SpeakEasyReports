const HALLUCINATION_PATTERNS = [
  /^H{6,}/i,
  /^(M[-\s]*){4,}/i,
  /^(\b\w\b[\s-]*){6,}$/,
  /(.)\1{12,}/,
];

export function isUsableTranscript(text) {
  const trimmed = String(text ?? '').trim();
  if (trimmed.length < 8) return false;

  const words = trimmed.match(/\b[a-zA-Z]{2,}\b/g) ?? [];
  if (words.length < 3) return false;

  const uniqueWords = new Set(words.map((word) => word.toLowerCase()));
  if (uniqueWords.size < 2) return false;

  const compact = trimmed.replace(/\s/g, '');
  if (!compact) return false;

  const charCounts = new Map();
  for (const char of compact) {
    charCounts.set(char, (charCounts.get(char) ?? 0) + 1);
  }
  const dominant = Math.max(...charCounts.values());
  if (dominant / compact.length > 0.45) return false;

  if (HALLUCINATION_PATTERNS.some((pattern) => pattern.test(trimmed))) {
    return false;
  }

  const letterRatio = (trimmed.match(/[a-zA-Z]/g) ?? []).length / trimmed.length;
  if (letterRatio < 0.35) return false;

  return true;
}

export function scoreTranscript(text) {
  if (!isUsableTranscript(text)) return 0;
  const words = text.match(/\b[a-zA-Z]{2,}\b/g) ?? [];
  const uniqueWords = new Set(words.map((word) => word.toLowerCase()));
  return uniqueWords.size * 20 + Math.min(words.join(' ').length, 300);
}

export function sanitizeTranscript(text) {
  const trimmed = String(text ?? '').trim();
  return isUsableTranscript(trimmed) ? trimmed : '';
}