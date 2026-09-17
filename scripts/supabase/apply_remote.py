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
  python3 scripts/supabase/apply_remote.py verify

`migrate` runs the whole file as one query, then records the version in
supabase_migrations.schema_migrations so a later `supabase db push` (by someone
who has the password) does not try to re-apply it.
`auth-hardening` sets: anonymous sign-ins OFF, SMTP sender name "Rxvarta",
minimum password length 8.
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
    elif cmd == "verify":
        verify()
    else:
        raise SystemExit("unknown command: " + cmd)


if __name__ == "__main__":
    main()
