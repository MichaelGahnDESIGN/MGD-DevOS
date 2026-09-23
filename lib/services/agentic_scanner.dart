import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/agentic_entity.dart';
import '../models/mgd_project.dart';

/// Liest den Agentic-Control-Panel-Graphen ausschließlich aus echten,
/// bereits im Dateisystem vorhandenen Projektdateien.
///
/// MGD-DevOS hat in dieser ersten Version **keinen** Live-Adapter zu Codex
/// oder Claude Code. Jeder hier erzeugte Knoten bekommt deshalb höchstens
/// den Status [AgenticStatus.claimedInactive] ("in Projektdateien
/// deklariert") oder [AgenticStatus.notConnected]/[AgenticStatus.unknown] –
/// niemals [AgenticStatus.claimedActive], weil kein Live-Status vorliegt.
class AgenticScanner {
  Future<List<AgenticEntity>> scan(List<MgdProject> projects) async {
    final now = DateTime.now();
    final entities = <AgenticEntity>[];

    for (final project in projects) {
      if (project.hasAgentsFile) {
        entities.addAll(await _readAgentsFile(project, now));
      }
      if (project.hasCapabilitiesCatalog) {
        entities.addAll(await _readCapabilitiesCatalog(project, now));
      }
      if (project.hasIntegrationsCatalog) {
        entities.addAll(await _readIntegrationsCatalog(project, now));
      }
    }

    return entities;
  }

  Future<List<AgenticEntity>> _readAgentsFile(
    MgdProject project,
    DateTime now,
  ) async {
    final file = File(p.join(project.path, 'AGENTS.md'));
    try {
      final lines = await file.readAsLines();
      final headings = <String>[];
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('## ') || trimmed.startsWith('### ')) {
          final title = trimmed.replaceFirst(RegExp(r'^#+\s*'), '').trim();
          if (title.isNotEmpty) headings.add(title);
        }
      }
      if (headings.isEmpty) {
        return [
          AgenticEntity(
            id: '${project.name}:AGENTS.md',
            name: 'AGENTS.md (${project.name})',
            kind: AgenticKind.agent,
            status: AgenticStatus.unknown,
            source: file.path,
            observedAt: now,
            description: 'Datei gefunden, aber keine Abschnitte erkannt.',
            projectName: project.name,
          ),
        ];
      }
      return headings.take(20).map((heading) {
        return AgenticEntity(
          id: '${project.name}:AGENTS.md:$heading',
          name: heading,
          kind: AgenticKind.agent,
          status: AgenticStatus.notConnected,
          source: file.path,
          observedAt: now,
          description:
              'Aus AGENTS.md deklariert. Kein Live-Adapter verbunden.',
          projectName: project.name,
        );
      }).toList();
    } catch (_) {
      return [
        AgenticEntity(
          id: '${project.name}:AGENTS.md:error',
          name: 'AGENTS.md (${project.name})',
          kind: AgenticKind.agent,
          status: AgenticStatus.unknown,
          source: file.path,
          observedAt: now,
          description: 'Datei konnte nicht gelesen werden.',
          projectName: project.name,
        ),
      ];
    }
  }

  Future<List<AgenticEntity>> _readCapabilitiesCatalog(
    MgdProject project,
    DateTime now,
  ) async {
    final file = File(p.join(project.path, 'catalog', 'capabilities.json'));
    try {
      final raw = await file.readAsString();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final categories = (data['categories'] as List?) ?? const [];
      final entities = <AgenticEntity>[];
      for (final category in categories) {
        if (category is! Map) continue;
        final categoryName = category['name']?.toString() ?? 'Kategorie';
        final options = (category['options'] as List?) ?? const [];
        for (final option in options) {
          entities.add(
            AgenticEntity(
              id: '${project.name}:capabilities:$categoryName:$option',
              name: option.toString(),
              kind: AgenticKind.skill,
              status: AgenticStatus.notConnected,
              source: file.path,
              observedAt: now,
              description: 'Katalogisierte Skill-Option ($categoryName).',
              projectName: project.name,
            ),
          );
        }
      }
      return entities;
    } catch (_) {
      return [
        AgenticEntity(
          id: '${project.name}:capabilities:error',
          name: 'capabilities.json (${project.name})',
          kind: AgenticKind.skill,
          status: AgenticStatus.unknown,
          source: file.path,
          observedAt: now,
          description: 'Datei konnte nicht gelesen oder geparst werden.',
          projectName: project.name,
        ),
      ];
    }
  }

  Future<List<AgenticEntity>> _readIntegrationsCatalog(
    MgdProject project,
    DateTime now,
  ) async {
    final file = File(p.join(project.path, 'catalog', 'integrations.json'));
    try {
      final raw = await file.readAsString();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final integrations = (data['integrations'] as List?) ?? const [];
      return integrations.map((entry) {
        final map = entry as Map<String, dynamic>;
        final name = map['name']?.toString() ?? 'Integration';
        final kind = map['kind']?.toString();
        return AgenticEntity(
          id: '${project.name}:integrations:$name',
          name: name,
          kind: AgenticKind.integration,
          status: AgenticStatus.notConnected,
          source: file.path,
          observedAt: now,
          description: [
            if (kind != null) 'Art: $kind',
            if (map['purpose'] != null) map['purpose'].toString(),
          ].join(' – '),
          projectName: project.name,
        );
      }).toList();
    } catch (_) {
      return [
        AgenticEntity(
          id: '${project.name}:integrations:error',
          name: 'integrations.json (${project.name})',
          kind: AgenticKind.integration,
          status: AgenticStatus.unknown,
          source: file.path,
          observedAt: now,
          description: 'Datei konnte nicht gelesen oder geparst werden.',
          projectName: project.name,
        ),
      ];
    }
  }
}
