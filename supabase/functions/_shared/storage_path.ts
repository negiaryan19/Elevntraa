// Ownership check for storage keys the client names in a request body.
//
// The edge functions reach storage with the SERVICE ROLE key, which bypasses
// the buckets' per-user folder policies. Any key that arrives from a client
// therefore has to be checked against the caller here, or a signed-in doctor
// could name another doctor's object.

/// True when [path] is inside [doctorId]'s own folder, i.e. `<uid>/<file>`.
///
/// Requires at least one segment after the folder, rejects a leading slash
/// (which would make the first segment empty) and rejects any `.` or `..`
/// segment: storage keys are flat strings, but a traversal segment would
/// still let a crafted key escape the folder wherever a key gets normalised.
export function isOwnStoragePath(doctorId: string, path: string): boolean {
  if (doctorId === "" || path === "") return false;
  const segments = path.split("/");
  if (segments.length < 2) return false;
  if (segments[0] !== doctorId) return false;
  return segments.every((s) => s !== "" && s !== "." && s !== "..");
}
