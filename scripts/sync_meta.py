#!/usr/bin/env python3
"""Überträgt die zentrale Version (assets/meta/version.json) in alle Stellen.

- pubspec.yaml: version: X.Y.Z+build
- assets/meta/versions.json: Timeline aus CHANGELOG.md und skill/CHANGELOG.md
- skill/dashboard/index.html: eingebettete Metadaten (Version, Timeline, Credits)

Aufruf: python3 scripts/sync_meta.py         (schreibt)
        python3 scripts/sync_meta.py --check (bricht ab, wenn etwas veraltet ist; für CI)
"""
import json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
META = ROOT / "assets/meta"
START, END = "/*MGD-META-START*/", "/*MGD-META-END*/"


def parse_changelog(path, component, pattern):
    """Liest '## x.y.z ...'-Abschnitte und ihre Aufzählungspunkte."""
    entries, cur = [], None
    for line in path.read_text(encoding="utf-8").splitlines():
        m = re.match(pattern, line)
        if m:
            cur = {"version": m.group(1), "date": m.group(2) or "", "component": component, "notes": []}
            entries.append(cur)
        elif line.startswith("## "):
            cur = None
        elif cur is not None and line.startswith("- "):
            cur["notes"].append(line[2:].strip())
        elif cur is not None and line.startswith("  ") and cur["notes"]:
            cur["notes"][-1] += " " + line.strip()
    return entries


def build():
    version = json.loads((META / "version.json").read_text(encoding="utf-8"))
    credits = json.loads((META / "credits.json").read_text(encoding="utf-8"))
    app = parse_changelog(ROOT / "CHANGELOG.md", "App", r"^## (\d+\.\d+\.\d+)(?: [(\s]*([0-9-]{10}))?")
    for e in app:
        if tuple(map(int, e["version"].split("."))) >= (0, 5, 0):
            e["component"] = "MGD-DevOS"
    skill = parse_changelog(ROOT / "skill/CHANGELOG.md", "Projektmanager-Skill", r"^## (\d+\.\d+\.\d+)(?: - ([0-9-]{10}))?")
    # Neueste zuerst; bei gleichem Datum steht MGD-DevOS vor App und Skill.
    rank = {"MGD-DevOS": 2, "App": 1, "Projektmanager-Skill": 0}
    timeline = sorted(app + skill, key=lambda e: (e["date"] or "0000", rank.get(e["component"], 0), tuple(map(int, e["version"].split(".")))), reverse=True)
    return version, credits, timeline


def main():
    check = "--check" in sys.argv
    version, credits, timeline = build()
    outputs = {}

    pub = ROOT / "pubspec.yaml"
    s = pub.read_text(encoding="utf-8")
    outputs[pub] = re.sub(r"^version: .*$", f"version: {version['version']}+{version['build']}", s, count=1, flags=re.M)

    outputs[META / "versions.json"] = json.dumps(timeline, ensure_ascii=False, indent=2) + "\n"

    dash = ROOT / "skill/dashboard/index.html"
    d = dash.read_text(encoding="utf-8")
    payload = json.dumps({"version": version, "versions": timeline, "credits": credits}, ensure_ascii=False, separators=(",", ":"))
    # "</" escapen, damit Texte nie das <script>-Tag beenden können.
    payload = payload.replace("</", "<\\/")
    block = f"{START}window.MGD_META={payload};{END}"
    if START not in d:
        sys.exit("Marker für Metadaten fehlt in skill/dashboard/index.html")
    outputs[dash] = re.sub(re.escape(START) + ".*?" + re.escape(END), lambda _: block, d, count=1, flags=re.S)

    stale = [p for p, new in outputs.items() if not p.exists() or p.read_text(encoding="utf-8") != new]
    if check:
        if stale:
            sys.exit("Veraltet, bitte scripts/sync_meta.py ausführen: " + ", ".join(str(p.relative_to(ROOT)) for p in stale))
        print("Metadaten aktuell.")
        return
    for p in stale:
        p.write_text(outputs[p], encoding="utf-8")
    print(f"{version['version']} {version['stage']} (Build {version['build']}): {len(stale)} Datei(en) aktualisiert, {len(timeline)} Versionen.")


if __name__ == "__main__":
    main()
