#!/usr/bin/env python3
"""Hängt Lizenzhinweis + Impressum ans Ende der README aller öffentlichen Repos.

  python3 legal.py --dry-run | python3 legal.py
Idempotent über den Marker <!-- MGD-LEGAL -->; Repos ohne LICENSE-Datei werden übersprungen.
"""
import base64, json, re, subprocess, sys
OWNER = "MichaelGahnDESIGN"
DRY = "--dry-run" in sys.argv

# SPDX-Kennung -> (Anzeigename, Link zum Lizenztext)
LICENSES = {
    "MIT": ("MIT-Lizenz", "https://opensource.org/license/mit"),
    "GPL-2.0-or-later": ("GNU GPL v2 oder neuer", "https://www.gnu.org/licenses/old-licenses/gpl-2.0.html"),
    "GPL-3.0-or-later": ("GNU GPL v3 oder neuer", "https://www.gnu.org/licenses/gpl-3.0.html"),
    "GPL-2.0": ("GNU GPL v2", "https://www.gnu.org/licenses/old-licenses/gpl-2.0.html"),
    "GPL-3.0": ("GNU GPL v3", "https://www.gnu.org/licenses/gpl-3.0.html"),
    "PolyForm-Noncommercial-1.0.0": ("PolyForm Noncommercial 1.0.0", "https://polyformproject.org/licenses/noncommercial/1.0.0"),
}

IMPRESSUM = """## Impressum

**Angaben gemäß § 5 DDG (Digitale-Dienste-Gesetz)**

Michael Gahn DESIGN  
Michael Gahn  
Dr.-Theodor-Brugsch Str. 12  
08529 Plauen  
Sachsen  
Deutschland

Tel.: +49 (0) 151 59156639  
E-Mail: Anfrage@Michael-Gahn.de

Umsatzsteuer-Identifikationsnummer gemäß § 27 a Umsatzsteuergesetz:  
Steuernummer: 223/222/02451  
Ust-ID: DE288143343

Wir sind zur Teilnahme an einem Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle weder verpflichtet noch bereit.

**Redaktionell verantwortlich:**

Michael Gahn DESIGN  
Michael Gahn  
Dr.-Theodor-Brugsch Str. 12  
08529 Plauen  
Sachsen  
Deutschland

Tel.: +49 (0) 151 59156639  
E-Mail: Anfrage@Michael-Gahn.de
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
        if "<!-- MGD-LEGAL -->" in text: print(f"SKIP {r}: schon vorhanden"); continue
        block = (f"\n\n<!-- MGD-LEGAL -->\n---\n\n## Lizenz\n\nDieses Projekt steht unter der [{name}]({url}). "
                 f"Den vollständigen Text enthält die Datei [LICENSE](LICENSE).\n\n{IMPRESSUM}<!-- /MGD-LEGAL -->\n")
        print(f"{'DRY  ' if DRY else 'WRITE'} {r}: {name}")
        if DRY: continue
        body = {"message": "docs: Lizenzhinweis und Impressum am README-Ende",
                "content": base64.b64encode((text.rstrip() + block).encode()).decode(), "sha": rd["sha"]}
        rc, _, err = gh("api", "-X", "PUT", f"repos/{OWNER}/{r}/contents/{rd['path']}", "--input", "-", inp=json.dumps(body))
        if rc: print(f"  FEHLER {r}: {err.strip()[:140]}")

if __name__ == "__main__":
    main()
