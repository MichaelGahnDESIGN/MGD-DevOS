import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/mgd_project.dart';
import '../models/platform_info.dart';

/// Durchsucht einen vom Nutzer gewählten Projekt-Root **eine Ebene tief**
/// nach Projektordnern und liest ausschließlich real vorhandene Dateien.
///
/// Es werden keine Netzwerkzugriffe gemacht und keine Inhalte verändert.
class ProjectScanner {
  /// Ordner ohne Projektmerkmal aus dem letzten [scan], für einen Hinweis in der UI.
  List<String> lastSkipped = const [];

  static const _documentCandidates = [
    'README.md',
    'CHANGELOG.md',
    'AGENTS.md',
    'GRUNDREGELN.md',
    'PROJEKTREGELN.md',
    'SKILL.md',
    'MGD_PLATFORM.yml',
    'docs/mgd-devos/ARCHITEKTUR.md',
    'docs/mgd-devos/STRIPE-SPENDEN.md',
  ];

  Future<List<MgdProject>> scan(String rootPath) async {
    final root = Directory(rootPath);
    if (!await root.exists()) {
      return const [];
    }

    final results = <MgdProject>[];
    final skipped = <String>[];
    final entries = root.list(followLinks: false);
    await for (final entry in entries) {
      final name = p.basename(entry.path);
      if (name.startsWith('.')) continue;
      final Directory dir;
      if (entry is Directory) {
        dir = entry;
      } else if (entry is Link &&
          await FileSystemEntity.isDirectory(entry.path)) {
        // Verlinkte Projektordner zählen mit; der Name bleibt der des Links.
        dir = Directory(entry.path);
      } else {
        continue;
      }
      final project = await _inspect(dir, name);
      if (project != null) {
        results.add(project);
      } else {
        skipped.add(name);
      }
    }
    skipped.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    lastSkipped = List.unmodifiable(skipped);

    results.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return results;
  }

  Future<MgdProject?> _inspect(Directory dir, String name) async {
    final hasGit = await Directory(p.join(dir.path, '.git')).exists();
    final livingDocsDir = Directory(p.join(dir.path, 'docs'));
    final hasLivingDocs = await livingDocsDir.exists();
    final hasDashboardConfig = await File(
      p.join(dir.path, 'PROJEKT', '.mgd-ai-projektmanager.json'),
    ).exists();
    final hasAgentsFile = await File(p.join(dir.path, 'AGENTS.md')).exists();
    final hasCapabilitiesCatalog = await File(
      p.join(dir.path, 'catalog', 'capabilities.json'),
    ).exists();
    final hasIntegrationsCatalog = await File(
      p.join(dir.path, 'catalog', 'integrations.json'),
    ).exists();
    final hasSkillsCatalog = await File(
      p.join(dir.path, 'catalog', 'skills.json'),
    ).exists();

    final platform = await _readPlatform(dir);

    final indexFile = File(p.join(dir.path, 'index.html'));
    final dashboardFile = await indexFile.exists() ? indexFile : null;

    // Nur echte Ordner mit mindestens einem erkennbaren Projektmerkmal
    // aufnehmen, damit beliebige unbeteiligte Verzeichnisse nicht als
    // "Projekt" erscheinen.
    final looksLikeProject = hasGit ||
        hasDashboardConfig ||
        hasAgentsFile ||
        platform != null ||
        await File(p.join(dir.path, 'README.md')).exists() ||
        await File(p.join(dir.path, 'pubspec.yaml')).exists() ||
        await File(p.join(dir.path, 'package.json')).exists();
    if (!looksLikeProject) return null;

    DateTime? lastModified;
    try {
      lastModified = (await dir.stat()).modified;
    } catch (_) {
      lastModified = null;
    }

    final documents = <File>[];
    for (final relative in _documentCandidates) {
      final file = File(p.join(dir.path, relative));
      if (await file.exists()) {
        documents.add(file);
      }
    }

    return MgdProject(
      name: name,
      directory: dir,
      hasGit: hasGit,
      hasLivingDocs: hasLivingDocs,
      hasDashboardConfig: hasDashboardConfig,
      hasAgentsFile: hasAgentsFile,
      hasCapabilitiesCatalog: hasCapabilitiesCatalog,
      hasIntegrationsCatalog: hasIntegrationsCatalog,
      hasSkillsCatalog: hasSkillsCatalog,
      dashboardFile: dashboardFile,
      lastModified: lastModified,
      documents: documents,
      platform: platform,
    );
  }

  /// Erkennt ein Projekt des MGD-Plattform-Builders an `MGD_PLATFORM.yml` und liest
  /// Version und Status aus `version.json`. Fehlt die Datei oder ist sie ungültig,
  /// wird das Projekt trotzdem als Plattform erkannt, nur ohne Version.
  Future<PlatformInfo?> _readPlatform(Directory dir) async {
    if (!await File(p.join(dir.path, PlatformInfo.profileFile)).exists()) return null;
    final versionFile = File(p.join(dir.path, PlatformInfo.versionFile));
    try {
      if (!await versionFile.exists()) return const PlatformInfo();
      return PlatformInfo.fromVersionJson(jsonDecode(await versionFile.readAsString()));
    } on FormatException {
      return const PlatformInfo();
    } on FileSystemException {
      return const PlatformInfo();
    }
  }
}
