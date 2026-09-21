-- 20260918000000_brand_bucket_and_welcome_email.sql
--
-- Purpose (branded auth e-mails + onboarding e-mail):
--   * storage brand               PUBLIC bucket for the logo the e-mail templates
--                                 load from /storage/v1/object/public/brand/rxvarta_logo.png.
--                                 Public buckets are readable through that URL without
--                                 any policy, so none is added. There is deliberately no
--                                 insert/update/delete policy either: only the service
--                                 role (scripts/supabase/apply_remote.py brand-assets)
--                                 writes here.
--   * doctors.welcome_email_sent_at
--                                 when the send-welcome-email edge function sent the
--                                 one-time welcome e-mail; null = not sent (yet). The
--                                 function claims the row with
--                                 `update ... where welcome_email_sent_at is null`,
--                                 so concurrent calls send at most one e-mail, and
--                                 resets it to null when the send fails so a later
--                                 call retries.
--   * doctors_keep_welcome_email_sent_at trigger
--                                 the doctors_update_own policy lets a doctor update
--                                 their whole row. Without this trigger a client could
--                                 reset the flag and make the function send again and
--                                 again, draining the Brevo quota the sign-up and
--                                 password-reset codes share. The app's roles cannot
--                                 change the column; edge functions and the SQL
--                                 editor can (set it to null to resend by hand).
--
-- How it is applied: like every migration here, as ONE query string through the
-- Management API (python3 scripts/supabase/apply_remote.py migrate <this file>; see
-- docs/SUPABASE.md). Plain SQL only: no psql meta-commands, no DO blocks, every
-- statement idempotent so the whole file can be re-run safely.

-- ── storage bucket: brand ─────────────────────────────────────────────────────

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'brand',
  'brand',
  true,
  1048576,
  array['image/png', 'image/svg+xml']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- ── public.doctors.welcome_email_sent_at ──────────────────────────────────────

alter table public.doctors add column if not exists welcome_email_sent_at timestamptz;

comment on column public.doctors.welcome_email_sent_at is
  'When send-welcome-email sent the one-time welcome e-mail; null = not sent. The app cannot change it.';

create or replace function public.doctors_keep_welcome_email_sent_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  -- The app reaches this table as authenticated (anon has no grant). Edge
  -- functions (service_role) and the SQL editor (postgres) may change it.
  if current_user in ('authenticated', 'anon') then
    new.welcome_email_sent_at := old.welcome_email_sent_at;
  end if;
  return new;
end;
$$;

comment on function public.doctors_keep_welcome_email_sent_at() is
  'Keeps doctors.welcome_email_sent_at unchanged when the app (authenticated/anon) writes the row.';

drop trigger if exists doctors_keep_welcome_email_sent_at on public.doctors;
create trigger doctors_keep_welcome_email_sent_at
  before update on public.doctors
  for each row
  execute function public.doctors_keep_welcome_email_sent_at();
