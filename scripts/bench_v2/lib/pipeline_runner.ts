// Runs one audio clip through the REAL pipeline by importing the SAME module
// the deployed Edge Function uses — supabase/functions/_shared/pipeline.ts.
// Nothing here re-implements STT or extraction: we call decideRouting,
// transcribeRest / transcribeBatchSync, and extractInsight verbatim, mirroring
// the routing/wiring in process-consultation/index.ts. The only difference from
// production is the audio source: we read a local WAV instead of downloading it
// from Supabase Storage.

import {
  decideRouting,
  extractInsight,
  type MedicalInsight,
  transcribeBatchSync,
  transcribeRest,
} from "../../../supabase/functions/_shared/pipeline.ts";

export type { MedicalInsight };

export interface PipelineRun {
  routing: "rest" | "batch_sync" | "batch_async";
  transcript: string;
  insight: MedicalInsight;
  sttMs: number;
  geminiMs: number;
  totalMs: number;
}

/**
 * Execute the real STT -> Gemini pipeline once for a local audio file.
 * `languageCode` defaults to "unknown" to match the app's default
 * (consultation_controller.dart: languageCode = 'unknown').
 */
export async function runPipeline(
  audioPath: string,
  sarvamKey: string,
  geminiKey: string,
  languageCode = "unknown",
): Promise<PipelineRun> {
  const audioBytes = await Deno.readFile(audioPath);
  const filename = audioPath.split("/").pop() ?? "audio.wav";

  // Duration drives routing exactly as the app does (it passes recording
  // duration to the Edge Function). We read it from the WAV header.
  const durationSeconds = wavDurationSeconds(audioBytes);
  const routing = decideRouting(durationSeconds);

  // ── STT ──────────────────────────────────────────────────────────────────
  const tStt = performance.now();
  let transcript: string;
  if (routing === "rest") {
    transcript = await transcribeRest(
      sarvamKey,
      audioBytes,
      filename,
      languageCode,
    );
  } else {
    // batch_sync and batch_async both use the batch flow for our short clips;
    // transcribeBatchSync polls to completion (all eval clips are < 5 min).
    transcript = await transcribeBatchSync(
      sarvamKey,
      audioBytes,
      filename,
      languageCode,
    );
  }
  const sttMs = performance.now() - tStt;

  // ── Gemini extraction ──────────────────────────────────────────────────────
  const tLlm = performance.now();
  const { transcript: relabeled, insight } = await extractInsight(
    transcript,
    geminiKey,
  );
  const geminiMs = performance.now() - tLlm;

  return {
    routing,
    transcript: relabeled,
    insight,
    sttMs,
    geminiMs,
    totalMs: sttMs + geminiMs,
  };
}

// Local, header-only WAV duration read (avoids importing the whole wav module
// into the runner; keeps this file focused on pipeline wiring).
function wavDurationSeconds(bytes: Uint8Array): number {
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const ascii = (o: number) =>
    String.fromCharCode(bytes[o], bytes[o + 1], bytes[o + 2], bytes[o + 3]);
  if (ascii(0) !== "RIFF" || ascii(8) !== "WAVE") return 0;

  let sampleRate = 0, channels = 0, bits = 0, dataLen = 0;
  let offset = 12;
  while (offset + 8 <= bytes.length) {
    const id = ascii(offset);
    const size = view.getUint32(offset + 4, true);
    const body = offset + 8;
    if (id === "fmt ") {
      channels = view.getUint16(body + 2, true);
      sampleRate = view.getUint32(body + 4, true);
      bits = view.getUint16(body + 14, true);
    } else if (id === "data") {
      dataLen = size;
    }
    offset = body + size + (size % 2);
  }
  const byteRate = sampleRate * channels * (bits / 8);
  return byteRate === 0 ? 0 : dataLen / byteRate;
}
