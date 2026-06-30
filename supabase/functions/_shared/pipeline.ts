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
  "For the instructions field, write in simple, clear prescription language " +
  'that a doctor would naturally write on a prescription pad. Use "Take" not ' +
  '"Administer". Use "before bed" not "prior to sleep". Keep each instruction ' +
  "short and direct. Examples of good instruction style: " +
  '"Take Paracetamol 650mg after food", "Take Cetirizine at bedtime", ' +
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
  "For the instructions field, write in simple, clear prescription language " +
  'that a doctor would naturally write on a prescription pad. Use "Take" not ' +
  '"Administer". Use "before bed" not "prior to sleep". Keep each instruction ' +
  "short and direct. Examples of good instruction style: " +
  '"Take Paracetamol 650mg after food", "Take Cetirizine at bedtime", ' +
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

export async function extractInsight(
  transcript: string,
  geminiKey: string,
): Promise<ExtractionResult> {
  if (transcript.trim() === "") {
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
    const insight = coerce(decoded) as unknown as MedicalInsight;

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
  const insight = coerce(decoded) as unknown as MedicalInsight;

  return { transcript, insight };
}
