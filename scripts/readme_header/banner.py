#!/usr/bin/env python3
"""Erzeugt ein Titelbild (SVG) und den README-Kopfbereich für ein Repository.

Reines Python ohne Abhängigkeiten. Jedes Repo bekommt anhand von Name und Kategorie eine eigene
Farbwelt und ein eigenes Muster (Fenster, Netzwerk, Pixel, Wellen, Raster), damit die Bilder
zusammengehören, aber unterscheidbar bleiben. Alles ist lokal gezeichnet: keine Bild-KI, keine Kosten.
"""
import hashlib, html, random, re

# Kategorie -> (Farbe 1, Farbe 2, Muster, Bezeichnung)
CATEGORIES = {
    "skill":    ("#5b3df5", "#2b7bff", "nodes",   "Skill für KI-Agenten"),
    "shop":     ("#ff6a3d", "#c2185b", "grid",    "Shop-Plugin"),
    "wordpress":("#2f6fed", "#0e9aa7", "waves",   "WordPress"),
    "game":     ("#8e2de2", "#e0338f", "pixels",  "Spiel"),
    "platform": ("#0f9d8a", "#1f5fbf", "windows", "Plattform"),
    "tool":     ("#1f6feb", "#6f42c1", "windows", "Werkzeug"),
    "docs":     ("#e8a317", "#d9480f", "grid",    "Dokumentation"),
    "web":      ("#0ea5e9", "#4338ca", "waves",   "Web"),
    "default":  ("#334e8f", "#1f2a5c", "windows", "Projekt"),
}

def categorize(name, desc="", lang=""):
    n = (name + " " + (desc or "")).lower()
    if "skill" in n: return "skill"
    if re.search(r"shopware|jtl|sw6", n): return "shop"
    if re.search(r"wordpress|divi|wp-plugin|\bwp\b", n): return "wordpress"
    if re.search(r"game|spiel|shape|arcanex|shadows|dungeon|tintling|allverund-map", n): return "game"
    if re.search(r"platform|plattform|immortuus|academy", n): return "platform"
    if re.search(r"designmanual|handbuch|bugreport|vault|documentation|dokumentation", n): return "docs"
    if re.search(r"website|shop\.de|\.de\b|css|theme", n): return "web"
    if re.search(r"tool|app|jarvis|clients|updater|editor", n): return "tool"
    return "default"

def pretty(name):
    n = re.sub(r"^(MGD[_-])", "", name)
    n = re.sub(r"[_-]?(SKILL|Skill|TOOL|GAME|WP-Plugin|SW6-Plugin)$", "", n)
    n = n.replace("_", " ").replace("-", " ").strip()
    return "MGD " + n if name.upper().startswith("MGD") else n

def esc(s): return html.escape(s or "", quote=True)

def motif(kind, rnd, w, h, c1):
    out = []
    if kind == "windows":
        for i in range(3):
            x, y, ww, hh = 60 + i*30, 40 - i*14 + 60, 220, 140
            out.append(f'<rect x="{x}" y="{y}" width="{ww}" height="{hh}" rx="12" fill="none" stroke="#fff" stroke-opacity=".{18+i*4}" stroke-width="2"/>')
    elif kind == "nodes":
        import math
        pts = [(int(200 + 130*math.cos(t/7*2*math.pi + rnd.random()*.4)), int(h/2 + 105*math.sin(t/7*2*math.pi + rnd.random()*.4))) for t in range(7)] + [(200, h//2)]
        for i, a in enumerate(pts):
            for b in (pts[(i+1) % 7], pts[7]):
                out.append(f'<line x1="{a[0]}" y1="{a[1]}" x2="{b[0]}" y2="{b[1]}" stroke="#fff" stroke-opacity=".22" stroke-width="2"/>')
        for x, y in pts:
            out.append(f'<circle cx="{x}" cy="{y}" r="{rnd.randint(6,12)}" fill="#fff" fill-opacity=".28"/>')
    elif kind == "pixels":
        for _ in range(26):
            s = rnd.choice([10, 14, 20, 28])
            out.append(f'<rect x="{rnd.randint(40,340)//10*10}" y="{rnd.randint(30,h-50)//10*10}" width="{s}" height="{s}" fill="#fff" fill-opacity=".{rnd.randint(10,32)}"/>')
    elif kind == "waves":
        for i in range(5):
            y = 90 + i*34
            out.append(f'<path d="M0 {y} C 90 {y-40}, 180 {y+40}, 270 {y} S 400 {y-30}, 420 {y}" fill="none" stroke="#fff" stroke-opacity=".{14+i*4}" stroke-width="2.4"/>')
    else:  # grid
        for gx in range(40, 400, 36):
            for gy in range(40, h-20, 36):
                out.append(f'<circle cx="{gx}" cy="{gy}" r="2.4" fill="#fff" fill-opacity=".34"/>')
        out.append('<rect x="70" y="70" width="150" height="90" rx="10" fill="none" stroke="#fff" stroke-opacity=".3" stroke-width="2"/>')
    return "\n  ".join(out)

def banner_svg(name, desc, lang=""):
    kind = categorize(name, desc, lang)
    c1, c2, mot, label = CATEGORIES[kind]
    seed = int(hashlib.sha256(name.encode()).hexdigest()[:8], 16)
    rnd = random.Random(seed)
    angle = rnd.choice([(0, 0, 1, 1), (0, 1, 1, 0), (0, 0, 1, .6)])
    title = pretty(name)
    size = 78 if len(title) <= 16 else 64 if len(title) <= 24 else 50 if len(title) <= 32 else 40
    sub = (desc or "").strip().split(". ")[0].strip()
    lines, cur = [], ""
    for word in sub.split():
        if len(cur) + len(word) + 1 > 52 and cur:
            lines.append(cur); cur = word
        else:
            cur = (cur + " " + word).strip()
    if cur: lines.append(cur)
    if len(lines) > 2:
        lines = lines[:2]; lines[1] = lines[1][:49].rstrip(" ,;:") + "…"
    sub_svg = "".join(f'<text x="422" y="{196 + i*30}" font-family="-apple-system,Segoe UI,Helvetica,Arial,sans-serif" font-size="23" fill="#fff" fill-opacity=".86">{esc(t)}</text>' for i, t in enumerate(lines))
    tag_y = 196 + max(len(lines), 1) * 30 + 10
    W, H = 1280, 320
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" role="img" aria-label="{esc(title)}">
  <defs>
    <linearGradient id="g" x1="{angle[0]}" y1="{angle[1]}" x2="{angle[2]}" y2="{angle[3]}"><stop offset="0" stop-color="{c1}"/><stop offset="1" stop-color="{c2}"/></linearGradient>
    <radialGradient id="glow" cx=".85" cy=".1" r=".9"><stop offset="0" stop-color="#fff" stop-opacity=".22"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></radialGradient>
    <clipPath id="c"><rect width="{W}" height="{H}" rx="24"/></clipPath>
  </defs>
  <g clip-path="url(#c)">
    <rect width="{W}" height="{H}" fill="url(#g)"/>
    <rect width="{W}" height="{H}" fill="url(#glow)"/>
  {motif(mot, rnd, W, H, c1)}
    <text x="420" y="140" font-family="-apple-system,Segoe UI,Helvetica,Arial,sans-serif" font-size="{size}" font-weight="700" fill="#fff" letter-spacing="-1">{esc(title)}</text>
    {sub_svg}
    <rect x="422" y="{tag_y}" width="{18+len(label)*10}" height="30" rx="15" fill="#fff" fill-opacity=".18"/>
    <text x="436" y="{tag_y+21}" font-family="-apple-system,Segoe UI,Helvetica,Arial,sans-serif" font-size="15" font-weight="600" fill="#fff">{esc(label)}</text>
  </g>
</svg>
'''

def header_md(repo, owner, private, license_key, lang, has_release, banner_path="assets/banner.svg", logo_path="assets/mgd-logo.png"):
    b = []
    if private:
        b.append('<img alt="Status" src="https://img.shields.io/badge/Status-privat-555">')
    else:
        b.append(f'<img alt="Lizenz" src="https://img.shields.io/github/license/{owner}/{repo}?label=Lizenz">')
        if has_release:
            b.append(f'<a href="https://github.com/{owner}/{repo}/releases/latest"><img alt="Release" src="https://img.shields.io/github/v/release/{owner}/{repo}?label=Release"></a>')
    if lang:
        b.append(f'<img alt="Sprache" src="https://img.shields.io/badge/Sprache-{lang.replace("-","--").replace(" ","%20")}-2f6fed">')
    b.append('<a href="https://Michael-Gahn.de"><img alt="by Michael Gahn DESIGN" src="https://img.shields.io/badge/by-Michael%20Gahn%20DESIGN-cd1616"></a>')
    return ("<!-- MGD-HEADER -->\n"
            f'<p align="center"><a href="https://Michael-Gahn.de"><img src="{logo_path}" alt="Michael Gahn DESIGN" width="48"></a></p>\n\n'
            f'<p align="center"><img src="{banner_path}" alt="{esc(pretty(repo))}" width="100%"></p>\n\n'
            f'<p align="center">\n  ' + "\n  ".join(b) + "\n</p>\n<!-- /MGD-HEADER -->\n\n")

if __name__ == "__main__":
    import sys
    for n, d in [("MGD_Todo_SKILL", "Universeller /todo-Skill für KI-Agenten: sortierbare, durchsuchbare TODO.html im eigenen Repo"),
                 ("MGD_Ausverkauft_Shopware-Plugin", "Ein Shopware 6.7.x Plugin, das Produkte mit Bestand 0 im Shop behält"),
                 ("MGD_Shape-Miner-Deluxe_GAME", "2D-Weltraum-Mining-Spiel (Flutter + Flame) mit PHP-Editor")]:
        open(f"/private/tmp/claude-501/sample-{n}.svg", "w").write(banner_svg(n, d))
    print("ok")
