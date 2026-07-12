// Shared pipeline logic: Sarvam STT + Gemini extraction.
// No Supabase client here — endpoints own that. All Sarvam/Gemini functions
// take explicit API keys so they remain testable in isolation.

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
  "For the diagnosis, if it maps clearly and unambiguously to a single " +
  'ICD-10 code, provide the code with icdConfidence "high". If it could ' +
  "reasonably map to a code but there is some ambiguity (e.g. multiple " +
  "possible codes, or the diagnosis is somewhat general), provide your best " +
  'code with icdConfidence "medium". If you are not reasonably confident, ' +
  "return null for icdCode, icdDescription, and icdConfidence — do not guess.";

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
  "For the diagnosis, if it maps clearly and unambiguously to a single " +
  'ICD-10 code, provide the code with icdConfidence "high". If it could ' +
  "reasonably map to a code but there is some ambiguity (e.g. multiple " +
  "possible codes, or the diagnosis is somewhat general), provide your best " +
  'code with icdConfidence "medium". If you are not reasonably confident, ' +
  "return null for icdCode, icdDescription, and icdConfidence — do not guess.";

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
    icdCode: { type: "STRING", nullable: true },
    icdDescription: { type: "STRING", nullable: true },
    icdConfidence: { type: "STRING", nullable: true },
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
    icdCode: { type: "STRING", nullable: true },
    icdDescription: { type: "STRING", nullable: true },
    icdConfidence: { type: "STRING", nullable: true },
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

  const rawIcd = input["icdCode"];
  const icdCode = typeof rawIcd === "string" && ICD_PATTERN.test(rawIcd)
    ? rawIcd
    : null;

  const rawDesc = input["icdDescription"];
  const icdDescription =
    icdCode !== null && typeof rawDesc === "string" && rawDesc !== ""
      ? rawDesc
      : null;

  const rawConf = input["icdConfidence"];
  const icdConfidence = icdCode !== null &&
      typeof rawConf === "string" &&
      (rawConf === "high" || rawConf === "medium")
    ? rawConf
    : null;

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

// ── Post-extraction validation (defense-in-depth anti-hallucination) ───────
// Runs AFTER Gemini returns. Even with a careful prompt the model can invent a
// medicine, a stock dosage, or a diagnosis that was never spoken. This layer
// cross-references every extracted field against the original transcript and
// strips anything it cannot ground. Philosophy: an empty field is always
// correct; a hallucinated field is never acceptable.

// Lowercase + drop everything but [a-z0-9] so spacing/punctuation/case drift
// between transcript and extraction never blocks a match ("500 mg" -> "500mg").
function _norm(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]/g, "");
}

// Strip speaker labels so they aren't counted as spoken content.
function _spokenText(transcript: string): string {
  return transcript
    .replace(/SPEAKER_\d+:/g, " ")
    .replace(/\b(?:Doctor|Patient|Speaker):/g, " ")
    .trim();
}

// Common Indian OTC/Rx drugs -> frequent STT / romanization / brand variants.
// The transcript is romanized Hindi/vernacular while Gemini outputs canonical
// English names, so we must match phonetically, not just literally.
const _MEDICINE_VARIANTS: Record<string, string[]> = {
  paracetamol: [
    "paracetamol",
    "paracetemol",
    "parcetamol",
    "paracitamol",
    "pcm",
    "dolo",
    "calpol",
  ],
  cetirizine: ["cetirizine", "cetrizine", "citrizine", "cetzine", "cetiriz"],
  amoxicillin: ["amoxicillin", "amoxicilin", "amoxycillin", "amox", "moxikind"],
  azithromycin: ["azithromycin", "azithromicin", "azithro", "azee"],
  pantoprazole: ["pantoprazole", "pantoprazol", "pantop", "pan"],
  omeprazole: ["omeprazole", "omeprazol", "omez"],
  ibuprofen: ["ibuprofen", "ibuprofin", "brufen", "ibugesic"],
  metformin: ["metformin", "metformine", "glycomet"],
  amlodipine: ["amlodipine", "amlodipin", "amlong"],
  ranitidine: ["ranitidine", "rantidine", "rantac", "aciloc"],
  domperidone: ["domperidone", "domperidon", "domstal"],
  ondansetron: ["ondansetron", "ondensetron", "emeset"],
  diclofenac: ["diclofenac", "diclofenak", "voveran"],
};

// True when the medicine name is plausibly present in the transcript.
function _medicineFoundInTranscript(
  name: string,
  transcriptNorm: string,
): boolean {
  const nameNorm = _norm(name);
  // Too short to cross-reference reliably — keep it rather than risk dropping
  // a legitimate short name.
  if (nameNorm.length < 4) return true;

  // Direct (normalized) substring.
  if (transcriptNorm.includes(nameNorm)) return true;

  // Phonetic / brand variants for common medicines.
  for (const [canonical, variants] of Object.entries(_MEDICINE_VARIANTS)) {
    if (nameNorm.includes(canonical) || canonical.includes(nameNorm)) {
      for (const v of variants) {
        if (transcriptNorm.includes(v)) return true;
      }
    }
  }

  // Transliteration tolerance: any leading substring of >= 4 chars present.
  for (let k = nameNorm.length; k >= 4; k--) {
    if (transcriptNorm.includes(nameNorm.slice(0, k))) return true;
  }
  return false;
}

// Stock values Gemini tends to invent (normalized, spaces removed).
const _SUSPICIOUS_DOSAGES = new Set(["500mg", "650mg", "325mg"]);
const _SUSPICIOUS_FREQUENCIES = new Set([
  "twicedaily",
  "threetimesaday",
  "oncedaily",
]);
const _SUSPICIOUS_DURATIONS = new Set(["3days", "5days", "7days"]);
const _SUSPICIOUS_TIMINGS = new Set([
  "afterfood",
  "beforefood",
  "emptystomach",
  "beforebed",
]);

// Romanized/vernacular source phrases for timing so a correctly-translated
// value isn't wrongly cleared on a vernacular consult. Every alias is stored
// already normalized (lowercase, non-alphanumeric stripped) to match _norm on
// the transcript. Covers all 8 supported languages: Hindi, Telugu, Tamil,
// Kannada, Bengali, Odia, Gujarati, Marathi.
const _TIMING_ALIASES: Record<string, string[]> = {
  afterfood: [
    "afterfood",
    "aftermeal",
    // Hindi
    "khanakhanekebaad",
    "khanekebaad",
    "khanebaad",
    "bhojankebaad",
    "bhojankhanekebaad",
    // Telugu
    "bhojanamtaruvata",
    "bhojanamtarvata",
    "thinakatarvata",
    // Tamil
    "sappaatukkuappuram",
    "sappaadukkuapuram",
    "unavuvakkupiraghu",
    // Kannada
    "ootaaadamele",
    "utaadamelay",
    // Bengali
    "khabarpare",
    "khawarpore",
    // Odia
    "khanaparey",
    "khaibapare",
    // Gujarati
    "jamanpachhi",
    "jamyapachhi",
    // Marathi
    "jevanaantar",
    "jevannantar",
  ],
  beforefood: [
    "beforefood",
    "beforemeal",
    // Hindi
    "khanakhanesepehle",
    "khanesepehle",
    "bhojansepehle",
    // Telugu
    "bhojanammundu",
    "thinakamundu",
    // Tamil
    "sappaatukkumunbu",
    "unavuvakkumunnaal",
    // Kannada
    "ootaaagodumunche",
    "utaagodmunche",
    // Bengali
    "khabaraage",
    "khawaraagey",
    // Odia
    "khanaaagaru",
    "khaibaagaru",
    // Gujarati
    "jamanpehla",
    "jamtapehla",
    // Marathi
    "jevanaapurvi",
    "jevanaadhi",
  ],
  emptystomach: [
    "emptystomach",
    // Hindi
    "khalipet",
    "khalipetmein",
    // Telugu
    "khalikaddupputho",
    "pustekadduppu",
    // Tamil
    "verumvayitril",
    "verumvayiru",
    // Kannada
    "khalihotte",
    "bareehotteyalli",
    // Bengali
    "khalipete",
    "khaalipete",
    // Odia
    "bhokapetare",
    "khalipetare",
    // Gujarati
    "khalipate",
    "khalipet",
    // Marathi
    "upashipoti",
    "rikaamyapoti",
  ],
  beforebed: [
    "beforebed",
    "atbedtime",
    "atnight",
    // Hindi
    "sonesepehle",
    "raatkosonesepehle",
    // Telugu
    "padukonemundu",
    "nidramundu",
    // Tamil
    "thoongumunnaal",
    "thookathukkumunbu",
    // Kannada
    "malagumunche",
    "niddemadodumunche",
    // Bengali
    "ghumabaraage",
    "shobaraagey",
    // Odia
    "suibaaagaru",
    "suibapurba",
    // Gujarati
    "sutaapehla",
    "suvapehla",
    // Marathi
    "zhopanyapurvi",
    "zopaychiaadhi",
  ],
};

// Romanized/vernacular source phrases for frequency across all 8 languages.
const _FREQUENCY_ALIASES: Record<string, string[]> = {
  twicedaily: [
    "twicedaily",
    "twiceaday",
    "bid",
    // Hindi
    "dinmeindobaar",
    // Telugu
    "rojukirendusarlu",
    // Tamil
    "naalukkuirandumurai",
    "dinathukkurendumurai",
    // Kannada
    "dinakkeeradusarti",
    // Bengali
    "dinaydubar",
    // Odia
    "dinakuduibaar",
    // Gujarati
    "divasmaabevaar",
    // Marathi
    "diwasatundonvela",
  ],
  threetimesaday: [
    "threetimesaday",
    "thricedaily",
    "tid",
    // Hindi
    "dinmeinteenbaar",
    // Telugu
    "rojukimoodusarlu",
    // Tamil
    "naalukkumoondrumurai",
    // Kannada
    "dinakkemoorusarti",
    // Bengali
    "dinaytinbar",
    // Odia
    "dinakutinibaar",
    // Gujarati
    "divasmaatranvaar",
    // Marathi
    "diwasatuntinvela",
  ],
  oncedaily: [
    "oncedaily",
    "onceaday",
    "od",
    // Hindi
    "dinmeinekbaar",
    // Telugu
    "rojukiokasari",
    // Tamil
    "naalukkuorumurai",
    // Kannada
    "dinakkeondusarti",
    // Bengali
    "dinayekbar",
    // Odia
    "dinakuekbaar",
    // Gujarati
    "divasmaaekvaar",
    // Marathi
    "diwasatunekvela",
  ],
};

// Romanized number-word + day-word combos so a spoken vernacular duration
// (e.g. "paanch din") grounds the corresponding English value ("5 days").
const _DURATION_ALIASES: Record<string, string[]> = {
  "3days": [
    "3days",
    "threedays",
    // Hindi / Bengali / Odia / Gujarati / Marathi (Devanagari-family)
    "teendin",
    "teendivas",
    "tindin",
    "tinidina",
    "trandivas",
    // Telugu
    "moodurojulu",
    // Tamil
    "moonrunaal",
    "moonrunaalkal",
    // Kannada
    "moorudina",
    "moorudinagalu",
  ],
  "5days": [
    "5days",
    "fivedays",
    // Hindi / Bengali / Gujarati / Marathi / Odia
    "paanchdin",
    "paanchdivas",
    "paachdivas",
    "paachdivsanche",
    "panchadina",
    // Telugu
    "aidurojulu",
    // Tamil
    "ainthunaal",
    "ainthunaalkal",
    // Kannada
    "aidudina",
    "aidudinagalu",
  ],
  "7days": [
    "7days",
    "sevendays",
    "oneweek",
    // Hindi / Bengali / Odia / Gujarati / Marathi
    "saatdin",
    "saatdivas",
    "shaatdin",
    "saatadina",
    // Telugu
    "edurojulu",
    // Tamil
    "ezhunaal",
    "ezhunaalkal",
    // Kannada
    "eludina",
    "eludinagalu",
  ],
};

// A suspicious default is "grounded" if the value itself, a known romanized
// alias, or its multi-digit number appears in the transcript.
function _valueGrounded(normValue: string, transcriptNorm: string): boolean {
  if (transcriptNorm.includes(normValue)) return true;
  const aliases = _TIMING_ALIASES[normValue] ??
    _FREQUENCY_ALIASES[normValue] ??
    _DURATION_ALIASES[normValue];
  if (aliases) {
    for (const a of aliases) if (transcriptNorm.includes(a)) return true;
  }
  // A specific multi-digit number (e.g. "500") is a strong signal; a single
  // digit (e.g. "3") is far too common to trust.
  const digits = normValue.replace(/[^0-9]/g, "");
  if (digits.length >= 3 && transcriptNorm.includes(digits)) return true;
  return false;
}

export function validateExtraction(
  insight: MedicalInsight,
  transcript: string,
): MedicalInsight {
  const spoken = _spokenText(transcript);

  // Belt-and-suspenders behind isLowQualityTranscript: a transcript with almost
  // no meaningful content can never justify any extraction, whatever Gemini
  // returned.
  if (spoken.replace(/\s+/g, "").length < 15) {
    console.warn(
      "[validateExtraction] transcript below 15 meaningful chars — " +
        "discarding entire extraction",
    );
    return _emptyInsight();
  }

  const transcriptNorm = _norm(spoken);

  // ── Medications: keep every extracted medicine (flagging ungrounded names
  // for review) and clear only suspicious ungrounded stock values ──
  const medications: Medication[] = [];
  for (const med of insight.medications) {
    // Previously an ungrounded medicine name was DROPPED here (`continue`),
    // which silently deleted real prescriptions whenever the romanized /
    // vernacular transcript spelled the drug differently from Gemini's canonical
    // name (e.g. "crocin" / "paracitamol" vs "Paracetamol"). We now KEEP the
    // medicine and flag it for review so the doctor always sees it and can
    // verify, rather than it vanishing from the prescription.
    const nameUngrounded = !_medicineFoundInTranscript(
      med.name,
      transcriptNorm,
    );
    if (nameUngrounded) {
      console.warn(
        "[validateExtraction] Ungrounded medicine kept for review — " +
          "name not found in transcript",
      );
    }

    let dosage = med.dosage;
    let frequency = med.frequency;
    let duration = med.duration;
    let timing = med.timing;
    let cleared = nameUngrounded;

    if (
      _SUSPICIOUS_DOSAGES.has(_norm(dosage)) &&
      !_valueGrounded(_norm(dosage), transcriptNorm)
    ) {
      console.warn(
        "[validateExtraction] Cleared suspicious dosage — " +
          "not found in transcript",
      );
      dosage = "";
      cleared = true;
    }
    if (
      _SUSPICIOUS_FREQUENCIES.has(_norm(frequency)) &&
      !_valueGrounded(_norm(frequency), transcriptNorm)
    ) {
      console.warn(
        "[validateExtraction] Cleared suspicious frequency — " +
          "not found in transcript",
      );
      frequency = "";
      cleared = true;
    }
    if (
      _SUSPICIOUS_DURATIONS.has(_norm(duration)) &&
      !_valueGrounded(_norm(duration), transcriptNorm)
    ) {
      console.warn(
        "[validateExtraction] Cleared suspicious duration — " +
          "not found in transcript",
      );
      duration = "";
      cleared = true;
    }
    if (
      _SUSPICIOUS_TIMINGS.has(_norm(timing)) &&
      !_valueGrounded(_norm(timing), transcriptNorm)
    ) {
      console.warn(
        "[validateExtraction] Cleared suspicious timing — " +
          "not found in transcript",
      );
      timing = "";
      cleared = true;
    }

    medications.push({
      ...med,
      dosage,
      frequency,
      duration,
      timing,
      // Flag any medicine we edited so the review screen can highlight it.
      needsReview: med.needsReview || cleared,
    });
  }

  // ── Diagnosis: grounding is now advisory only. Previously an ungrounded
  // diagnosis (no significant word shared with the transcript) was CLEARED —
  // which, for romanized/vernacular transcripts where the doctor states the
  // diagnosis in English, wiped legitimate diagnoses. We now KEEP the diagnosis
  // and only log when it looks ungrounded, leaving verification to the doctor.
  // (The ICD code is re-derived on-device from this diagnosis by the client
  // mapper regardless, so the backend ICD fields are advisory here too.)
  const diagnosis = insight.diagnosis;
  const icdCode = insight.icdCode;
  const icdDescription = insight.icdDescription;
  const icdConfidence = insight.icdConfidence;
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

  return {
    ...insight,
    medications,
    diagnosis,
    icdCode,
    icdDescription,
    icdConfidence,
  };
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
