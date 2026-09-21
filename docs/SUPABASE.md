# Supabase — rxvarta-prod

Project ref `excmhjpttqjfyodynfza` (ap-south-1, Mumbai), Postgres 17. Dashboard: https://supabase.com/dashboard/project/excmhjpttqjfyodynfza

## Migrations
- Live in `supabase/migrations/` as `YYYYMMDDHHmmss_description.sql` (checked by `scripts/ci/check_migrations.sh`). Write every file idempotent (`create ... if not exists`, `drop policy if exists` + `create policy`, `insert ... on conflict do update`) so it can be re-run safely.
- Dev machines do not keep the database password, so a migration is applied by POSTing the whole file as ONE query string to the Management API: `POST https://api.supabase.com/v1/projects/excmhjpttqjfyodynfza/database/query` with body `{"query": "<file contents>"}` and a personal access token in `Authorization: Bearer <token>`. Plain statements only: no psql meta-commands, no `DO` blocks.
- Then record it, through the same endpoint, so `supabase db push` stays consistent for whoever does have the password: `insert into supabase_migrations.schema_migrations (version, name) values ('20260916000000', 'doctors_and_buckets') on conflict do nothing;`

## Storage buckets (all private, one folder per doctor)
Objects live under `<auth uid>/...`. RLS policies on `storage.objects` let the `authenticated` role select/insert/update/delete only objects whose first folder segment (`(storage.foldername(name))[1]`) equals `auth.uid()`; `service_role` (edge functions) bypasses RLS. Policy names follow `<bucket_snake>_<select|insert|update|delete>_own`.
| Bucket | Purpose | Size limit | MIME |
|---|---|---|---|
| `consultation-audio` | recordings uploaded by the app, read by `process-consultation` | 50 MiB | audio/mp4, m4a, aac, mpeg, wav |
| `doctor-signatures` | `<uid>/signature.png`, the letterhead signature (metadata in `public.doctors`) | 2 MiB | image/png, image/jpeg |
| `backups` | `<uid>/<timestamp>.zip` exports of the local database, restored on a new phone | 200 MiB | application/zip, application/octet-stream |
| `brand` | **public** — `rxvarta_logo.png`, loaded by the auth e-mail templates | 1 MiB | image/png, image/svg+xml |

`brand` is the one public bucket and has no write policy: only the service role writes to it, via `python3 scripts/supabase/apply_remote.py brand-assets`.

A client-supplied storage key must never be handed straight to the service-role client, because that bypasses the folder policies above. `process-consultation` checks `audioPath` against the caller with `isOwnStoragePath` (`supabase/functions/_shared/storage_path.ts`) before downloading or deleting.

## Tables
| Table | RLS | Policy |
|---|---|---|
| `public.doctors` | on | select/insert/update own row (`id = auth.uid()`) |
| `public.pipeline_jobs` | on | select own rows (`doctor_id = auth.uid()`); writes are service-role only |

## Auth
Email + password only. Email confirmation ON; the *Confirm signup* and *Reset password* templates send an 8-digit code (`{{ .Token }}`, no links; `otp_length = 8`); anonymous sign-ins OFF; minimum password length 8; sender name "Rxvarta". `supabase/config.toml` mirrors these values so local dev behaves like production.

The branded templates live in `supabase/templates/`. The hosted project does not read `config.toml`, so push them with `python3 scripts/supabase/apply_remote.py auth-emails` (subjects + HTML for confirmation, recovery, magic link, e-mail change, reauthentication, invite). The *password changed* notification has no Management API field and is set in the dashboard.

## Edge functions
`process-consultation`, `check-job-status` and `send-welcome-email` (all `verify_jwt = false`, see `config.toml`; each verifies the caller itself with `auth.getUser`). Deploy without Docker: `supabase functions deploy <name> --use-api --project-ref excmhjpttqjfyodynfza`. Secrets are set in the dashboard (`supabase secrets set` also works).

| Secret | Used by |
|---|---|
| `SARVAM_API_KEY`, `GEMINI_API_KEY` | `process-consultation`, `check-job-status` |
| `BREVO_API_KEY` | `send-welcome-email` — Brevo transactional API key (the same account GoTrue's SMTP uses) |
| `WELCOME_EMAIL_SENDER` | `send-welcome-email` — the From address, which must be a verified Brevo sender |

`send-welcome-email` is called by the app once the doctor's profile is complete, and is idempotent: it claims the send with a conditional update on `doctors.welcome_email_sent_at`, and releases the claim if the send fails so a later call retries. To re-send by hand, set that column back to `null` in the SQL editor — the app cannot change it (a trigger blocks `authenticated`/`anon` writes).
