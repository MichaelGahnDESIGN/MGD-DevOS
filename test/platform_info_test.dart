import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:mgd_devos/models/platform_info.dart';
import 'package:mgd_devos/screens/projects_screen.dart';
import 'package:mgd_devos/services/project_scanner.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('mgd_platform_test_');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  Future<Directory> platformProject(String name, {String? versionJson}) async {
    final dir = Directory(p.join(root.path, name));
    await dir.create();
    await File(p.join(dir.path, 'MGD_PLATFORM.yml')).writeAsString('project:\n  name: "$name"\n');
    if (versionJson != null) {
      await File(p.join(dir.path, 'version.json')).writeAsString(versionJson);
    }
    return dir;
  }

  test('erkennt MGD_PLATFORM.yml als Projekt und liest Version und Status aus version.json', () async {
    await platformProject('plattform', versionJson: '{"version": "0.0.1", "status": "pre-alpha", "released_at": "2026-09-25"}');

    final projects = await ProjectScanner().scan(root.path);

    expect(projects, hasLength(1));
    final platform = projects.single.platform;
    expect(platform, isNotNull);
    expect(platform!.version, '0.0.1');
    expect(platform.status, 'pre-alpha');
    expect(platform.label, '0.0.1 Pre-Alpha');
    expect(platformBadgeLabel(platform), 'Plattform 0.0.1 Pre-Alpha');
    expect(projects.single.documents.map((f) => p.basename(f.path)), contains('MGD_PLATFORM.yml'));
  });

  test('Plattform ohne oder mit kaputter version.json bleibt ohne erfundene Version', () async {
    await platformProject('ohne-version');
    await platformProject('kaputt', versionJson: '{nicht json');
    await platformProject('falsches-format', versionJson: '{"version": "1.0", "status": "<b>x</b>"}');

    final projects = await ProjectScanner().scan(root.path);

    expect(projects.map((x) => x.name), ['falsches-format', 'kaputt', 'ohne-version']);
    for (final project in projects) {
      expect(project.platform, isNotNull, reason: project.name);
      expect(project.platform!.label, isNull, reason: project.name);
      expect(platformBadgeLabel(project.platform!), 'MGD-Plattform');
    }
  });

  test('version.json allein macht noch keine Plattform', () async {
    final dir = Directory(p.join(root.path, 'normal'));
    await dir.create();
    await Directory(p.join(dir.path, '.git')).create();
    await File(p.join(dir.path, 'version.json')).writeAsString('{"version": "1.2.3", "status": "stable"}');

    final projects = await ProjectScanner().scan(root.path);

    expect(projects.single.platform, isNull);
  });

  test('Status-Anzeige formatiert Bindestriche und LTS', () {
    expect(PlatformInfo.fromVersionJson({'version': '2.0.0', 'status': 'pre-release'}).label, '2.0.0 Pre-Release');
    expect(PlatformInfo.fromVersionJson({'version': '2.0.0', 'status': 'lts'}).label, '2.0.0 LTS');
    expect(PlatformInfo.fromVersionJson({'version': '2.0.0'}).label, '2.0.0');
    expect(PlatformInfo.fromVersionJson('kein Objekt').label, isNull);
  });
}
