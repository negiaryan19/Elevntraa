-- 20260921000000_pipeline_jobs_rls_and_audio_bucket.sql
--
-- Purpose (closes the last two gaps between the repo and a working project):
--
--   * RLS on public.pipeline_jobs
--                   20260629000000 grants `select` on this table to
--                   `authenticated` so the Data API exposes it, but no
--                   migration ever turned row-level security on. Without a
--                   policy that grant means any signed-in doctor can read
--                   EVERY row — including cached_transcript and
--                   cached_insight, i.e. other doctors' consultations. The
--                   live project had this policy applied by hand; this
--                   migration puts it in the repo so a fresh project is not
--                   silently wide open.
--
--                   Only `select` is granted, so a read policy is all that is
--                   needed: insert/update stay with service_role (the edge
--                   functions), which bypasses RLS.
--
--   * storage bucket: consultation-audio
--                   PRIVATE bucket the app uploads the recording to before
--                   invoking process-consultation. Also created by hand
--                   originally and never committed. Objects are keyed
--                   `<uid>/<job uuid>.m4a` and the policies below hold a
--                   doctor to their own folder.
--
--                   process-consultation downloads with the service role,
--                   which bypasses these policies, so it checks the prefix
--                   itself before touching the object.
--
-- How it is applied: as ONE query string through the Management API
-- (python3 scripts/supabase/apply_remote.py migrate <this file>; see
-- docs/SUPABASE.md). Plain SQL only, every statement idempotent.

-- ── RLS: public.pipeline_jobs ─────────────────────────────────────────────────

alter table public.pipeline_jobs enable row level security;

drop policy if exists pipeline_jobs_select_own on public.pipeline_jobs;
create policy pipeline_jobs_select_own on public.pipeline_jobs
  for select to authenticated
  using (doctor_id = auth.uid());

-- ── storage bucket: consultation-audio ────────────────────────────────────────

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'consultation-audio',
  'consultation-audio',
  false,
  52428800,
  array['audio/mp4', 'audio/m4a', 'audio/aac', 'audio/mpeg', 'audio/wav']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists consultation_audio_select_own on storage.objects;
create policy consultation_audio_select_own on storage.objects
  for select to authenticated
  using (
    bucket_id = 'consultation-audio'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists consultation_audio_insert_own on storage.objects;
create policy consultation_audio_insert_own on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'consultation-audio'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists consultation_audio_update_own on storage.objects;
create policy consultation_audio_update_own on storage.objects
  for update to authenticated
  using (
    bucket_id = 'consultation-audio'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'consultation-audio'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists consultation_audio_delete_own on storage.objects;
create policy consultation_audio_delete_own on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'consultation-audio'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
