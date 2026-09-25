#!/usr/bin/env python3
"""Überträgt die zentrale Version (assets/meta/version.json) in alle Stellen.

App und Projektmanager-Skill tragen eine gemeinsame Version. Einzige Quelle ist
assets/meta/version.json; dieses Skript schreibt sie weiter:

- pubspec.yaml: version: X.Y.Z+build
- assets/meta/versions.json: Timeline aus CHANGELOG.md und skill/CHANGELOG.md
- skill/dashboard/index.html und integration_test/fixtures/control_plane_dashboard.html: eingebettete Metadaten (Version, Timeline, Credits)
- README.md, skill/README.md, skill/SKILL.md: Text zwischen den Markern
  <!-- mgd:version -->…<!-- /mgd:version --> (z. B. „0.5.2 Pre-Alpha")
- README.md: Anzahl der Tests zwischen <!-- mgd:tests -->…<!-- /mgd:tests -->
  (gezählt: test(…) und testWidgets(…) in test/ und integration_test/)
- skill/LICENSE, skill/NOTICE: Kopien von LICENSE und NOTICE, damit das Skill-ZIP
  (git archive HEAD:skill) sie enthält

Zusätzlich muss CHANGELOG.md einen Abschnitt „## X.Y.Z" für die aktuelle Version haben.

Aufruf: python3 scripts/sync_meta.py         (schreibt)
        python3 scripts/sync_meta.py --check (bricht ab, wenn etwas veraltet ist; für CI)
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
META = ROOT / "assets/meta"
START, END = "/*MGD-META-START*/", "/*MGD-META-END*/"
VERSION_DOCS = ["README.md", "skill/README.md", "skill/SKILL.md"]
TEST_DOCS = ["README.md"]
COPIES = {"skill/LICENSE": "LICENSE", "skill/NOTICE": "NOTICE"}
TEST_CALL = re.compile(r"^\s*(?:test|testWidgets)\(", re.M)


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
    skill = parse_changelog(ROOT / "skill/CHANGELOG.md", "Projektmanager-Skill", r"^## (\d+\.\d+\.\d+)(?: - | \()?([0-9-]{10})?")
    # Neueste zuerst; bei gleichem Datum steht MGD-DevOS vor App und Skill.
    rank = {"MGD-DevOS": 2, "App": 1, "Projektmanager-Skill": 0}
    timeline = sorted(app + skill, key=lambda e: (e["date"] or "0000", rank.get(e["component"], 0), tuple(map(int, e["version"].split(".")))), reverse=True)
    return version, credits, timeline, app


def count_tests():
    files = [f for d in ("test", "integration_test") for f in sorted((ROOT / d).rglob("*_test.dart"))]
    return sum(len(TEST_CALL.findall(f.read_text(encoding="utf-8"))) for f in files)


def replace_marker(text, name, value, path):
    """Ersetzt den Inhalt zwischen <!-- mgd:name --> und <!-- /mgd:name -->."""
    pattern = re.compile(rf"(<!-- mgd:{name} -->).*?(<!-- /mgd:{name} -->)", re.S)
    if not pattern.search(text):
        sys.exit(f"Marker <!-- mgd:{name} --> fehlt in {path}")
    return pattern.sub(lambda m: m.group(1) + value + m.group(2), text)


def main():
    check = "--check" in sys.argv
    version, credits, timeline, app = build()
    label = f"{version['version']} {version['stage']}".strip()
    outputs = {}

    pub = ROOT / "pubspec.yaml"
    s = pub.read_text(encoding="utf-8")
    outputs[pub] = re.sub(r"^version: .*$", f"version: {version['version']}+{version['build']}", s, count=1, flags=re.M)

    outputs[META / "versions.json"] = json.dumps(timeline, ensure_ascii=False, indent=2) + "\n"

    payload = json.dumps({"version": version, "versions": timeline, "credits": credits}, ensure_ascii=False, separators=(",", ":"))
    # Jedes "<" als < schreiben: Texte können so weder das <script> beenden noch den Parser umschalten.
    payload = payload.replace("<", "\\u003c")
    block = f"{START}window.MGD_META={payload};{END}"
    # Dashboard-Vorlage und die Test-Fixture des Integrationstests tragen dieselben eingebetteten Metadaten.
    for rel in ("skill/dashboard/index.html", "integration_test/fixtures/control_plane_dashboard.html"):
        dash = ROOT / rel
        d = dash.read_text(encoding="utf-8")
        if START not in d:
            sys.exit(f"Marker für Metadaten fehlt in {rel}")
        outputs[dash] = re.sub(re.escape(START) + ".*?" + re.escape(END), lambda _: block, d, count=1, flags=re.S)

    tests = count_tests()
    for rel in sorted(set(VERSION_DOCS) | set(TEST_DOCS)):
        path = ROOT / rel
        text = outputs.get(path, path.read_text(encoding="utf-8"))
        if rel in VERSION_DOCS:
            text = replace_marker(text, "version", label, rel)
        if rel in TEST_DOCS:
            text = replace_marker(text, "tests", f"{tests} Tests", rel)
        outputs[path] = text

    for target, source in COPIES.items():
        outputs[ROOT / target] = (ROOT / source).read_text(encoding="utf-8")

    if not any(e["version"] == version["version"] for e in app):
        sys.exit(f"CHANGELOG.md hat keinen Abschnitt „## {version['version']}\" für die aktuelle Version.")

    stale = [p for p, new in outputs.items() if not p.exists() or p.read_text(encoding="utf-8") != new]
    if check:
        if stale:
            sys.exit("Veraltet, bitte scripts/sync_meta.py ausführen: " + ", ".join(str(p.relative_to(ROOT)) for p in stale))
        print(f"Metadaten aktuell ({label}, {tests} Tests).")
        return
    for p in stale:
        p.write_text(outputs[p], encoding="utf-8")
    print(f"{label} (Build {version['build']}): {len(stale)} Datei(en) aktualisiert, {len(timeline)} Versionen, {tests} Tests.")


if __name__ == "__main__":
    main()
