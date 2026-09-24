import 'package:flutter/material.dart';

import '../models/agentic_entity.dart';
import '../theme/app_theme.dart';
import 'ui.dart';

enum GraphNodeType { project, group, entity }

/// Knoten mit fester Position im Graphen. Reine Daten, damit das Layout
/// ohne Flutter-Rendering testbar ist.
class GraphNode {
  const GraphNode({
    required this.id,
    required this.type,
    required this.rect,
    required this.label,
    this.kind,
    this.entity,
    this.count = 0,
    this.collapsed = false,
  });

  final String id;
  final GraphNodeType type;
  final Rect rect;
  final String label;
  final AgenticKind? kind;
  final AgenticEntity? entity;
  final int count;
  final bool collapsed;
}

class GraphEdge {
  const GraphEdge(this.from, this.to);
  final String from;
  final String to;
}

class GraphLayout {
  const GraphLayout({required this.nodes, required this.edges, required this.size});

  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final Size size;

  static const projectSize = Size(220, 64);
  static const groupSize = Size(200, 52);
  static const entitySize = Size(280, 44);
  static const colX = [40.0, 340.0, 620.0];
  static const gap = 10.0;
  static const blockGap = 36.0;

  /// Ordnet Projekte links, Gruppen je Art in der Mitte und Einträge rechts
  /// an. Eingeklappte Gruppen zeigen keine Einträge.
  static GraphLayout build(List<AgenticEntity> entities, Set<String> collapsedGroups) {
    final byProject = <String, Map<AgenticKind, List<AgenticEntity>>>{};
    for (final e in entities) {
      final project = e.projectName ?? 'Ohne Projekt';
      byProject.putIfAbsent(project, () => {}).putIfAbsent(e.kind, () => []).add(e);
    }
    final nodes = <GraphNode>[];
    final edges = <GraphEdge>[];
    var y = 40.0;

    for (final project in byProject.keys) {
      final kinds = byProject[project]!;
      final blockTop = y;
      final groupNodes = <GraphNode>[];
      for (final kind in AgenticKind.values) {
        final list = kinds[kind];
        if (list == null || list.isEmpty) continue;
        final groupId = '$project::${kind.name}';
        final collapsed = collapsedGroups.contains(groupId);
        final entityTop = y;
        if (!collapsed) {
          for (final e in list) {
            final node = GraphNode(
              id: e.id,
              type: GraphNodeType.entity,
              rect: Offset(colX[2], y) & entitySize,
              label: e.name,
              kind: kind,
              entity: e,
            );
            nodes.add(node);
            edges.add(GraphEdge(groupId, e.id));
            y += entitySize.height + gap;
          }
        }
        final entityBottom = collapsed ? entityTop + groupSize.height : y - gap;
        final groupY = (entityTop + entityBottom) / 2 - groupSize.height / 2;
        final g = GraphNode(
          id: groupId,
          type: GraphNodeType.group,
          rect: Offset(colX[1], groupY) & groupSize,
          label: _kindLabel(kind),
          kind: kind,
          count: list.length,
          collapsed: collapsed,
        );
        groupNodes.add(g);
        if (collapsed) y += groupSize.height + gap;
        y += gap * 2;
      }
      final blockBottom = y - gap * 3;
      final projectId = 'project::$project';
      nodes.add(GraphNode(
        id: projectId,
        type: GraphNodeType.project,
        rect: Offset(colX[0], (blockTop + blockBottom) / 2 - projectSize.height / 2) & projectSize,
        label: project,
        count: kinds.values.fold(0, (a, l) => a + l.length),
      ));
      for (final g in groupNodes) {
        nodes.add(g);
        edges.add(GraphEdge(projectId, g.id));
      }
      y += blockGap;
    }
    final height = nodes.isEmpty ? 400.0 : nodes.map((n) => n.rect.bottom).reduce((a, b) => a > b ? a : b) + 60;
    return GraphLayout(nodes: nodes, edges: edges, size: Size(colX[2] + entitySize.width + 60, height));
  }

  static String _kindLabel(AgenticKind k) => switch (k) {
        AgenticKind.agent => 'Agenten',
        AgenticKind.skill => 'Skills',
        AgenticKind.mcp => 'MCP',
        AgenticKind.integration => 'Integrationen',
      };
}

IconData kindIcon(AgenticKind k) => switch (k) {
      AgenticKind.agent => Icons.smart_toy_outlined,
      AgenticKind.skill => Icons.extension_outlined,
      AgenticKind.mcp => Icons.cable_outlined,
      AgenticKind.integration => Icons.link,
    };

/// Graph-Arbeitsfläche mit Punktraster, Kanten und Knoten. Verschiebbar und
/// zoombar; Klick auf einen Eintrag wählt ihn aus, Klick auf eine Gruppe
/// klappt sie ein oder aus.
class AgenticGraphCanvas extends StatelessWidget {
  const AgenticGraphCanvas({
    super.key,
    required this.layout,
    required this.selectedId,
    required this.onSelect,
    required this.onToggleGroup,
    required this.controller,
  });

  final GraphLayout layout;
  final String? selectedId;
  final ValueChanged<AgenticEntity> onSelect;
  final ValueChanged<String> onToggleGroup;
  final TransformationController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final byId = {for (final n in layout.nodes) n.id: n};
    return ClipRect(
      child: CustomPaint(
        painter: _GridPainter(color: c.border.withValues(alpha: 0.9)),
        child: InteractiveViewer(
          transformationController: controller,
          constrained: false,
          minScale: 0.4,
          maxScale: 1.8,
          boundaryMargin: const EdgeInsets.all(400),
          child: SizedBox(
            width: layout.size.width,
            height: layout.size.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _EdgePainter(
                      layout: layout,
                      byId: byId,
                      color: c.border,
                      hot: Theme.of(context).colorScheme.primary,
                      selectedId: selectedId,
                    ),
                  ),
                ),
                for (final n in layout.nodes)
                  Positioned.fromRect(
                    rect: n.rect,
                    child: switch (n.type) {
                      GraphNodeType.project => _ProjectNode(node: n),
                      GraphNodeType.group => _GroupNode(node: n, onTap: () => onToggleGroup(n.id)),
                      GraphNodeType.entity => _EntityNode(
                          node: n,
                          selected: n.id == selectedId,
                          onTap: () => onSelect(n.entity!),
                        ),
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    for (var x = 0.0; x < size.width; x += 18) {
      for (var y = 0.0; y < size.height; y += 18) {
        canvas.drawCircle(Offset(x, y), 0.8, p);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.color != color;
}

class _EdgePainter extends CustomPainter {
  _EdgePainter({required this.layout, required this.byId, required this.color, required this.hot, this.selectedId});

  final GraphLayout layout;
  final Map<String, GraphNode> byId;
  final Color color;
  final Color hot;
  final String? selectedId;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color;
    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = hot;
    final selectedGroup = selectedId == null
        ? null
        : layout.edges.where((e) => e.to == selectedId).map((e) => e.from).firstOrNull;
    for (final e in layout.edges) {
      final a = byId[e.from];
      final b = byId[e.to];
      if (a == null || b == null) continue;
      final start = Offset(a.rect.right, a.rect.center.dy);
      final end = Offset(b.rect.left, b.rect.center.dy);
      final mx = (start.dx + end.dx) / 2;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(mx, start.dy, mx, end.dy, end.dx, end.dy);
      final isHot = e.to == selectedId || (selectedGroup != null && e.to == selectedGroup);
      canvas.drawPath(path, isHot ? active : base);
      final dot = Paint()..color = isHot ? hot : color;
      canvas.drawCircle(start, 3, dot);
      canvas.drawCircle(end, 3, dot);
    }
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.layout != layout || old.selectedId != selectedId || old.color != color || old.hot != hot;
}

BoxDecoration _nodeBox(BuildContext context, {bool selected = false, bool strong = false}) {
  final c = context.colors;
  final accent = Theme.of(context).colorScheme.primary;
  return BoxDecoration(
    color: c.card,
    borderRadius: BorderRadius.circular(Radii.md),
    border: Border.all(color: selected ? accent : (strong ? c.muted.withValues(alpha: 0.5) : c.border), width: selected ? 1.6 : 1),
    boxShadow: [
      if (selected) BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 14),
    ],
  );
}

class _ProjectNode extends StatelessWidget {
  const _ProjectNode({required this.node});
  final GraphNode node;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: '${node.label} · ${node.count} Einträge',
      child: Semantics(
      label: 'Projekt ${node.label}, ${node.count} Einträge',
      child: Container(
        decoration: _nodeBox(context, strong: true),
        padding: const EdgeInsets.symmetric(horizontal: Space.md),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Icon(Icons.folder_outlined, size: 18, color: context.accentText),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PROJEKT', style: TextStyle(fontSize: 9.5, letterSpacing: 1, fontWeight: FontWeight.w700, color: c.muted)),
                  Text(node.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _GroupNode extends StatelessWidget {
  const _GroupNode({required this.node, required this.onTap});
  final GraphNode node;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: node.collapsed ? 'Ausklappen' : 'Einklappen',
      child: Semantics(
        button: true,
        expanded: !node.collapsed,
        label: '${node.label}, ${node.count}',
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Radii.md),
            child: Ink(
              decoration: _nodeBox(context),
              padding: const EdgeInsets.symmetric(horizontal: Space.md),
              child: Row(
                children: [
                  Icon(kindIcon(node.kind!), size: 18, color: c.muted),
                  const SizedBox(width: Space.sm),
                  Expanded(child: Text(node.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                  Badge2(label: '${node.count}'),
                  const SizedBox(width: 4),
                  Icon(node.collapsed ? Icons.chevron_right : Icons.expand_more, size: 18, color: c.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EntityNode extends StatelessWidget {
  const _EntityNode({required this.node, required this.selected, required this.onTap});
  final GraphNode node;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final e = node.entity!;
    final dot = switch (e.status) {
      AgenticStatus.claimedActive => c.success,
      AgenticStatus.unknown => c.warning,
      _ => c.neutral,
    };
    final mandatory = e.description?.startsWith('Pflicht-Skill') ?? false;
    return Semantics(
      button: true,
      selected: selected,
      label: '${e.name}, ${e.status.labelDe}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.md),
          child: AnimatedContainer(
            duration: Motion.of(context, Motion.fast),
            decoration: _nodeBox(context, selected: selected),
            padding: const EdgeInsets.symmetric(horizontal: Space.md),
            child: Row(
              children: [
                Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                const SizedBox(width: Space.sm),
                Expanded(child: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                if (mandatory) const Badge2(label: 'Pflicht', tone: Tone.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
