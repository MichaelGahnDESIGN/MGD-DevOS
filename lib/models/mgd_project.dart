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
    required this.hasSkillsCatalog,
    required this.dashboardFile,
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
  final bool hasSkillsCatalog;

  /// `index.html` im Projektroot (das `/dashboard` des Projektmanagers),
  /// falls vorhanden. Wird in einem eigenen Tab angezeigt.
  final File? dashboardFile;
  final DateTime? lastModified;

  /// Textdokumente (README, Living Docs, AGENTS.md, ...), die in der Projekt-
  /// ansicht direkt geöffnet werden können. Nur real gefundene Dateien.
  final List<File> documents;

  String get path => directory.path;
}
