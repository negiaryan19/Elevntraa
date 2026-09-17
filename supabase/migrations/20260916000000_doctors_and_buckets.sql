-- 20260916000000_doctors_and_buckets.sql
--
-- Purpose (launch roadmap items 3, 4, 6 and 24, backend side):
--   * public.doctors            one row per signed-in doctor (letterhead identity:
--                               name, qualifications, registration number, clinic).
--                               The app keeps a local copy and syncs it here so a
--                               reinstall or a second phone gets the profile back.
--                               updated_at is written by the client and used for
--                               last-writer-wins merging, so there is no trigger.
--   * storage doctor-signatures private bucket holding <uid>/signature.png.
--   * storage backups           private bucket holding <uid>/<timestamp>.zip exports
--                               of the local database (restore on a new device).
--
-- Access model: every table/bucket is per doctor. Row level security on
-- public.doctors and storage.objects only lets the authenticated role touch rows
-- whose id / first folder segment equals auth.uid(). service_role bypasses RLS.
-- There is deliberately no delete policy on public.doctors: the row goes away with
-- the auth user (on delete cascade), never from the client.
--
-- How it is applied: dev machines do not hold the database password, so this file
-- is sent as ONE query string to the Supabase Management API and then recorded in
-- supabase_migrations.schema_migrations (see docs/SUPABASE.md). Keep it plain SQL:
-- no psql meta-commands, no DO blocks, and every statement idempotent so the
-- whole file can be re-run safely.

-- ── public.doctors ─────────────────────────────────────────────────────────────

create table if not exists public.doctors (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null default '',
  qualifications text not null default '',
  registration_number text not null default '',
  clinic_name text not null default '',
  clinic_address text not null default '',
  clinic_phone text not null default '',
  phone text not null default '',
  signature_updated_at timestamptz,
  onboarding_completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.doctors is
  'Prescribing doctor / clinic identity, one row per auth user (id = auth.users.id).';
comment on column public.doctors.updated_at is
  'Client-maintained; the newer of local vs remote wins on sync. No trigger.';
comment on column public.doctors.signature_updated_at is
  'When <uid>/signature.png in the doctor-signatures bucket last changed; null = no signature.';
comment on column public.doctors.onboarding_completed_at is
  'Set once the doctor finished onboarding; null sends the app back to onboarding.';

alter table public.doctors enable row level security;

drop policy if exists doctors_select_own on public.doctors;
create policy doctors_select_own on public.doctors
  for select to authenticated
  using (id = auth.uid());

drop policy if exists doctors_insert_own on public.doctors;
create policy doctors_insert_own on public.doctors
  for insert to authenticated
  with check (id = auth.uid());

drop policy if exists doctors_update_own on public.doctors;
create policy doctors_update_own on public.doctors
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- auto_expose_new_tables is off for this project, so grants are explicit.
grant select, insert, update on public.doctors to authenticated;
grant all on public.doctors to service_role;

-- ── storage bucket: doctor-signatures ──────────────────────────────────────────

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'doctor-signatures',
  'doctor-signatures',
  false,
  2097152,
  array['image/png', 'image/jpeg']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists doctor_signatures_select_own on storage.objects;
create policy doctor_signatures_select_own on storage.objects
  for select to authenticated
  using (
    bucket_id = 'doctor-signatures'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists doctor_signatures_insert_own on storage.objects;
create policy doctor_signatures_insert_own on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'doctor-signatures'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists doctor_signatures_update_own on storage.objects;
create policy doctor_signatures_update_own on storage.objects
  for update to authenticated
  using (
    bucket_id = 'doctor-signatures'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'doctor-signatures'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists doctor_signatures_delete_own on storage.objects;
create policy doctor_signatures_delete_own on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'doctor-signatures'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ── storage bucket: backups ────────────────────────────────────────────────────

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'backups',
  'backups',
  false,
  209715200,
  array['application/zip', 'application/octet-stream']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists backups_select_own on storage.objects;
create policy backups_select_own on storage.objects
  for select to authenticated
  using (
    bucket_id = 'backups'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists backups_insert_own on storage.objects;
create policy backups_insert_own on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'backups'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists backups_update_own on storage.objects;
create policy backups_update_own on storage.objects
  for update to authenticated
  using (
    bucket_id = 'backups'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'backups'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists backups_delete_own on storage.objects;
create policy backups_delete_own on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'backups'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
