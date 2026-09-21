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
-- It is idempotent (`if not exists` throughout), so on a project where the
-- table already exists it changes nothing. The async columns added by the
-- later migrations are deliberately NOT repeated here: those migrations are
-- `add column if not exists` and remain the place they are defined.
--
-- RLS lives in 20260921000000_pipeline_jobs_rls_and_audio_bucket.sql.

create table if not exists public.pipeline_jobs (
  id uuid primary key default gen_random_uuid(),
  doctor_id uuid not null references auth.users (id) on delete cascade,
  status text not null default 'processing',
  language text,
  audio_duration_seconds double precision,
  error_code text,
  created_at timestamptz not null default now(),
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

-- The functions look jobs up by id, but check-job-status also scans by doctor
-- when reporting, and the RLS policy filters on doctor_id.
create index if not exists pipeline_jobs_doctor_id_created_at_idx
  on public.pipeline_jobs (doctor_id, created_at desc);
