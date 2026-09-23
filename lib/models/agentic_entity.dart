/// Verbindungsstatus einer Agentic-Control-Panel-Kachel.
///
/// MGD-DevOS zeigt niemals erfundene "aktiv"-Zustände. Solange kein echter
/// Codex- oder Claude-Code-Adapter lokal angebunden ist, bleibt der Status
/// [AgenticStatus.notConnected] oder [AgenticStatus.unknown].
enum AgenticStatus {
  /// Aus einer echten lokalen Quelle gelesen und aktuell als aktiv markiert.
  claimedActive,

  /// Aus einer echten lokalen Quelle gelesen, aber aktuell nicht aktiv.
  claimedInactive,

  /// In den Projektdateien deklariert, aber kein Live-Adapter verbunden.
  notConnected,

  /// Datenlage unklar oder Quelle nicht lesbar.
  unknown,
}

extension AgenticStatusLabel on AgenticStatus {
  String get labelDe {
    switch (this) {
      case AgenticStatus.claimedActive:
        return 'belegt aktiv';
      case AgenticStatus.claimedInactive:
        return 'belegt inaktiv';
      case AgenticStatus.notConnected:
        return 'nicht verbunden';
      case AgenticStatus.unknown:
        return 'unbekannt';
    }
  }
}

enum AgenticKind { agent, skill, mcp, integration }

/// Ein Knoten im Agentic-Control-Panel-Graphen.
///
/// [source] benennt die Datei oder das Verzeichnis, aus dem der Eintrag
/// stammt, [observedAt] den Zeitpunkt des letzten lokalen Scans. Beides ist
/// Pflicht, damit jede Aussage im Graphen nachvollziehbar bleibt.
class AgenticEntity {
  AgenticEntity({
    required this.id,
    required this.name,
    required this.kind,
    required this.status,
    required this.source,
    required this.observedAt,
    this.description,
    this.projectName,
  });

  final String id;
  final String name;
  final AgenticKind kind;
  final AgenticStatus status;
  final String source;
  final DateTime observedAt;
  final String? description;
  final String? projectName;
}
