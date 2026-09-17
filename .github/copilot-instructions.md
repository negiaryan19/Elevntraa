# Copilot / AI assistant instructions — Rxvarta (EMR)

Rxvarta is a Flutter app for AI-assisted prescription dictation for Indian
doctors. Keep suggestions idiomatic to this codebase.

## Tech stack

- **Framework:** Flutter (Dart SDK `^3.12.1`), Material 3.
- **State management:** `flutter_riverpod` (use providers; avoid `setState` for
  shared/business state).
- **Routing:** `go_router` — route paths are centralized in `lib/app/router.dart`
  via the `AppRoute` enum. Use `AppRoute.foo.path`, never raw strings.
- **Networking:** `supabase_flutter` (Auth, Storage, PostgREST, Edge Functions); no direct HTTP client.
- **Local DB:** `drift` over `sqlite3`. Generated code lives in `*.g.dart`.
- **Models:** `freezed` + `json_serializable`. Generated `*.freezed.dart` /
  `*.g.dart` files are committed-out (gitignored); regenerate with
  `dart run build_runner build --delete-conflicting-outputs`.
- **Config / secrets:** Build-time values come from `--dart-define-from-file=config/app_config.json`
  via `lib/core/config/app_config.dart` (Supabase URL + publishable key only). Provider
  secrets live in Supabase Edge Function secrets, never in the app. Document any new
  key in `config/app_config.example.json`.

## Project structure

- `lib/app/` — app shell, router, theming entrypoints.
- `lib/core/` — cross-cutting concerns: config, network, theme, widgets, utils.
- `lib/data/` — repositories and the drift database.
- `lib/domain/` — immutable models.
- `lib/features/<feature>/presentation/` — feature UI screens.

## Conventions

- Follow the lints in `analysis_options.yaml` (`flutter_lints`). Code must pass
  `flutter analyze` and `dart format .` with no diffs — CI enforces both.
- Prefer `const` constructors and widgets where possible.
- Keep API keys and secrets out of source and out of the app bundle. Build-time
  config goes through `AppConfig` (`--dart-define-from-file`); document any new
  key in `config/app_config.example.json`.
- Don't edit generated files (`*.g.dart`, `*.freezed.dart`) by hand.
- Write/extend widget tests under `test/` and end-to-end flows under
  `integration_test/`.

## Security

- Never hardcode Sarvam or Gemini API keys, tokens, keystores, or
  `key.properties` in code or commits. Secret scanning (gitleaks) runs in CI.
- This app handles patient health data — be conservative with logging; never log
  PII or prescription content.
