#!/usr/bin/env bash
# Baut MGD-DevOS.app im Release-Modus und verpackt sie als MGD-DevOS.dmg.
#
# Voraussetzung: vollständiges Xcode (nicht nur die Command Line Tools),
# installiert über den App Store mit der eigenen Apple-ID. Prüfen mit:
#   xcodebuild -version
# Falls das fehlschlägt, zuerst:
#   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
#   sudo xcodebuild -runFirstLaunch
#
# Aufruf:
#   scripts/package_macos.sh
#
# Ergebnis:
#   dist/macos/MGD-DevOS.app
#   dist/macos/MGD-DevOS.dmg

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Fehler: 'flutter' ist nicht im PATH. Siehe README.md für die Einrichtung." >&2
  exit 1
fi

if ! xcodebuild -version >/dev/null 2>&1; then
  echo "Fehler: vollständiges Xcode fehlt (nur Command Line Tools reichen nicht)." >&2
  echo "Installiere Xcode über den App Store und führe danach aus:" >&2
  echo "  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer" >&2
  echo "  sudo xcodebuild -runFirstLaunch" >&2
  exit 1
fi

echo "==> flutter pub get"
flutter pub get

echo "==> flutter analyze"
flutter analyze

echo "==> flutter test"
flutter test

echo "==> flutter build macos --release"
flutter build macos --release

APP_SRC="build/macos/Build/Products/Release/MGD-DevOS.app"
if [ ! -d "$APP_SRC" ]; then
  echo "Fehler: $APP_SRC wurde nicht gefunden. Build-Ausgabe prüfen." >&2
  exit 1
fi

DIST_DIR="dist/macos"
DMG_PATH="$DIST_DIR/MGD-DevOS.dmg"
STAGING_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGING_DIR"' EXIT

mkdir -p "$DIST_DIR"
rm -f "$DMG_PATH"

echo "==> Staging-Ordner für das DMG vorbereiten"
cp -R "$APP_SRC" "$STAGING_DIR/MGD-DevOS.app"
ln -s /Applications "$STAGING_DIR/Applications"
cp "$REPO_ROOT/dist/DMG-README.md" "$STAGING_DIR/Liesmich.md" 2>/dev/null || true
cp "$REPO_ROOT/LICENSE" "$STAGING_DIR/LICENSE.txt"
cp "$REPO_ROOT/NOTICE" "$STAGING_DIR/NOTICE.txt"

echo "==> hdiutil: DMG erstellen"
hdiutil create -volname "MGD-DevOS" \
  -srcfolder "$STAGING_DIR" \
  -ov -format UDZO \
  "$DMG_PATH"

echo ""
echo "Fertig:"
echo "  App: $REPO_ROOT/$APP_SRC"
echo "  DMG: $REPO_ROOT/$DMG_PATH"
echo ""
echo "Das DMG ist NICHT signiert oder notarisiert (siehe README.md, Abschnitt"
echo "Sicherheit/Release). macOS zeigt beim ersten Start eine Gatekeeper-Warnung;"
echo "das ist erwartet, solange keine Apple Developer ID hinterlegt ist."
