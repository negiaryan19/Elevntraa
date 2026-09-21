// The welcome e-mail interpolates two values from outside the file into HTML:
// the doctor's own name (user input) and the logo URL (from SUPABASE_URL).
// Both must be escaped, and the logo must come from the running project.
//
// Run: deno test supabase/functions/send-welcome-email/

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  brandLogoUrl,
  welcomeEmailHtml,
  welcomeEmailText,
} from "./welcome_email.ts";

const LOGO =
  "https://example.supabase.co/storage/v1/object/public/brand/rxvarta_logo.png";

Deno.test("the logo comes from the project running the function", () => {
  assertEquals(brandLogoUrl("https://example.supabase.co"), LOGO);
  // A trailing slash on SUPABASE_URL must not double up.
  assertEquals(brandLogoUrl("https://example.supabase.co/"), LOGO);
  assertEquals(brandLogoUrl("https://example.supabase.co//"), LOGO);
});

Deno.test("a name containing markup is escaped, not rendered", () => {
  const html = welcomeEmailHtml('Asha <img src=x onerror="alert(1)">', LOGO);
  assert(!html.includes("<img src=x"), "raw markup leaked into the e-mail");
  assertStringIncludes(
    html,
    "Asha &lt;img src=x onerror=&quot;alert(1)&quot;&gt;",
  );
});

Deno.test("an ampersand in a name is escaped exactly once", () => {
  // `&` must be replaced first, or the `&lt;` produced for `<` would itself
  // be turned into `&amp;lt;`.
  const html = welcomeEmailHtml("Rao & Rao <MD>", LOGO);
  assertStringIncludes(html, "Rao &amp; Rao &lt;MD&gt;");
  assert(!html.includes("&amp;lt;"), "double-escaped");
});

Deno.test("a quote in the logo URL cannot break out of src", () => {
  const html = welcomeEmailHtml("Asha", 'https://x.co/a.png" onload="x');
  assert(!html.includes('a.png" onload'), "attribute breakout");
  assertStringIncludes(html, 'src="https://x.co/a.png&quot; onload=&quot;x"');
});

Deno.test("a blank name falls back to a plain greeting", () => {
  assertStringIncludes(welcomeEmailHtml("   ", LOGO), "Welcome to Rxvarta!");
  assert(welcomeEmailText("").startsWith("Welcome to Rxvarta!"));
  assert(
    welcomeEmailText("Asha Verma").startsWith(
      "Welcome to Rxvarta, Asha Verma!",
    ),
  );
});

Deno.test("the HTML carries the logo it was given", () => {
  assertStringIncludes(welcomeEmailHtml("Asha", LOGO), `src="${LOGO}"`);
});
