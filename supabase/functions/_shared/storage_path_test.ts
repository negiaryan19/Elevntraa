// Tests for the storage-key ownership check that process-consultation applies
// before handing a client-supplied path to the service-role client.
//
// Run: deno test supabase/functions/_shared/storage_path_test.ts

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { isOwnStoragePath } from "./storage_path.ts";

const UID = "6f1b2c3d-4e5f-4a6b-8c9d-0e1f2a3b4c5d";
const OTHER = "11111111-2222-4333-8444-555555555555";

Deno.test("accepts the path the app actually uploads", () => {
  assertEquals(
    isOwnStoragePath(UID, `${UID}/9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d.m4a`),
    true,
  );
});

Deno.test("rejects another doctor's folder", () => {
  assertEquals(isOwnStoragePath(UID, `${OTHER}/recording.m4a`), false);
});

Deno.test("rejects a uid prefix that is not a whole segment", () => {
  // `<uid>-evil/...` starts with the uid as a string but is a different folder.
  assertEquals(isOwnStoragePath(UID, `${UID}-evil/recording.m4a`), false);
});

Deno.test("rejects a bare file with no folder", () => {
  assertEquals(isOwnStoragePath(UID, "recording.m4a"), false);
  assertEquals(isOwnStoragePath(UID, UID), false);
});

Deno.test("rejects a leading slash", () => {
  assertEquals(isOwnStoragePath(UID, `/${UID}/recording.m4a`), false);
});

Deno.test("rejects traversal segments", () => {
  assertEquals(
    isOwnStoragePath(UID, `${UID}/../${OTHER}/recording.m4a`),
    false,
  );
  assertEquals(isOwnStoragePath(UID, `${UID}/./recording.m4a`), false);
});

Deno.test("rejects empty segments", () => {
  assertEquals(isOwnStoragePath(UID, `${UID}//recording.m4a`), false);
  assertEquals(isOwnStoragePath(UID, `${UID}/`), false);
});

Deno.test("rejects empty inputs", () => {
  assertEquals(isOwnStoragePath("", "a/b.m4a"), false);
  assertEquals(isOwnStoragePath(UID, ""), false);
});

Deno.test("allows nested folders inside the doctor's own folder", () => {
  assertEquals(isOwnStoragePath(UID, `${UID}/2026/09/recording.m4a`), true);
});
