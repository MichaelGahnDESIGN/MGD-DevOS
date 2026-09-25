#!/usr/bin/env python3
"""Fügt allen aktiven Repos den README-Kopfbereich hinzu (Logo, Titelbild, Badges).

  python3 apply.py --dry-run     zeigt nur, was passieren würde
  python3 apply.py               schreibt (je Repo 3 Commits auf den Standard-Branch)

Idempotent: Repos, deren README schon den Marker <!-- MGD-HEADER --> enthält, werden übersprungen.
Benötigt die GitHub-CLI (gh) mit Schreibrecht.
"""
import base64, json, subprocess, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from banner import banner_svg, header_md

OWNER = "MichaelGahnDESIGN"
SKIP = {"MGD-DevOS"}                       # hat den Kopf schon von Hand
LOGO = Path(__file__).resolve().parents[2] / "assets/brand/logo-64.png"
DRY = "--dry-run" in sys.argv

def gh(*args, inp=None):
    r = subprocess.run(["gh", *args], input=inp, capture_output=True, text=True)
    return r.returncode, r.stdout, r.stderr

def api_get(path):
    rc, out, err = gh("api", path)
    return json.loads(out) if rc == 0 else None

def put(repo, path, content_b64, message, sha=None, branch=None):
    body = {"message": message, "content": content_b64}
    if sha: body["sha"] = sha
    if branch: body["branch"] = branch
    rc, out, err = gh("api", "-X", "PUT", f"repos/{OWNER}/{repo}/contents/{path}", "--input", "-", inp=json.dumps(body))
    return rc == 0, err.strip()[:160]

def main():
    rc, out, _ = gh("repo", "list", OWNER, "--limit", "200", "--json", "name,isPrivate,isArchived,isFork,description,primaryLanguage,defaultBranchRef,licenseInfo")
    repos = [r for r in json.loads(out) if not r["isArchived"] and not r["isFork"] and r["name"] not in SKIP]
    logo_b64 = base64.b64encode(LOGO.read_bytes()).decode()
    stats = {"ok": 0, "skip": 0, "fail": 0}
    for r in sorted(repos, key=lambda x: x["name"]):
        name, branch = r["name"], (r["defaultBranchRef"] or {}).get("name")
        if not branch:
            print(f"SKIP  {name}: leeres Repo"); stats["skip"] += 1; continue
        readme = api_get(f"repos/{OWNER}/{name}/readme?ref={branch}")
        text = base64.b64decode(readme["content"]).decode("utf-8", "replace") if readme else ""
        if "<!-- MGD-HEADER -->" in text:
            print(f"SKIP  {name}: Kopf vorhanden"); stats["skip"] += 1; continue
        rel = api_get(f"repos/{OWNER}/{name}/releases/latest")
        header = header_md(name, OWNER, r["isPrivate"], (r["licenseInfo"] or {}).get("key"), (r["primaryLanguage"] or {}).get("name", ""), bool(rel and rel.get("tag_name")))
        readme_path = readme["path"] if readme else "README.md"
        new_text = header + (text if text else f"# {name}\n\n{r['description'] or ''}\n")
        print(f"{'DRY ' if DRY else 'WRITE'} {name} ({'privat' if r['isPrivate'] else 'öffentlich'}, {branch}, README: {readme_path if readme else 'neu'})")
        if DRY: stats["ok"] += 1; continue
        ok = True
        for path, data, msg in [
            ("assets/banner.svg", base64.b64encode(banner_svg(name, r["description"] or "", (r["primaryLanguage"] or {}).get("name", "")).encode()).decode(), "docs: Titelbild für die README"),
            ("assets/mgd-logo.png", logo_b64, "docs: Logo für die README"),
            (readme_path, base64.b64encode(new_text.encode()).decode(), "docs: README-Kopfbereich mit Logo, Titelbild und Badges"),
        ]:
            existing = api_get(f"repos/{OWNER}/{name}/contents/{path}?ref={branch}")
            good, err = put(name, path, data, msg, sha=existing["sha"] if existing and "sha" in existing else None, branch=branch)
            if not good:
                print(f"  FEHLER {path}: {err}"); ok = False; break
        stats["ok" if ok else "fail"] += 1
    print(stats)

if __name__ == "__main__":
    main()
