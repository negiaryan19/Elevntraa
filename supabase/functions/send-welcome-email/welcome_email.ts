// The welcome e-mail body, as a TS module rather than an .html file so the
// edge-function bundler picks it up without a static_files entry.
//
// Markup rules are the same ones supabase/templates/*.html follow, because the
// same mail clients render both: tables for layout, inline styles only, no
// <style> block, no web fonts, explicit bgcolor next to every background-color.

/// Where the logo is served from: the public `brand` bucket of whichever
/// project runs this function. Built from SUPABASE_URL rather than a pasted
/// project ref, so a fresh project from this repo mails its own logo.
export function brandLogoUrl(supabaseUrl: string): string {
  return `${
    supabaseUrl.replace(/\/+$/, "")
  }/storage/v1/object/public/brand/rxvarta_logo.png`;
}

const SANS =
  "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif";

/// Minimal HTML-escape for the values interpolated from outside this file: the
/// doctor's own name (user input — a `<` in it would break the markup) and
/// the logo URL. `&` goes first so the entities added after it survive.
function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

/// A single "what you can do" row.
function step(number: string, title: string, body: string): string {
  return `
          <tr>
            <td style="padding:0 24px 16px 24px;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
                <tr>
                  <td width="32" valign="top" style="width:32px;">
                    <table role="presentation" cellpadding="0" cellspacing="0" border="0">
                      <tr>
                        <td align="center" bgcolor="#EFF6FF" style="background-color:#EFF6FF;border:1px solid #BFDBFE;border-radius:16px;width:28px;height:28px;font-family:${SANS};font-size:14px;line-height:28px;font-weight:700;color:#1D4ED8;">${number}</td>
                      </tr>
                    </table>
                  </td>
                  <td valign="top" style="padding-left:12px;">
                    <p style="margin:0 0 2px 0;font-family:${SANS};font-size:15px;line-height:22px;font-weight:700;color:#111827;">${title}</p>
                    <p style="margin:0;font-family:${SANS};font-size:14px;line-height:21px;color:#4B5563;">${body}</p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>`;
}

/// Renders the welcome e-mail. [name] is the doctor's full name; when it is
/// blank the greeting falls back to a plain "Welcome to Rxvarta!". [logoUrl]
/// comes from [brandLogoUrl].
export function welcomeEmailHtml(name: string, logoUrl: string): string {
  const trimmed = name.trim();
  const greeting = trimmed === ""
    ? "Welcome to Rxvarta!"
    : `Welcome to Rxvarta, ${escapeHtml(trimmed)}!`;

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="x-apple-disable-message-reformatting">
  <meta name="color-scheme" content="light">
  <meta name="supported-color-schemes" content="light">
  <title>Welcome to Rxvarta</title>
</head>
<body style="margin:0;padding:0;background-color:#F1F5FF;-webkit-text-size-adjust:100%;-ms-text-size-adjust:100%;">
  <div style="display:none;max-height:0;max-width:0;overflow:hidden;opacity:0;font-size:1px;line-height:1px;color:#F1F5FF;mso-hide:all;">Your Rxvarta account is ready. Here is how to write your first prescription.</div>
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" bgcolor="#F1F5FF" style="background-color:#F1F5FF;">
    <tr>
      <td align="center" style="padding:32px 16px;">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" bgcolor="#FFFFFF" style="width:100%;max-width:600px;background-color:#FFFFFF;border:1px solid #E5E7EB;border-radius:16px;">
          <tr>
            <td align="center" bgcolor="#2563EB" style="background-color:#2563EB;background-image:linear-gradient(135deg,#2563EB 0%,#14B8A6 100%);border-radius:16px 16px 0 0;padding:28px 24px;">
              <table role="presentation" cellpadding="0" cellspacing="0" border="0">
                <tr>
                  <td align="center" bgcolor="#FFFFFF" style="background-color:#FFFFFF;border-radius:14px;padding:6px;">
                    <img src="${
    escapeHtml(logoUrl)
  }" width="56" height="56" alt="Rxvarta" style="display:block;width:56px;height:56px;border:0;outline:none;text-decoration:none;border-radius:10px;">
                  </td>
                </tr>
              </table>
              <p style="margin:12px 0 0 0;font-family:${SANS};font-size:24px;line-height:30px;font-weight:700;color:#FFFFFF;">Rxvarta</p>
            </td>
          </tr>
          <tr>
            <td style="padding:32px 24px 0 24px;">
              <h1 style="margin:0 0 12px 0;font-family:${SANS};font-size:22px;line-height:30px;font-weight:700;color:#111827;">${greeting}</h1>
              <p style="margin:0 0 24px 0;font-family:${SANS};font-size:16px;line-height:24px;color:#4B5563;">Your account is ready. Rxvarta listens to a consultation and turns it into a structured prescription you review, sign and share &mdash; in the language you and your patient already speak.</p>
            </td>
          </tr>
${
    step(
      "1",
      "Record the consultation",
      "Start a visit and talk as you normally would. Hindi, Marathi, Bengali, Gujarati, Kannada, Tamil, Telugu and English all work.",
    )
  }
${
    step(
      "2",
      "Review what was heard",
      "Medicines, diagnosis, investigations and advice come back filled in. Every field is editable before you sign.",
    )
  }
${
    step(
      "3",
      "Sign and share",
      "Your signature and clinic letterhead go on the PDF, ready to hand over or send on WhatsApp.",
    )
  }
          <tr>
            <td style="padding:8px 24px 0 24px;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
                <tr>
                  <td style="border-top:1px solid #E5E7EB;font-size:0;line-height:0;">&nbsp;</td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td style="padding:16px 24px 24px 24px;">
              <p style="margin:0 0 8px 0;font-family:${SANS};font-size:14px;line-height:21px;color:#4B5563;"><strong style="color:#111827;">One tip before you start:</strong> add your clinic details and signature in Settings once, and every prescription you write afterwards carries them.</p>
              <p style="margin:0;font-family:${SANS};font-size:14px;line-height:21px;color:#4B5563;">Patient records stay on your phone. Nothing is shared with anyone else.</p>
            </td>
          </tr>
        </table>
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="width:100%;max-width:600px;">
          <tr>
            <td align="center" style="padding:20px 16px 0 16px;font-family:${SANS};font-size:12px;line-height:18px;color:#6B7280;">
              <p style="margin:0;"><strong style="color:#4B5563;">Rxvarta</strong> &mdash; AI-assisted prescriptions for Indian doctors</p>
              <p style="margin:4px 0 0 0;">You received this e-mail because an Rxvarta account was created with this address.</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}

/// Plain-text alternative, for clients that refuse HTML.
export function welcomeEmailText(name: string): string {
  const trimmed = name.trim();
  const greeting = trimmed === ""
    ? "Welcome to Rxvarta!"
    : `Welcome to Rxvarta, ${trimmed}!`;
  return [
    greeting,
    "",
    "Your account is ready. Rxvarta listens to a consultation and turns it",
    "into a structured prescription you review, sign and share.",
    "",
    "1. Record the consultation - talk as you normally would. Hindi, Marathi,",
    "   Bengali, Gujarati, Kannada, Tamil, Telugu and English all work.",
    "2. Review what was heard - medicines, diagnosis, investigations and advice",
    "   come back filled in, and every field is editable before you sign.",
    "3. Sign and share - your signature and clinic letterhead go on the PDF.",
    "",
    "One tip: add your clinic details and signature in Settings once, and every",
    "prescription you write afterwards carries them.",
    "",
    "Patient records stay on your phone. Nothing is shared with anyone else.",
    "",
    "Rxvarta - AI-assisted prescriptions for Indian doctors",
  ].join("\n");
}
