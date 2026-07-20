# Golden audio cases

Each subfolder here is one end-to-end test case that gets replayed through the
**real production backend** (Supabase `process-consultation` Edge Function — the
same path the app uses). The harness that runs them lives in
[`scripts/golden_audio_bench/`](../../scripts/golden_audio_bench/README.md).

## Add a case

1. Record the consultation on your phone (or export the `.m4a` from a real
   visit).
2. Create a folder named after the case, e.g. `test/golden_audio/my_case/`.
3. Drop the audio in as **`audio.m4a`**.
4. Write **`expected.json`** describing what the extraction must produce.

```
test/golden_audio/
  my_case/
    audio.m4a        <- your recording (git-ignored; never committed)
    expected.json    <- assertions (committed)
```

A folder with `expected.json` but no `audio.m4a` is a **placeholder**: the
harness lists it and skips it (not a failure). That is the state the two seeded
folders ship in — drop your recordings in to activate them.

## `expected.json` schema

Every field is optional; only the fields you include are asserted.

```jsonc
{
  "medicines_must_contain":     ["Luliconazole", "Itraconazole", "Atarax"],
  "medicines_must_not_contain": ["Paracetamol"],
  "min_medicine_count":         3,
  "diagnosis_contains":         "fungal",
  "followUpDays":               14
}
```

| Field | Meaning |
|---|---|
| `medicines_must_contain` | Each name must appear in an extracted medicine name. |
| `medicines_must_not_contain` | None of these may appear. |
| `min_medicine_count` | Extracted medicine count must be ≥ this. |
| `diagnosis_contains` | Substring that must appear in the diagnosis. |
| `followUpDays` | Extracted `followUpDays` must equal this exactly. |

Optional extra: `"languageCode"` (defaults to `"unknown"`, i.e. Sarvam
auto-detect).

### Matching rules

- All string matching is **case-insensitive substring**.
- **Brand names are asserted verbatim**: because matching is substring on the
  extracted name as-is, `"Atarax"` only passes if the backend returns `Atarax`
  (or `Atarax 25`) — not if it silently canonicalizes to the generic
  `Hydroxyzine`. This is exactly the brand-guard guarantee we want to gate on.

## Run

```
dart run scripts/golden_audio_bench/run.dart
```

See [`scripts/golden_audio_bench/README.md`](../../scripts/golden_audio_bench/README.md)
for when to run it and cost notes.
