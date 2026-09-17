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
| `consultation-audio` | recordings uploaded by the app, read by `process-consultation` | dashboard defaults | dashboard defaults |
| `doctor-signatures` | `<uid>/signature.png`, the letterhead signature (metadata in `public.doctors`) | 2 MiB | image/png, image/jpeg |
| `backups` | `<uid>/<timestamp>.zip` exports of the local database, restored on a new phone | 200 MiB | application/zip, application/octet-stream |

## Auth
Email + password only. Email confirmation ON; the *Confirm signup* and *Reset password* templates send an 8-digit code (`{{ .Token }}`, no links; `otp_length = 8`); anonymous sign-ins OFF; minimum password length 8; sender name "Rxvarta". `supabase/config.toml` mirrors these values so local dev behaves like production.

## Edge functions
`process-consultation` and `check-job-status` (`verify_jwt = false`, see `config.toml`). Deploy without Docker: `supabase functions deploy <name> --use-api --project-ref excmhjpttqjfyodynfza`. Secrets are set in the dashboard (`supabase secrets set` also works).
