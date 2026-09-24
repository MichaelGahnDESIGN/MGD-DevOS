import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../models/agentic_entity.dart';
import '../theme/app_theme.dart';
import '../widgets/agentic_graph.dart';
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
  bool _graph = true;
  AgenticEntity? _selected;
  final Set<String> _collapsed = {};
  bool _collapsedInit = false;
  final TransformationController _view = TransformationController();

  static String kindLabel(AgenticKind k) => switch (k) {
        AgenticKind.agent => 'Agenten',
        AgenticKind.skill => 'Skills',
        AgenticKind.mcp => 'MCP',
        AgenticKind.integration => 'Integrationen',
      };

  @override
  void dispose() {
    _view.dispose();
    super.dispose();
  }

  List<AgenticEntity> _filtered(List<AgenticEntity> all) {
    final q = _query.toLowerCase();
    return all.where((e) {
      if (_kind != null && e.kind != _kind) return false;
      if (q.isEmpty) return true;
      return e.name.toLowerCase().contains(q) || (e.description ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.appState.agenticEntities;
    final shown = _filtered(all);
    int count(AgenticKind k) => all.where((e) => e.kind == k).length;
    if (!_collapsedInit && all.isNotEmpty) {
      // Große Gruppen starten eingeklappt, damit der Graph überschaubar bleibt.
      for (final e in all) {
        final id = '${e.projectName ?? 'Ohne Projekt'}::${e.kind.name}';
        if (all.where((x) => x.projectName == e.projectName && x.kind == e.kind).length > 8) _collapsed.add(id);
      }
      _collapsedInit = true;
    }
    final selected = _selected != null && shown.any((e) => e.id == _selected!.id) ? _selected : null;
    final c = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Agentic Control Panel',
          subtitle: 'Agenten, Skills und Integrationen aus deinen Projektdateien',
          actions: [
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: true, label: Text('Graph'), icon: Icon(Icons.account_tree_outlined, size: 16)),
                ButtonSegment(value: false, label: Text('Liste'), icon: Icon(Icons.view_list_outlined, size: 16)),
              ],
              selected: {_graph},
              onSelectionChanged: (v) => setState(() => _graph = v.first),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.xxl, 0, Space.xxl, Space.md),
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: [
                    ChoiceChip(label: Text('Alle ${all.length}'), selected: _kind == null, onSelected: (_) => setState(() => _kind = null)),
                    for (final k in AgenticKind.values)
                      if (count(k) > 0)
                        ChoiceChip(
                          avatar: Icon(kindIcon(k), size: 15),
                          label: Text('${kindLabel(k)} ${count(k)}'),
                          selected: _kind == k,
                          onSelected: (_) => setState(() => _kind = _kind == k ? null : k),
                        ),
                  ],
                ),
              ),
              if (_graph) ...[
                IconButton(
                  tooltip: 'Ansicht zurücksetzen',
                  onPressed: () => _view.value = Matrix4.identity(),
                  icon: const Icon(Icons.center_focus_strong_outlined, size: 18),
                ),
                const SizedBox(width: Space.xs),
              ],
              SizedBox(
                width: 220,
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
                  : Container(
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _graph
                                ? AgenticGraphCanvas(
                                    layout: GraphLayout.build(shown, _query.isEmpty && _kind == null ? _collapsed : const {}),
                                    selectedId: selected?.id,
                                    controller: _view,
                                    onSelect: (e) => setState(() => _selected = e),
                                    onToggleGroup: (id) => setState(() => _collapsed.contains(id) ? _collapsed.remove(id) : _collapsed.add(id)),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(Space.xxl, Space.md, Space.xxl, Space.xl),
                                    itemCount: shown.length,
                                    separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
                                    itemBuilder: (context, i) => _EntityTile(
                                      entity: shown[i],
                                      icon: kindIcon(shown[i].kind),
                                      selected: shown[i].id == selected?.id,
                                      onTap: () => setState(() => _selected = shown[i]),
                                    ),
                                  ),
                          ),
                          _Inspector(entity: selected, onClose: () => setState(() => _selected = null)),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }
}

class _Inspector extends StatelessWidget {
  const _Inspector({required this.entity, required this.onClose});

  final AgenticEntity? entity;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final e = entity;
    Widget kv(String k, Widget v) => Padding(
          padding: const EdgeInsets.only(bottom: Space.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SectionLabel(k), const SizedBox(height: 4), v]),
        );
    return Container(
      width: 300,
      decoration: BoxDecoration(color: c.sidebar, border: Border(left: BorderSide(color: c.border))),
      child: e == null
          ? Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Inspektor'),
                  const SizedBox(height: Space.md),
                  Text('Wähle einen Eintrag im Graphen oder in der Liste, um Details zu sehen.', style: t.bodyMedium?.copyWith(color: c.muted, height: 1.5)),
                  const SizedBox(height: Space.lg),
                  const _AdapterNote(),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(Space.lg),
              children: [
                Row(
                  children: [
                    const Expanded(child: SectionLabel('Inspektor')),
                    IconButton(tooltip: 'Auswahl aufheben', visualDensity: VisualDensity.compact, onPressed: onClose, icon: const Icon(Icons.close, size: 16)),
                  ],
                ),
                Text(e.name, style: t.titleMedium),
                const SizedBox(height: Space.lg),
                kv('Status', Align(alignment: Alignment.centerLeft, child: Badge2(label: e.status.labelDe, tone: e.status == AgenticStatus.unknown ? Tone.warning : Tone.neutral))),
                kv('Art', Text(_AgenticControlPanelScreenState.kindLabel(e.kind))),
                if (e.projectName != null) kv('Projekt', Text(e.projectName!)),
                if (e.description != null) kv('Beschreibung', SelectableText(e.description!, style: const TextStyle(height: 1.5))),
                kv('Quelle', SelectableText(e.source, style: TextStyle(fontSize: 12, color: c.muted, height: 1.45))),
                kv('Beobachtet', Text(DateFormat('dd.MM.yyyy, HH:mm').format(e.observedAt))),
                const Divider(height: Space.xl),
                const _AdapterNote(),
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
  const _EntityTile({required this.entity, required this.icon, required this.selected, required this.onTap});

  final AgenticEntity entity;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = Theme.of(context).colorScheme.primary;
    final mandatory = entity.description?.startsWith('Pflicht-Skill') ?? false;
    return Material(
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: selected ? accent : c.border, width: selected ? 1.6 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
          child: Row(
            children: [
              Icon(icon, size: 18, color: c.muted),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(child: Text(entity.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                      if (mandatory) ...[const SizedBox(width: Space.sm), const Badge2(label: 'Pflicht', tone: Tone.accent)],
                    ]),
                    if (entity.projectName != null) Text(entity.projectName!, style: TextStyle(fontSize: 12, color: c.muted)),
                  ],
                ),
              ),
              Badge2(label: entity.status.labelDe, tone: entity.status == AgenticStatus.unknown ? Tone.warning : Tone.neutral),
            ],
          ),
        ),
      ),
    );
  }
}
