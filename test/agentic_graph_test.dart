import 'package:flutter_test/flutter_test.dart';

import 'package:mgd_devos/models/agentic_entity.dart';
import 'package:mgd_devos/widgets/agentic_graph.dart';

AgenticEntity e(String name, AgenticKind kind, String project) => AgenticEntity(
      id: '$project:$name',
      name: name,
      kind: kind,
      status: AgenticStatus.notConnected,
      source: '/x',
      observedAt: DateTime(2026, 9, 24),
      projectName: project,
    );

void main() {
  final entities = [
    e('Planer', AgenticKind.agent, 'A'),
    e('Reviewer', AgenticKind.agent, 'A'),
    e('Thread', AgenticKind.skill, 'A'),
    e('Shop', AgenticKind.integration, 'B'),
  ];

  test('Layout: Projekt → Gruppe → Eintrag, ohne Überlappung', () {
    final l = GraphLayout.build(entities, const {});
    final projects = l.nodes.where((n) => n.type == GraphNodeType.project).toList();
    final groups = l.nodes.where((n) => n.type == GraphNodeType.group).toList();
    final items = l.nodes.where((n) => n.type == GraphNodeType.entity).toList();
    expect(projects.map((n) => n.label), ['A', 'B']);
    expect(groups.length, 3);
    expect(items.length, 4);
    expect(l.edges.length, 3 + 4);
    for (var i = 0; i < l.nodes.length; i++) {
      for (var j = i + 1; j < l.nodes.length; j++) {
        expect(l.nodes[i].rect.overlaps(l.nodes[j].rect), isFalse,
            reason: '${l.nodes[i].id} überlappt ${l.nodes[j].id}');
      }
    }
    for (final n in l.nodes) {
      expect(n.rect.bottom <= l.size.height && n.rect.right <= l.size.width, isTrue);
    }
  });

  test('Eingeklappte Gruppe zeigt keine Einträge, aber die Anzahl', () {
    final l = GraphLayout.build(entities, const {'A::agent'});
    final g = l.nodes.singleWhere((n) => n.id == 'A::agent');
    expect(g.collapsed, isTrue);
    expect(g.count, 2);
    expect(l.nodes.where((n) => n.type == GraphNodeType.entity).map((n) => n.label), ['Thread', 'Shop']);
  });

  test('Leere Liste ergibt leeren Graphen', () {
    final l = GraphLayout.build(const [], const {});
    expect(l.nodes, isEmpty);
    expect(l.edges, isEmpty);
  });
}
