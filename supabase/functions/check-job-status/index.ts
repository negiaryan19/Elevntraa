import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
import {
  batchCheckStatus,
  batchDownloadTranscript,
  batchGetDownloadUrl,
  extractInsight,
  type MedicalInsight,
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
  let jobId: string;
  try {
    const json = (await req.json()) as { jobId: string };
    jobId = json.jobId;
  } catch {
    return corsResponse({ error: "Invalid request body" }, 400);
  }

  if (!jobId) {
    return corsResponse({ error: "jobId is required" }, 400);
  }

  const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey);

  // ── 3. Fetch pipeline_jobs row ─────────────────────────────────────────
  const { data: job, error: fetchError } = await supabaseAdmin
    .from("pipeline_jobs")
    .select(
      "id, doctor_id, status, sarvam_job_id, error_code, cached_transcript, cached_insight, created_at",
    )
    .eq("id", jobId)
    .single();

  if (fetchError || !job) {
    return corsResponse({ error: "Job not found" }, 404);
  }

  const row = job as {
    id: string;
    doctor_id: string;
    status: string;
    sarvam_job_id: string | null;
    error_code: string | null;
    cached_transcript: string | null;
    cached_insight: MedicalInsight | null;
    created_at: string;
  };

  // ── 4. Authorization check ─────────────────────────────────────────────
  if (row.doctor_id !== doctorId) {
    return corsResponse({ error: "Forbidden" }, 403);
  }

  console.log(
    `[check-job-status] doctor=${doctorId} job=${jobId} db_status=${row.status}`,
  );

  // ── 5. Already completed ───────────────────────────────────────────────
  if (row.status === "success") {
    if (row.cached_transcript !== null && row.cached_transcript !== undefined) {
      const transcript = row.cached_transcript;
      const insight = row.cached_insight as MedicalInsight;

      // Clear cached patient data now that it's been delivered.
      // Best-effort: errors here must not suppress the response.
      try {
        await supabaseAdmin
          .from("pipeline_jobs")
          .update({ cached_transcript: null, cached_insight: null })
          .eq("id", jobId);
      } catch (e) {
        console.error(
          `[check-job-status] cache clear failed for job=${jobId}:`,
          e,
        );
      }

      console.log(
        `[check-job-status] job=${jobId} returning cached result (clearing cache)`,
      );
      return corsResponse({ status: "done", transcript, insight });
    }

    // Cache already consumed on a previous poll.
    console.log(
      `[check-job-status] job=${jobId} already done, cache consumed`,
    );
    return corsResponse({ status: "done" });
  }

  // ── 6. Already failed ─────────────────────────────────────────────────
  if (row.status === "failed") {
    return corsResponse({
      status: "failed",
      error: row.error_code ?? "Unknown error",
    });
  }

  // ── 7. Still processing — check Sarvam ────────────────────────────────
  if (!row.sarvam_job_id) {
    // Job is processing but Sarvam ID not stored yet (initiation may still
    // be in flight). Tell the phone to keep polling.
    return corsResponse({ status: "running" });
  }

  const t0 = Date.now();

  let sarvamState: Awaited<ReturnType<typeof batchCheckStatus>>;
  try {
    sarvamState = await batchCheckStatus(sarvamApiKey, row.sarvam_job_id);
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error(
      `[check-job-status] job=${jobId} batchCheckStatus failed: ${msg}`,
    );
    return corsResponse({ error: msg }, 500);
  }

  console.log(
    `[check-job-status] doctor=${doctorId} job=${jobId} sarvam_state=${sarvamState.state}`,
  );

  // ── Completed ──────────────────────────────────────────────────────────
  if (sarvamState.state === "Completed" && sarvamState.outputFilename) {
    try {
      const downloadUrl = await batchGetDownloadUrl(
        sarvamApiKey,
        row.sarvam_job_id,
        sarvamState.outputFilename,
      );
      const rawTranscript = await batchDownloadTranscript(downloadUrl);
      const { transcript, insight } = await extractInsight(
        rawTranscript,
        geminiApiKey,
      );

      const totalMs = Date.now() - t0;
      console.log(
        `[check-job-status] doctor=${doctorId} job=${jobId} done total_duration_ms=${totalMs}`,
      );

      // For async jobs, stt_duration_ms and extraction_duration_ms are omitted:
      // the STT runs inside Sarvam's batch infrastructure with no observable
      // start/end timestamps, and polling latency makes any approximation
      // misleading. total_duration_ms covers the full wall-clock span.
      const completedAt = new Date().toISOString();
      const totalDurationMs = Date.now() - new Date(row.created_at).getTime();

      // Cache result so phone can re-poll once more if it missed this response.
      // Cache is cleared on the next successful poll (see step 5 above).
      await supabaseAdmin
        .from("pipeline_jobs")
        .update({
          status: "success",
          cached_transcript: transcript,
          cached_insight: insight,
          total_duration_ms: totalDurationMs,
          completed_at: completedAt,
        })
        .eq("id", jobId);

      return corsResponse({ status: "done", transcript, insight });
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      console.error(
        `[check-job-status] job=${jobId} extraction failed: ${msg}`,
      );
      await supabaseAdmin
        .from("pipeline_jobs")
        .update({ status: "failed", error_code: msg.substring(0, 255) })
        .eq("id", jobId);
      return corsResponse({ status: "failed", error: msg }, 500);
    }
  }

  // ── Sarvam job failed ──────────────────────────────────────────────────
  if (sarvamState.state === "Failed") {
    const errorMsg = sarvamState.errorMessage ??
      "Sarvam batch transcription failed";
    await supabaseAdmin
      .from("pipeline_jobs")
      .update({ status: "failed", error_code: errorMsg.substring(0, 255) })
      .eq("id", jobId);
    return corsResponse({ status: "failed", error: errorMsg });
  }

  // ── Still running (Accepted / Pending / Running) ───────────────────────
  return corsResponse({ status: "running" });
});
