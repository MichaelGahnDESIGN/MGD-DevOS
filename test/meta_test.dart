import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mgd_devos/services/meta_service.dart';

class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(await File(key).readAsBytes());
}

void main() {
  test('Metadaten laden: Version, Timeline, Credits, nur https-Links', () async {
    final meta = await AppMeta.load(_DiskBundle());
    final v = jsonDecode(File('assets/meta/version.json').readAsStringSync()) as Map<String, dynamic>;
    expect(meta.version, v['version']);
    expect(meta.label, '${v['version']} ${v['stage']}');
    expect(meta.versions, isNotEmpty);
    expect(meta.versions.first.version, v['version'], reason: 'Neueste Version steht oben in der Timeline');
    expect(meta.credits.people, isNotEmpty);
    expect(meta.credits.tools.any((t) => t.name.startsWith('Inter')), isTrue);
    for (final t in meta.credits.tools) {
      expect(t.links.every((l) => l.startsWith('https://')), isTrue);
    }
  });

  test('pubspec.yaml trägt dieselbe Version wie assets/meta/version.json', () {
    final v = jsonDecode(File('assets/meta/version.json').readAsStringSync()) as Map<String, dynamic>;
    expect(File('pubspec.yaml').readAsStringSync(), contains('version: ${v['version']}+${v['build']}'));
  });
}
