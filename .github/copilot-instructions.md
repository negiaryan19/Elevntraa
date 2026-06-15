# Copilot / AI assistant instructions — MedScribe (EMR)

MedScribe is a Flutter app for AI-assisted prescription dictation for Indian
doctors. Keep suggestions idiomatic to this codebase.

## Tech stack

- **Framework:** Flutter (Dart SDK `^3.12.1`), Material 3.
- **State management:** `flutter_riverpod` (use providers; avoid `setState` for
  shared/business state).
- **Routing:** `go_router` — route paths are centralized in `lib/app/router.dart`
  via the `AppRoute` enum. Use `AppRoute.foo.path`, never raw strings.
- **Networking:** `dio` (see `lib/core/network/dio_client.dart`).
- **Local DB:** `drift` over `sqlite3`. Generated code lives in `*.g.dart`.
- **Models:** `freezed` + `json_serializable`. Generated `*.freezed.dart` /
  `*.g.dart` files are committed-out (gitignored); regenerate with
  `dart run build_runner build --delete-conflicting-outputs`.
- **Config:** `flutter_dotenv` reads keys from a `.env` asset; secrets via
  `flutter_secure_storage`.

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
- Keep API keys and secrets out of source. Read them from `.env` /
  `flutter_dotenv`; document any new key in `.env.example`.
- Don't edit generated files (`*.g.dart`, `*.freezed.dart`) by hand.
- Write/extend widget tests under `test/` and end-to-end flows under
  `integration_test/`.

## Security

- Never hardcode Sarvam or Gemini API keys, tokens, keystores, or
  `key.properties` in code or commits. Secret scanning (gitleaks) runs in CI.
- This app handles patient health data — be conservative with logging; never log
  PII or prescription content.
