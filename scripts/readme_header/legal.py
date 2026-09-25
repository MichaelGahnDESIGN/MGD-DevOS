#!/usr/bin/env python3
"""Hängt Lizenzhinweis + Impressum-Link ans Ende der README aller öffentlichen Repos des Inhabers.

Nur für die eigenen Repositories von OWNER gedacht (schreibt per gh-API direkt auf den Standard-Branch).
Es wird kein Impressumstext mit persönlichen Daten eingefügt, nur ein Link auf IMPRESSUM_URL.

  python3 legal.py --dry-run | python3 legal.py | python3 legal.py --update [--dry-run]
Idempotent über den Marker <!-- MGD-LEGAL -->; mit --update werden vorhandene Blöcke ersetzt,
z. B. um früher eingefügte Impressumstexte durch den Link zu ersetzen.
Repos ohne LICENSE-Datei werden übersprungen.
"""
import base64, json, re, subprocess, sys
OWNER = "MichaelGahnDESIGN"
DRY = "--dry-run" in sys.argv
UPDATE = "--update" in sys.argv   # vorhandene MGD-LEGAL-Blöcke ersetzen (z. B. alter Impressumstext)
LEGAL_BLOCK = re.compile(r"<!-- MGD-LEGAL -->.*?<!-- /MGD-LEGAL -->", re.S)

# SPDX-Kennung -> (Anzeigename, Link zum Lizenztext)
LICENSES = {
    "MIT": ("MIT-Lizenz", "https://opensource.org/license/mit"),
    "GPL-2.0-or-later": ("GNU GPL v2 oder neuer", "https://www.gnu.org/licenses/old-licenses/gpl-2.0.html"),
    "GPL-3.0-or-later": ("GNU GPL v3 oder neuer", "https://www.gnu.org/licenses/gpl-3.0.html"),
    "GPL-2.0": ("GNU GPL v2", "https://www.gnu.org/licenses/old-licenses/gpl-2.0.html"),
    "GPL-3.0": ("GNU GPL v3", "https://www.gnu.org/licenses/gpl-3.0.html"),
    "PolyForm-Noncommercial-1.0.0": ("PolyForm Noncommercial 1.0.0", "https://polyformproject.org/licenses/noncommercial/1.0.0"),
    "LicenseRef-MGD": ("MGD-Lizenz 1.0", "LICENSE"),
}

# Kein Abdruck persönlicher Daten (Adresse, Telefon, Steuernummer) in READMEs: nur ein Link auf das
# gepflegte Impressum. So bleibt es an einer Stelle aktuell und wird nicht in Forks und Kopien vervielfältigt.
IMPRESSUM_URL = "https://michael-gahn.de/impressum"
IMPRESSUM = f"""## Impressum

Angaben gemäß § 5 DDG: [michael-gahn.de/impressum]({IMPRESSUM_URL})
"""

def gh(*a, inp=None):
    r = subprocess.run(["gh", *a], input=inp, capture_output=True, text=True)
    return r.returncode, r.stdout, r.stderr

def spdx(text):
    """Lizenzart aus der LICENSE-Datei ableiten (SPDX-Zeile, sonst Titel)."""
    m = re.search(r"SPDX-License-Identifier:\s*(\S+)", text)
    if m: return m.group(1)
    head = text[:300]
    if "PolyForm Noncommercial" in head: return "PolyForm-Noncommercial-1.0.0"
    if "MGD-Lizenz" in head: return "LicenseRef-MGD"
    if head.lstrip().startswith("MIT License"): return "MIT"
    if "GNU GENERAL PUBLIC LICENSE" in head and "Version 2" in head: return "GPL-2.0"
    if "GNU GENERAL PUBLIC LICENSE" in head and "Version 3" in head: return "GPL-3.0"
    return None

def main():
    _, out, _ = gh("repo", "list", OWNER, "--visibility", "public", "--no-archived", "--source", "--limit", "200", "--json", "name")
    for r in sorted(x["name"] for x in json.loads(out)):
        rc, lic, _ = gh("api", f"repos/{OWNER}/{r}/contents/LICENSE", "-H", "Accept: application/vnd.github.raw")
        if rc: print(f"SKIP {r}: keine LICENSE-Datei"); continue
        key = spdx(lic)
        if key not in LICENSES: print(f"SKIP {r}: Lizenz unbekannt ({key})"); continue
        name, url = LICENSES[key]
        _, o, _ = gh("api", f"repos/{OWNER}/{r}/readme")
        rd = json.loads(o)
        text = base64.b64decode(rd["content"]).decode()
        block = (f"<!-- MGD-LEGAL -->\n---\n\n## Lizenz\n\nDieses Projekt steht unter der [{name}]({url}). "
                 f"Den vollständigen Text enthält die Datei [LICENSE](LICENSE).\n\n{IMPRESSUM}<!-- /MGD-LEGAL -->")
        if LEGAL_BLOCK.search(text):
            if not UPDATE: print(f"SKIP {r}: schon vorhanden (mit --update ersetzen)"); continue
            new_text = LEGAL_BLOCK.sub(lambda _: block, text)
            if new_text == text: print(f"SKIP {r}: aktuell"); continue
        else:
            new_text = text.rstrip() + "\n\n" + block + "\n"
        print(f"{'DRY  ' if DRY else 'WRITE'} {r}: {name}")
        if DRY: continue
        body = {"message": "docs: Lizenzhinweis und Impressum-Link am README-Ende",
                "content": base64.b64encode(new_text.encode()).decode(), "sha": rd["sha"]}
        rc, _, err = gh("api", "-X", "PUT", f"repos/{OWNER}/{r}/contents/{rd['path']}", "--input", "-", inp=json.dumps(body))
        if rc: print(f"  FEHLER {r}: {err.strip()[:140]}")

if __name__ == "__main__":
    main()
