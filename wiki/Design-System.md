# Design-System

Ruhiges, flaches Developer-Tool-Design (Richtung über den Skill ui-ux-pro-max abgeleitet: Stil „Flat",
Schrift Inter, dezente Bewegung). Tokens liegen in `lib/theme/app_theme.dart`.

| Token | Hell | Dunkel |
|---|---|---|
| Canvas | `#F6F7F9` | `#0F141C` |
| Karte | `#FFFFFF` | `#19212D` |
| Rahmen | `#E3E6EB` | `#2A3444` |
| Text gedämpft | `#526071` | `#9AA6B8` |
| Akzent (Fläche) | MGD-Rot `#CD1616` | `#CD1616` |
| Akzent (Text) | `#CD1616` | aufgehellt (42 % Weiß) für ≥ 4,5:1 |

- **Abstände:** 4 / 8 / 12 / 16 / 24 / 32. **Radien:** 8 / 12 / 16.
- **Bewegung:** 150 ms (Hover), 200 ms (Wechsel); bei „Bewegung reduzieren" 0 ms.
- **Icons:** Material Outline, 16–20 px, keine Emojis.
- **Schrift:** Inter Variable, lokal eingebettet (keine Netzwerkanfrage).
- **Regeln:** Farben nur über Tokens/Theme, Rot sparsam (Auswahl, Hauptaktion, Marke), Pflicht-Footer nie entfernen.
