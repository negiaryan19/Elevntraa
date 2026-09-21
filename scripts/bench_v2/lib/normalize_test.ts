// The grader decides what counts as a correct extraction, so a lenient grader
// hides exactly the errors the eval exists to find. These pin the rule that
// spelling may drift but a number may not.
//
// Run: deno test scripts/bench_v2/lib/

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { fieldsMatch, nameMatches } from "./normalize.ts";

Deno.test("a wrong number is never forgiven as spelling drift", () => {
  // Each pair is one edit apart, which the fuzzy fallback used to accept.
  assertEquals(fieldsMatch("duration", "5 days", "3 days"), false);
  assertEquals(fieldsMatch("duration", "1 month", "2 month"), false);
  assertEquals(fieldsMatch("dosage", "5 ml", "2 ml"), false);
  assertEquals(fieldsMatch("dosage", "2 drops", "3 drops"), false);
  assertEquals(fieldsMatch("dosage", "1 tablet", "2 tablet"), false);
});

Deno.test("formatting and plural drift around the same number still match", () => {
  assertEquals(fieldsMatch("dosage", "5 ml", "5ml"), true);
  assertEquals(fieldsMatch("dosage", "1 tablet", "1 tablets"), true);
  assertEquals(fieldsMatch("dosage", "2 drops", "two drops"), true);
  assertEquals(fieldsMatch("duration", "5 days", "five days"), true);
  assertEquals(fieldsMatch("dosage", "half tablet", "half tablet"), true);
});

Deno.test("the same frequency in other words matches", () => {
  assertEquals(
    fieldsMatch("frequency", "three times a day", "thrice daily"),
    true,
  );
  assertEquals(fieldsMatch("frequency", "three times a day", "TDS"), true);
  // The extraction prompt asks for this exact phrase.
  assertEquals(fieldsMatch("frequency", "as needed", "as needed (SOS)"), true);
  assertEquals(fieldsMatch("frequency", "twice a day", "thrice a day"), false);
});

Deno.test("an empty expectation only matches an empty answer", () => {
  assertEquals(fieldsMatch("dosage", "", ""), true);
  assertEquals(fieldsMatch("dosage", "", "1 tablet"), false);
  assertEquals(fieldsMatch("dosage", "1 tablet", ""), false);
});

Deno.test("a wrong strength in the name is never a match", () => {
  const dolo = ["Dolo 650", "dolo 650", "dolo"];
  assertEquals(nameMatches(dolo, "Dolo 650"), true);
  assertEquals(
    nameMatches(dolo, "Dolo"),
    true,
    "no strength: the alias allows it",
  );
  assertEquals(nameMatches(dolo, "Dolo 500"), false);

  // "500 ek tablet" mis-heard as "501 tablet".
  const azithro = ["Azithromycin 500", "azithromycin 500", "azithromycin"];
  assertEquals(nameMatches(azithro, "Azithromycin 501"), false);
  assertEquals(nameMatches(azithro, "Azithromycin 501mg"), false);
  assertEquals(nameMatches(azithro, "Azithromycin 500 mg"), true);
});

Deno.test("spelling drift in a name without numbers still matches", () => {
  assertEquals(nameMatches(["Cetrizine", "cetirizine"], "Cetirizine"), true);
  assertEquals(nameMatches(["Montek LC", "montek"], "Montair LC"), false);
});
