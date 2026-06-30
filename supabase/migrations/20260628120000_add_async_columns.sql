alter table pipeline_jobs add column if not exists sarvam_job_id text;
alter table pipeline_jobs add column if not exists audio_storage_path text;
alter table pipeline_jobs add column if not exists cached_transcript text;
alter table pipeline_jobs add column if not exists cached_insight jsonb;
