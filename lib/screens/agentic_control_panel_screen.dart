import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../models/agentic_entity.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Lesender Agentic-Control-Panel-Graph aus echten lokalen Projektdateien.
/// Keine Aktionen (Pause, Stop, Delegation), solange kein echter Adapter
/// mit geprüfter Autorisierung existiert.
class AgenticControlPanelScreen extends StatefulWidget {
  const AgenticControlPanelScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<AgenticControlPanelScreen> createState() => _AgenticControlPanelScreenState();
}

class _AgenticControlPanelScreenState extends State<AgenticControlPanelScreen> {
  String _query = '';
  AgenticKind? _kind;

  static String kindLabel(AgenticKind k) => switch (k) {
        AgenticKind.agent => 'Agenten',
        AgenticKind.skill => 'Skills',
        AgenticKind.mcp => 'MCP',
        AgenticKind.integration => 'Integrationen',
      };

  static IconData kindIcon(AgenticKind k) => switch (k) {
        AgenticKind.agent => Icons.smart_toy_outlined,
        AgenticKind.skill => Icons.extension_outlined,
        AgenticKind.mcp => Icons.cable_outlined,
        AgenticKind.integration => Icons.link,
      };

  @override
  Widget build(BuildContext context) {
    final all = widget.appState.agenticEntities;
    final q = _query.toLowerCase();
    final shown = all.where((e) {
      if (_kind != null && e.kind != _kind) return false;
      if (q.isEmpty) return true;
      return e.name.toLowerCase().contains(q) || (e.description ?? '').toLowerCase().contains(q);
    }).toList();
    int count(AgenticKind k) => all.where((e) => e.kind == k).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeader(
          title: 'Agentic Control Panel',
          subtitle: 'Agenten, Skills und Integrationen aus deinen Projektdateien',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.xxl),
          child: LayoutBuilder(builder: (context, box) {
            final cards = [
              _StatCard(icon: Icons.smart_toy_outlined, label: 'Agenten', value: '${count(AgenticKind.agent)}'),
              _StatCard(icon: Icons.extension_outlined, label: 'Skills', value: '${count(AgenticKind.skill)}'),
              _StatCard(icon: Icons.link, label: 'Integrationen', value: '${count(AgenticKind.integration)}'),
              const _StatCard(icon: Icons.sensors_off_outlined, label: 'Live-Adapter', value: 'nicht verbunden', small: true),
            ];
            final perRow = box.maxWidth > 900 ? 4 : 2;
            return Wrap(
              spacing: Space.md,
              runSpacing: Space.md,
              children: [
                for (final card in cards)
                  SizedBox(width: (box.maxWidth - Space.md * (perRow - 1)) / perRow, child: card),
              ],
            );
          }),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(Space.xxl, Space.md, Space.xxl, 0),
          child: _AdapterNote(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.xxl, Space.lg, Space.xxl, Space.sm),
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: Space.sm,
                  children: [
                    ChoiceChip(label: const Text('Alle'), selected: _kind == null, onSelected: (_) => setState(() => _kind = null)),
                    for (final k in AgenticKind.values)
                      if (count(k) > 0)
                        ChoiceChip(
                          label: Text('${kindLabel(k)} ${count(k)}'),
                          selected: _kind == k,
                          onSelected: (_) => setState(() => _kind = _kind == k ? null : k),
                        ),
                  ],
                ),
              ),
              SizedBox(
                width: 240,
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 18), hintText: 'Filtern'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: all.isEmpty
              ? const EmptyState(
                  icon: Icons.hub_outlined,
                  title: 'Noch nichts gefunden',
                  message: 'MGD-DevOS liest AGENTS.md und catalog/*.json aus deinen Projekten. Keines der gescannten Projekte enthält diese Dateien.',
                )
              : shown.isEmpty
                  ? const EmptyState(icon: Icons.search_off, title: 'Kein Treffer', message: 'Passe Filter oder Suchbegriff an.')
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(Space.xxl, Space.sm, Space.xxl, Space.xl),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.colors.card,
                          borderRadius: BorderRadius.circular(Radii.md),
                          border: Border.all(color: context.colors.border),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(Radii.md),
                          child: ListView.separated(
                            itemCount: shown.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, i) => _EntityTile(entity: shown[i], icon: kindIcon(shown[i].kind)),
                          ),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value, this.small = false});

  final IconData icon;
  final String label;
  final String value;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: c.muted),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: c.muted)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: small ? 15 : 22, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdapterNote extends StatelessWidget {
  const _AdapterNote();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 16, color: c.muted),
        const SizedBox(width: Space.sm),
        Expanded(
          child: Text(
            'Noch kein Live-Adapter zu Codex oder Claude Code verbunden. Einträge stammen aus lokal gelesenen Dateien und zeigen nie einen erfundenen „aktiv"-Status.',
            style: TextStyle(fontSize: 12.5, color: c.muted, height: 1.45),
          ),
        ),
      ],
    );
  }
}

class _EntityTile extends StatelessWidget {
  const _EntityTile({required this.entity, required this.icon});

  final AgenticEntity entity;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final tone = switch (entity.status) {
      AgenticStatus.claimedActive => Tone.success,
      AgenticStatus.claimedInactive => Tone.neutral,
      AgenticStatus.notConnected => Tone.neutral,
      AgenticStatus.unknown => Tone.warning,
    };
    final mandatory = entity.description?.startsWith('Pflicht-Skill') ?? false;
    final time = DateFormat('dd.MM.yyyy, HH:mm').format(entity.observedAt);

    return Material(
      type: MaterialType.transparency,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Icon(icon, size: 20, color: c.muted),
          title: Row(
            children: [
              Flexible(child: Text(entity.name, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
              if (mandatory) ...[const SizedBox(width: Space.sm), const Badge2(label: 'Pflicht', tone: Tone.accent)],
            ],
          ),
          subtitle: entity.projectName == null
              ? null
              : Text(entity.projectName!, style: TextStyle(fontSize: 12, color: c.muted)),
          trailing: Badge2(label: entity.status.labelDe, tone: tone),
          childrenPadding: const EdgeInsets.fromLTRB(56, 0, Space.lg, Space.lg),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entity.description != null)
              SelectableText(entity.description!, style: t.bodyMedium?.copyWith(height: 1.45)),
            const SizedBox(height: Space.sm),
            SelectableText('Quelle: ${entity.source}', style: TextStyle(fontSize: 12, color: c.muted)),
            Text('Beobachtet: $time', style: TextStyle(fontSize: 12, color: c.muted)),
          ],
        ),
      ),
    );
  }
}
