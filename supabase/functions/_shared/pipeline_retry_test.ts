// Transient upstream failures must not cost a doctor a consultation.
//
// Production, June–September 2026: 21 % of pipeline jobs failed, among them
// Gemini 503s, a Sarvam 504 and Sarvam batch hiccups. Gemini calls had a
// retry; Sarvam calls had none, so a single gateway timeout failed the whole
// job even though the recording was fine. These pin the policy: retry what can
// succeed on a second try, fail at once on what cannot.
//
// Run: deno test supabase/functions/_shared/pipeline_retry_test.ts

import {
  assertEquals,
  assertRejects,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  batchCheckStatus,
  batchUploadFile,
  extractInsight,
  setRetryDelayForTests,
  transcribeRest,
} from "./pipeline.ts";

/** Replaces global fetch with a scripted sequence; the last entry repeats. */
function scriptFetch(sequence: Array<(() => Response) | Error>) {
  const original = globalThis.fetch;
  let calls = 0;
  globalThis.fetch = (() => {
    const step = sequence[Math.min(calls, sequence.length - 1)];
    calls++;
    return step instanceof Error
      ? Promise.reject(step)
      : Promise.resolve(step());
  }) as typeof fetch;
  return {
    calls: () => calls,
    restore: () => {
      globalThis.fetch = original;
    },
  };
}

const json = (body: unknown, status = 200) => () =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
const text = (body: string, status: number) => () =>
  new Response(body, { status });

const audio = new Uint8Array([1, 2, 3]);

// No real waiting in tests; record the backoff that WOULD have been slept.
const slept: number[] = [];
setRetryDelayForTests((ms) => {
  slept.push(ms);
  return Promise.resolve();
});

Deno.test("Sarvam REST: a 504 followed by a 200 succeeds", async () => {
  slept.length = 0;
  const f = scriptFetch([
    text("<html>504 Gateway Time-out</html>", 504),
    json({ transcript: "namaste doctor" }),
  ]);
  try {
    assertEquals(
      await transcribeRest("k", audio, "a.m4a", "hi-IN"),
      "namaste doctor",
    );
    assertEquals(f.calls(), 2);
    assertEquals(slept, [1000]);
  } finally {
    f.restore();
  }
});

Deno.test("Sarvam REST: a 400 fails immediately, with the same message as before", async () => {
  slept.length = 0;
  const f = scriptFetch([text('{"error":{"message":"bad audio"}}', 400)]);
  try {
    await assertRejects(
      () => transcribeRest("k", audio, "a.m4a", "hi-IN"),
      Error,
      'Sarvam REST 400: {"error":{"message":"bad audio"}}',
    );
    assertEquals(f.calls(), 1, "a bad request is never retried");
    assertEquals(slept, []);
  } finally {
    f.restore();
  }
});

Deno.test("Sarvam REST: a dropped connection is retried", async () => {
  const f = scriptFetch([
    new TypeError("connection reset"),
    new TypeError("connection reset"),
    json({ transcript: "ok" }),
  ]);
  try {
    assertEquals(await transcribeRest("k", audio, "a.m4a", "hi-IN"), "ok");
    assertEquals(f.calls(), 3);
  } finally {
    f.restore();
  }
});

Deno.test("Sarvam REST: gives up after three attempts, backing off 1 s then 2 s", async () => {
  slept.length = 0;
  const f = scriptFetch([text("overloaded", 503)]);
  try {
    await assertRejects(
      () => transcribeRest("k", audio, "a.m4a", "hi-IN"),
      Error,
      "Sarvam REST 503: overloaded",
    );
    assertEquals(f.calls(), 3);
    assertEquals(slept, [1000, 2000]);
  } finally {
    f.restore();
  }
});

Deno.test("Sarvam REST: an empty transcript is an answer, not a failure to retry", async () => {
  // The app recognises this message ("produced no transcript") and tells the
  // doctor nothing was heard. Retrying would only pay for the same silence.
  const f = scriptFetch([json({ transcript: "", language_code: "hi-IN" })]);
  try {
    await assertRejects(
      () => transcribeRest("k", audio, "a.m4a", "hi-IN"),
      Error,
      "produced no transcript",
    );
    assertEquals(f.calls(), 1);
  } finally {
    f.restore();
  }
});

Deno.test("Sarvam batch: a status poll survives a 502", async () => {
  const f = scriptFetch([
    text("bad gateway", 502),
    json({ job_state: "Running" }),
  ]);
  try {
    assertEquals(await batchCheckStatus("k", "job-1"), { state: "Running" });
    assertEquals(f.calls(), 2);
  } finally {
    f.restore();
  }
});

Deno.test("Sarvam batch: the audio upload survives a 500", async () => {
  const f = scriptFetch([text("oops", 500), text("", 201)]);
  try {
    await batchUploadFile("https://blob.example/upload", audio);
    assertEquals(f.calls(), 2);
  } finally {
    f.restore();
  }
});

Deno.test("Gemini: a 503 followed by a 200 still extracts", async () => {
  const insight = {
    consultationSummary: "Fever for two days.",
    symptoms: ["fever"],
    diagnosis: "Viral fever",
    medications: [],
    tests: [],
    advice: [],
    instructions: [],
    followUpDays: null,
    doctorNotes: "",
  };
  const f = scriptFetch([
    text('{"error":{"code":503,"message":"high demand"}}', 503),
    json({
      candidates: [{ content: { parts: [{ text: JSON.stringify(insight) }] } }],
    }),
  ]);
  try {
    const result = await extractInsight(
      "Doctor: Do din se bukhar hai, viral fever lag raha hai. Patient: Ji doctor.",
      "k",
    );
    assertEquals(result.insight.diagnosis, "Viral fever");
    assertEquals(f.calls(), 2);
  } finally {
    f.restore();
  }
});

Deno.test("Gemini: a 400 fails immediately", async () => {
  const f = scriptFetch([text('{"error":{"code":400}}', 400)]);
  try {
    await assertRejects(
      () =>
        extractInsight(
          "Doctor: Do din se bukhar hai, viral fever lag raha hai. Patient: Ji.",
          "k",
        ),
      Error,
      "Gemini 400",
    );
    assertEquals(f.calls(), 1);
  } finally {
    f.restore();
  }
});
