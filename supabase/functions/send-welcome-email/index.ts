// send-welcome-email — the one-time welcome e-mail, sent after onboarding.
//
// Why an edge function and not a GoTrue template: GoTrue only mails what its
// own flows trigger (confirmation, recovery, …). "Onboarding finished" is our
// event, so we send it ourselves, through the same Brevo account the auth
// e-mails use.
//
// Sending at most once is enforced in the database, not here: the function
// CLAIMS the row with `update ... where welcome_email_sent_at is null`, which
// is atomic, so two concurrent calls cannot both win. If the send then fails
// the claim is released (set back to null) so a later call retries. See
// migration 20260918000000_brand_bucket_and_welcome_email.sql.
//
// verify_jwt is off in config.toml (as for the other two functions) and the
// caller is verified here instead, which also yields the user id and the
// address to mail.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
import { welcomeEmailHtml, welcomeEmailText } from "./welcome_email.ts";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function corsResponse(body: unknown, status = 200): Response {
  if (body === null) {
    return new Response(null, { status, headers: CORS_HEADERS });
  }
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

const BREVO_ENDPOINT = "https://api.brevo.com/v3/smtp/email";
const SENDER_NAME = "Rxvarta";

serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: CORS_HEADERS });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    "";
  const brevoApiKey = Deno.env.get("BREVO_API_KEY") ?? "";
  const senderEmail = Deno.env.get("WELCOME_EMAIL_SENDER") ?? "";

  // ── 1. Verify JWT ──────────────────────────────────────────────────────
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return corsResponse({ error: "Missing authorization header" }, 401);
  }

  const userClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const {
    data: { user },
    error: authError,
  } = await userClient.auth.getUser();
  if (authError || !user) {
    return corsResponse({ error: "Unauthorized" }, 401);
  }
  const doctorId = user.id;
  const email = user.email ?? "";
  if (!email) {
    // Phone-only accounts cannot be mailed; nothing to retry later either.
    return corsResponse({ sent: false, reason: "no_email" }, 200);
  }

  // A missing secret must not burn the one-shot flag, so this is checked
  // before the claim.
  if (!brevoApiKey || !senderEmail) {
    console.error(
      "[send-welcome-email] BREVO_API_KEY / WELCOME_EMAIL_SENDER not set",
    );
    return corsResponse({ error: "Mailer not configured" }, 500);
  }

  const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey);

  // ── 2. Claim the send ──────────────────────────────────────────────────
  // `is("welcome_email_sent_at", null)` makes this the atomic test-and-set:
  // whoever updates 0 rows has already sent it (or the row is missing).
  const claimedAt = new Date().toISOString();
  const { data: claimed, error: claimError } = await supabaseAdmin
    .from("doctors")
    .update({ welcome_email_sent_at: claimedAt })
    .eq("id", doctorId)
    .is("welcome_email_sent_at", null)
    .select("id, full_name")
    .maybeSingle();

  if (claimError) {
    console.error(
      `[send-welcome-email] doctor=${doctorId} claim failed:`,
      claimError.message,
    );
    return corsResponse({ error: "Failed to claim welcome e-mail" }, 500);
  }

  if (!claimed) {
    // Already sent, or no doctors row yet (onboarding writes it first).
    console.log(`[send-welcome-email] doctor=${doctorId} nothing to send`);
    return corsResponse({ sent: false, reason: "already_sent" }, 200);
  }

  const fullName = (claimed as { full_name: string | null }).full_name ?? "";

  // ── 3. Send through Brevo ──────────────────────────────────────────────
  let ok = false;
  let failure = "";
  try {
    const response = await fetch(BREVO_ENDPOINT, {
      method: "POST",
      headers: {
        "api-key": brevoApiKey,
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: JSON.stringify({
        sender: { name: SENDER_NAME, email: senderEmail },
        to: [
          fullName.trim() === "" ? { email } : { email, name: fullName.trim() },
        ],
        subject: "Welcome to Rxvarta",
        htmlContent: welcomeEmailHtml(fullName),
        textContent: welcomeEmailText(fullName),
      }),
    });
    ok = response.ok;
    if (!ok) {
      failure = `${response.status} ${await response.text()}`;
    }
  } catch (e) {
    failure = e instanceof Error ? e.message : String(e);
  }

  // ── 4. Release the claim if it did not go out ──────────────────────────
  if (!ok) {
    console.error(
      `[send-welcome-email] doctor=${doctorId} send failed: ${failure}`,
    );
    const { error: releaseError } = await supabaseAdmin
      .from("doctors")
      .update({ welcome_email_sent_at: null })
      .eq("id", doctorId)
      .eq("welcome_email_sent_at", claimedAt);
    if (releaseError) {
      // The flag is stuck at our timestamp: no e-mail was sent and no later
      // call will retry. Loud, because only a manual reset clears it.
      console.error(
        `[send-welcome-email] doctor=${doctorId} could not release claim:`,
        releaseError.message,
      );
    }
    return corsResponse({ error: "Failed to send welcome e-mail" }, 502);
  }

  console.log(`[send-welcome-email] doctor=${doctorId} sent`);
  return corsResponse({ sent: true }, 200);
});
