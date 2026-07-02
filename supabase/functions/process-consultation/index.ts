import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
import {
  batchGetUploadUrl,
  batchInitiate,
  batchStartJob,
  batchUploadFile,
  decideRouting,
  extractInsight,
  transcribeBatchSync,
  transcribeRest,
} from "../_shared/pipeline.ts";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function corsResponse(body: unknown, status = 200): Response {
  if (body === null) {
    return new Response(null, { status, headers: CORS_HEADERS });
  }
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: CORS_HEADERS });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    "";
  const sarvamApiKey = Deno.env.get("SARVAM_API_KEY") ?? "";
  const geminiApiKey = Deno.env.get("GEMINI_API_KEY") ?? "";

  // ── 1. Verify JWT ──────────────────────────────────────────────────────
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return corsResponse({ error: "Missing authorization header" }, 401);
  }

  const userClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const {
    data: { user },
    error: authError,
  } = await userClient.auth.getUser();
  if (authError || !user) {
    return corsResponse({ error: "Unauthorized" }, 401);
  }
  const doctorId = user.id;

  // ── 2. Parse request body ──────────────────────────────────────────────
  let audioPath: string;
  let languageCode: string;
  let audioDurationSeconds: number | null;
  let previousTranscript: string | null;

  try {
    const json = (await req.json()) as {
      audioPath: string;
      languageCode: string;
      audioDurationSeconds: number | null;
      previousTranscript?: string | null;
    };
    audioPath = json.audioPath;
    languageCode = json.languageCode ?? "unknown";
    audioDurationSeconds = json.audioDurationSeconds ?? null;
    previousTranscript = json.previousTranscript ?? null;
  } catch {
    return corsResponse({ error: "Invalid request body" }, 400);
  }

  // Non-empty prior transcript from earlier "Add More" segments, or null.
  const hasPrevious = previousTranscript != null &&
    previousTranscript.trim() !== "";

  if (!audioPath) {
    return corsResponse({ error: "audioPath is required" }, 400);
  }

  const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey);

  // ── 3. Insert pipeline_jobs row ────────────────────────────────────────
  const { data: jobData, error: jobInsertError } = await supabaseAdmin
    .from("pipeline_jobs")
    .insert({
      status: "processing",
      doctor_id: doctorId,
      audio_duration_seconds: audioDurationSeconds,
      language: languageCode,
      created_at: new Date().toISOString(),
    })
    .select("id")
    .single();

  if (jobInsertError || !jobData) {
    console.error(
      `[process-consultation] doctor=${doctorId} insert failed:`,
      jobInsertError?.message,
    );
    return corsResponse({ error: "Failed to create job record" }, 500);
  }
  const jobId = (jobData as { id: string }).id;

  // ── 4. Decide routing ──────────────────────────────────────────────────
  const mode = decideRouting(audioDurationSeconds);
  console.log(
    `[process-consultation] doctor=${doctorId} job=${jobId} mode=${mode} duration=${audioDurationSeconds}`,
  );

  // ── 5. Download audio from storage ────────────────────────────────────
  const t0 = Date.now();
  const { data: audioBlob, error: storageError } = await supabaseAdmin.storage
    .from("consultation-audio")
    .download(audioPath);

  if (storageError || !audioBlob) {
    console.error(
      `[process-consultation] job=${jobId} storage download failed:`,
      storageError?.message,
    );
    await supabaseAdmin
      .from("pipeline_jobs")
      .update({ status: "failed", error_code: "storage_download_failed" })
      .eq("id", jobId);
    return corsResponse(
      { error: "Failed to download audio from storage" },
      500,
    );
  }

  const audioBytes = new Uint8Array(await audioBlob.arrayBuffer());
  const filename = audioPath.split("/").pop() ?? "audio.m4a";
  console.log(
    `[process-consultation] job=${jobId} audio_download_ms=${Date.now() - t0}`,
  );

  // ── 6. Route ───────────────────────────────────────────────────────────
  if (mode === "rest") {
    try {
      const tStt0 = Date.now();
      const newTranscript = await transcribeRest(
        sarvamApiKey,
        audioBytes,
        filename,
        languageCode,
      );
      const sttDurationMs = Date.now() - tStt0;
      console.log(
        `[process-consultation] job=${jobId} stt_ms=${sttDurationMs}`,
      );

      // "Add More" accumulation: prepend the prior segments so extraction runs
      // over the whole consultation, not just the newest audio chunk.
      const combinedTranscript = hasPrevious
        ? `${previousTranscript}\n${newTranscript}`
        : newTranscript;

      const tLlm0 = Date.now();
      const { transcript, insight } = await extractInsight(
        combinedTranscript,
        geminiApiKey,
      );
      const extractionDurationMs = Date.now() - tLlm0;
      console.log(
        `[process-consultation] job=${jobId} llm_ms=${extractionDurationMs}`,
      );

      await supabaseAdmin.storage
        .from("consultation-audio")
        .remove([audioPath]);
      const totalDurationMs = Date.now() - t0;
      await supabaseAdmin
        .from("pipeline_jobs")
        .update({
          status: "success",
          stt_duration_ms: sttDurationMs,
          extraction_duration_ms: extractionDurationMs,
          total_duration_ms: totalDurationMs,
          completed_at: new Date().toISOString(),
        })
        .eq("id", jobId);
      console.log(
        `[process-consultation] job=${jobId} status=success total_ms=${totalDurationMs}`,
      );

      return corsResponse({ mode: "sync", transcript, insight });
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      console.error(`[process-consultation] job=${jobId} rest failed: ${msg}`);
      await supabaseAdmin
        .from("pipeline_jobs")
        .update({ status: "failed", error_code: msg.substring(0, 255) })
        .eq("id", jobId);
      return corsResponse({ error: msg }, 500);
    }
  }

  if (mode === "batch_sync") {
    try {
      const tStt0 = Date.now();
      const newTranscript = await transcribeBatchSync(
        sarvamApiKey,
        audioBytes,
        filename,
        languageCode,
      );
      const sttDurationMs = Date.now() - tStt0;
      console.log(
        `[process-consultation] job=${jobId} stt_ms=${sttDurationMs}`,
      );

      // "Add More" accumulation: prepend the prior segments so extraction runs
      // over the whole consultation, not just the newest audio chunk.
      const combinedTranscript = hasPrevious
        ? `${previousTranscript}\n${newTranscript}`
        : newTranscript;

      const tLlm0 = Date.now();
      const { transcript, insight } = await extractInsight(
        combinedTranscript,
        geminiApiKey,
      );
      const extractionDurationMs = Date.now() - tLlm0;
      console.log(
        `[process-consultation] job=${jobId} llm_ms=${extractionDurationMs}`,
      );

      await supabaseAdmin.storage
        .from("consultation-audio")
        .remove([audioPath]);
      const totalDurationMs = Date.now() - t0;
      await supabaseAdmin
        .from("pipeline_jobs")
        .update({
          status: "success",
          stt_duration_ms: sttDurationMs,
          extraction_duration_ms: extractionDurationMs,
          total_duration_ms: totalDurationMs,
          completed_at: new Date().toISOString(),
        })
        .eq("id", jobId);
      console.log(
        `[process-consultation] job=${jobId} status=success total_ms=${totalDurationMs}`,
      );

      return corsResponse({ mode: "sync", transcript, insight });
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      console.error(
        `[process-consultation] job=${jobId} batch_sync failed: ${msg}`,
      );
      await supabaseAdmin
        .from("pipeline_jobs")
        .update({ status: "failed", error_code: msg.substring(0, 255) })
        .eq("id", jobId);
      return corsResponse({ error: msg }, 500);
    }
  }

  // batch_async: initiate + upload + delete storage + start + store job id
  try {
    const sarvamJobId = await batchInitiate(sarvamApiKey, languageCode);
    console.log(
      `[process-consultation] job=${jobId} sarvam_job_id=${sarvamJobId}`,
    );

    const uploadUrl = await batchGetUploadUrl(
      sarvamApiKey,
      sarvamJobId,
      filename,
    );
    await batchUploadFile(uploadUrl, audioBytes);

    // Sarvam now holds the audio — remove from Supabase storage immediately
    await supabaseAdmin.storage
      .from("consultation-audio")
      .remove([audioPath]);

    await batchStartJob(sarvamApiKey, sarvamJobId);

    await supabaseAdmin
      .from("pipeline_jobs")
      .update({
        sarvam_job_id: sarvamJobId,
        audio_storage_path: audioPath,
        // Persisted across the async gap: check-job-status will combine this
        // with the Sarvam transcript before extraction, then clear it.
        cached_previous_transcript: hasPrevious ? previousTranscript : null,
      })
      .eq("id", jobId);

    console.log(
      `[process-consultation] job=${jobId} async initiated total_ms=${
        Date.now() - t0
      }`,
    );

    return corsResponse({ mode: "async", jobId, sarvamJobId });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error(
      `[process-consultation] job=${jobId} batch_async failed: ${msg}`,
    );
    await supabaseAdmin
      .from("pipeline_jobs")
      .update({ status: "failed", error_code: msg.substring(0, 255) })
      .eq("id", jobId);
    return corsResponse({ error: msg }, 500);
  }
});
