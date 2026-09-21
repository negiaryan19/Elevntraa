-- 20260628000000_pipeline_jobs_base.sql
--
-- Purpose: the base definition of public.pipeline_jobs, one row per
-- consultation handed to the transcription pipeline.
--
-- Why it is dated before 20260628120000: the table was originally created by
-- hand in the SQL editor, so the repo only ever held `alter table` migrations
-- against it (20260628120000, 20260629000000, 20260702000000). Applied to a
-- fresh project those fail at the first statement, because the table they
-- alter does not exist. This migration supplies it, dated just ahead of them
-- so the sequence replays cleanly from an empty database.
--
-- The columns, types, nullability and defaults mirror the table as it exists
-- on rxvarta-prod (read from information_schema on 2026-09-21), so a project
-- built from this repo ends up with the same table production has. That
-- includes the three *_duration_ms columns: nothing ever added them in a
-- migration, but process-consultation and check-job-status write them, and
-- without them every successful job's final update would fail.
--
-- It is idempotent (`if not exists`), so on a project where the table already
-- exists it changes nothing. The async columns (sarvam_job_id,
-- audio_storage_path, cached_transcript, cached_insight,
-- cached_previous_transcript) are deliberately NOT repeated here: the later
-- `add column if not exists` migrations remain the place they are defined.
--
-- RLS lives in 20260921000000_pipeline_jobs_rls_and_audio_bucket.sql.

create table if not exists public.pipeline_jobs (
  id uuid primary key default gen_random_uuid(),
  doctor_id uuid,
  status text not null,
  audio_duration_seconds integer,
  language text,
  stt_duration_ms integer,
  extraction_duration_ms integer,
  total_duration_ms integer,
  error_code text,
  created_at timestamptz default now(),
  completed_at timestamptz
);

comment on table public.pipeline_jobs is
  'One row per consultation sent through the transcription + extraction pipeline. Written only by the edge functions (service_role).';
comment on column public.pipeline_jobs.doctor_id is
  'The signed-in doctor who started the job; the RLS select policy matches on it.';
comment on column public.pipeline_jobs.status is
  'processing | success | failed.';
comment on column public.pipeline_jobs.error_code is
  'Short failure reason when status = failed; free text, cut to 255 chars by the caller.';
