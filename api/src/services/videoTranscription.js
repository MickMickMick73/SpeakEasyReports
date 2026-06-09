import { spawnSync } from 'child_process';
import fs from 'fs';
import os from 'os';
import path from 'path';

import ffmpegPath from 'ffmpeg-static';
import wavefile from 'wavefile';

import { isUsableTranscript, sanitizeTranscript, scoreTranscript } from './transcriptQuality.js';

const WHISPER_MODELS = ['Xenova/whisper-small.en', 'Xenova/whisper-base.en'];
const AUDIO_FILTERS = [
  null,
  'loudnorm=I=-16:TP=-1.5:LRA=11',
  'dynaudnorm,acompressor,highpass=f=120,lowpass=f=7000,volume=18dB',
  'highpass=f=80,lowpass=f=8000,volume=25dB',
];

const transcriberCache = new Map();
let transcriptionChain = Promise.resolve();

function enqueueTranscription(task) {
  const run = transcriptionChain.then(task);
  transcriptionChain = run.catch(() => {});
  return run;
}

async function getLocalTranscriber(modelId) {
  if (!transcriberCache.has(modelId)) {
    const { pipeline } = await import('@xenova/transformers');
    console.log(`Loading Whisper model ${modelId} (first run may take a minute)...`);
    transcriberCache.set(modelId, pipeline('automatic-speech-recognition', modelId));
  }
  return transcriberCache.get(modelId);
}

function extractAudioToWav(sourcePath, audioFilter) {
  const tmpWav = path.join(
    os.tmpdir(),
    `varm-audio-${Date.now()}-${Math.random().toString(36).slice(2)}.wav`
  );
  const args = ['-y', '-i', sourcePath, '-map', '0:a:0'];
  if (audioFilter) {
    args.push('-af', audioFilter);
  }
  args.push('-ar', '16000', '-ac', '1', '-vn', tmpWav);

  spawnSync(ffmpegPath, args, { stdio: 'ignore', maxBuffer: 1024 * 1024 * 50 });
  if (!fs.existsSync(tmpWav) || fs.statSync(tmpWav).size < 1000) {
    throw new Error('Audio extraction produced an empty file');
  }
  return tmpWav;
}

function measureSpeechRatio(mediaPath) {
  const result = spawnSync(
    ffmpegPath,
    ['-hide_banner', '-i', mediaPath, '-map', '0:a:0', '-af', 'silencedetect=noise=-35dB:d=0.35', '-f', 'null', '-'],
    { encoding: 'utf8', maxBuffer: 1024 * 1024 * 10 }
  );
  const stderr = `${result.stderr ?? ''}${result.stdout ?? ''}`;
  const durationMatch = stderr.match(/Duration:\s*(\d+):(\d+):([\d.]+)/);
  if (!durationMatch) return { speechRatio: 1, mostlySilent: false };

  const totalSeconds =
    Number(durationMatch[1]) * 3600 +
    Number(durationMatch[2]) * 60 +
    Number(durationMatch[3]);
  if (totalSeconds <= 0) return { speechRatio: 0, mostlySilent: true };

  const silenceMatches = [...stderr.matchAll(/silence_duration:\s*([\d.]+)/g)];
  const silentSeconds = silenceMatches.reduce((sum, match) => sum + Number(match[1]), 0);
  const speechRatio = Math.max(0, Math.min(1, 1 - silentSeconds / totalSeconds));

  return {
    speechRatio,
    mostlySilent: speechRatio < 0.35,
    silentSeconds,
    totalSeconds,
  };
}

async function transcribeWithOpenAI(wavPath) {
  if (!process.env.OPENAI_API_KEY) return null;

  try {
    const { default: OpenAI } = await import('openai');
    const { toFile } = await import('openai/uploads');
    const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
    const file = await toFile(fs.createReadStream(wavPath), 'audio.wav', { type: 'audio/wav' });
    const result = await client.audio.transcriptions.create({
      file,
      model: 'whisper-1',
      language: 'en',
    });
    const text = sanitizeTranscript(result.text?.trim() ?? '');
    if (!text) return null;
    return {
      text,
      source: 'openai-whisper',
      segments: [],
    };
  } catch (error) {
    console.warn('OpenAI transcription failed, using local Whisper:', error.message);
    return null;
  }
}

function loadWavSamples(wavPath) {
  const buffer = fs.readFileSync(wavPath);
  const wav = new wavefile.WaveFile(buffer);
  wav.toBitDepth('32f');
  wav.toSampleRate(16000);
  let audioData = wav.getSamples();
  if (Array.isArray(audioData)) {
    if (audioData.length > 1) {
      const merged = new Float32Array(audioData[0].length);
      for (let i = 0; i < merged.length; i += 1) {
        merged[i] = (audioData[0][i] + audioData[1][i]) / 2;
      }
      audioData = merged;
    } else {
      audioData = audioData[0];
    }
  }
  return audioData;
}

function getAudioDurationSeconds(audioData) {
  return audioData.length / 16000;
}

async function transcribeWithLocalWhisper(wavPath, modelId) {
  const transcriber = await getLocalTranscriber(modelId);
  const audioData = loadWavSamples(wavPath);
  const durationSeconds = getAudioDurationSeconds(audioData);
  const options =
    durationSeconds < 25
      ? { language: 'english', task: 'transcribe' }
      : { chunk_length_s: 30, stride_length_s: 5, language: 'english', task: 'transcribe' };

  const result = await transcriber(audioData, options);
  const chunks = result.chunks ?? [];
  const segments = chunks.map((chunk) => ({
    text: chunk.text?.trim() ?? '',
    offsetMs: Math.round((chunk.timestamp?.[0] ?? 0) * 1000),
  }));

  const rawText = (result.text ?? segments.map((segment) => segment.text).join(' ')).trim();
  const text = sanitizeTranscript(rawText);

  return {
    text,
    source: 'local-whisper',
    modelId,
    segments: segments.filter((segment) => segment.text),
    rawText,
  };
}

function pickBestTranscript(results) {
  return (
    results
      .map((result) => ({
        ...result,
        text: sanitizeTranscript(result?.text),
      }))
      .filter((result) => result.text && isUsableTranscript(result.text))
      .sort((a, b) => scoreTranscript(b.text) - scoreTranscript(a.text))[0] ?? null
  );
}

async function transcribeFromWavVariants(sourcePath, label) {
  const speechMetrics = measureSpeechRatio(sourcePath);
  const wavPaths = [];

  try {
    console.log(`Extracting audio from ${label}...`);
    if (speechMetrics.mostlySilent) {
      console.warn(
        `Low speech activity in ${label} (${Math.round(speechMetrics.speechRatio * 100)}% non-silent)`
      );
    }

    for (const audioFilter of AUDIO_FILTERS) {
      try {
        wavPaths.push(extractAudioToWav(sourcePath, audioFilter));
      } catch {
        // Try next filter variant.
      }
    }

    if (!wavPaths.length) {
      throw new Error('Could not extract audio from file');
    }

    for (const wavPath of wavPaths) {
      const openAiResult = await transcribeWithOpenAI(wavPath);
      if (openAiResult?.text) {
        console.log(`OpenAI transcript: ${openAiResult.text.slice(0, 80)}...`);
        return { ...openAiResult, speechMetrics };
      }
    }

    console.log(`Transcribing ${label} with local Whisper...`);
    const localResults = [];
    for (const modelId of WHISPER_MODELS) {
      for (const wavPath of wavPaths) {
        localResults.push(await transcribeWithLocalWhisper(wavPath, modelId));
      }
      const bestForModel = pickBestTranscript(localResults.filter((r) => r.modelId === modelId));
      if (bestForModel?.text) break;
    }

    const best = pickBestTranscript(localResults);
    const localResult = best ?? { text: '', source: 'local-whisper', segments: [] };
    console.log(
      localResult.text
        ? `Local transcript (${localResult.modelId ?? 'unknown'}): ${localResult.text.slice(0, 80)}...`
        : `Local transcript for ${label}: (no usable speech detected)`
    );

    return {
      text: localResult.text,
      source: localResult.source,
      modelId: localResult.modelId,
      segments: localResult.segments,
      speechMetrics,
      noSpeechDetected: !localResult.text,
    };
  } finally {
    for (const wavPath of wavPaths) {
      if (wavPath && fs.existsSync(wavPath)) {
        fs.unlinkSync(wavPath);
      }
    }
  }
}

export async function transcribeMediaFile(mediaPath) {
  if (!ffmpegPath) {
    throw new Error('ffmpeg is not available for audio extraction');
  }
  if (!fs.existsSync(mediaPath)) {
    throw new Error(`Media file not found: ${mediaPath}`);
  }

  return enqueueTranscription(() => transcribeFromWavVariants(mediaPath, path.basename(mediaPath)));
}

export async function transcribeVideoFile(videoPath) {
  return transcribeMediaFile(videoPath);
}

function findMediaFile(sessionId, mediaId, uploadsDir, extensionPattern) {
  const sessionDir = path.join(uploadsDir, sessionId);
  if (!fs.existsSync(sessionDir)) return null;

  const match = fs
    .readdirSync(sessionDir)
    .find((fileName) => fileName.includes(mediaId) && extensionPattern.test(fileName));

  return match ? path.join(sessionDir, match) : null;
}

function findVideoFile(sessionId, mediaId, uploadsDir) {
  return findMediaFile(sessionId, mediaId, uploadsDir, /\.(mp4|mov|m4v|webm)$/i);
}

function findAudioFile(sessionId, mediaId, uploadsDir) {
  return findMediaFile(sessionId, mediaId, uploadsDir, /\.(m4a|aac|wav|mp3|caf)$/i);
}

export async function enrichManifestWithVideoTranscripts(manifest, uploadsDir) {
  const enrichedMedia = [];
  const transcriptResults = [];

  for (const item of manifest.media ?? []) {
    if (item.type !== 'video') {
      enrichedMedia.push(item);
      continue;
    }

    const existingTranscript = sanitizeTranscript(item.transcript);
    if (existingTranscript && isUsableTranscript(existingTranscript)) {
      enrichedMedia.push({ ...item, transcript: existingTranscript });
      transcriptResults.push({
        mediaId: item.id,
        transcript: existingTranscript,
        source: item.transcriptSource ?? 'device',
      });
      continue;
    }

    let result = null;

    if (item.narrationAudioId) {
      const audioPath = findAudioFile(manifest.sessionId, item.narrationAudioId, uploadsDir);
      if (audioPath) {
        try {
          console.log(`Transcribing narration audio for video ${item.id}...`);
          result = await transcribeMediaFile(audioPath);
          if (!result.text || !isUsableTranscript(result.text)) {
            console.warn(`Narration audio transcript unusable for ${item.id}, trying video track`);
            result = null;
          }
        } catch (error) {
          console.warn(`Narration audio transcription failed for ${item.id}:`, error.message);
        }
      } else {
        console.warn(`No uploaded narration audio found for media ${item.narrationAudioId}`);
      }
    }

    if (!result?.text) {
      const videoPath = findVideoFile(manifest.sessionId, item.id, uploadsDir);
      if (!videoPath) {
        console.warn(`No uploaded video file found for media ${item.id}`);
        enrichedMedia.push(item);
        continue;
      }

      try {
        result = await transcribeVideoFile(videoPath);
      } catch (error) {
        console.error(`Transcription failed for ${item.id}:`, error.message);
        enrichedMedia.push(item);
        continue;
      }
    }

    const sanitizedText = sanitizeTranscript(result.text);
    const enriched = {
      ...item,
      transcript: sanitizedText,
      transcriptSegments: result.segments,
      transcriptSource: result.source,
      noSpeechDetected: !sanitizedText,
      speechRatio: result.speechMetrics?.speechRatio,
      recordingStartedAt: item.recordingStartedAt ?? item.createdAt,
      recordingEndedAt: item.recordingEndedAt ?? item.createdAt,
    };
    enrichedMedia.push(enriched);
    transcriptResults.push({
      mediaId: item.id,
      transcript: sanitizedText,
      source: result.source,
      noSpeechDetected: !sanitizedText,
    });
  }

  return {
    manifest: { ...manifest, media: enrichedMedia },
    transcriptResults,
  };
}