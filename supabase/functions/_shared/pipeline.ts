// Shared pipeline logic: Sarvam STT + Gemini extraction.
// No Supabase client here — endpoints own that. All Sarvam/Gemini functions
// take explicit API keys so they remain testable in isolation.

import { drugMatcher, transliterateDevanagari } from "./drug_matcher.ts";

// ── Constants ─────────────────────────────────────────────────────────────

export const SARVAM_BASE = "https://api.sarvam.ai";
export const GEMINI_ENDPOINT =
  "https://generativelanguage.googleapis.com/v1beta";
export const GEMINI_MODEL = "gemini-2.5-flash";

// Sarvam REST rejects audio > 30 s; keep a 2 s safety margin.
export const REST_THRESHOLD_SECONDS = 28;
// Edge Functions time out after ~150 s; stay well inside with 100 s polling.
export const SYNC_BATCH_THRESHOLD_SECONDS = 300;

// ── Interfaces ────────────────────────────────────────────────────────────

export interface Medication {
  name: string;
  dosage: string;
  frequency: string;
  duration: string;
  timing: string;
  needsReview: boolean;
}

export interface MedicalInsight {
  consultationSummary: string;
  symptoms: string[];
  diagnosis: string;
  differentials: string[];
  medications: Medication[];
  tests: string[];
  advice: string[];
  instructions: string[];
  followUpDays: number | null;
  doctorNotes: string;
  icdCode: string | null;
  icdDescription: string | null;
  icdConfidence: string | null;
}

export interface ExtractionResult {
  transcript: string;
  insight: MedicalInsight;
}

export interface PipelineInput {
  audioPath: string;
  languageCode: string;
  audioDurationSeconds: number | null;
}

export interface PipelineResult {
  mode: "sync" | "async";
  transcript?: string;
  insight?: MedicalInsight;
  jobId?: string;
  sarvamJobId?: string;
}

export interface BatchStatus {
  state: string;
  outputFilename?: string;
  errorMessage?: string;
}

// ── Routing ───────────────────────────────────────────────────────────────

export function decideRouting(
  durationSeconds: number | null,
): "rest" | "batch_sync" | "batch_async" {
  if (durationSeconds === null) return "batch_async";
  if (durationSeconds < REST_THRESHOLD_SECONDS) return "rest";
  if (durationSeconds < SYNC_BATCH_THRESHOLD_SECONDS) return "batch_sync";
  return "batch_async";
}

// ── Sarvam REST (< 28 s) ─────────────────────────────────────────────────

export async function transcribeRest(
  key: string,
  audioBytes: Uint8Array,
  filename: string,
  languageCode: string,
): Promise<string> {
  const mode = languageCode === "unknown" ? "transcribe" : "codemix";

  const form = new FormData();
  form.append(
    "file",
    new Blob([audioBytes as BlobPart], { type: "audio/mp4" }),
    filename,
  );
  form.append("model", "saaras:v3");
  form.append("mode", mode);
  form.append("language_code", languageCode);

  const res = await fetch(`${SARVAM_BASE}/speech-to-text`, {
    method: "POST",
    headers: { "API-Subscription-Key": key, Accept: "application/json" },
    body: form,
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Sarvam REST ${res.status}: ${body}`);
  }

  const body = (await res.json()) as Record<string, unknown>;
  const transcript = body["transcript"] as string | undefined;
  if (!transcript || transcript.trim() === "") {
    const detected = body["language_code"] as string | undefined;
    throw new Error(
      `Sarvam heard audio but produced no transcript (${
        detected ?? "no language detected"
      }).`,
    );
  }
  return transcript;
}

// ── Sarvam Batch primitives ───────────────────────────────────────────────

export async function batchInitiate(
  key: string,
  languageCode: string,
): Promise<string> {
  const mode = languageCode === "unknown" ? "transcribe" : "codemix";

  const res = await fetch(`${SARVAM_BASE}/speech-to-text/job/v1`, {
    method: "POST",
    headers: {
      "API-Subscription-Key": key,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      job_parameters: {
        model: "saaras:v3",
        mode,
        language_code: languageCode,
        with_diarization: true,
        num_speakers: 2,
      },
    }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Sarvam batch initiate ${res.status}: ${body}`);
  }

  const body = (await res.json()) as Record<string, unknown>;
  const jobId = body["job_id"] as string | undefined;
  if (!jobId) throw new Error("Sarvam did not return a job_id.");
  return jobId;
}

export async function batchGetUploadUrl(
  key: string,
  jobId: string,
  filename: string,
): Promise<string> {
  const res = await fetch(
    `${SARVAM_BASE}/speech-to-text/job/v1/upload-files`,
    {
      method: "POST",
      headers: {
        "API-Subscription-Key": key,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ job_id: jobId, files: [filename] }),
    },
  );

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Sarvam get upload URL ${res.status}: ${body}`);
  }

  const body = (await res.json()) as Record<string, unknown>;
  const urls = body["upload_urls"] as
    | Record<string, Record<string, unknown>>
    | undefined;
  const url = urls?.[filename]?.["file_url"] as string | undefined;
  if (!url) throw new Error("Sarvam did not return an upload URL.");
  return url;
}

// Presigned URL is self-authenticating; x-ms-blob-type is mandatory for the
// Azure Blob backend — without it Azure returns 400 MissingRequiredHeader.
export async function batchUploadFile(
  uploadUrl: string,
  audioBytes: Uint8Array,
): Promise<void> {
  const res = await fetch(uploadUrl, {
    method: "PUT",
    headers: {
      "Content-Type": "audio/mp4",
      "x-ms-blob-type": "BlockBlob",
    },
    body: audioBytes as BodyInit,
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Sarvam file upload ${res.status}: ${body}`);
  }
}

export async function batchStartJob(
  key: string,
  jobId: string,
): Promise<void> {
  const res = await fetch(
    `${SARVAM_BASE}/speech-to-text/job/v1/${jobId}/start`,
    {
      method: "POST",
      headers: {
        "API-Subscription-Key": key,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({}),
    },
  );

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Sarvam start job ${res.status}: ${body}`);
  }
}

export async function batchCheckStatus(
  key: string,
  jobId: string,
): Promise<BatchStatus> {
  const res = await fetch(
    `${SARVAM_BASE}/speech-to-text/job/v1/${jobId}/status`,
    {
      method: "GET",
      headers: { "API-Subscription-Key": key },
    },
  );

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Sarvam check status ${res.status}: ${body}`);
  }

  const body = (await res.json()) as Record<string, unknown>;
  const state = (body["job_state"] as string | undefined) ?? "Unknown";

  if (state === "Completed") {
    const details = body["job_details"] as
      | Array<Record<string, unknown>>
      | undefined;
    const outputs = details?.[0]?.["outputs"] as
      | Array<Record<string, unknown>>
      | undefined;
    const outputFilename = outputs?.[0]?.["file_name"] as string | undefined;
    if (!outputFilename) {
      throw new Error("Job completed but no output file listed.");
    }
    return { state, outputFilename };
  }

  if (state === "Failed") {
    const errorMessage = (body["error_message"] as string | undefined) ??
      "Unknown error";
    return { state, errorMessage };
  }

  return { state };
}

export async function batchGetDownloadUrl(
  key: string,
  jobId: string,
  outputFilename: string,
): Promise<string> {
  const res = await fetch(
    `${SARVAM_BASE}/speech-to-text/job/v1/download-files`,
    {
      method: "POST",
      headers: {
        "API-Subscription-Key": key,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ job_id: jobId, files: [outputFilename] }),
    },
  );

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Sarvam get download URL ${res.status}: ${body}`);
  }

  const body = (await res.json()) as Record<string, unknown>;
  const urls = body["download_urls"] as
    | Record<string, Record<string, unknown>>
    | undefined;
  const url = urls?.[outputFilename]?.["file_url"] as string | undefined;
  if (!url) throw new Error("Sarvam did not return a download URL.");
  return url;
}

export async function batchDownloadTranscript(
  downloadUrl: string,
): Promise<string> {
  const res = await fetch(downloadUrl);
  if (!res.ok) {
    throw new Error(`Failed to download Sarvam transcript: ${res.status}`);
  }

  const raw = await res.text();
  const json = JSON.parse(raw) as Record<string, unknown>;

  const segments = _readDiarizedSegments(json["diarized_transcript"]);
  if (segments && segments.length > 0) {
    return _buildDiarizedText(segments);
  }
  return (json["transcript"] as string | undefined) ?? "";
}

function _readDiarizedSegments(
  raw: unknown,
): Array<Record<string, unknown>> | null {
  if (Array.isArray(raw)) return raw as Array<Record<string, unknown>>;
  if (raw !== null && typeof raw === "object") {
    const r = raw as Record<string, unknown>;
    const entries = r["entries"] ?? r["segments"];
    if (Array.isArray(entries)) {
      return entries as Array<Record<string, unknown>>;
    }
  }
  return null;
}

function _buildDiarizedText(
  segments: Array<Record<string, unknown>>,
): string {
  const lines: string[] = [];
  for (const seg of segments) {
    const id = String(seg["speaker_id"] ?? "0");
    const text = ((seg["transcript"] as string | undefined) ?? "").trim();
    if (text) lines.push(`SPEAKER_${id}: ${text}`);
  }
  return lines.join("\n");
}

// Synchronous batch transcription: full flow + polls up to ~100 s.
// Used for audio between REST_THRESHOLD_SECONDS and SYNC_BATCH_THRESHOLD_SECONDS.
export async function transcribeBatchSync(
  key: string,
  audioBytes: Uint8Array,
  filename: string,
  languageCode: string,
): Promise<string> {
  const jobId = await batchInitiate(key, languageCode);
  const uploadUrl = await batchGetUploadUrl(key, jobId, filename);
  await batchUploadFile(uploadUrl, audioBytes);
  await batchStartJob(key, jobId);

  const deadline = Date.now() + 100_000;
  while (Date.now() < deadline) {
    await _delay(3_000);
    const status = await batchCheckStatus(key, jobId);
    console.log(`[batchSync] job=${jobId} state=${status.state}`);

    if (status.state === "Completed" && status.outputFilename) {
      const downloadUrl = await batchGetDownloadUrl(
        key,
        jobId,
        status.outputFilename,
      );
      const transcript = await batchDownloadTranscript(downloadUrl);
      if (!transcript.trim()) {
        throw new Error("Sarvam produced no transcript — likely silent audio.");
      }
      return transcript;
    }

    if (status.state === "Failed") {
      throw new Error(`Sarvam batch job failed: ${status.errorMessage}`);
    }
  }

  throw new Error("Transcription timed out after 100 s.");
}

function _delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// ── Gemini system instructions (VERBATIM from insight_service.dart) ───────

export const PLAIN_INSTRUCTION =
  "You are a medical scribe. Given a doctor-patient consultation transcript " +
  '(lines labeled "Doctor:"/"Patient:"), do two things: ' +
  "1) Write a consultationSummary: 1-2 plain sentences describing what the " +
  "patient came in for and what the doctor prescribed or advised. Write it " +
  "as a simple human-readable note, not a list. " +
  "2) Extract structured fields: symptoms (patient-described or " +
  "doctor-observed); diagnosis, medications, tests, followUpDays, " +
  "doctorNotes; " +
  "advice (general health guidance: rest, diet, hydration, lifestyle — NOT " +
  "tied to a specific medicine); " +
  "instructions (specific actionable directions the patient must follow: " +
  "how/when to take medicines, precautions, warning signs to return, when " +
  "to follow up). " +
  "Each advice/instruction is a short separate sentence in the list. " +
  "Extract these ONLY from the Doctor's explicit words. " +
  "Write EVERY output field (consultationSummary, symptoms, diagnosis, " +
  "medications, tests, advice, instructions, doctorNotes) in clear English. " +
  "If the consultation " +
  "is in Hindi or code-mixed Hindi/English, translate the meaning into " +
  "English — never output Hindi or Devanagari script. Keep drug names in " +
  "their standard Latin spelling. Translating the language is allowed, but " +
  "never add clinical information that was not spoken. " +
  "Never infer or add anything unspoken. Use empty list/string when absent " +
  "(null followUpDays). Output strict JSON per schema. " +
  "CRITICAL: If any medicine field (dosage, frequency, duration, timing) is " +
  "not explicitly and clearly spoken in the transcript, return an empty " +
  'string for that field. NEVER guess or fill in common defaults like "500mg", ' +
  '"650mg", "twice daily", or "5 days". A missing field is always safer than ' +
  "a hallucinated one. " +
  "If the transcript is garbled, unclear, or mostly background noise, return " +
  "empty arrays and empty strings. Do not attempt to extract from " +
  "unintelligible audio. An empty result is correct when the input is " +
  "unclear. " +
  "For the instructions field, write in simple, clear prescription language " +
  'that a doctor would naturally write on a prescription pad. Use "Take" not ' +
  '"Administer". Use "before bed" not "prior to sleep". Keep each instruction ' +
  "short and direct. Examples of good instruction style: " +
  '"Take medication after food", "Take Cetirizine at bedtime", ' +
  '"Drink plenty of water and take rest", "Avoid cold food and drinks", ' +
  '"Return after 3 days if fever persists". ' +
  "Do not repeat dosage, frequency, or duration details that are already " +
  "captured in the medications list — only include timing relative to meals, " +
  "special precautions, lifestyle advice, and follow-up guidance. " +
  "Pay special attention to follow-up instructions. If the doctor mentions " +
  'ANY of these: "come back", "return", "wapas aana", "follow up", "phir ' +
  'aana", "check-up ke liye aana", or any indication of a return visit with ' +
  "a timeframe, extract the followUpDays as a number. If a timeframe is " +
  'mentioned but vague (e.g. "come back if not better"), set followUpDays to ' +
  "null but include the instruction in the instructions field. " +
  "When the doctor specifies a duration that applies to multiple medicines " +
  '(e.g. "take both for 5 days", "teen din tak dono lena", "sab medicine ' +
  'paanch din tak"), apply that duration to ALL the medicines it refers to, ' +
  "not just the last one mentioned. If a blanket duration is stated after " +
  "listing all medicines, apply it to every medicine that does not have its " +
  "own specific duration. " +
  "For each medication, extract the timing relative to food/meals into the " +
  "timing field of that specific medication. Use one of these values exactly: " +
  '"Before food", "After food", "With food", "Empty stomach", "Before bed", ' +
  'or "As directed". If the doctor says "khana khane ke baad" extract ' +
  '"After food". If "khali pet" extract "Empty stomach". If "sone se pehle" ' +
  'extract "Before bed". If "khana khane se pehle" extract "Before food". ' +
  "Every medication should have a timing value if the doctor mentioned when " +
  "to take it. Do not put timing information only in instructions — it must " +
  "be in the medication's timing field. " +
  // Structured field mapping (few-shot).
  "STRUCTURED FIELDS: when a medicine's frequency, duration, or timing is " +
  "spoken, it MUST be placed in that medicine's structured fields (frequency, " +
  "duration, timing) — not only in instructions. Instructions may repeat it, " +
  "but the structured fields are mandatory whenever the detail is spoken. Map " +
  "spoken Hindi/Hinglish to fields like this: " +
  '"din mein do baar" -> frequency "twice daily"; ' +
  '"raat ko" -> frequency "once daily", timing "Before bed"; ' +
  '"subah khali pet" -> frequency "once daily" (morning), timing ' +
  '"Empty stomach"; ' +
  '"khane ke baad" -> timing "After food"; ' +
  '"teen din" / "paanch din" / "do hafte" -> duration "3 days" / "5 days" / ' +
  '"2 weeks"; ' +
  '"dard hone par" -> frequency "as needed (SOS)". ' +
  // Drug-name guidance: best clinical interpretation, no invention.
  "DRUG NAMES: output each medicine under your best clinical interpretation of " +
  "what the doctor said. If a brand was clearly spoken, prefer that brand. Never " +
  "substitute a category for a product (for example, B-Complex must never become " +
  "Multivitamins). Never invent a medicine that was not mentioned. " +
  // Distractor robustness.
  "DISTRACTORS: the transcript may contain unrelated conversation (other " +
  "people, a TV or radio, a phone call). Extract only the medical consultation " +
  "portion, wherever in the transcript it appears. If one or more medicines " +
  "with doses are clearly stated anywhere in the transcript, never return an " +
  "empty extraction.";

export const DIARIZED_INSTRUCTION =
  "You are a medical scribe. Given a doctor-patient consultation transcript " +
  "with speakers labeled SPEAKER_0/1/... (roles unknown), do three things: " +
  "1) Identify which speaker is the Doctor (examines, diagnoses, prescribes) " +
  "and which is the Patient (describes symptoms). " +
  "2) Write a consultationSummary: 1-2 plain sentences describing what the " +
  "patient came in for and what the doctor prescribed or advised. Write it " +
  "as a simple human-readable note, not a list. " +
  "3) Extract structured fields: symptoms (patient-described or " +
  "doctor-observed); diagnosis, medications, tests, followUpDays, " +
  "doctorNotes; " +
  "advice (general health guidance: rest, diet, hydration, lifestyle — NOT " +
  "tied to a specific medicine); " +
  "instructions (specific actionable directions the patient must follow: " +
  "how/when to take medicines, precautions, warning signs to return, when " +
  "to follow up). " +
  "Each advice/instruction is a short separate sentence in the list. " +
  "Extract these ONLY from Doctor lines. " +
  "Write EVERY output field (consultationSummary, symptoms, diagnosis, " +
  "medications, tests, advice, instructions, doctorNotes) in clear English. " +
  "If the consultation " +
  "is in Hindi or code-mixed Hindi/English, translate the meaning into " +
  "English — never output Hindi or Devanagari script. Keep drug names in " +
  "their standard Latin spelling. Translating the language is allowed, but " +
  "never add clinical information that was not spoken. " +
  "Never infer or add anything unspoken. Use empty list/string when absent " +
  "(null followUpDays). Output strict JSON per schema. " +
  "CRITICAL: If any medicine field (dosage, frequency, duration, timing) is " +
  "not explicitly and clearly spoken in the transcript, return an empty " +
  'string for that field. NEVER guess or fill in common defaults like "500mg", ' +
  '"650mg", "twice daily", or "5 days". A missing field is always safer than ' +
  "a hallucinated one. " +
  "If the transcript is garbled, unclear, or mostly background noise, return " +
  "empty arrays and empty strings. Do not attempt to extract from " +
  "unintelligible audio. An empty result is correct when the input is " +
  "unclear. " +
  "For the instructions field, write in simple, clear prescription language " +
  'that a doctor would naturally write on a prescription pad. Use "Take" not ' +
  '"Administer". Use "before bed" not "prior to sleep". Keep each instruction ' +
  "short and direct. Examples of good instruction style: " +
  '"Take medication after food", "Take Cetirizine at bedtime", ' +
  '"Drink plenty of water and take rest", "Avoid cold food and drinks", ' +
  '"Return after 3 days if fever persists". ' +
  "Do not repeat dosage, frequency, or duration details that are already " +
  "captured in the medications list — only include timing relative to meals, " +
  "special precautions, lifestyle advice, and follow-up guidance. " +
  "Pay special attention to follow-up instructions. If the doctor mentions " +
  'ANY of these: "come back", "return", "wapas aana", "follow up", "phir ' +
  'aana", "check-up ke liye aana", or any indication of a return visit with ' +
  "a timeframe, extract the followUpDays as a number. If a timeframe is " +
  'mentioned but vague (e.g. "come back if not better"), set followUpDays to ' +
  "null but include the instruction in the instructions field. " +
  "When the doctor specifies a duration that applies to multiple medicines " +
  '(e.g. "take both for 5 days", "teen din tak dono lena", "sab medicine ' +
  'paanch din tak"), apply that duration to ALL the medicines it refers to, ' +
  "not just the last one mentioned. If a blanket duration is stated after " +
  "listing all medicines, apply it to every medicine that does not have its " +
  "own specific duration. " +
  "For each medication, extract the timing relative to food/meals into the " +
  "timing field of that specific medication. Use one of these values exactly: " +
  '"Before food", "After food", "With food", "Empty stomach", "Before bed", ' +
  'or "As directed". If the doctor says "khana khane ke baad" extract ' +
  '"After food". If "khali pet" extract "Empty stomach". If "sone se pehle" ' +
  'extract "Before bed". If "khana khane se pehle" extract "Before food". ' +
  "Every medication should have a timing value if the doctor mentioned when " +
  "to take it. Do not put timing information only in instructions — it must " +
  "be in the medication's timing field. " +
  // Structured field mapping (few-shot).
  "STRUCTURED FIELDS: when a medicine's frequency, duration, or timing is " +
  "spoken, it MUST be placed in that medicine's structured fields (frequency, " +
  "duration, timing) — not only in instructions. Instructions may repeat it, " +
  "but the structured fields are mandatory whenever the detail is spoken. Map " +
  "spoken Hindi/Hinglish to fields like this: " +
  '"din mein do baar" -> frequency "twice daily"; ' +
  '"raat ko" -> frequency "once daily", timing "Before bed"; ' +
  '"subah khali pet" -> frequency "once daily" (morning), timing ' +
  '"Empty stomach"; ' +
  '"khane ke baad" -> timing "After food"; ' +
  '"teen din" / "paanch din" / "do hafte" -> duration "3 days" / "5 days" / ' +
  '"2 weeks"; ' +
  '"dard hone par" -> frequency "as needed (SOS)". ' +
  // Drug-name guidance: best clinical interpretation, no invention.
  "DRUG NAMES: output each medicine under your best clinical interpretation of " +
  "what the doctor said. If a brand was clearly spoken, prefer that brand. Never " +
  "substitute a category for a product (for example, B-Complex must never become " +
  "Multivitamins). Never invent a medicine that was not mentioned. " +
  // Distractor robustness.
  "DISTRACTORS: the transcript may contain unrelated conversation (other " +
  "people, a TV or radio, a phone call). Extract only the medical consultation " +
  "portion, wherever in the transcript it appears. If one or more medicines " +
  "with doses are clearly stated anywhere in the transcript, never return an " +
  "empty extraction.";

// ── Gemini schemas (VERBATIM from insight_service.dart) ───────────────────

export const DIARIZED_SCHEMA: Record<string, unknown> = {
  type: "OBJECT",
  properties: {
    doctor_speaker_id: { type: "STRING" },
    patient_speaker_id: { type: "STRING" },
    consultationSummary: { type: "STRING" },
    symptoms: { type: "ARRAY", items: { type: "STRING" } },
    diagnosis: { type: "STRING" },
    differentials: { type: "ARRAY", items: { type: "STRING" } },
    medications: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          name: { type: "STRING" },
          dosage: { type: "STRING" },
          frequency: { type: "STRING" },
          duration: { type: "STRING" },
          timing: { type: "STRING" },
          needsReview: { type: "BOOLEAN" },
        },
        required: ["name"],
      },
    },
    tests: { type: "ARRAY", items: { type: "STRING" } },
    advice: { type: "ARRAY", items: { type: "STRING" } },
    instructions: { type: "ARRAY", items: { type: "STRING" } },
    followUpDays: { type: "INTEGER", nullable: true },
    doctorNotes: { type: "STRING" },
  },
  required: [
    "doctor_speaker_id",
    "patient_speaker_id",
    "consultationSummary",
    "symptoms",
    "diagnosis",
    "differentials",
    "medications",
    "tests",
    "advice",
    "instructions",
    "doctorNotes",
  ],
};

export const PLAIN_SCHEMA: Record<string, unknown> = {
  type: "OBJECT",
  properties: {
    consultationSummary: { type: "STRING" },
    symptoms: { type: "ARRAY", items: { type: "STRING" } },
    diagnosis: { type: "STRING" },
    differentials: { type: "ARRAY", items: { type: "STRING" } },
    medications: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          name: { type: "STRING" },
          dosage: { type: "STRING" },
          frequency: { type: "STRING" },
          duration: { type: "STRING" },
          timing: { type: "STRING" },
          needsReview: { type: "BOOLEAN" },
        },
        required: ["name"],
      },
    },
    tests: { type: "ARRAY", items: { type: "STRING" } },
    advice: { type: "ARRAY", items: { type: "STRING" } },
    instructions: { type: "ARRAY", items: { type: "STRING" } },
    followUpDays: { type: "INTEGER", nullable: true },
    doctorNotes: { type: "STRING" },
  },
  required: [
    "consultationSummary",
    "symptoms",
    "diagnosis",
    "differentials",
    "medications",
    "tests",
    "advice",
    "instructions",
    "doctorNotes",
  ],
};

// ── Coerce / normalization (mirrors InsightService._coerce exactly) ────────

// ICD-10: letter + 2 digits, optional dot + 1-4 alphanumeric chars (e.g. B34.9)
// Retained for the Flutter client, which re-derives ICD on-device via
// Icd10LocalMapper. Gemini no longer produces ICD codes here.
export const ICD_PATTERN = /^[A-Z]\d{2}(\.[0-9A-Z]{1,4})?$/;

export function normalizeTiming(raw: string): string {
  if (raw.trim() === "") return "";
  const lower = raw.toLowerCase();
  if (lower.includes("before food") || lower.includes("before meal")) {
    return "Before food";
  }
  if (lower.includes("after food") || lower.includes("after meal")) {
    return "After food";
  }
  if (lower.includes("with food") || lower.includes("with meal")) {
    return "With food";
  }
  if (
    lower.includes("empty stomach") ||
    lower.includes("khali pet") ||
    lower.includes("on empty")
  ) {
    return "Empty stomach";
  }
  if (
    lower.includes("before bed") ||
    lower.includes("bedtime") ||
    lower.includes("before sleep") ||
    lower.includes("before sleeping") ||
    lower.includes("at night") ||
    lower.includes("sone se pehle")
  ) {
    return "Before bed";
  }
  if (lower.includes("as directed")) return "As directed";
  return "As directed";
}

export function coerce(
  input: Record<string, unknown>,
): Record<string, unknown> {
  const rawMeds = input["medications"];
  const meds: Record<string, unknown>[] = Array.isArray(rawMeds)
    ? rawMeds.map((m) => {
      if (m === null || typeof m !== "object" || Array.isArray(m)) {
        return {
          name: String(m),
          dosage: "",
          frequency: "",
          duration: "",
          timing: "",
          needsReview: false,
        };
      }
      const med = m as Record<string, unknown>;
      return {
        name: med["name"] ?? "",
        dosage: med["dosage"] ?? "",
        frequency: med["frequency"] ?? "",
        duration: med["duration"] ?? "",
        timing: normalizeTiming(String(med["timing"] ?? "")),
        needsReview: med["needsReview"] ?? med["needs_review"] ?? false,
      };
    })
    : [];

  // ICD codes are now assigned on-device by Icd10LocalMapper from the
  // diagnosis text. Gemini no longer guesses them, so these are always null.
  const icdCode = null;
  const icdDescription = null;
  const icdConfidence = null;

  return {
    consultationSummary: input["consultationSummary"] ??
      input["consultation_summary"] ?? "",
    symptoms: input["symptoms"] ?? [],
    diagnosis: input["diagnosis"] ?? "",
    differentials: input["differentials"] ?? [],
    medications: meds,
    tests: input["tests"] ?? [],
    advice: input["advice"] ?? [],
    instructions: input["instructions"] ?? [],
    followUpDays: input["followUpDays"] ?? input["follow_up_days"] ?? null,
    doctorNotes: input["doctorNotes"] ?? input["doctor_notes"] ?? "",
    icdCode,
    icdDescription,
    icdConfidence,
  };
}

// ── Gemini extraction ─────────────────────────────────────────────────────

const _speakerPattern = /SPEAKER_\d+:/;

function _extractGeminiText(data: Record<string, unknown>): string {
  const candidates = data["candidates"] as
    | Array<Record<string, unknown>>
    | undefined;
  if (!candidates || candidates.length === 0) return "{}";
  const content = candidates[0]["content"] as
    | Record<string, unknown>
    | undefined;
  const parts = content?.["parts"] as
    | Array<Record<string, unknown>>
    | undefined;
  if (!parts || parts.length === 0) return "{}";
  return parts.map((p) => (p["text"] as string) ?? "").join("");
}

function _relabelTranscript(
  raw: string,
  doctorId: string,
  patientId: string,
): string {
  let result = raw;
  if (doctorId.trim() !== "") {
    result = result.replaceAll(`${doctorId}:`, "Doctor:");
  }
  if (patientId.trim() !== "") {
    result = result.replaceAll(`${patientId}:`, "Patient:");
  }
  result = result.replace(/SPEAKER_\d+:/g, "Speaker:");
  return result;
}

function _emptyInsight(): MedicalInsight {
  return {
    consultationSummary: "",
    symptoms: [],
    diagnosis: "",
    differentials: [],
    medications: [],
    tests: [],
    advice: [],
    instructions: [],
    followUpDays: null,
    doctorNotes: "",
    icdCode: null,
    icdDescription: null,
    icdConfidence: null,
  };
}

// Guards against feeding noise/garbage to Gemini. A bad STT decode of heavy
// background noise (e.g. noisy Telugu audio) produces short or repetitive
// gibberish; extracting from it makes the model hallucinate medicines. When
// this returns true we skip extraction entirely and return an empty insight —
// an empty result is always safer than a fabricated one.
export function isLowQualityTranscript(transcript: string): boolean {
  // Strip speaker labels so they don't count as spoken content.
  const content = transcript
    .replace(/SPEAKER_\d+:/g, " ")
    .replace(/\b(?:Doctor|Patient|Speaker):/g, " ")
    .trim();

  // Too short to hold a real consultation.
  if (content.length < 10) return true;

  // Ignore whitespace when inspecting the actual characters decoded.
  const compact = content.replace(/\s+/g, "");
  if (compact.length < 10) return true;

  // Noise often decodes to one repeated character/symbol ("aaaaaa", "......",
  // "। । ।"). Real speech uses many distinct characters.
  const distinctChars = new Set(compact.toLowerCase()).size;
  if (distinctChars < 4) return true;

  // Repeated-token gibberish ("ha ha ha ha", "na na na na"): almost no lexical
  // variety across several words.
  const words = content.toLowerCase().split(/\s+/).filter((w) => w.length > 0);
  if (words.length >= 4) {
    const distinctWords = new Set(words).size;
    if (distinctWords / words.length < 0.2) return true;
  }

  return false;
}

// ── Post-extraction confidence flag ───────────────────────────────────────
// Runs AFTER Gemini returns. The doctor's review screen is the safety gate, so
// the server never rewrites a medicine and never silently drops one: it keeps
// exactly what Gemini extracted. Its only job here is to raise a needsReview
// FLAG when a medicine name is neither grounded in the transcript nor recognized
// in the drug dictionary, so the review UI can highlight it. No mutation.

// Transliterate Devanagari, then lowercase + drop everything but [a-z0-9] so
// spacing/punctuation/case/script drift between transcript and extraction never
// blocks a match ("500 mg" -> "500mg", "तीन दिन" -> "teendin").
function _norm(s: string): string {
  return transliterateDevanagari(s).toLowerCase().replace(/[^a-z0-9]/g, "");
}

// Strip speaker labels so they aren't counted as spoken content.
function _spokenText(transcript: string): string {
  return transcript
    .replace(/SPEAKER_\d+:/g, " ")
    .replace(/\b(?:Doctor|Patient|Speaker):/g, " ")
    .trim();
}

export function validateExtraction(
  insight: MedicalInsight,
  transcript: string,
): MedicalInsight {
  const spoken = _spokenText(transcript);
  const transcriptNorm = _norm(spoken);

  // Confidence FLAG only — never a rewrite, never a drop. Every medicine Gemini
  // returned is kept exactly as returned. We raise needsReview when a medicine
  // name is neither grounded in the transcript (romanization + Devanagari aware)
  // nor recognized in the drug dictionary (generic / brand / variant). This is a
  // hint for the review UI; it has no other effect and mutates no field.
  const medications: Medication[] = insight.medications.map((med) => {
    const grounded = drugMatcher.findInTranscript(
      med.name,
      transcriptNorm,
      spoken,
    );
    const recognized = drugMatcher.isKnownDrug(med.name);
    const unverified = !grounded && !recognized;
    if (unverified) {
      // Log the flag only (no patient data) so review rates can be audited.
      console.warn(
        "[validateExtraction] Flagging medicine for review — not found in " +
          "transcript and not recognized in dictionary",
      );
    }
    return { ...med, needsReview: med.needsReview || unverified };
  });

  // Diagnosis: intentionally KEPT even when it looks ungrounded, unlike a drug
  // name. A diagnosis is a paraphrase, not a quotation: Gemini renders the
  // spoken complaint as English clinical phrasing (e.g. Hinglish "sardi-zukaam"
  // -> "Viral upper respiratory infection"), so almost none of its words appear
  // verbatim in a romanized/vernacular transcript. A word-overlap grounding
  // check would false-positive and wipe legitimate diagnoses, so we only log the
  // mismatch and leave verification to the doctor, who edits the diagnosis on the
  // review screen. (The ICD code is re-derived on-device from this diagnosis by
  // the client mapper regardless.)
  const diagnosis = insight.diagnosis;
  if (diagnosis.trim() !== "") {
    const stop = new Set(["the", "and", "with", "from"]);
    const significant = diagnosis
      .toLowerCase()
      .split(/\s+/)
      .map((w) => w.replace(/[^a-z0-9]/g, ""))
      .filter((w) => w.length > 3 && !stop.has(w));
    const anyPresent = significant.some((w) => transcriptNorm.includes(w));
    if (significant.length > 0 && !anyPresent) {
      console.warn(
        "[validateExtraction] Ungrounded diagnosis kept for review — " +
          "no significant word found in transcript",
      );
    }
  }

  return { ...insight, medications };
}

export async function extractInsight(
  transcript: string,
  geminiKey: string,
): Promise<ExtractionResult> {
  // Skip Gemini on empty, too-short, or garbage transcripts — this both avoids
  // a wasted LLM call on noise and prevents hallucination from bad input.
  if (isLowQualityTranscript(transcript)) {
    return { transcript, insight: _emptyInsight() };
  }

  const isDiarized = _speakerPattern.test(transcript);
  const url =
    `${GEMINI_ENDPOINT}/models/${GEMINI_MODEL}:generateContent?key=${geminiKey}`;

  if (isDiarized) {
    const body = {
      systemInstruction: {
        parts: [{ text: DIARIZED_INSTRUCTION }],
      },
      contents: [
        {
          role: "user",
          parts: [{ text: transcript }],
        },
      ],
      generationConfig: {
        temperature: 0.3,
        responseMimeType: "application/json",
        responseSchema: DIARIZED_SCHEMA,
        maxOutputTokens: 4096,
        thinkingConfig: { thinkingBudget: 1024 },
      },
    };

    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });

    if (!res.ok) {
      const errBody = await res.text();
      throw new Error(`Gemini ${res.status}: ${errBody}`);
    }

    const data = (await res.json()) as Record<string, unknown>;
    const raw = _extractGeminiText(data);
    const decoded = JSON.parse(raw) as Record<string, unknown>;

    const doctorId = ((decoded["doctor_speaker_id"] as string) ?? "").trim();
    const patientId = (
      (decoded["patient_speaker_id"] as string) ?? ""
    ).trim();

    const relabeled = _relabelTranscript(transcript, doctorId, patientId);
    const insight = validateExtraction(
      coerce(decoded) as unknown as MedicalInsight,
      transcript,
    );

    return { transcript: relabeled, insight };
  }

  // Plain path
  const body = {
    systemInstruction: {
      parts: [{ text: PLAIN_INSTRUCTION }],
    },
    contents: [
      {
        role: "user",
        parts: [{ text: transcript }],
      },
    ],
    generationConfig: {
      temperature: 0.3,
      responseMimeType: "application/json",
      responseSchema: PLAIN_SCHEMA,
      maxOutputTokens: 4096,
      thinkingConfig: { thinkingBudget: 1024 },
    },
  };

  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const errBody = await res.text();
    throw new Error(`Gemini ${res.status}: ${errBody}`);
  }

  const data = (await res.json()) as Record<string, unknown>;
  const raw = _extractGeminiText(data);
  const decoded = JSON.parse(raw) as Record<string, unknown>;
  const insight = validateExtraction(
    coerce(decoded) as unknown as MedicalInsight,
    transcript,
  );

  return { transcript, insight };
}
