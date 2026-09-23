import 'dart:io';

/// Ein lokal gefundenes Projekt unterhalb des konfigurierten Projekt-Root.
///
/// Alle Felder stammen aus echten Dateisystem-Beobachtungen. Es werden keine
/// erfundenen Werte gesetzt: fehlt eine Information, bleibt das Feld null
/// oder eine leere Liste, statt einen Platzhalter vorzutäuschen.
class MgdProject {
  MgdProject({
    required this.name,
    required this.directory,
    required this.hasGit,
    required this.hasLivingDocs,
    required this.hasDashboardConfig,
    required this.hasAgentsFile,
    required this.hasCapabilitiesCatalog,
    required this.hasIntegrationsCatalog,
    required this.lastModified,
    required this.documents,
  });

  final String name;
  final Directory directory;
  final bool hasGit;
  final bool hasLivingDocs;
  final bool hasDashboardConfig;
  final bool hasAgentsFile;
  final bool hasCapabilitiesCatalog;
  final bool hasIntegrationsCatalog;
  final DateTime? lastModified;

  /// Textdokumente (README, Living Docs, AGENTS.md, ...), die in der Projekt-
  /// ansicht direkt geöffnet werden können. Nur real gefundene Dateien.
  final List<File> documents;

  String get path => directory.path;
}
