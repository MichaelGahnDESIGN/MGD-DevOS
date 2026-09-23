# Installation

## Voraussetzungen

- Flutter Stable (getestet mit 3.47.5, Dart 3.13.4), Installation nach der Anleitung auf flutter.dev.
- macOS: **volles Xcode** (nicht nur die Command Line Tools) und CocoaPods.
- Windows: Visual Studio mit „Desktop development with C++".
- Linux: `clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev`.

## Aus dem Quellcode

```bash
git clone https://github.com/MichaelGahnDESIGN/MGD-DevOS.git
cd MGD-DevOS
flutter pub get
flutter run -d macos      # oder windows / linux
```

Standard-Entwicklungspfad auf dem Entwicklungsrechner: `~/Developer/MGD-DevOS`.

## Fertige Pakete

Es gibt derzeit **keine geprüften Installer**. Die Pipeline ([Release-Prozess](Release-Prozess.md))
erzeugt DMG (macOS), ZIP (Windows) und TAR.GZ (Linux). Sie sind unsigniert: macOS zeigt beim
ersten Start eine Gatekeeper-Warnung (Rechtsklick, Öffnen), Windows ggf. SmartScreen.

## Deinstallation

App löschen. Lokal liegen nur Theme, Akzentfarbe und Projektordner-Pfad in den
Programmeinstellungen des Betriebssystems.
