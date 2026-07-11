// Synthetic audio generation via Sarvam Bulbul (bulbul:v2) TTS.
//
// Each script in the answer key is a two-party PATIENT/DOCTOR dialogue. We give
// the patient and the doctor DIFFERENT voices and stitch their utterances in
// order, so the resulting clip is genuinely two-speaker audio — which is what
// Sarvam's diarized STT expects (the app records real 2-speaker consultations).
// The spoken "PATIENT:"/"DOCTOR:" labels are stripped before synthesis so they
// are not read aloud.
//
// TTS is cached to disk: if audio/<id>.wav exists we skip regeneration, because
// Bulbul calls cost money.

import { concatWavs, durationOfBytes } from "./wav.ts";

const SARVAM_BASE = "https://api.sarvam.ai";
const TTS_MODEL = "bulbul:v2";
const TARGET_LANG = "hi-IN"; // Hindi / code-mixed Hinglish
const SAMPLE_RATE = 22050;
// Bulbul accepts up to ~500 chars per input; keep a margin.
const MAX_CHARS_PER_CALL = 480;

// bulbul:v2 speakers, alternating gender so doctor/patient are easy to tell
// apart (helps diarization on the synthetic audio).
const FEMALE = ["anushka", "manisha", "vidya", "arya"];
const MALE = ["abhilash", "karun", "hitesh"];
const PACES = [0.9, 1.0, 1.1]; // nudge speed ±10% across the set

export interface Utterance {
  role: "PATIENT" | "DOCTOR";
  text: string;
}

export interface TtsProfile {
  doctorSpeaker: string;
  patientSpeaker: string;
  pace: number;
}

export interface TtsResult {
  path: string;
  cached: boolean;
  durationSeconds: number;
  charCount: number;
  wallSeconds: number;
  profile: TtsProfile;
}

/** Pick a distinct voice per role and a pace, rotating across the 12 scripts. */
export function profileFor(index: number): TtsProfile {
  // Doctor draws from one gender pool, patient from the other, so they differ.
  const doctorPool = index % 2 === 0 ? MALE : FEMALE;
  const patientPool = index % 2 === 0 ? FEMALE : MALE;
  return {
    doctorSpeaker: doctorPool[index % doctorPool.length],
    patientSpeaker: patientPool[index % patientPool.length],
    pace: PACES[index % PACES.length],
  };
}

/** Split "PATIENT: ... DOCTOR: ..." dialogue into ordered utterances. */
export function parseUtterances(scriptText: string): Utterance[] {
  const regex = /(PATIENT|DOCTOR)\s*:/g;
  const utterances: Utterance[] = [];
  const matches = [...scriptText.matchAll(regex)];

  if (matches.length === 0) {
    // No labels — treat the whole thing as one doctor utterance.
    const t = scriptText.trim();
    return t ? [{ role: "DOCTOR", text: t }] : [];
  }

  for (let i = 0; i < matches.length; i++) {
    const m = matches[i];
    const role = m[1] as "PATIENT" | "DOCTOR";
    const start = m.index! + m[0].length;
    const end = i + 1 < matches.length
      ? matches[i + 1].index!
      : scriptText.length;
    const text = scriptText.slice(start, end).trim();
    if (text) utterances.push({ role, text });
  }
  return utterances;
}

/** Break a long utterance into <=MAX_CHARS_PER_CALL chunks at sentence/space. */
function chunkText(text: string): string[] {
  if (text.length <= MAX_CHARS_PER_CALL) return [text];
  const chunks: string[] = [];
  let remaining = text.trim();
  while (remaining.length > MAX_CHARS_PER_CALL) {
    let cut = remaining.lastIndexOf(".", MAX_CHARS_PER_CALL);
    if (cut < MAX_CHARS_PER_CALL * 0.5) {
      cut = remaining.lastIndexOf(" ", MAX_CHARS_PER_CALL);
    }
    if (cut <= 0) cut = MAX_CHARS_PER_CALL;
    chunks.push(remaining.slice(0, cut + 1).trim());
    remaining = remaining.slice(cut + 1).trim();
  }
  if (remaining) chunks.push(remaining);
  return chunks;
}

async function synthesizeChunk(
  key: string,
  text: string,
  speaker: string,
  pace: number,
): Promise<Uint8Array> {
  const res = await fetch(`${SARVAM_BASE}/text-to-speech`, {
    method: "POST",
    headers: {
      "API-Subscription-Key": key,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      text,
      target_language_code: TARGET_LANG,
      speaker,
      pace,
      pitch: 0,
      loudness: 1.0,
      speech_sample_rate: SAMPLE_RATE,
      enable_preprocessing: true,
      model: TTS_MODEL,
    }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Sarvam TTS ${res.status}: ${body}`);
  }

  const body = (await res.json()) as { audios?: string[] };
  const b64 = body.audios?.[0];
  if (!b64) throw new Error("Sarvam TTS returned no audio.");
  // Decode base64 WAV.
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

/**
 * Generate (or reuse cached) audio for one script. Returns metadata including
 * TTS wall time and character count for cost logging.
 */
export async function generateAudio(
  key: string,
  scriptText: string,
  outPath: string,
  profile: TtsProfile,
): Promise<TtsResult> {
  // Cache hit — skip regeneration.
  try {
    const existing = await Deno.readFile(outPath);
    return {
      path: outPath,
      cached: true,
      durationSeconds: durationOfBytes(existing),
      charCount: 0,
      wallSeconds: 0,
      profile,
    };
  } catch {
    // Not cached — synthesize below.
  }

  const utterances = parseUtterances(scriptText);
  const started = performance.now();
  const clips: Uint8Array[] = [];
  let charCount = 0;

  for (const utt of utterances) {
    const speaker = utt.role === "DOCTOR"
      ? profile.doctorSpeaker
      : profile.patientSpeaker;
    for (const chunk of chunkText(utt.text)) {
      charCount += chunk.length;
      clips.push(await synthesizeChunk(key, chunk, speaker, profile.pace));
    }
  }

  const wav = concatWavs(clips);
  await Deno.writeFile(outPath, wav);
  const wallSeconds = (performance.now() - started) / 1000;

  return {
    path: outPath,
    cached: false,
    durationSeconds: durationOfBytes(wav),
    charCount,
    wallSeconds,
    profile,
  };
}
