-- Grant Data API access to pipeline_jobs.
-- Supabase's default config.toml has auto_expose_new_tables = false,
-- so tables created via SQL editor do not auto-receive grants. This
-- migration makes the grants permanent so they survive future schema
-- resets or db pushes.

grant select, insert, update, delete on public.pipeline_jobs to service_role;
grant select on public.pipeline_jobs to authenticated;
