// Loads the two secrets bench_v2 needs — SARVAM_API_KEY (STT + Bulbul TTS) and
// GEMINI_API_KEY (extraction) — from the process environment first, then from a
// .env file. These are the SAME keys the deployed Edge Function reads via
// Deno.env.get; the difference here is that a local run also accepts them from a
// .env file so you don't have to export them by hand.
//
// NOTE: the app's committed .env only holds Supabase connection details — the
// Sarvam/Gemini keys are server-side Supabase secrets. To run bench_v2 for real
// you must supply them, e.g.:
//   SARVAM_API_KEY=... GEMINI_API_KEY=... deno task bench
// or add them to a local .env (never commit it — .env is git-ignored).

export interface BenchKeys {
  sarvamKey: string;
  geminiKey: string;
}

/** Parse a dotenv-style file. Mirrors the app's tolerant `.env` parsing. */
function parseEnvFile(raw: string): Record<string, string> {
  const map: Record<string, string> = {};
  for (const line of raw.split("\n")) {
    const trimmed = line.trim();
    if (trimmed === "" || trimmed.startsWith("#")) continue;
    const idx = trimmed.indexOf("=");
    if (idx < 0) continue;
    const key = trimmed.slice(0, idx).trim();
    let value = trimmed.slice(idx + 1).trim();
    // Strip surrounding quotes if present.
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    map[key] = value;
  }
  return map;
}

async function readEnvFile(path: string): Promise<Record<string, string>> {
  try {
    return parseEnvFile(await Deno.readTextFile(path));
  } catch {
    return {};
  }
}

/**
 * Resolve the Sarvam + Gemini keys, checking (in order):
 *   1. process environment (Deno.env)
 *   2. the given .env files (first match wins)
 * Throws with an actionable message if either is missing.
 */
export async function loadKeys(envPaths: string[]): Promise<BenchKeys> {
  const fromFiles: Record<string, string> = {};
  for (const p of envPaths) {
    const parsed = await readEnvFile(p);
    for (const [k, v] of Object.entries(parsed)) {
      // Earlier files take precedence — don't overwrite.
      if (!(k in fromFiles)) fromFiles[k] = v;
    }
  }

  const pick = (name: string): string =>
    (Deno.env.get(name) ?? fromFiles[name] ?? "").trim();

  const sarvamKey = pick("SARVAM_API_KEY");
  const geminiKey = pick("GEMINI_API_KEY");

  const missing: string[] = [];
  if (sarvamKey === "") missing.push("SARVAM_API_KEY");
  if (geminiKey === "") missing.push("GEMINI_API_KEY");

  if (missing.length > 0) {
    throw new Error(
      `Missing required key(s): ${missing.join(", ")}.\n` +
        "These are Supabase server-side secrets (not in the committed .env).\n" +
        "Provide them via the environment or a local .env, e.g.:\n" +
        "  SARVAM_API_KEY=... GEMINI_API_KEY=... deno task bench\n" +
        "Or run `deno task dry-run` to exercise the grader/report without keys.",
    );
  }

  return { sarvamKey, geminiKey };
}
