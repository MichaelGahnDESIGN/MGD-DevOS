import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:mgd_devos/services/agentic_scanner.dart';
import 'package:mgd_devos/services/project_scanner.dart';
import 'package:mgd_devos/models/agentic_entity.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('mgd_devos_test_');
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  test('ignoriert Ordner ohne erkennbare Projektmerkmale', () async {
    await Directory(p.join(root.path, 'random_folder')).create();

    final scanner = ProjectScanner();
    final projects = await scanner.scan(root.path);

    expect(projects, isEmpty);
  });

  test('erkennt ein Projekt anhand von .git und liest Dokumente', () async {
    final projectDir = Directory(p.join(root.path, 'mein-projekt'));
    await projectDir.create();
    await Directory(p.join(projectDir.path, '.git')).create();
    await File(p.join(projectDir.path, 'README.md'))
        .writeAsString('# Mein Projekt');
    await File(p.join(projectDir.path, 'AGENTS.md')).writeAsString(
      '# Agenten\n\n## Planer\n\nBeschreibung.\n\n## Reviewer\n\nBeschreibung.',
    );

    final scanner = ProjectScanner();
    final projects = await scanner.scan(root.path);

    expect(projects, hasLength(1));
    final project = projects.single;
    expect(project.name, 'mein-projekt');
    expect(project.hasGit, isTrue);
    expect(project.hasAgentsFile, isTrue);
    expect(project.documents.map((f) => p.basename(f.path)),
        containsAll(['README.md', 'AGENTS.md']));
  });

  test('AgenticScanner liest AGENTS.md und markiert nie als live aktiv',
      () async {
    final projectDir = Directory(p.join(root.path, 'mein-projekt'));
    await projectDir.create();
    await Directory(p.join(projectDir.path, '.git')).create();
    await File(p.join(projectDir.path, 'AGENTS.md')).writeAsString(
      '# Agenten\n\n## Planer\n\nBeschreibung.\n\n## Reviewer\n\nBeschreibung.',
    );

    final projects = await ProjectScanner().scan(root.path);
    final entities = await AgenticScanner().scan(projects);

    expect(entities, isNotEmpty);
    expect(entities.map((e) => e.name), containsAll(['Planer', 'Reviewer']));
    expect(
      entities.every((e) => e.status != AgenticStatus.claimedActive),
      isTrue,
      reason: 'Ohne Live-Adapter darf nie "belegt aktiv" behauptet werden.',
    );
  });

  test('AgenticScanner liest catalog/skills.json inkl. Pflicht-Skills',
      () async {
    final projectDir = Directory(p.join(root.path, 'mein-projekt'));
    await projectDir.create();
    await Directory(p.join(projectDir.path, '.git')).create();
    await Directory(p.join(projectDir.path, 'catalog')).create();
    await File(p.join(projectDir.path, 'catalog', 'skills.json'))
        .writeAsString('''
{
  "skills": [
    {
      "name": "MGD_AI-Thread",
      "url": "https://github.com/MichaelGahnDESIGN/MGD_AI-Thread",
      "description": "Schreibt eine belegte Uebergabe.",
      "mandatory": true,
      "slashCommands": ["/thread"]
    }
  ]
}
''');

    final projects = await ProjectScanner().scan(root.path);
    expect(projects.single.hasSkillsCatalog, isTrue);

    final entities = await AgenticScanner().scan(projects);
    final thread = entities.singleWhere((e) => e.name == 'MGD_AI-Thread');
    expect(thread.kind, AgenticKind.skill);
    expect(thread.description, contains('Pflicht-Skill'));
    expect(thread.status, isNot(AgenticStatus.claimedActive));
  });
}
