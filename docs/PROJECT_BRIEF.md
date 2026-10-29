# Rxvarta — engineering handoff brief

*Written 2026-09-21 for an AI assistant (Gemini) that will continue engineering work on this repository. Everything here was verified against the code and the live backend on that date; §9 says exactly what is and is not deployed. Where a statement is a decision rather than a fact, it says whose. Read §12 before running anything.*

## 1. What Rxvarta is

Rxvarta is an Android app (Flutter) for doctors in India. A doctor records a consultation in the language they and the patient actually speak — Hindi, Marathi, Bengali, Gujarati, Kannada, Tamil, Telugu, English, or code-mixed — and the app turns the recording into a structured prescription: diagnosis, medicines with strength/frequency/duration/timing, investigations, advice, follow-up. The doctor reviews and edits every field, signs it with their real signature, and hands over or shares a PDF on the clinic's letterhead. Patient records stay on the doctor's phone; the cloud (Supabase, Mumbai region) holds only the doctor's account, profile, signature and optional backups, and processes each recording transiently.

Core loop: **sign in → intake patient → record → (cloud STT + LLM extraction) → review & edit → sign → PDF → share**. Everything else (patients list, history, backup, export, settings) supports that loop.

Owner/maintainer: the repo is `Varadraj75/EMR` upstream with a working fork `bserc-labs/EMR`; the current engineering is on branch `launch/roadmap` (see §9). The product is pre-launch: no Play Store listing yet.

## 2. Stack and repository layout

**Client:** Flutter (Dart SDK `^3.12.1`), Riverpod 3 (`flutter_riverpod`), `go_router` 17, Drift 2 on SQLite (`sqlite3_flutter_libs`), `freezed`/`json_serializable` models, `supabase_flutter` 2.17, `flutter_secure_storage` 11, `record` 7 (audio capture), `flutter_foreground_task` 11 (keeps the mic alive with the screen locked), `pdf` 3.13 + `printing` 5 (PDF build/preview), `share_plus` 13, `signature` 6 (drawn signature), `image_picker`, `connectivity_plus`, `archive` (backup zips), `google_fonts`, `intl`, `shared_preferences`, `package_info_plus`, `url_launcher`. Android toolchain: AGP 9.0.1, Kotlin 2.3.20, Gradle 9.1.0, Java 17. iOS project exists but is out of scope for launch (owner decision).

**Backend:** Supabase project (Postgres 17, Auth/GoTrue, Storage) + three Deno edge functions. Speech-to-text: **Sarvam AI** (REST for short audio, batch API for long). Extraction: **Google Gemini** with a strict JSON response schema. Transactional e-mail: **Brevo** (GoTrue SMTP relay for OTP codes; the welcome e-mail calls Brevo's HTTP API directly).

**Size:** ~42,700 hand-written lines (excluding generated `*.g.dart`/`*.freezed.dart`/localization output and the 181 KB drug dictionary): client ~24,000 · edge functions ~3,000 · migrations ~440 · tests ~9,300 · integration tests ~1,900 · scripts ~3,700.

```
lib/
  main.dart                 bootstrap: prefs, Supabase.initialize with SecureSessionStorage, orientation
  app/router.dart           GoRouter table (AppRoute enum), auth redirect wiring, bottom-nav shell
  core/
    auth/                   AuthController + providers, AuthErrorKind, SecureSessionStorage
    config/app_config.dart  build-time dart-defines
    errors/                 Failure types + localized failure_text
    locale/ theme/ prefs/ network/ utils/ widgets/
  data/db/                  Drift AppDatabase (Patients, Visits), per-doctor database provider
  data/repositories/        PatientRepository, VisitRepository, …
  domain/models/            PatientProfile, VisitRecord, MedicalInsight, Medication, ReportAttachment, DoctorProfile, json_coerce
  features/
    auth/                   login, signup, verify_otp, forgot, reset, splash; auth_redirect (state machine); auth_validation
    onboarding/             first-run doctor profile + signature
    home/                   greeting, start consultation, recent patients, search
    consultation/           intake (new/existing), recording, pipeline_service (upload + invoke + poll), controller
    prescription/           review_sign_screen (edit/sign), prescription_pdf_service, pdf_shaper, pdf_preview
    patient/                patients list, detail (visit history), existing-patient search, view prescription
    settings/               profile form, signature capture, backup/restore, export, privacy, legal, help, language, theme, logout
  services/                 on-device helpers: drug_name_corrector, icd10_local_mapper, differential_engine
  l10n/                     app_{en,hi,mr,bn,gu,kn,ta,te}.arb + generated app_localizations*.dart
assets/                     fonts/ (Noto Sans + 6 Indic families, regular+bold), data/ (drug_dictionary, icd10_opd_map, differential_rules), legal/ (privacy_en, terms_en), brand/, icon/
supabase/
  functions/                process-consultation, check-job-status, send-welcome-email, _shared/ (pipeline.ts, drug_matcher.ts, storage_path.ts, drug_dictionary.json, *_test.ts)
  migrations/               7 SQL files (see §5)
  templates/                7 branded GoTrue e-mail templates (8-digit code, no links)
  config.toml               local-dev mirror of the hosted auth config
scripts/
  supabase/apply_remote.py  migrate | auth-hardening | auth-emails | brand-assets | verify (Management API, no DB password)
  ci/                       check_migrations, check_prompt_drift (+ prompt_hashes.txt, update_prompt_hashes), check_drug_dict_sync, check_no_hardcoded_keys
  bench_v2/                 automated eval harness: TTS → live pipeline → per-field grading → report
  golden_audio_bench/ pipeline_bench/ android/setup_emulator.sh
test/                       ~35 files, 282 tests;  integration_test/  e2e (settings, prescription through the live pipeline)
docs/                       SUPABASE.md, SUPABASE_CI.md, RELEASE.md;  README.md (setup from zero)
rxvarta_answer_key.json     eval ground truth: 12 scripts with expected extractions (used by scripts/bench_v2)
medi.json                   drug dictionary source; must stay byte-identical to the two copies under assets/ and supabase/
.github/workflows/          ci.yml (analyze/test, APK, gitleaks), supabase-ci.yml (deno check/lint/fmt/test + 4 guard scripts)
```

## 3. Architecture — the end-to-end flow

1. **Sign in.** Email + password against Supabase Auth; sign-up requires an 8-digit e-mailed code (no magic links). The session (access + refresh token) is persisted in the Android Keystore / iOS Keychain (`SecureSessionStorage`), not plain prefs. `computeRedirect()` in `auth_redirect.dart` is the single state machine deciding splash / login / onboarding / home / reset-password for every navigation.
2. **Onboarding gate.** Until the doctor's profile is complete, every route redirects to onboarding. `DoctorProfile.isComplete` requires exactly: name, qualifications, registration number, clinic name, clinic address, the doctor's phone, and a signature (`missingFields`, `doctor_profile.dart:63`); clinic phone is optional. The profile and the drawn or uploaded signature PNG are stored locally and upserted to `public.doctors` + the `doctor-signatures` bucket; newer `updated_at` wins on sync.
3. **Per-doctor data.** Everything local lives under `<documents>/users/<uid>/`: the Drift SQLite database, report attachments, recordings, profile JSON, signature. Signed out ⇒ an empty in-memory database. Data from pre-account builds migrates to the first doctor who signs in.
4. **Intake.** New patient (name, age, sex, phone/WhatsApp) or an existing one found by debounced search. A `VisitRecord` is created.
5. **Recording.** AAC-LC at 64 kbps, 16 kHz, mono (`audio/mp4`) via `record`, with an Android foreground service of type `microphone` (`FOREGROUND_SERVICE_MICROPHONE`, `WAKE_LOCK`, an ongoing notification) so the mic keeps running when the screen locks or the app is backgrounded; a dropped connection does not stop the recording.
6. **Upload + invoke.** `PipelineService` uploads to `consultation-audio/<uid>/<uuid>.m4a` and calls `process-consultation` with `{audioPath, languageCode, audioDurationSeconds, previousTranscript?}` (the last for "add more" continuations).
7. **Edge function.** Verifies the JWT itself, rejects any `audioPath` outside `<uid>/` (`isOwnStoragePath`), inserts a `pipeline_jobs` row, downloads the audio with the service role, and routes by duration (`decideRouting`): **< 28 s → `rest`** (Sarvam REST STT, which rejects audio over 30 s); **28–300 s → `batch_sync`** (Sarvam batch job polled inside the function for up to 100 s, because edge functions time out at ~150 s); **≥ 300 s or unknown duration → `batch_async`** (the function starts the batch job, stores `sarvam_job_id` in the row and returns a `jobId`; the app polls `check-job-status` every 3 s for up to 20 min). The first two return transcript + insight in the response. Completed results are cached in the row (`cached_transcript`, `cached_insight`) and cleared on first successful read. The audio object is deleted after processing.
8. **Extraction.** Gemini is asked for strict JSON: `consultationSummary, symptoms[], diagnosis, differentials[], medications[{name, dosage, frequency, duration, timing, needsReview}], tests[], advice[], instructions[], followUpDays, doctorNotes` plus speaker ids. Rules: extract only from the doctor's explicit words, translate to English, never invent a missing field (empty string over a guessed "500mg"), empty result on garbled audio. `validateExtraction` keeps every medicine as returned and only *flags* `needsReview` when a name is neither grounded in the transcript nor in the drug dictionary (Devanagari transliteration aware). Transient Gemini errors (408/429/5xx) retry 3× with backoff.
9. **Review & sign.** `ReviewSignScreen` shows every field as an editable card (summary, diagnosis, medicines table, investigations, instructions, advice, doctor's notes, follow-up, collapsed raw transcript). Every save is awaited; a failed save shows Retry and blocks signing. Signing requires a complete profile with a signature and sets `signed = true`.
10. **PDF.** `PrescriptionPdfService` builds an A4 document: clinic letterhead, patient row, diagnosis, medicines table, investigations, instructions, advice, follow-up, signature block (real signature image when signed, "Awaiting signature" otherwise), footer; attached report photos become extra pages. All labels are in the app's language. Indian-script lines are shaped by Flutter's text engine (`PdfShaper`) and embedded as 288-dpi images, because the `pdf` package cannot shape Indic text; Latin stays real text. **Doctor's notes are never printed.**
11. **Share.** `Printing.sharePdf` (the `printing` package) opens the system share sheet with the PDF; the button is labelled "Share on WhatsApp" but there is no WhatsApp-specific intent, so "WhatsApp" and "Other apps" open the same sheet (roadmap 20, partial). `share_plus` is used only by Settings → Export.
12. **Afterwards.** The visit appears in the patient's history; Settings offers backup to the `backups` bucket (zip of the doctor's folder, restore replaces it), export (JSON, Excel-safe CSV, PDFs), and "Delete all local data".

Sections 4–8 describe each of these in depth; §5 the backend; §9 what is live.

## 4. Features — what exists and how each one works

Status legend: **Done** = built, wired, tested · **Partial** = works with a stated gap · **Open** = not built.

### 4.1 Accounts and sign-in — Done
*Files:* `lib/core/auth/auth_providers.dart` (`AuthController`, `AuthErrorKind`, `authErrorKind()`), `lib/core/auth/secure_session_storage.dart`, `lib/features/auth/auth_redirect.dart`, `lib/features/auth/auth_validation.dart`, `lib/features/auth/presentation/{login,signup,verify_otp,forgot_password,reset_password,splash}_screen.dart`, `auth_widgets.dart`, `auth_scaffold.dart`, `lib/app/router.dart`.

- E-mail + password. Sign-up sends an **8-digit code** (never a link); `VerifyOtpScreen` takes it (`purpose` = signup or recovery, carried as query parameters so it survives process death). Password reset: forgot → code → `/reset-password`; a verified recovery code *forces* the reset screen wherever the doctor navigates (`passwordRecoveryPendingProvider`) so recovery cannot be used to skip setting a password. No shared or automatic login exists any more.
- **Routing is one pure function**, `computeRedirect({hasBackend, signedIn, profile, location, recoveryPending})`, unit-tested in `test/auth_redirect_test.dart`. Rules in order: no backend config → only `/login` (which explains "App not configured"); signed out → only the auth paths; signed in → `/reset-password` always allowed; recovery pending → forced there; profile still loading *and no complete profile held* → `/splash` (a reload that still holds a complete profile does **not** evict a doctor mid-consultation); profile incomplete → `/onboarding`; profile complete → auth pages/splash/onboarding bounce to home. It never returns the current path, so it cannot loop. The router is rebuilt never; a `_RouterRefresh` `ChangeNotifier` coalesces provider changes into one redirect pass per microtask.
- **Session at rest.** `SecureSessionStorage extends LocalStorage` keeps the Supabase session in Android Keystore / iOS Keychain (`first_unlock_this_device`). `initialize()` does, in order: (1) on an installation's first launch (no `secure_session_ready` marker in prefs) delete any Keychain session a previous install left — and **if that delete fails, block session reads for this launch** rather than sign the new user in as the previous doctor; (2) migrate an older build's plaintext session from SharedPreferences; (3) set the marker. Sign-out and sign-in both delete any leftover plaintext copy. An unreadable vault entry (e.g. `BadPaddingException` after a backup restore) counts as signed out and is deleted. macOS/desktop deliberately keeps the plain store (`forThisDevice`), because ad-hoc-signed dev builds cannot use the Keychain.
- **Validation** (`auth_validation.dart`, pure Dart, 100 % unit-tested): `isValidEmail` (strict: RFC-ish local part, label and TLD rules, 254/64/63 length limits) gates **sign-up only**; `looksLikeEmail` (one `@`, something each side, no spaces) gates **log-in and forgot-password**, so an address the server accepted long ago is never refused by the form. `suggestEmailFix` proposes a correction for near-misses of common providers (gmail/yahoo/yahoo.co.in/hotmail/outlook/icloud/rediffmail/live; ≤1 edit per 5 chars, max 2; OSA distance) and stays silent for real look-alikes (`ymail.com`, `mail.com`, `email.com`) and **regional brand domains** (`hotmail.ch`, `yahoo.co.za` — brand exact + country-code suffix). On sign-up a well-formed typo (`doctor@gmial.com`) triggers a **warn-once** banner offering the fix; a second tap keeps the address as typed. On log-in the hint is appended to the *invalid credentials* error only. `passwordIssues` mirrors the server policy (`lower_upper_letters_digits_symbols`, min 8, bcrypt's 72-**byte** limit counted in UTF-8) and the form names the next unmet rule in all 8 languages.
- `AuthErrorKind` classifies every failure (invalid credentials, e-mail not confirmed, user exists, weak password, OTP expired/invalid, rate limited, **emailSendFailed** = GoTrue's SMTP relay refused the code mail, network, signup disabled, validation, not configured, unknown). Raw exception text is shown only behind a "Details" expander for `unknown`.

### 4.2 Onboarding, doctor profile, signature — Done
*Files:* `lib/features/onboarding/presentation/onboarding_screen.dart`, `lib/features/settings/presentation/{doctor_profile_form,signature_capture_sheet,signature_preview}.dart`, `lib/features/settings/data/doctor_profile_repository.dart`, `lib/domain/models/doctor_profile.dart`.

- Required to proceed (and to sign): name, qualifications, registration number, clinic name, clinic address, phone, **signature**. Clinic phone is optional. The signature is drawn (`signature` package) or picked from the gallery, stored as PNG at `users/<uid>/` and uploaded to `doctor-signatures/<uid>/signature.png`.
- Local-first sync: every save writes locally (`dirty: true`) then tries `pushRemote` (upsert into `public.doctors`); failure leaves it dirty for a later retry. On start-up the newer of local/remote `updated_at` wins (client-maintained; there is no DB trigger). `onboarding_completed_at` is set the first time the profile becomes complete.
- After a successful push with onboarding complete, the repository fires `send-welcome-email` **unawaited, best-effort**; the function is idempotent, so repeat calls are no-ops.
- A cached copy of the old hard-coded sample doctor ("Dr. Rajesh Sharma / MH-12345") is detected and discarded so it can never print on a prescription.

### 4.3 Consultation: intake → recording → processing → offline queue — Done
*Files:* `lib/features/consultation/presentation/{intake_choice_screen,intake_screen,intake_controller,recording_screen,consultation_controller}.dart`, `lib/features/consultation/data/{recording_service,recording_keep_alive,pipeline_service,mock_pipeline_service,consultation_processor,pending_consultations}.dart`, `lib/features/home/presentation/pending_consultations_card.dart`, `lib/features/patient/presentation/existing_patient_screen.dart`.

- Intake: new patient form or existing-patient search (debounced, out-of-order results discarded). **Report photos are attached here** (`image_picker`, camera or gallery), stored under `users/<uid>/attachments/` and later printed as extra PDF pages; the review screen does not manage attachments. Creates/updates `PatientProfile` and a `VisitRecord`; resets `cumulativeTranscriptProvider`.
- Recording: AAC-LC 64 kbps / 16 kHz / mono to `users/<uid>/recordings/`. Pause/resume/cancel. An Android **foreground service of type `microphone`** with an ongoing notification keeps capture alive with the screen locked or the app backgrounded (before this, locking the phone silenced the mic). Losing internet does not pause a recording; processing waits. iOS has `UIBackgroundModes: audio` but is untested.
- **`ConsultationProcessor.process`** (2026-09-22, extracted from the controller so a live and a queued consultation take the same path): `PipelineService.processConsultation` → if `!insight.hasClinicalContent` throws `ApiFailure(invalidAudio)` and leaves the visit untouched (the screen shows "No consultation was heard"; never a blank prescription) → **on-device post-processing** (§4.5) → writes transcript + insight into the visit. It captures every dependency (pipeline, repository, the three loaders) **before its first await**: a sign-out mid-processing swaps `appDatabaseProvider` under it, and a run in flight must finish against the database it started with or not at all. `ConsultationController._process` delegates to it, probes the duration first, and only after success commits the cumulative transcript (so a failed segment cannot pollute "Add more").
- **Retry with this recording:** on failure the audio is kept and `retryProcessing()` resends the same file.
- **Add more:** a further recording is sent with `previousTranscript`; the backend re-extracts over the whole consultation and returns the combined transcript.
- `PipelineService`: uploads bytes to `consultation-audio/<uid>/<uuid>.<ext>` (`audio/mp4`, `upsert: false`), invokes `process-consultation`; on `mode: async` polls `check-job-status` every 3 s up to 20 min. Failures map to `ApiFailure` / `NetworkFailure` / `AuthFailure` / `StorageFailure` and are rendered by `failure_text.dart` as one translated sentence per kind.
- `DEBUG_SKIP_STT=true` swaps in `MockPipelineService` (canned insight, no network) for emulator work; it is AND-ed with `!kReleaseMode`, so a release build can never serve mock consultations.
- **Offline (roadmap 13, 14; 2026-09-22).** The recording screen no longer gates Start, Resume or Done on connectivity. Offline, a notice says the recording will be saved and processed later; Done → `stopAndQueue()` (stop the recorder, save `audioPath`, `pendingState = queued`), a snackbar, and `context.go(home)`. After a failed attempt, **Process later** → `queueForLater()` does the same with the recording already on disk. `PendingConsultations` (a `Notifier`, kept alive by `ref.listen` in `RxvartaApp`) drains the queue oldest-first, one at a time, through `ConsultationProcessor`: on every online transition, every 2 min (`pendingRetryIntervalProvider`), and once at start-up. Policy per failure: network/auth → stays queued, the pass stops; server → retried, marked failed after 3 in one session; invalidAudio / missing file / storage / unknown → `failed` with `pendingError = code.name`. Success → `ready`. Overlapping `drain()` calls collapse into one; a pass that stopped early does not go round again. Home shows `PendingConsultationsCard` (hidden when empty): patient, status (waiting / processing / ready / failed + reason via `failureCodeText`), tap-to-review clears the pending state, Retry (not offered for `invalidAudio`), Dismiss. The pending state lives on the visit row in the doctor's own database (schema v3), so it survives a restart and never crosses doctors.

### 4.4 Backend pipeline: speech-to-text + extraction — Done (dosage accuracy: broken, see §10)
*Files:* `supabase/functions/process-consultation/index.ts`, `check-job-status/index.ts`, `_shared/pipeline.ts` (~1,100 lines), `_shared/drug_matcher.ts`, `_shared/storage_path.ts`, `_shared/drug_dictionary.json`.

- **Contract.** `POST process-consultation` with the doctor's JWT, body `{audioPath, languageCode, audioDurationSeconds|null, previousTranscript?}` → `{mode:"sync", transcript, insight}` or `{mode:"async", jobId}`. `POST check-job-status {jobId}` → status, and transcript + insight once complete. Both verify the JWT themselves (`verify_jwt = false` in `config.toml`), both answer CORS preflight. `check-job-status` rejects a job whose `doctor_id` is not the caller's. `process-consultation` rejects (403) any `audioPath` not under `<caller uid>/` — this matters because it downloads **and afterwards deletes** the object with the service-role key, which bypasses storage RLS. `audioPath`/`languageCode` are `typeof`-guarded (a non-string used to throw out of the handler as a bare 500 without CORS headers).
- **Routing** (`decideRouting`): `< 28 s` → `rest`; `28–300 s` → `batch_sync` (polled in-function ≤ 100 s, every 3 s); `≥ 300 s` or duration unknown → `batch_async`.
- **Sarvam.** Base `https://api.sarvam.ai`, header `API-Subscription-Key`, model **`saaras:v3`**. REST: `POST /speech-to-text` multipart (`file`, `model`, `mode` = `codemix`, or `transcribe` when the language is `"unknown"`, `language_code`). Batch: initiate (with `with_diarization: true`, `num_speakers: 2`) → get upload URL → upload → start → poll status → download; diarized output is flattened to `SPEAKER_n: text` lines. An empty transcript throws "Sarvam heard audio but produced no transcript".
- **Gemini.** `gemini-2.5-flash` via `generativelanguage.googleapis.com/v1beta`, `temperature 0.3`, `responseMimeType: application/json`, a `responseSchema`, `maxOutputTokens 4096`, `thinkingBudget 1024`. Two system prompts: `PLAIN_INSTRUCTION` (transcript with `Doctor:`/`Patient:` labels) and `DIARIZED_INSTRUCTION` (`SPEAKER_n` labels; the model also returns `doctor_speaker_id`/`patient_speaker_id`, which `_relabelTranscript` uses to rewrite the transcript as `Doctor:`/`Patient:`). Prompt rules, in substance: extract only from the doctor's explicit words; write every field in English (translate Hindi/Hinglish, never output Devanagari; keep drug names in Latin spelling); never infer; **if a medicine field is not explicitly spoken return an empty string — never default to "500mg"/"twice daily"/"5 days"**; garbled/noisy transcript → empty result; instructions in plain prescription language; follow-up phrases ("wapas aana", "phir aana") → `followUpDays`, vague ones → `null` plus an instruction; a blanket duration ("dono paanch din") applies to every medicine without its own; `timing` ∈ {Before food, After food, With food, Empty stomach, Before bed, As directed}; a few-shot Hinglish → field mapping ("din mein do baar" → twice daily, "khali pet" → Empty stomach, "dard hone par" → as needed (SOS)); brand spoken ⇒ keep the brand, never substitute a category for a product (B-Complex ≠ Multivitamins); ignore distractor speech (TV, phone calls) but never return empty if a medicine with dose is clearly stated. **The schema gives every medication field as a bare `{type:"STRING"}` with no description — the root cause of the dosage defect.**
- **Guards.** `isLowQualityTranscript` (too short, < 4 distinct characters, or < 20 % distinct words) skips Gemini entirely and returns an empty insight. `postGemini` retries 408/429/500/502/503/504 and network errors up to 3 attempts with 1 s·2ⁿ backoff (a single Gemini 503 used to cost the doctor the consultation). `validateExtraction` **never rewrites and never drops**: it keeps every medicine exactly as returned and sets `needsReview` when a name is neither grounded in the transcript (normalised; Devanagari transliterated) nor known to the drug dictionary. An ungrounded diagnosis is kept and only logged — a diagnosis is a paraphrase, so word-overlap grounding would wipe legitimate ones. Logs carry status codes, job ids and doctor ids only — never transcript, prompt or prescription text.
- **`pipeline_jobs` lifecycle.** insert `{status:"processing", doctor_id, audio_duration_seconds, language, created_at}` → on success `{status:"success", stt_duration_ms, extraction_duration_ms, total_duration_ms, completed_at}`; on failure `{status:"failed", error_code}` (≤ 255 chars). Async adds `sarvam_job_id`, `audio_storage_path`, `cached_previous_transcript`; `check-job-status` runs extraction when Sarvam reports Completed, caches `cached_transcript`/`cached_insight` in the row, returns them and **clears the cache on that read**. The audio object is removed from the bucket after processing on every path.

### 4.5 On-device post-processing — Done
*Files:* `lib/services/{drug_name_corrector,icd10_local_mapper,differential_engine}.dart`, `assets/data/{drug_dictionary.json (181 KB), icd10_opd_map.json (44 KB), differential_rules.json (27 KB)}`. All three load once via `FutureProvider`s in `consultation_controller.dart`.

- **DrugNameCorrector** — romanisation-aware matcher over the same dictionary the backend uses. Where it finds a canonical form different from the extracted name it replaces the name and **keeps the original in `Medication.originalName`**. It does not rewrite combination medicines (a past bug turned "Montelukast + Levocetirizine" into "Cetirizine"; `test/drug_name_corrector_safety_test.dart` pins this). So: *server flags, client corrects, doctor decides.*
- **Icd10LocalMapper** — the LLM supplies only diagnosis *text*; the ICD-10 code is assigned on-device from a curated WHO OPD map and **always overwrites** whatever ICD fields the extractor returned, including clearing all three when there is no confident match. The doctor never sees a guessed code.
- **DifferentialEngine** — rule-based differential suggestions from the extracted symptoms. **Doctor-only:** held in transient controller state, never written to the visit, never printed, never auto-fills the diagnosis.
- The drug dictionary exists in three byte-identical copies — `assets/data/drug_dictionary.json` (Flutter), `supabase/functions/_shared/drug_dictionary.json` (Deno) and `medi.json` at the repo root (the editing source); `scripts/ci/check_drug_dict_sync.sh` enforces it.

### 4.6 Review and sign — Done
*File:* `lib/features/prescription/presentation/review_sign_screen.dart` (~2,900 lines; one screen, many private card widgets).

- Editable cards: patient details (name/age/sex/phone/WhatsApp), consultation summary, diagnosis (+ ICD line), medicines (add/edit/remove; `needsReview` highlighted), **Investigations**, instructions, advice, **Doctor's notes** (captioned "Kept for your records; not printed on the prescription"), follow-up days, a collapsed read-only transcript, the doctor-only differentials, and "Add more" (another recording).
- Every edit calls `_save()`, which is **awaited**; a failure shows a snackbar with Retry and blocks signing. (Saves used to be fire-and-forget.)
- `_sign()`: `_passesSignGate()` → save → `signed = true, signedAt = now` → push the PDF screen (push, not go, so Back returns to edit and regenerate). The gate loops until the doctor profile `isComplete` (offering the profile form in a sheet), and blocks when the patient has no name or a medicine line has no name.

### 4.7 Prescription PDF — Done
*Files:* `lib/features/prescription/data/{prescription_pdf_service,pdf_shaper}.dart`, `presentation/pdf_preview_screen.dart`, `lib/features/patient/presentation/view_prescription_screen.dart`, `assets/fonts/` (Noto Sans + Devanagari, Bengali, Gujarati, Kannada, Tamil, Telugu; regular + bold; registered in pubspec as `RxNotoSans*`).

- A4. Sections in order: doctor/clinic letterhead → rule → patient row (Patient, Date, Age, Gender, Phone) → Diagnosis → medicines table (#, Medicine, Dosage, Frequency, Duration, Timing; "No medicines prescribed." when empty) → Investigations advised → Instructions → Advice → Follow-up ("After N days" + next-visit date) → signature block → footer ("computer-generated" line + tagline). Attached reports become extra pages ("Previous reports", "Attached for <name>", "Report n"). Unique file name per visit.
- **Signature block:** signed + image → the doctor's real signature above the rule with name and Reg. No.; unsigned → localized "Awaiting signature". Never a typed stand-in.
- **Language:** all labels come from `AppLocalizations` for the app's chosen language (`prescriptionPdfServiceProvider` watches `appLocaleProvider`; the constructor defaults to English). Clinical content stays as the doctor left it (English from the extractor unless edited).
- **Shaping (`PdfShaper`).** The `pdf` package draws one glyph per code point in typing order, which misspells every Indic script (pre-base vowel signs, conjuncts). Any line containing U+0900–U+0D7F is laid out with Flutter's `TextPainter` using the bundled Noto families and embedded as a PNG at 4 px/pt (288 dpi); Latin-only lines stay real, selectable PDF text. Layout runs **twice** with one shaper: pass 1 records lines needing shaping and gets placeholders, `shapePending()` renders them, pass 2 places the images. Shaped lines are cached across documents (LRU, 500) keyed by **language** + width + alignment + per-run (size, weight, colour, text); each document holds its own `pw.MemoryImage` because a pdf image pins the document it was drawn into. The shaper is given the prescription's `Locale` — Marathi and Hindi share Devanagari, but Noto draws ल/श differently for Marathi via OpenType `locl`, which applies only when the engine knows the language.
- **Never printed:** doctor's notes, differentials, the transcript.
- `PdfPreviewScreen` builds the bytes, rasterises pages at 200 dpi for the on-screen preview, and shares via `Printing.sharePdf`.

### 4.8 Patients and history — Done
*Files:* `lib/features/home/presentation/home_screen.dart`, `lib/features/patient/presentation/{patients_screen,patient_detail_screen,edit_patient_sheet,existing_patient_screen,view_prescription_screen}.dart`, `lib/data/repositories/`.
Home: greeting, connectivity chip, "Start new consultation", live recent-patients list, search. Patients tab: every patient with correct visit counts (it used to stop at the last 50 visits). Patient detail: visit history, open any prescription, re-share its PDF; **Edit** (2026-09-22, roadmap 16) opens `EditPatientSheet` — name required, age/WhatsApp digits-only, saved with a fresh `updatedAt`, inline error + Retry; the Patients list reloads on return. Each visit card ends with a **reports strip** (roadmap 17): thumbnails of that visit's attachments resolved through `AppPaths.resolveAttachment`, missing files skipped, tap for a zoomable full-screen viewer.

### 4.9 Settings — Done
*Files:* `lib/features/settings/presentation/*`, `lib/features/settings/data/{backup_service,zip_builder,export_service,local_data_wiper}.dart`.
- **Profile**, **Signature** (redraw/replace), **Dark mode**, **App language** (8).
- **Backup & sync** → bucket `backups/<uid>/rxvarta-backup-YYYYMMDD-HHMMSS.zip`: `manifest.json` (v1) + the SQLite database + `attachments/` + `profile/` (profile JSON + signature). **Recordings are excluded** (large, and already processed). Keeps the newest 5 (`_prune`). Restore downloads, validates the archive in a staging directory, then replaces the database and profile and **merges** attachments; only the signed-in doctor's folder is touched; the app asks to be reopened afterwards.
- **Export data** → one zip shared through `share_plus`: JSON, CSV (Excel-safe cells — formula-injection guarded — with a BOM), the report images, and a PDF of every **signed** prescription.
- **Privacy & security** (where data lives, processors: Sarvam, Google Gemini, Supabase; retention; "Delete all local data on this device" = `LocalDataWiper`: closes the DB, deletes `users/<uid>/` incl. WAL/SHM/journal, unclaimed legacy shared data, and every preference except language and theme; best-effort with a per-step report).
- **Terms**, **Privacy policy** (bundled Markdown, English only; `TERMS_URL`/`PRIVACY_URL` open a hosted copy when set), **Help & support** (`SUPPORT_EMAIL`/`SUPPORT_WHATSAPP`; both currently empty → no contact route), version line, **Log out** (ends the session; local records stay).

### 4.10 Local data and per-doctor isolation — Done
*Files:* `lib/data/db/{app_database,database_provider}.dart`, `lib/core/utils/app_paths.dart`, `lib/domain/models/*`.
- Drift, **`schemaVersion 3`** (v3 on 2026-09-22 adds `pendingState?`, `pendingError?` to Visits; `if (from < 3) addColumn` ×2, proven against a real v2 file in `test/db_migration_v3_test.dart`), two tables. `Patients(id, name, age?, sex?, whatsappNumber?, phone?, createdAt, updatedAt)`. `Visits(id, patientId, createdAt, audioPath?, transcript?, languageCode, insightJson?, attachmentsJson?, pdfPath?, signed=false, signedAt?, patientConsent, consentAt?, pendingState?, pendingError?)`. The whole `MedicalInsight` is one JSON column; attachments are a JSON list of **relative** file names resolved against the doctor's attachments folder at read time (so a container-path change cannot orphan them).
- Everything is under `<documents>/users/<uid>/` (`database`, `attachments/`, `recordings/`, profile, signature). Signed out ⇒ an empty in-memory database. `AppPaths.claimSharedData(uid)` moves the pre-accounts shared database/attachments/recordings to the **first** doctor who signs in; later doctors start empty. `test/doctor_data_isolation_test.dart` proves Doctor B cannot see Doctor A's data on the same phone.
- `json_coerce.dart`: lenient parsing of LLM output (a string where a list belongs, a numeric string, a bare medicine name instead of an object) so a type mismatch no longer throws away a whole consultation.

### 4.11 Internationalisation — Done
8 locales — en, hi, mr, bn, gu, kn, ta, te — 520 keys each, all in lockstep (`flutter gen-l10n` fails otherwise). The app language drives the UI **and** the PDF labels. Bundled legal text is English only.

### 4.12 Branded e-mail — Done in repo, not deployed
`supabase/templates/` — confirmation, recovery, magic_link, email_change, reauthentication, invite, password_changed_notification; table layout, inline styles, the 8-digit `{{ .Token }}`, "valid for 60 minutes", logo from the public `brand` bucket. `send-welcome-email`: verifies the caller; checks `BREVO_API_KEY`/`WELCOME_EMAIL_SENDER` **before** claiming (a missing secret must not burn the one-shot flag); claims with `update doctors set welcome_email_sent_at = now where id = uid and welcome_email_sent_at is null` (atomic test-and-set); sends HTML + text through Brevo's `/v3/smtp/email`; on failure releases the claim (`… where welcome_email_sent_at = <claimedAt>`) and returns 502. A DB trigger lets only `service_role` and `postgres` change that column (allow-list), so a client cannot reset it and drain the Brevo quota the OTP mails share.

## 5. Backend reference

**Migrations** (`supabase/migrations/`, applied in timestamp order; all idempotent):

| File | What |
|---|---|
| `20260628000000_pipeline_jobs_base.sql` | `create table if not exists public.pipeline_jobs` mirroring production (incl. the three `*_duration_ms` columns). Dated ahead of the `alter` migrations so the sequence replays from an empty DB. |
| `20260628120000_add_async_columns.sql` | `sarvam_job_id`, `audio_storage_path`, `cached_transcript`, `cached_insight` |
| `20260629000000_grant_pipeline_jobs.sql` | all to `service_role`; `select` to `authenticated` (safe only with RLS) |
| `20260702000000_add_previous_transcript.sql` | `cached_previous_transcript` |
| `20260916000000_doctors_and_buckets.sql` | `public.doctors` + own-row RLS; buckets `doctor-signatures`, `backups` with own-folder policies |
| `20260918000000_brand_bucket_and_welcome_email.sql` | public `brand` bucket; `doctors.welcome_email_sent_at`; allow-list trigger |
| `20260921000000_pipeline_jobs_rls_and_audio_bucket.sql` | RLS + `pipeline_jobs_select_own`; `consultation-audio` bucket + 4 own-folder policies; drops production's hand-made duplicates |

**Storage rule everywhere:** objects live under `<auth uid>/…`; policies named `<bucket_snake>_<select|insert|update|delete>_own` compare `(storage.foldername(name))[1]` with `auth.uid()::text`. The service role bypasses RLS — so **a client-supplied storage key must be checked with `isOwnStoragePath` before it reaches a service-role client.**

`scripts/supabase/apply_remote.py` (Management API; token from `SUPABASE_ACCESS_TOKEN` or the macOS keychain item "Supabase CLI"): `migrate <file>` · `auth-hardening` (anonymous sign-ins off, sender name, min password 8) · `auth-emails` (subjects + HTML for six templates; the *password changed* notification has no API field → dashboard) · `brand-assets` (uploads `assets/brand/*` to `brand` via the Storage API with the service-role key) · `verify`.

## 6. Security model

| Asset | Protection |
|---|---|
| Patient records | On the phone only, under `users/<uid>/`; per-doctor database; in-memory DB when signed out; wiped per doctor by "Delete all local data". *Gap:* included in Android Auto Backup (§10.8). |
| Session tokens | Keystore/Keychain; excluded from cloud backup and device transfer; stale-install wipe with fail-closed reads; plaintext copies purged on sign-in/out |
| Provider keys (Sarvam, Gemini, Brevo) | Edge-function secrets only. The app binary holds just the Supabase URL + publishable anon key. `check_no_hardcoded_keys.sh` + gitleaks in CI |
| Consultation audio | Private bucket, own-folder policies, ownership check before service-role access, deleted after processing |
| `pipeline_jobs` (transcripts + insights cache) | RLS own-row select; writes service-role only; cache cleared on first read |
| Doctor profile / signature / backups | Own-row / own-folder RLS |
| Welcome-e-mail quota | DB-side one-shot claim + allow-list trigger |
| Release integrity | Release builds refuse the debug key without `android/key.properties` |
| Logs | Ids and status codes only; upstream error bodies capped at 500 chars |

Medical-safety stance in code: nothing is auto-accepted — every field is editable, unverified medicines are flagged, ICD codes are deterministic, differentials are doctor-only, missing fields stay empty rather than guessed, an unsigned PDF says so, and signing requires a complete, identifiable doctor profile.

## 7. Testing and evaluation

- **Flutter unit + widget: 349** (`flutter test`, 2026-09-22). Notable: `pending_consultations_test` (17: drain order, network stop, server retry cap, sign-out mid-processing, overlapping drains), `recording_offline_test` (4), `pending_consultations_card_test` (9), `pending_consultations_app_test` (the queue drains with Home nowhere on screen), `db_migration_v3_test`, `patient_edit_test`, `patient_history_reports_test`, `l10n_claims_test` (no "HIPAA"/"end-to-end" in any ARB), `auth_redirect_test`, `auth_router_flow_test`, `auth_validation_test`, `secure_session_storage_test` (fake vault with failRead/failQuery/failWrite/failDelete), `signup_typo_warning_test`, `doctor_data_isolation_test`, `consultation_retry_test`, `consultation_nothing_heard_test`, `review_sign_save_failure_test`, `review_investigations_test`, `pdf_shaper_test` (conjunct narrower than its letters; per-language letterforms with a determinism control; no cross-language cache reuse), `prescription_pdf_{fonts,labels,signature}_test` (each printed label goes through the shaper in all 7 Indian languages; notes never printed; investigations printed), `export_service_test`, `zip_builder_test`, `failure_text_test`, `medical_insight_lenient_json_test`, drug corrector + ICD tests.
- **Deterministic on-device evals (no network):** `eval_pipeline_test`, `eval_stress_test` (20 adversarial), `eval_vernacular_150_test`, `eval_mega_450_test` (450 realistic rural STT outputs across Hindi/Hinglish, Telugu, Tamil, Kannada … ) — they feed realistic extraction outputs into the ICD mapper + differential engine and print a report card. They do **not** exercise Sarvam or Gemini.
- **Deno: 42** (`deno test supabase/functions/ scripts/bench_v2/lib/`, no permissions): drug matcher contract, extraction contract (transliteration, "B-Complex stays B-Complex", one medicine amid unrelated talk not dropped), `isOwnStoragePath` (9, incl. `<uid>-evil/`, traversal, empty segments), welcome e-mail escaping (6), `fetchWithRetry` (9, fetch stubbed, backoff recorded not slept), the bench grader (6).
- **Integration (device + live backend + keys):** `integration_test/prescription_e2e_test.dart` (spoken clip fixture → upload → Sarvam → Gemini → Review → Sign → PDF; asserts diagnosis, medicine, dosage, timing, investigations, advice, follow-up), `settings_e2e_test.dart` (login → onboarding with a drawn signature → every Settings tile → logout; macOS desktop with a dev account), `e2e_test.dart` (live mic).
- **Pipeline eval harness `scripts/bench_v2`** (Deno): answer-key scripts → Sarvam **Bulbul TTS** → WAV → the *same* `_shared/pipeline.ts` functions imported directly (so prompt edits are measured without a deploy) → per-field grading (name with `accept_name` aliases, dosage, frequency, duration, timing, followUpDays, trap assertions) → `results/report.md` + `results.json`, with latency and ₹ cost. `--dry-run` exercises grader + report with mock extractions, no keys. Ground truth: `rxvarta_answer_key.json` at the repo root (12 Hinglish scripts). **First full baseline, 2026-09-22: 84 % of clinical fields, dosage 55 % (§10.2).** `bin/regrade.ts` re-grades any saved run offline; `holdout_answer_key.json` is the held-out set; `scripts/bench_v2/lib/normalize_test.ts` pins the grader. Every run overwrites `results/` — copy it aside first. `scripts/pipeline_bench` (Dart) is older and calls the *deployed* function. `scripts/golden_audio_bench` replays golden audio.

## 8. CI and release

- `.github/workflows/ci.yml` (pull requests and pushes to `main`/`develop`): **Analyze & Test** — checkout, Java 17, Flutter, `pub get`, `dart format --set-exit-if-changed`, `build_runner`, `flutter analyze`, `flutter test`; **Build APK** — frees runner disk first (it failed for weeks with "No space left on device"), placeholder `app_config.json`, `flutter build apk --debug`, uploads the artifact; **Secret Scan** — gitleaks.
- `.github/workflows/supabase-ci.yml` (paths `supabase/**`, `scripts/ci/**`, the dictionary): `deno check` ×4, `deno lint`, `deno fmt --check`, **`deno test`** (added 2026-09-21; the tests existed but never ran), then the four guard scripts.
- CodeRabbit reviews PRs (GitHub app; no config file in the repo); Dependabot (`.github/dependabot.yml`) bumps pub and Gradle.
- Release: `flutter build appbundle --release --dart-define-from-file=config/app_config.json`; upload keystore outside the repo (PKCS12) referenced by git-ignored `android/key.properties` (`docs/RELEASE.md`). No Play Console work has started.

## 9. Current state (as of 2026-09-22)

**Branch:** `launch/roadmap`, off `main`. `b80b2cb` is the last commit pushed to both remotes; **`d588db5` and `8c76fab` are local only** — the owner has asked that nothing more be pushed or added to the PRs until they say so.

**Uncommitted on 2026-09-22, all analyzer-clean, 349 tests green, ready as three commits** (messages drafted; the LiveReview gate's BYOK Gemini reviews have been failing since ~04:00 IST, see §12):

| Commit | Content | Size | Gate |
|---|---|---|---|
| A (staged) | Edit a patient outside a consultation (roadmap 16); false "HIPAA compliant – End-to-end encrypted" removed from 7 translations; two overflow fixes; `patient_edit_test` (6), `l10n_claims_test` (9) | ~650 LOC | fits the remaining quota |
| B | Reports strip in visit history (roadmap 17); `patient_history_reports_test` (5) | ~310 LOC | fits |
| C | Offline consultation + upload queue (roadmap 13, 14): `ConsultationProcessor`, `PendingConsultations`, Home card, schema v3, recording-screen changes, 9 strings ×8 languages; 34 tests, 20 mutations caught | ~2,600 LOC | exceeds the quota — needs the owner's vouch, as for `ab242fe`/`a2306f7` |

**Untracked:** this brief; `scripts/bench_v2/pending/dosage_prompt_2026-09-22.patch` (§10.2) and `measure_dosage_fix.sh` (applies the patch, runs both keys, re-grades against the baseline, removes the patch again).

**Remotes and PRs** (same branch, two PRs; keep both in sync):

| Remote | Repo | PR | Role |
|---|---|---|---|
| `varadraj` | `Varadraj75/EMR` | [#86](https://github.com/Varadraj75/EMR/pull/86) | Upstream. The active PR: full description, roadmap status, CI, CodeRabbit. Edit its body by inserting sections, never by replacing it; it ends with a CodeRabbit-managed block between HTML comments that must stay byte-identical. |
| `origin` | `bserc-labs/EMR` (fork of the above) | [#1](https://github.com/bserc-labs/EMR/pull/1) | Mirror. Its body now just points at #86. |

**Commits on the branch beyond `main`** (oldest first):

| Hash | Summary |
|---|---|
| `7de3e8e` | Launch roadmap: doctor accounts, per-doctor data, signed PDFs, reliability fixes (the big one; 197 tests) |
| `f742ff3` | Recording survives screen lock, retry with the same audio, plain error messages, release signing gate |
| `39ab6ff` | Live recent-patient list, debounced patient search, CI disk space |
| `b8674c5` | `pipeline_jobs` base schema + RLS migrations; **audio-path ownership check** in `process-consultation` (closes an IDOR) |
| `fd5c2b5` | Branded auth e-mails and the one-time welcome e-mail (`send-welcome-email` edge function) |
| `b5eada9` | Base `pipeline_jobs` migration matched to production's real schema; adopt/replace prod's hand-made policies |
| `dd10049` | Welcome e-mail hardening (logo URL from `SUPABASE_URL`, HTML-escaping, allow-list trigger); **CI now runs the Deno tests** |
| `ab242fe` | PDF shaping for 7 Indian scripts, translated PDF labels, Investigations + Doctor's notes on review (roadmap 19, 21) |
| `a2306f7` | Session encrypted in Keystore/Keychain; strict sign-up and permissive log-in validation; password policy explained; typo hint |
| `b80b2cb` | Drug-name corrector keeps the strength and keeps a brand a brand (`Telma 40` was becoming `Telmisartan`) |
| `d588db5` | *(local only)* Eval grader: a wrong number is never a match; `bin/regrade.ts`; held-out answer key; grader tests in CI |
| `8c76fab` | *(local only)* `fetchWithRetry` for all 8 Sarvam calls and Gemini (3 attempts, 1 s/2 s, 408/429/5xx + network errors); 9 Deno tests |

**CI on `a2306f7`:** all green — Analyze & Test (282 Flutter tests, analyzer clean), Build APK, Secret Scan (gitleaks), validate-supabase (27 Deno tests, lint, fmt, migration/prompt/dictionary/key checks).

**Local verification of the working tree (2026-09-22, HEAD `8c76fab` + A/B/C above):** `flutter analyze` no issues · `flutter test` 349 pass · `dart format` clean · `deno fmt --check`, `deno lint` clean · `deno test` 42 pass · all 4 `scripts/ci/*.sh` pass · every migration parses under libpg_query.

**Note on `ab242fe` and `a2306f7`:** they were committed with `lrc review --staged --vouch` at the user's explicit request because the LiveReview plan (free, 30,000 LOC/month) had 2,494 lines left and C alone needed 5,028. Before that, both went through a 44-agent adversarial review (6 dimensions × 3 independent verifiers per finding); its 8 confirmed defects were fixed and each fix was mutation-tested (revert the fix → its test goes red; 10/10 did).

### 9.1 Production (Supabase project `rxvarta-prod`, ref `excmhjpttqjfyodynfza`, ap-south-1, Postgres 17) — repo vs live

Read from the live project on 2026-09-21 via the Management API (read-only). **The repo is ahead of production.** Nothing from this branch's backend work is live yet:

| Thing | Repo | Live |
|---|---|---|
| `process-consultation` | audio-path ownership check (IDOR fix), Gemini retry/backoff, typeof guards | **v19** — predates all three. Any signed-in doctor can still have another doctor's audio transcribed and deleted. |
| `check-job-status` | Gemini retry via `_shared/pipeline.ts` | v15 — predates it |
| `send-welcome-email` | complete | **not deployed** |
| `extract-insights` | not in repo | v1 live — an orphan from an old design; unused by the app; safe to delete |
| Migrations applied | 7 files | 4: `20260628120000`, `20260629000000`, `20260702000000`, `20260916000000` |
| `pipeline_jobs` RLS | migration `20260921000000` | ON, via a hand-made policy `doctors_see_own_jobs` (`auth.uid() = doctor_id`, role `public`). The migration drops it and creates `pipeline_jobs_select_own` for `authenticated`. |
| `consultation-audio` bucket | migration `20260921000000` | exists (50 MiB; mp4/x-m4a/aac/mpeg/wav) with 5 hand-made policies incl. a duplicated INSERT; migration replaces them with 4 canonical ones |
| `pipeline_jobs` columns | base migration mirrors live | live has `stt_duration_ms`, `extraction_duration_ms`, `total_duration_ms` (integer) that no earlier migration created — the functions write them |
| `doctors.welcome_email_sent_at` + trigger | migration `20260918000000` | absent |
| `brand` bucket + logo | migration + `apply_remote.py brand-assets` | absent |
| Auth e-mail templates | `supabase/templates/*.html` + `apply_remote.py auth-emails` | older 8-digit OTP templates are live (sender name "Rxvarta"; SMTP host `smtp-relay.brevo.com`; the sender is the project's `smtp_admin_email`) |
| Secrets | needs `BREVO_API_KEY`, `WELCOME_EMAIL_SENDER` | present: `SARVAM_API_KEY`, `GEMINI_API_KEY`, plus the Supabase-managed ones. **Brevo ones absent** |
| Auth config | `config.toml`: `password_requirements = "lower_upper_letters_digits_symbols"`, `otp_length = 8`, confirmations on | matches for OTP/min length 8; password_requirements not verified live |

**Deploy runbook** (owner runs it; an AI in Claude Code cannot — see §12). Order matters; the first line closes a live hole:

```bash
supabase functions deploy process-consultation --use-api --project-ref excmhjpttqjfyodynfza
supabase functions deploy check-job-status --use-api --project-ref excmhjpttqjfyodynfza
python3 scripts/supabase/apply_remote.py migrate supabase/migrations/20260628000000_pipeline_jobs_base.sql
python3 scripts/supabase/apply_remote.py migrate supabase/migrations/20260918000000_brand_bucket_and_welcome_email.sql
python3 scripts/supabase/apply_remote.py migrate supabase/migrations/20260921000000_pipeline_jobs_rls_and_audio_bucket.sql
supabase functions deploy send-welcome-email --use-api --project-ref excmhjpttqjfyodynfza
python3 scripts/supabase/apply_remote.py brand-assets
python3 scripts/supabase/apply_remote.py auth-emails
supabase secrets set WELCOME_EMAIL_SENDER=<the project's smtp_admin_email — already a verified Brevo sender> BREVO_API_KEY=xkeysib-... --project-ref excmhjpttqjfyodynfza
```

`BREVO_API_KEY` must be a Brevo **API** key (`xkeysib-…`, *SMTP & API → API Keys*), not the SMTP key GoTrue uses (`xsmtpsib-…`). Until the two secrets exist, `send-welcome-email` answers HTTP 500 "Mailer not configured" without touching the one-shot flag; nothing else is affected. Every migration is idempotent and the Management API runs a file as one transaction (verified: `clock_timestamp() - now()` in statement 2 equals a `pg_sleep` in statement 1). The API runs as role `postgres`, which is **not** a superuser on hosted Supabase. `supabase db push` cannot be used from dev machines: nobody has the DB password; `apply_remote.py migrate` posts the file and records the version in `supabase_migrations.schema_migrations`.

**Verification after deploy** (read-only): `python3 scripts/supabase/apply_remote.py verify` prints doctors columns, policies, buckets, auth values. The scratch helpers `remote_state.py` / `remote_policies.py` (not in repo) did a fuller snapshot; rebuild from `apply_remote.sql()` if needed.

## 10. Known defects and open issues (ranked)

1. **The Gemini key is on the free tier: 20 requests per DAY.** Found 2026-09-22 when the bench died at its 20th request: HTTP 429, `quotaId: GenerateRequestsPerDayPerProjectPerModel-FreeTier`, `limit: 20, model: gemini-2.5-flash`. That is the key in the git-ignored `.env`. **Whether the production secret `GEMINI_API_KEY` is the same project is unverified** — secret values cannot be read, and production has never exceeded 11 jobs in a day, so it has never reached the cap (no 429 in `pipeline_jobs`). If it is free-tier, launch means 20 consultations a day across every doctor, then hard failures. Second reason to move to the paid tier regardless: under Google's Gemini API terms, content sent to the *unpaid* service may be used to improve Google's products and be read by human reviewers; the paid tier is not (verify the current terms) — and this content is doctor–patient conversation. Owner action: enable billing on the project behind the production key (cost is ~₹0.28 per consultation). It also unblocks all eval work: one 12-script pass plus the 6 held-out scripts is 18 requests, i.e. the whole day's quota. LiveReview's free plan is "BYOK" too, so its commit-gate reviews appear to fail when the same quota is exhausted.
2. **Dosage extraction — measured 11/20 (55 %) on the first full baseline**, 2026-09-22, saved as `scripts/bench_v2/results/baseline_2026-09-22_pre-dosage-fix.{json,md}` (git-ignored; re-grade with `bin/regrade.ts`). All clinical fields: 86/102 (84 %): name 21/22, dosage 11/20, frequency 20/21, duration 12/15, timing 11/12, follow-up 11/12; both traps pass; median 8.1 s; ₹0.43. The same prompt scored 100 % on `script_01` on 09-11 and 0/2 on 09-15 with **no prompt change in between** (last prompt edit: July) — so the failure is *stochastic*, and any fix must be judged on repeated passes, never one. The nine dosage misses, by cause:
   - **Left empty though "ek tablet" was spoken** (2). In both prompts the word "dosage" occurs only in two negative rules ("if not explicitly spoken return empty; NEVER guess '500mg'…", "do not repeat dosage in instructions"). The `STRUCTURED FIELDS` few-shot block maps frequency, duration and timing but **never dosage**; *tablet / goli / chammach* appear nowhere; every schema field is a bare `{type:"STRING"}`.
   - **Strength written instead of the amount — the amount is lost** (5): "Augmentin 625 **ek tablet**" → name `Augmentin`, dosage `625mg`. Had the doctor said *do tablet* or *aadhi goli*, the prescription would still read "650mg". The ground truth's convention loses nothing and is the one to adopt: **the strength belongs to the name (`Augmentin 625`), dosage is the amount taken each time (`1 tablet`)**.
   - **Hindi number merging, a safety hazard** (1, inside the 5): "Azithromycin **500 ek** tablet" was transcribed as "**501** tablet" and extracted as dosage `501mg`.
   - **The ground truth asks for an inference** (2) — see item 4.
   Other misses: "continue karo" not captured as a duration (2); a conditional follow-up *with* a timeframe ("hafte baad dikhana agar zaroorat pade") returned null (1); a spoken brand swapped for another brand of the same drug, `Montek LC` → `Montair LC` (1).
   **The fix is written but NOT measured** (blocked by item 1): `scripts/bench_v2/pending/dosage_prompt_2026-09-22.patch` (untracked; `git apply` it) — for both prompts: dosage added to STRUCTURED FIELDS with a definition and few-shots, strength-in-name rule, the 501 rule (restore the real strength, dosage `1 tablet`, `needsReview: true`), `continue` as a duration, conditional-but-timed follow-ups, never swap a spoken brand; `description` on every medication field in both schemas; `prompt_hashes.txt` updated. Its examples deliberately use medicines that are **not** in either answer key. It was taken out of the working tree on purpose: `supabase functions deploy` ships the working tree, and an unmeasured prompt must not reach production. To finish: paid key → `git apply` the patch → three full passes (copy `results/` aside after each: every run overwrites it) → `./run.sh --answer-key holdout_answer_key.json` → compare with `deno run --allow-read bin/regrade.ts results/baseline_…json results/<pass>.json`. Accept only if dosage is materially up on **both** keys, the not-spoken dosages stay empty (`script_04` Betadine, `script_07` Candid, `holdout_04` both medicines), traps pass, nothing else regresses.
3. **The on-device corrector stripped brand and strength — FIXED in `b80b2cb`.** The extractor already returns some names with a strength ("Telma 40" in the baseline); `DrugNameCorrector.correct` matched the whole string, the brand guard missed ("telma40" ≠ "telma"), and the prescription showed `Telmisartan` — `Augmentin 625` → `Amoxicillin + Clavulanic Acid`, `Dolo 650` → `Paracetamol`. It now matches the name without its trailing strength and puts the strength back. 11 new tests; one older expectation changed on purpose (`tab paracetamol 500mg` → `Paracetamol 500mg`, no longer bare `Paracetamol`). This had to land before the prompt fix, which moves strengths into names.
4. **Two ground-truth entries expect an unspoken dosage — owner/clinician decision, do not "fix" by tuning.** `script_05`: "Ofloxacin-Ornidazole **ki tablet** subah shaam" and `script_08`: "Metformin 500 subah shaam … continue karo" — no amount is spoken, the key expects `1 tablet`. The product's rule is *never infer an unspoken field*, and the pending prompt says "do not assume one tablet", so these two will keep scoring as misses until someone decides: change the key to `""`, or accept one-tablet inference as safe. Dosage can therefore reach at most 18/20 under the current rule.
5. **The bench grader forgave wrong numbers — fixed, staged, not yet committed.** `fieldsMatch` fell back to Levenshtein ≤ 1 on the raw strings, so "5 days" matched "3 days", "5 ml" matched "2 ml", "1 tablet" matched "2 tablet"; `nameMatches` let "Dolo 500" pass for "Dolo 650" and "Azithromycin 501" pass through the bare alias. Numbers must now agree exactly; only the words around them may drift. It also gained the synonyms whose absence marked correct answers wrong (`thrice daily`; `as needed (SOS)` — the phrase the prompt itself asks for). Re-grading the baseline under the fixed grader moved frequency 17/21 → 20/21 and nothing else, so no wrong-number pass was hiding in it. New: `scripts/bench_v2/lib/normalize_test.ts` (6 tests, now run by Supabase CI), `scripts/bench_v2/bin/regrade.ts` (re-grade saved runs with the current grader: free, offline, `--misses` lists every miss, `--answer-key` for the held-out set), and `holdout_answer_key.json` (6 scripts, 9 medicines that appear in neither the main key nor the prompt's examples, written before any post-fix result was seen; clinical content AI-drafted, needs a clinician's check). Committed as `d588db5` (local only).
6. **Production reliability so far:** 136 jobs since June, 108 succeeded — **21 % failed**: Gemini 503 ×8 (the retry that handles them is in the repo but not deployed), Sarvam "failed to read the file" ×6 (July), no-transcript / silent audio ×7 (several are test recordings), batch timeout ×2, others ×5. Sarvam calls now retry too (`8c76fab`, local only) — not live until `process-consultation` and `check-job-status` are redeployed.
7. **Production is behind the repo** — the IDOR fix is not live (§9.1).
8. **Android backs up all patient data to the doctor's Google account.** Pre-existing behaviour (there was no `allowBackup`/`fullBackupContent` before). The new `backup_rules.xml` / `data_extraction_rules.xml` exclude only `flutter_secure_storage`'s two prefs files. Whether `app_flutter/users/<uid>/` (SQLite DB, attachments, recordings, signature) may leave the phone is a compliance decision (India's DPDP Act) — a two-line change once decided.
9. **Store readiness gaps:** `PRIVACY_URL` and `TERMS_URL` are empty in `config/app_config.json` (Play requires a hosted privacy policy URL; the text exists only as bundled `assets/legal/privacy_en.md`, `terms_en.md`, English only, while the app ships 8 languages); `SUPPORT_EMAIL` / `SUPPORT_WHATSAPP` empty, so Help & Support offers no contact route; no Play listing/data-safety work done; iOS out of scope by decision.
10. `assets/brand/rxvarta_logo.png` (85 KB) is declared in `pubspec.yaml` assets but never loaded from Dart — it exists for the e-mail templates (served from the public `brand` bucket). Dead weight in every APK unless in-app branding is planned.
11. `.env` at the repo root (gitignored) still carries `AUTO_LOGIN_EMAIL` / `AUTO_LOGIN_PASSWORD` from the removed shared-login era plus the Sarvam/Gemini keys. The app does not read it (it uses `--dart-define-from-file=config/app_config.json`); `scripts/bench_v2/lib/env.ts` may. Do not reintroduce it as an asset.
12. **Plus Jakarta Sans is fetched at runtime** (`google_fonts` in `app_typography.dart`, from `fonts.gstatic.com`; cached after the first fetch). A first launch without internet renders the UI in the system font until the font arrives. Now that offline is a supported state, bundle the family under `assets/fonts/` as the Noto files already are (a `pubspec` change plus `GoogleFonts.config.allowRuntimeFetching = false`). Cosmetic; noticed 2026-09-22 from the test-log noise.
13. Roadmap items still open (§11.3).

## 11. Implementation plan

Decided with the owner on 2026-09-21: **Android only; phases in the order below** (measure before fixing, so the fix is provable).

### Phase 1 — Ship what's built — DONE (repo side)
Six commits landed and pushed; PRs updated; CI green. **Remaining: the production runbook in §9.1, owner-run.** Then a read-only verification.

### Phase 2 — Full 12-script baseline — DONE 2026-09-22
86/102 clinical fields (84 %), dosage 11/20; details and the saved run in §10.2.

### Phase 3 — Fix dosage extraction — WRITTEN, NOT MEASURED; blocked on the Gemini quota (§10.1)
Landed: the corrector fix (`b80b2cb`); the grader fix, `bin/regrade.ts`, the held-out key and the CI step (`d588db5`, local only). One command measures the patch once the quota is back: `scripts/bench_v2/pending/measure_dosage_fix.sh` (18 Gemini requests; applies the patch, runs both keys, re-grades against the saved baseline, and always takes the patch out of the working tree again). Pending as a patch: the prompt and schema change (§10.2), with the exact steps to measure and the acceptance bar. Open decision: the two ground-truth entries in §10.4. **Done when:** dosage is materially up on the 12 scripts *and* the 6 held-out ones across three passes, every not-spoken dosage is still empty, traps pass, no other field regressed; then redeploy `process-consultation` and `check-job-status`. Afterwards: scripts in languages other than Hinglish (both keys are `hinglish` only), and a bench floor in CI.

### Phase 4 — Store readiness (Android)
Hosted privacy policy + terms (translate, at least Hindi), `PRIVACY_URL`/`TERMS_URL`/`SUPPORT_*` in the build config, Play data-safety form, listing assets, closed-testing track; decide §10 item 8 first, since the data-safety form asks exactly that question.

### 11.3 Roadmap items (1–33) not yet done
From PR #86 (see §4 for what each feature does). Not done: **15** live transcript · **18** safety checks (drug interactions/allergies) · **30** crash reporting (Sentry was removed in cleanup; nothing replaced it). Partly done: **20** "WhatsApp" and "Other apps" open the same share sheet (no WhatsApp-specific intent) · **32**. Done 2026-09-22, uncommitted (§9): **13** and **14** offline consultation + queue, **16** patient editing, **17** reports in history. Everything else is done (12 Must-Haves in `7de3e8e`; 19, 21, 31 since).

## 12. Working constraints for an AI on this repo (learned the hard way)

**Commit gate.** A LiveReview hook wraps `git commit` (global `core.hooksPath` + a Claude Code `PreToolUse` hook). Consequences:
- Plain `git commit` with an unreviewed staged tree opens a **blocking browser review** (localhost:800x) and waits up to 20 min for a human click; the message chosen in the browser **replaces** the one passed to git. If the session ends first the staged tree is frozen.
- The no-click path: stage → `lrc review --agent-mode` (JSON review, writes an "agent-reviewed" attestation) → read its comments → bare `git commit -F msg.txt` as its **own** Bash call (compound commands like `cd … && git commit` or `git add … && git commit` are rejected with a misleading "supports a single git commit command only"). The message is kept.
- Each review is billed against a monthly LOC quota (plan `free_30k`, 30,000/month; ~2,500 lines left as of 2026-09-21, resets monthly). Over quota → "Operation requires N LOC, but you only have M remaining". `lrc usage inspect` returns 401 even though reviews work.
- Message-only `git commit --amend` fails ("no diff content collected"); a bad message cannot be fixed through the gate.
- The free plan is **BYOK**: reviews run on two Gemini connectors in `~/.lrc.toml` (both `gemini-2.5-flash`; not the `.env` key). When they fail with `all N batches failed: [batch-1 batch-2]` the review is unusable but still counts as an attempt; on 2026-09-22 three reviews succeeded around 04:00 IST and every one after failed that way, which fits a per-day free-tier cap (reset 00:00 Pacific = 12:30 IST). Retry after the reset; do not bypass.
- Never `--no-verify`, `lrc review --skip`, `--vouch`, or `lrc hooks disable` on your own initiative; only when the user explicitly asks. Record it in the commit message when they do.

**Bash hook quirk.** The same hook rejects **any** Bash command containing `$(`, `${`, process substitution `<(`, or a leading `VAR=$…` assignment, with the same misleading message — even `grep`, even `for` loops. Write files that contain `$` (Dart interpolation, shell) with the Write/Edit tools, not heredocs; do loops in `python3 -c`; use `env VAR=value cmd`.

**`rtk` rewrites shell commands.** A hook proxies common commands through `rtk` (a token-saving wrapper): `find` becomes `rtk find`, which **rejects compound predicates** (`-not`, `-exec`) with exit 1. With `2>/dev/null` that error is invisible and an empty result reads as "no such file" — exactly how this brief's first draft came to claim the answer key did not exist. Never suppress stderr on an existence check; confirm with `ls <path>` and `git ls-files <path>`; use `rtk proxy <cmd>` for the raw command.

**The bench overwrites its own results.** Every `./run.sh` — including `--dry-run` — rewrites `results/report.md` and `results/results.json`, which are git-ignored: a dry run destroyed the only copy of the 09-15 live run. Copy `results/` aside before running, and use `bin/regrade.ts` to compare saved runs. A live pass is 12 Gemini requests against a **20-per-day** free-tier quota (§10.1): check the quota before starting a multi-pass job, because each refused script still pays Sarvam for its transcription.

**`supabase functions deploy` ships the working tree, not HEAD.** Never leave an unmeasured or unreviewed change to `supabase/functions/` in the tree while a deploy is pending; park it as a patch (`scripts/bench_v2/pending/`) or on a branch.

**Auto-mode classifier.** Every mutation of the live Supabase project — `apply_remote.py migrate`, `supabase functions deploy`, `supabase secrets set`, Management API PATCH — is denied as "Production Deploy" / "Modify Shared Resources", even when the user says "do it yourself". Read-only GETs and SQL SELECTs through `apply_remote.sql()` work. Hand the runbook to the user; don't retry.

**Generated code is gitignored.** `**/*.g.dart`, `**/*.freezed.dart` (Drift, freezed, json_serializable). After checkout or any model change: `dart run build_runner build --delete-conflicting-outputs`. CI does this. A snapshot of the tree without it has ~380 analyzer errors — not real.

**Localisation.** Source of truth is `lib/l10n/app_*.arb` (8 files, must stay in lockstep — `flutter gen-l10n` fails on a missing key). The generated `lib/l10n/app_localizations*.dart` **are committed**; regenerate with `flutter gen-l10n` (`l10n.yaml`; `generate: true` in pubspec) and commit them together with the ARBs. English `@key` metadata declares placeholders.

**Prompt drift guard.** `scripts/ci/check_prompt_drift.sh` compares hashes of the Gemini prompts in `_shared/pipeline.ts` against `scripts/ci/prompt_hashes.txt`. Any prompt edit must run `scripts/ci/update_prompt_hashes.sh` and commit the file, or CI fails. Same for `assets/data/drug_dictionary.json` vs `supabase/functions/_shared/drug_dictionary.json` (and a third copy) — `check_drug_dict_sync.sh` requires all byte-identical.

**Deno.** CI pins `denoland/setup-deno@v2` with `deno-version: v1.x`; local dev has 2.9.5. Functions import by full URL (`https://deno.land/std@0.224.0/…`, `https://esm.sh/@supabase/supabase-js@2.45.0`); each function's `deno.json` is the unused scaffold import map — keep them identical. `deno test supabase/functions/` needs **no** permission flags; keep tests pure. `supabase functions download <slug>` overwrites `_shared/` with that function's bundled copy — download into separate dirs when comparing.

**Tests.** `flutter test` 349 (unit + widget; `google_fonts` prints "unable to load font" noise — harmless). Widget tests of screens that navigate after an action must `pump()` frames, not `pumpAndSettle()` (spinners never settle without the router). A test that instantiates `pendingConsultationsProvider` must dispose its container and pump past the 2-minute retry timer before the body ends (`flutter_test` fails on a pending `Timer`); `audioFileExistsProvider` is overridden to `(_) => true` when recordings are imaginary. Integration tests need a booted device + `config/app_config.json` + live keys. Expectation set on this branch: **a fix ships with a test that has been seen to fail without it** (mutation check).

**Build config.** `flutter run/build … --dart-define-from-file=config/app_config.json` (gitignored; example in `config/app_config.example.json`). Without it the app boots to "App not configured". Release builds refuse to sign with the debug key unless `android/key.properties` exists (`docs/RELEASE.md`); `RXVARTA_ALLOW_DEBUG_SIGNING=true` overrides for local trial only. macOS desktop builds run (Xcode 26.6) but keep the plain SharedPreferences session store by design (ad-hoc signing cannot use the Keychain).

**Conventions.** Commit messages: a one-line summary, then *why* in prose (the repo's messages explain the failure that motivated each change), end with `Co-Authored-By: Claude … <noreply@anthropic.com>`. PR descriptions end with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`. Dart: `dart format` (line 80), `flutter_lints`. Comments explain *why*, never restate *what*. Migrations: `YYYYMMDDHHmmss_snake_case.sql`, plain SQL only (no `DO` blocks, no psql meta-commands — the Management API runs the file as one query string), every statement idempotent, a header comment saying what and why, and the word "truncated" trips the destructive-SQL warning in `check_migrations.sh`.

## 13. Key identifiers

| | |
|---|---|
| Package / app id | `rxvarta` / `com.rxvarta.rxvarta`, version `1.0.0+1` |
| Supabase | ref `excmhjpttqjfyodynfza`, `https://excmhjpttqjfyodynfza.supabase.co`, Mumbai |
| Buckets | `consultation-audio` (private, 50 MiB), `doctor-signatures` (private, 2 MiB, `<uid>/signature.png`), `backups` (private, 200 MiB, `<uid>/<timestamp>.zip`), `brand` (public, 1 MiB, logo) |
| Tables | `public.doctors` (RLS own-row), `public.pipeline_jobs` (RLS own-row select; service_role writes) |
| Edge functions | `process-consultation`, `check-job-status`, `send-welcome-email` — all `verify_jwt = false`, each verifies the caller itself with `auth.getUser()` |
| Function secrets | `SARVAM_API_KEY`, `GEMINI_API_KEY`, `BREVO_API_KEY`, `WELCOME_EMAIL_SENDER` (+ Supabase-managed `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`) |
| Dart-defines | `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPPORT_EMAIL`, `SUPPORT_WHATSAPP`, `PRIVACY_URL`, `TERMS_URL`; debug-only `DEBUG_SKIP_STT=true` (forced off in release) |
| Session key | `sb-excmhjpttqjfyodynfza-auth-token` (same key supabase_flutter's default store used, so migration finds it) |
| Audio object key | `<auth uid>/<job uuid>.m4a`, `audio/mp4` |
| Local data | `<app documents>/users/<uid>/` — Drift SQLite (`schemaVersion 3`: `Patients`, `Visits`), attachments, recordings, profile, signature |
| Roles that may change `doctors.welcome_email_sent_at` | `service_role`, `postgres` only (trigger allow-list) |
