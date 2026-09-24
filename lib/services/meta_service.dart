import 'dart:convert';

import 'package:flutter/services.dart';

/// Zentrale Metadaten aus assets/meta (Quelle: scripts/sync_meta.py).
class AppMeta {
  const AppMeta({required this.version, required this.stage, required this.date, required this.scheme, required this.versions, required this.credits});

  final String version;
  final String stage;
  final String date;
  final String scheme;
  final List<VersionEntry> versions;
  final Credits credits;

  String get label => '$version $stage'.trim();

  static const empty = AppMeta(version: '?', stage: '', date: '', scheme: '', versions: [], credits: Credits(people: [], tools: []));

  static Future<AppMeta> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    try {
      final v = jsonDecode(await b.loadString('assets/meta/version.json', cache: false)) as Map<String, dynamic>;
      final list = jsonDecode(await b.loadString('assets/meta/versions.json', cache: false)) as List<dynamic>;
      final c = jsonDecode(await b.loadString('assets/meta/credits.json', cache: false)) as Map<String, dynamic>;
      return AppMeta(
        version: v['version'] as String,
        stage: (v['stage'] as String?) ?? '',
        date: (v['date'] as String?) ?? '',
        scheme: (v['scheme'] as String?) ?? '',
        versions: [for (final e in list) VersionEntry.fromJson(e as Map<String, dynamic>)],
        credits: Credits.fromJson(c),
      );
    } catch (_) {
      return empty; // Fehlende oder kaputte Metadaten dürfen den Start nicht verhindern.
    }
  }
}

class VersionEntry {
  const VersionEntry({required this.version, required this.date, required this.component, required this.notes});

  final String version;
  final String date;
  final String component;
  final List<String> notes;

  factory VersionEntry.fromJson(Map<String, dynamic> j) => VersionEntry(
        version: j['version'] as String,
        date: (j['date'] as String?) ?? '',
        component: (j['component'] as String?) ?? '',
        notes: [for (final n in (j['notes'] as List<dynamic>? ?? const [])) n as String],
      );
}

class Credits {
  const Credits({required this.people, required this.tools});

  final List<CreditPerson> people;
  final List<CreditTool> tools;

  factory Credits.fromJson(Map<String, dynamic> j) => Credits(
        people: [for (final p in (j['people'] as List<dynamic>? ?? const [])) CreditPerson.fromJson(p as Map<String, dynamic>)],
        tools: [for (final t in (j['tools'] as List<dynamic>? ?? const [])) CreditTool.fromJson(t as Map<String, dynamic>)],
      );
}

class CreditPerson {
  const CreditPerson({required this.name, required this.role, required this.links});
  final String name;
  final String role;
  final List<String> links;

  factory CreditPerson.fromJson(Map<String, dynamic> j) =>
      CreditPerson(name: j['name'] as String, role: (j['role'] as String?) ?? '', links: _links(j['links']));
}

class CreditTool {
  const CreditTool({required this.name, required this.category, required this.description, required this.provider, required this.links, required this.tags, this.notice, this.symbol});
  final String name;
  final String category;
  final String description;
  final String provider;
  final List<String> links;
  final List<String> tags;
  final String? notice;
  final String? symbol;

  factory CreditTool.fromJson(Map<String, dynamic> j) => CreditTool(
        name: j['name'] as String,
        category: (j['category'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
        provider: (j['provider'] as String?) ?? '',
        links: _links(j['links']),
        tags: [for (final t in (j['tags'] as List<dynamic>? ?? const [])) t as String],
        notice: j['notice'] as String?,
        symbol: j['symbol'] as String?,
      );
}

/// Nur https-Links übernehmen; alles andere (javascript:, file:, …) wird verworfen.
List<String> _links(Object? raw) => [
      for (final l in (raw as List<dynamic>? ?? const []))
        if (l is String && l.startsWith('https://')) l,
    ];
