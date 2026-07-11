// Cost estimation, in ₹. The Sarvam/Gemini APIs don't return per-call billing,
// so these are ESTIMATES derived from published list prices. Adjust the rate
// constants below to match your actual plan — every number in the report that
// depends on cost flows from here.

// ── Rate constants (edit to match your billing) ────────────────────────────
export const USD_TO_INR = 83;

// Sarvam Speech-to-Text (Saaras), billed per minute of audio (estimate).
export const SARVAM_STT_PER_MIN_INR = 0.5;

// Sarvam Bulbul TTS, billed per character (estimate). Only affects the
// test-generation cost line, not per-consultation cost.
export const SARVAM_TTS_PER_1K_CHARS_INR = 3.0;

// Google Gemini 2.5 Flash list price (USD per 1M tokens).
export const GEMINI_IN_PER_1M_USD = 0.3;
export const GEMINI_OUT_PER_1M_USD = 2.5;

// Rough token estimate: ~4 characters per token.
const CHARS_PER_TOKEN = 4;

export interface ConsultCost {
  sttInr: number;
  geminiInr: number;
  totalInr: number;
}

/** Estimated STT cost for a clip of the given audio duration. */
export function sttCost(durationSeconds: number): number {
  return (durationSeconds / 60) * SARVAM_STT_PER_MIN_INR;
}

/**
 * Estimated Gemini cost for one extraction. We approximate input tokens from
 * the transcript length plus a fixed system-prompt allowance, and output tokens
 * from the serialized insight length (plus the thinking budget of 1024).
 */
export function geminiCost(
  transcriptChars: number,
  outputChars: number,
): number {
  const SYSTEM_PROMPT_TOKENS = 900; // the (long) scribe instruction
  const THINKING_TOKENS = 1024; // generationConfig.thinkingConfig
  const inTokens = SYSTEM_PROMPT_TOKENS + transcriptChars / CHARS_PER_TOKEN;
  const outTokens = THINKING_TOKENS + outputChars / CHARS_PER_TOKEN;
  const usd = (inTokens / 1e6) * GEMINI_IN_PER_1M_USD +
    (outTokens / 1e6) * GEMINI_OUT_PER_1M_USD;
  return usd * USD_TO_INR;
}

export function consultCost(
  durationSeconds: number,
  transcriptChars: number,
  outputChars: number,
): ConsultCost {
  const stt = sttCost(durationSeconds);
  const gem = geminiCost(transcriptChars, outputChars);
  return { sttInr: stt, geminiInr: gem, totalInr: stt + gem };
}

/** Estimated TTS cost for synthesizing `chars` characters. */
export function ttsCost(chars: number): number {
  return (chars / 1000) * SARVAM_TTS_PER_1K_CHARS_INR;
}
