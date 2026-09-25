/// Stand eines mit dem MGD-Plattform-Builder erzeugten Projekts
/// (`MGD_PLATFORM.yml` im Projektordner, Version aus `version.json`).
///
/// Werte stammen ausschließlich aus den Dateien des Projekts. Fehlt
/// `version.json` oder ist sie ungültig, bleiben [version] und [status] null.
class PlatformInfo {
  const PlatformInfo({this.version, this.status});

  /// Dateiname, an dem der Scanner ein Plattform-Projekt erkennt.
  static const profileFile = 'MGD_PLATFORM.yml';

  /// Einzige Versionsquelle eines Plattform-Projekts.
  static const versionFile = 'version.json';

  static final _semver = RegExp(r'^\d+\.\d+\.\d+$');
  static final _status = RegExp(r'^[a-z]+(-[a-z]+)*$');

  /// Version im Format MAJOR.MINOR.PATCH, z. B. `0.0.1`.
  final String? version;

  /// Status laut `version.json`, z. B. `pre-alpha`.
  final String? status;

  /// Liest die Felder `version` und `status` aus dem geparsten `version.json`.
  /// Unerwartete Werte werden verworfen statt angezeigt.
  factory PlatformInfo.fromVersionJson(Object? json) {
    if (json is! Map) return const PlatformInfo();
    final v = json['version'];
    final s = json['status'];
    return PlatformInfo(
      version: v is String && _semver.hasMatch(v) ? v : null,
      status: s is String && _status.hasMatch(s) ? s : null,
    );
  }

  /// Status für die Anzeige: `pre-alpha` → `Pre-Alpha`, `lts` → `LTS`.
  String? get statusLabel {
    final s = status;
    if (s == null) return null;
    if (s == 'lts') return 'LTS';
    return s.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join('-');
  }

  /// Zum Beispiel `0.0.1 Pre-Alpha`; null, wenn keine Version bekannt ist.
  String? get label {
    final v = version;
    if (v == null) return null;
    final s = statusLabel;
    return s == null ? v : '$v $s';
  }
}
