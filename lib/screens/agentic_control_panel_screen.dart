import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../models/agentic_entity.dart';

/// Lesender Agentic-Control-Panel-Graph.
///
/// Zeigt ausschließlich Einträge, die [AgenticScanner] aus echten lokalen
/// Projektdateien gelesen hat. Es gibt bewusst noch keine Aktionen (Pause,
/// Stop, Delegation, Modellwechsel): Diese kommen erst mit einem echten
/// Codex-/Claude-Code-Adapter und einer geprüften Autorisierung.
class AgenticControlPanelScreen extends StatelessWidget {
  const AgenticControlPanelScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final entities = appState.agenticEntities;
    final byKind = <AgenticKind, List<AgenticEntity>>{
      for (final kind in AgenticKind.values) kind: [],
    };
    for (final entity in entities) {
      byKind[entity.kind]!.add(entity);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Text(
            'Agentic Control Panel',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: _NoLiveAdapterNotice(),
        ),
        Expanded(
          child: entities.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Keine Agenten, Skills oder Integrationen gefunden. '
                      'MGD-DevOS liest dafür AGENTS.md sowie '
                      'catalog/capabilities.json und '
                      'catalog/integrations.json aus den gescannten '
                      'Projekten.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final kind in AgenticKind.values)
                      if (byKind[kind]!.isNotEmpty)
                        _KindSection(kind: kind, entities: byKind[kind]!),
                  ],
                ),
        ),
      ],
    );
  }
}

class _NoLiveAdapterNotice extends StatelessWidget {
  const _NoLiveAdapterNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Noch kein Live-Adapter zu Codex oder Claude Code verbunden. '
              'Alle Einträge stammen aus lokal gelesenen Projektdateien '
              '(Quelle und Zeitpunkt stehen bei jedem Eintrag) und zeigen '
              'daher höchstens "belegt inaktiv", "nicht verbunden" oder '
              '"unbekannt" – niemals einen erfundenen Live-Status.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _KindSection extends StatelessWidget {
  const _KindSection({required this.kind, required this.entities});

  final AgenticKind kind;
  final List<AgenticEntity> entities;

  String get _title => switch (kind) {
        AgenticKind.agent => 'Agenten',
        AgenticKind.skill => 'Skills',
        AgenticKind.mcp => 'MCP-Verbindungen',
        AgenticKind.integration => 'Integrationen',
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(_title, style: Theme.of(context).textTheme.titleMedium),
        ),
        ...entities.map((entity) => _EntityTile(entity: entity)),
      ],
    );
  }
}

class _EntityTile extends StatelessWidget {
  const _EntityTile({required this.entity});

  final AgenticEntity entity;

  Color _statusColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (entity.status) {
      AgenticStatus.claimedActive => scheme.primary,
      AgenticStatus.claimedInactive => scheme.tertiary,
      AgenticStatus.notConnected => scheme.outline,
      AgenticStatus.unknown => scheme.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('dd.MM.yyyy HH:mm');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 6,
          backgroundColor: _statusColor(context),
        ),
        title: Text(entity.name),
        subtitle: Text(
          [
            if (entity.projectName != null) 'Projekt: ${entity.projectName}',
            if (entity.description != null) entity.description!,
            'Quelle: ${entity.source}',
            'Beobachtet: ${timeFormat.format(entity.observedAt)}',
          ].join('\n'),
        ),
        isThreeLine: true,
        trailing: Chip(
          label: Text(entity.status.labelDe),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
