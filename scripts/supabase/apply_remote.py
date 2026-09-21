#!/usr/bin/env python3
"""Apply a migration file and/or auth settings to the linked Supabase project
through the Management API (no database password needed).

Why this exists: dev machines do not hold the Postgres password, so
`supabase db push` cannot run here. The Management API accepts the personal
access token the Supabase CLI already stored in the macOS keychain (service
"Supabase CLI") or SUPABASE_ACCESS_TOKEN in the environment.

Usage:
  python3 scripts/supabase/apply_remote.py migrate supabase/migrations/20260916000000_doctors_and_buckets.sql
  python3 scripts/supabase/apply_remote.py auth-hardening
  python3 scripts/supabase/apply_remote.py auth-emails
  python3 scripts/supabase/apply_remote.py brand-assets
  python3 scripts/supabase/apply_remote.py verify

`migrate` runs the whole file as one query, then records the version in
supabase_migrations.schema_migrations so a later `supabase db push` (by someone
who has the password) does not try to re-apply it.
`auth-hardening` sets: anonymous sign-ins OFF, SMTP sender name "Rxvarta",
minimum password length 8.
`auth-emails` pushes the branded subjects and supabase/templates/*.html.
`brand-assets` uploads assets/brand/* to the public `brand` bucket those
templates load the logo from (Storage API + service_role key).
`verify` prints the doctors table, its policies, the buckets and the auth
values so you can confirm the state.
"""
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def project_ref() -> str:
    p = os.path.join(ROOT, "supabase", ".temp", "project-ref")
    if os.path.exists(p):
        return open(p).read().strip()
    raise SystemExit("Not linked: run `supabase link --project-ref <ref>` first")


def token() -> str:
    t = os.environ.get("SUPABASE_ACCESS_TOKEN", "").strip()
    if t:
        return t
    r = subprocess.run(
        ["security", "find-generic-password", "-s", "Supabase CLI", "-w"],
        capture_output=True,
        text=True,
    )
    if r.stdout.strip():
        return r.stdout.strip()
    p = os.path.expanduser("~/.supabase/access-token")
    if os.path.exists(p):
        return open(p).read().strip()
    raise SystemExit("No Supabase access token: run `supabase login` or set SUPABASE_ACCESS_TOKEN")


def call(method: str, path: str, body=None):
    url = "https://api.supabase.com/v1/projects/" + project_ref() + path
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(
        url,
        data=data,
        headers={"Authorization": "Bearer " + token(), "Content-Type": "application/json"},
        method=method,
    )
    try:
        with urllib.request.urlopen(req, timeout=180) as r:
            raw = r.read().decode()
    except urllib.error.HTTPError as e:
        raise SystemExit(f"HTTP {e.code}: {e.read().decode()[:2000]}")
    try:
        return json.loads(raw)
    except Exception:
        return raw


def sql(query: str):
    return call("POST", "/database/query", {"query": query})


def migrate(path: str):
    text = open(path).read()
    name = os.path.basename(path)
    m = re.match(r"(\d+)_(.+)\.sql$", name)
    if not m:
        raise SystemExit("migration file must be named <version>_<name>.sql")
    version, mig_name = m.group(1), m.group(2)
    print("applying", name, "...")
    sql(text)
    print("recording version", version)
    sql(
        "insert into supabase_migrations.schema_migrations (version, name) "
        f"values ('{version}', '{mig_name}') on conflict (version) do nothing"
    )
    print("done")


def auth_hardening():
    body = {
        "external_anonymous_users_enabled": False,
        "smtp_sender_name": "Rxvarta",
        "password_min_length": 8,
    }
    res = call("PATCH", "/config/auth", body)
    for k in body:
        print(k, "=", res.get(k) if isinstance(res, dict) else "?")


# config.toml maps each GoTrue template to a file; the hosted project does not
# read config.toml, so the same pairs are pushed through the Management API.
# Keys are the GoTrue config names: mailer_subjects_<x> / mailer_templates_<x>_content.
AUTH_EMAILS = (
    ("confirmation", "{{ .Token }} is your Rxvarta verification code"),
    ("recovery", "{{ .Token }} is your Rxvarta password reset code"),
    ("magic_link", "{{ .Token }} is your Rxvarta sign-in code"),
    ("email_change", "{{ .Token }} is your code to change your Rxvarta e-mail"),
    ("reauthentication", "{{ .Token }} is your Rxvarta confirmation code"),
    ("invite", "{{ .Token }} is your Rxvarta invitation code"),
)


def auth_emails():
    """Push the branded subjects and HTML in supabase/templates/ to the project."""
    body = {}
    for slug, subject in AUTH_EMAILS:
        path = os.path.join(ROOT, "supabase", "templates", slug + ".html")
        if not os.path.exists(path):
            raise SystemExit("missing template: " + path)
        with open(path, encoding="utf-8") as f:
            body["mailer_templates_" + slug + "_content"] = f.read()
        body["mailer_subjects_" + slug] = subject

    res = call("PATCH", "/config/auth", body)
    for slug, _ in AUTH_EMAILS:
        key = "mailer_subjects_" + slug
        print(key, "=", res.get(key) if isinstance(res, dict) else "?")
    # password_changed_notification.html is not pushed: GoTrue exposes that
    # notification through config.toml only, so set it in the dashboard.
    print("note: password_changed_notification.html must be set in the dashboard")


def service_role_key() -> str:
    keys = call("GET", "/api-keys")
    if isinstance(keys, list):
        for k in keys:
            if isinstance(k, dict) and k.get("name") == "service_role":
                return k.get("api_key", "")
    raise SystemExit("could not read the service_role key from the Management API")


def brand_assets():
    """Upload assets/brand/* to the public `brand` bucket the e-mails load from.

    The Management API has no object endpoint, so this goes to the project's
    Storage API with the service_role key (the bucket has no write policy by
    design; only the service role writes here).
    """
    src_dir = os.path.join(ROOT, "assets", "brand")
    if not os.path.isdir(src_dir):
        raise SystemExit("no assets/brand directory")
    names = sorted(n for n in os.listdir(src_dir) if n.endswith((".png", ".svg")))
    if not names:
        raise SystemExit("no .png / .svg files in assets/brand")

    key = service_role_key()
    base = "https://" + project_ref() + ".supabase.co/storage/v1/object/brand/"
    for name in names:
        with open(os.path.join(src_dir, name), "rb") as f:
            data = f.read()
        ctype = "image/svg+xml" if name.endswith(".svg") else "image/png"
        req = urllib.request.Request(
            base + name,
            data=data,
            headers={
                "Authorization": "Bearer " + key,
                "Content-Type": ctype,
                # Replace the object if it is already there.
                "x-upsert": "true",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=180) as r:
                r.read()
        except urllib.error.HTTPError as e:
            raise SystemExit(f"upload {name}: HTTP {e.code}: {e.read().decode()[:2000]}")
        print("uploaded", name, "(" + str(len(data)) + " bytes)")
    print("public URL prefix:", base.replace("/object/brand/", "/object/public/brand/"))


def verify():
    print("== doctors columns ==")
    print(json.dumps(sql(
        "select column_name, data_type, is_nullable from information_schema.columns "
        "where table_schema='public' and table_name='doctors' order by ordinal_position"
    ), indent=1))
    print("== policies ==")
    print(json.dumps(sql(
        "select schemaname, tablename, policyname, cmd from pg_policies "
        "where tablename in ('doctors','objects') order by 1,2,3"
    ), indent=1))
    print("== buckets ==")
    print(json.dumps(sql(
        "select id, public, file_size_limit, allowed_mime_types from storage.buckets order by 1"
    ), indent=1))
    print("== auth ==")
    cfg = call("GET", "/config/auth")
    for k in ("external_anonymous_users_enabled", "smtp_sender_name", "password_min_length", "mailer_autoconfirm", "mailer_otp_length"):
        print(k, "=", cfg.get(k))


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return
    cmd = sys.argv[1]
    if cmd == "migrate":
        migrate(sys.argv[2])
    elif cmd == "auth-hardening":
        auth_hardening()
    elif cmd == "auth-emails":
        auth_emails()
    elif cmd == "brand-assets":
        brand_assets()
    elif cmd == "verify":
        verify()
    else:
        raise SystemExit("unknown command: " + cmd)


if __name__ == "__main__":
    main()
