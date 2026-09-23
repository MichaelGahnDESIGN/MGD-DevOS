import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/mgd_project.dart';

/// Durchsucht einen vom Nutzer gewählten Projekt-Root **eine Ebene tief**
/// nach Projektordnern und liest ausschließlich real vorhandene Dateien.
///
/// Es werden keine Netzwerkzugriffe gemacht und keine Inhalte verändert.
class ProjectScanner {
  static const _documentCandidates = [
    'README.md',
    'CHANGELOG.md',
    'AGENTS.md',
    'GRUNDREGELN.md',
    'PROJEKTREGELN.md',
    'SKILL.md',
    'docs/mgd-devos/ARCHITEKTUR.md',
    'docs/mgd-devos/STRIPE-SPENDEN.md',
  ];

  Future<List<MgdProject>> scan(String rootPath) async {
    final root = Directory(rootPath);
    if (!await root.exists()) {
      return const [];
    }

    final results = <MgdProject>[];
    final entries = root.list(followLinks: false);
    await for (final entry in entries) {
      if (entry is! Directory) continue;
      final name = p.basename(entry.path);
      if (name.startsWith('.')) continue;
      final project = await _inspect(entry, name);
      if (project != null) {
        results.add(project);
      }
    }

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

    // Nur echte Ordner mit mindestens einem erkennbaren Projektmerkmal
    // aufnehmen, damit beliebige unbeteiligte Verzeichnisse nicht als
    // "Projekt" erscheinen.
    final looksLikeProject = hasGit ||
        hasDashboardConfig ||
        hasAgentsFile ||
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
      lastModified: lastModified,
      documents: documents,
    );
  }
}
