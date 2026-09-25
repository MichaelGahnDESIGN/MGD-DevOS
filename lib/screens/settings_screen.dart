import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../services/meta_service.dart';
import '../services/pin_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

const List<(Color, String)> _accentSwatches = [
  (Brand.red, 'MGD-Rot'),
  (Color(0xFF2F6FED), 'Blau'),
  (Color(0xFF0F9F6E), 'Grün'),
  (Color(0xFF7C3AED), 'Violett'),
  (Color(0xFFD97706), 'Bernstein'),
  (Color(0xFF0E7490), 'Petrol'),
];

/// Einstellungen mit Suche und Bereichsleiste. Bei einer Suche werden alle passenden Bereiche
/// untereinander angezeigt, sonst nur der gewählte.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _query = '';
  String _section = 'darstellung';

  AppState get appState => widget.appState;

  Future<void> _changeProjectsRoot() async {
    final directory = await getDirectoryPath(
      confirmButtonText: 'Diesen Ordner verwenden',
      initialDirectory: appState.projectsRoot,
    );
    if (directory != null) await appState.setProjectsRoot(directory);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // (id, Titel, Suchbegriffe, Inhalt)
    final sections = <(String, String, String, Widget Function())>[
      ('darstellung', 'Darstellung', 'farbschema hell dunkel system akzentfarbe theme', _appearance),
      ('projekte', 'Projekte', 'projektordner scannen pfad ordner', _projects),
      ('grundregeln', 'Grundregeln', 'regeln editor grundregeln.md bearbeiten', () => _RulesEditor(appState: appState)),
      ('sicherheit', 'Sicherheit', 'pin sperre schutz passwort sicherheit', () => _PinSettings(appState: appState)),
      ('datenschutz', 'Datenschutz', 'datenschutz telemetrie lokal privat', _privacy),
      ('versionen', 'Versionen', 'version timeline changelog versionshinweise', () => _Versions(meta: appState.meta)),
      ('ueber', 'Über', 'über version lizenz github', _about),
      ('credits', 'Credits', 'credits personen tools bibliotheken schriften icons lizenzen', () => _CreditsView(meta: appState.meta)),
    ];
    final q = _query.trim().toLowerCase();
    final hits = sections.where((s) => q.isEmpty || '${s.$2} ${s.$3}'.toLowerCase().contains(q)).toList();
    final shown = q.isEmpty ? sections.where((s) => s.$1 == _section).toList() : hits;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Einstellungen',
          subtitle: 'MGD-DevOS ${appState.meta.label}',
          actions: [
            SizedBox(
              width: 260,
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 18), hintText: 'Einstellungen durchsuchen'),
              ),
            ),
          ],
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 200,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(Space.xxl, 0, 0, Space.xl),
                  children: [
                    for (final s in sections)
                      if (q.isEmpty || hits.contains(s))
                        _NavEntry(
                          label: s.$2,
                          selected: q.isEmpty && s.$1 == _section,
                          onTap: () => setState(() {
                            _section = s.$1;
                            _query = '';
                          }),
                        ),
                  ],
                ),
              ),
              Expanded(
                child: shown.isEmpty
                    ? Padding(padding: const EdgeInsets.all(Space.xxl), child: Text('Keine Einstellung gefunden.', style: TextStyle(color: c.muted)))
                    : ListView(
                        padding: const EdgeInsets.only(bottom: Space.xxl),
                        children: [for (final s in shown) _Section(title: s.$2, children: [s.$4()])],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _appearance() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row(
            label: 'Farbschema',
            hint: 'Folgt standardmäßig deinem System.',
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto_outlined, size: 16)),
                ButtonSegment(value: ThemeMode.light, label: Text('Hell'), icon: Icon(Icons.light_mode_outlined, size: 16)),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dunkel'), icon: Icon(Icons.dark_mode_outlined, size: 16)),
              ],
              selected: {appState.themeMode},
              onSelectionChanged: (s) => appState.setThemeMode(s.first),
            ),
          ),
          const Divider(height: Space.xl),
          _Row(
            label: 'Akzentfarbe',
            hint: 'Für Auswahl, Buttons und Markierungen.',
            child: Wrap(
              spacing: Space.sm,
              children: [
                for (final (color, name) in _accentSwatches)
                  _Swatch(
                    color: color,
                    name: name,
                    selected: color.toARGB32() == appState.accentColor.toARGB32(),
                    onTap: () => appState.setAccentColor(color),
                  ),
              ],
            ),
          ),
        ],
      );

  Widget _projects() => _Row(
        label: 'Projektordner',
        hint: appState.projectsRoot ?? 'Nicht gesetzt',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(onPressed: appState.rescan, icon: const Icon(Icons.refresh, size: 16), label: const Text('Neu scannen')),
            const SizedBox(width: Space.sm),
            FilledButton.icon(onPressed: _changeProjectsRoot, icon: const Icon(Icons.folder_open_outlined, size: 16), label: const Text('Ändern')),
          ],
        ),
      );

  Widget _privacy() {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_outlined, size: 20, color: c.success),
        const SizedBox(width: Space.md),
        Expanded(
          child: Text(
            'Alles bleibt lokal: keine Konten, keine Telemetrie, keine Zugangsdaten. Gespeichert werden nur Farbschema, '
            'Akzentfarbe, Projektordner und – falls gesetzt – der Hash deiner PIN.',
            style: TextStyle(fontSize: 13.5, height: 1.5, color: c.muted),
          ),
        ),
      ],
    );
  }

  Widget _about() {
    final c = context.colors;
    return Row(
      children: [
        const BrandMark(size: 40),
        const SizedBox(width: Space.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MGD-DevOS ${appState.meta.label}', style: Theme.of(context).textTheme.titleMedium),
              Text('Stand ${appState.meta.date} · Lizenz: PolyForm Noncommercial 1.0.0', style: TextStyle(fontSize: 12.5, color: c.muted)),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () => launchUrl(Uri.parse('https://github.com/MichaelGahnDESIGN/MGD-DevOS'), mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text('GitHub'),
        ),
      ],
    );
  }
}

class _NavEntry extends StatelessWidget {
  const _NavEntry({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected ? scheme.primary.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.sm),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 9),
            child: Text(label, style: TextStyle(fontSize: 13.5, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: selected ? context.accentText : scheme.onSurface)),
          ),
        ),
      ),
    );
  }
}

/// Bearbeitet GRUNDREGELN.md eines gewählten Projekts. Schreibt ausschließlich diese eine Datei
/// im Projekt-Hauptordner und erst nach Bestätigung.
class _RulesEditor extends StatefulWidget {
  const _RulesEditor({required this.appState});
  final AppState appState;

  @override
  State<_RulesEditor> createState() => _RulesEditorState();
}

class _RulesEditorState extends State<_RulesEditor> {
  final _text = TextEditingController();
  String? _projectPath;
  String? _status;
  bool _dirty = false;

  static const fileName = 'GRUNDREGELN.md';

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  File get _file => File(p.join(_projectPath!, fileName));

  // Zähler verwirft Ergebnisse älterer Ladevorgänge, falls schnell zwischen Projekten gewechselt wird.
  int _loadId = 0;
  bool _loaded = false;

  Future<void> _load(String path) async {
    final id = ++_loadId;
    setState(() {
      _projectPath = path;
      _loaded = false;
      _dirty = false;
      _status = 'Lade …';
      _text.clear();
    });
    final f = File(p.join(path, fileName));
    try {
      final exists = await f.exists();
      final content = exists
          ? await f.readAsString()
          : '# Grundregeln\n\n- Antworte auf Deutsch, einfach und knapp.\n- Keine Secrets lesen oder ausgeben.\n- Installationen, Pushes und Löschungen nur nach Freigabe.\n';
      if (!mounted || id != _loadId) return;
      setState(() {
        _text.text = content;
        _loaded = true;
        _status = exists ? 'Geladen: ${f.path}' : 'Noch keine $fileName, Vorschlag geladen.';
      });
    } catch (e) {
      if (!mounted || id != _loadId) return;
      setState(() => _status = 'Datei konnte nicht gelesen werden: $e');
    }
  }

  Future<void> _save() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Grundregeln speichern?'),
        content: Text('Schreibt ${_file.path}. Eine bestehende Datei wird überschrieben.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Speichern')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _file.writeAsString(_text.text);
      if (!mounted) return;
      setState(() {
        _dirty = false;
        _status = 'Gespeichert: ${_file.path}';
      });
    } catch (e) {
      if (mounted) setState(() => _status = 'Speichern fehlgeschlagen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final projects = widget.appState.projects;
    if (projects.isEmpty) {
      return Text('Kein Projekt gefunden. Lege zuerst einen Projektordner fest.', style: TextStyle(color: c.muted));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Grundregeln gelten für alle Assistenten in einem Projekt ($fileName im Projekt-Hauptordner).', style: TextStyle(fontSize: 13, color: c.muted)),
        const SizedBox(height: Space.md),
        DropdownButton<String>(
          value: _projectPath,
          hint: const Text('Projekt wählen'),
          items: [for (final pr in projects) DropdownMenuItem(value: pr.path, child: Text(pr.name))],
          onChanged: (v) {
            if (v != null) _load(v);
          },
        ),
        if (_projectPath != null) ...[
          const SizedBox(height: Space.md),
          TextField(
            controller: _text,
            enabled: _loaded,
            minLines: 10,
            maxLines: 20,
            onChanged: (_) => setState(() => _dirty = true),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5),
            decoration: const InputDecoration(),
          ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              FilledButton.icon(onPressed: _dirty && _loaded ? _save : null, icon: const Icon(Icons.save_outlined, size: 16), label: const Text('Speichern')),
              const SizedBox(width: Space.sm),
              OutlinedButton(onPressed: () => _load(_projectPath!), child: const Text('Neu laden')),
            ],
          ),
        ],
        if (_status != null) ...[const SizedBox(height: Space.sm), Text(_status!, style: TextStyle(fontSize: 12, color: c.muted))],
      ],
    );
  }
}

/// PIN festlegen, ändern oder deaktivieren. Ändern und Deaktivieren nur mit aktueller PIN.
class _PinSettings extends StatefulWidget {
  const _PinSettings({required this.appState});
  final AppState appState;

  @override
  State<_PinSettings> createState() => _PinSettingsState();
}

class _PinSettingsState extends State<_PinSettings> {
  final _cur = TextEditingController();
  final _new = TextEditingController();
  final _rep = TextEditingController();
  int _len = 6;
  String? _msg;
  bool _busy = false;

  @override
  void dispose() {
    _cur.dispose();
    _new.dispose();
    _rep.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      await action();
      await widget.appState.refreshPinState();
      _cur.clear();
      _new.clear();
      _rep.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      _msg = e is StateError ? e.message : (e is ArgumentError ? '${e.message}' : '$e');
    }
    if (mounted) setState(() => _busy = false);
  }

  void _set() {
    if (!PinService.isValid(_new.text, _len)) return setState(() => _msg = 'Die PIN muss genau $_len Ziffern haben.');
    if (_new.text != _rep.text) return setState(() => _msg = 'Die Wiederholung stimmt nicht überein.');
    final active = widget.appState.pinLength != null;
    _run(() => widget.appState.pin.setPin(_new.text, _len, current: active ? _cur.text : null), 'PIN gespeichert. Bitte sicher notieren!');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final active = widget.appState.pinLength;
    Widget pinField(TextEditingController ctl, String label, int maxLen) => SizedBox(
          width: 220,
          child: TextField(
            controller: ctl,
            obscureText: true,
            maxLength: maxLen,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: label, counterText: ''),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Die PIN sperrt MGD-DevOS beim Start. Sie schützt vor Blicken, ersetzt aber nicht die Anmeldung am Rechner und verschlüsselt keine Projektdateien.',
            style: TextStyle(fontSize: 13, color: c.muted, height: 1.5)),
        const SizedBox(height: Space.md),
        Badge2(label: active == null ? 'Keine PIN' : 'PIN aktiv ($active Stellen)', tone: active == null ? Tone.neutral : Tone.success),
        const SizedBox(height: Space.lg),
        if (active != null) ...[pinField(_cur, 'Aktuelle PIN', active), const SizedBox(height: Space.md)],
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [for (final l in PinService.allowedLengths) ButtonSegment(value: l, label: Text('$l Stellen'))],
          selected: {_len},
          onSelectionChanged: (v) => setState(() => _len = v.first),
        ),
        const SizedBox(height: Space.md),
        Wrap(spacing: Space.md, runSpacing: Space.md, children: [pinField(_new, 'Neue PIN', _len), pinField(_rep, 'Neue PIN wiederholen', _len)]),
        const SizedBox(height: Space.md),
        Container(
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(color: c.warning.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(Radii.sm), border: Border.all(color: c.warning.withValues(alpha: 0.5))),
          child: Text(
            'Wichtig: Schreib dir die PIN auf oder speichere sie in deinem Passwort-Manager. Ohne PIN kommst du nur wieder hinein, '
            'wenn du die App-Einstellungen löschst (dabei gehen auch Projektordner und Darstellung verloren).',
            style: TextStyle(fontSize: 13, height: 1.45),
          ),
        ),
        const SizedBox(height: Space.md),
        Row(
          children: [
            FilledButton(onPressed: _busy ? null : _set, child: Text(active == null ? 'PIN festlegen' : 'PIN ändern')),
            if (active != null) ...[
              const SizedBox(width: Space.sm),
              OutlinedButton(
                onPressed: _busy ? null : () => _run(() => widget.appState.pin.disable(_cur.text), 'PIN deaktiviert'),
                child: const Text('PIN deaktivieren'),
              ),
            ],
            if (_busy) ...[const SizedBox(width: Space.md), const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))],
          ],
        ),
        if (_msg != null) ...[const SizedBox(height: Space.sm), Text(_msg!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13))],
      ],
    );
  }
}

class _Versions extends StatefulWidget {
  const _Versions({required this.meta});
  final AppMeta meta;

  @override
  State<_Versions> createState() => _VersionsState();
}

class _VersionsState extends State<_Versions> {
  String? _component;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final comps = {for (final v in widget.meta.versions) v.component}.toList();
    final list = widget.meta.versions.where((v) => _component == null || v.component == _component).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aktuell: ${widget.meta.label}. Schema: ${widget.meta.scheme}', style: TextStyle(fontSize: 13, color: c.muted, height: 1.45)),
        const SizedBox(height: Space.md),
        Wrap(spacing: Space.sm, children: [
          ChoiceChip(label: const Text('Alle'), selected: _component == null, onSelected: (_) => setState(() => _component = null)),
          for (final comp in comps) ChoiceChip(label: Text(comp), selected: _component == comp, onSelected: (_) => setState(() => _component = comp)),
        ]),
        const SizedBox(height: Space.md),
        for (final v in list)
          Container(
            margin: const EdgeInsets.only(bottom: Space.md),
            padding: const EdgeInsets.only(left: Space.md),
            decoration: BoxDecoration(border: Border(left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(v.version, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(width: Space.sm),
                  Badge2(label: v.component),
                  const SizedBox(width: Space.sm),
                  Text(v.date, style: TextStyle(fontSize: 12, color: c.muted)),
                ]),
                for (final n in v.notes) Padding(padding: const EdgeInsets.only(top: 3), child: Text('• $n', style: TextStyle(fontSize: 13, color: c.muted, height: 1.45))),
              ],
            ),
          ),
      ],
    );
  }
}

class _CreditsView extends StatelessWidget {
  const _CreditsView({required this.meta});
  final AppMeta meta;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget symbol(String s) => Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Radii.sm)),
          child: Text(s.isEmpty ? '?' : s.characters.first.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w700, color: context.accentText)),
        );
    Widget links(List<String> l) => Wrap(spacing: Space.sm, children: [
          for (final url in l)
            InkWell(
              onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
              child: Text(url.replaceFirst('https://', ''), style: TextStyle(fontSize: 12.5, color: context.accentText, decoration: TextDecoration.underline)),
            ),
        ]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Personen'),
        for (final pr in meta.credits.people)
          ListTile(contentPadding: EdgeInsets.zero, leading: symbol(pr.name), title: Text(pr.name), subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(pr.role), links(pr.links)])),
        const SizedBox(height: Space.md),
        const SectionLabel('KI-Systeme, Werkzeuge, Bibliotheken, Schriften, Icons'),
        for (final t in meta.credits.tools)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                symbol(t.name),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [Flexible(child: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600))), const SizedBox(width: Space.sm), Badge2(label: t.category)]),
                      Text(t.description, style: const TextStyle(height: 1.45)),
                      Text('Anbieter: ${t.provider}${t.notice != null ? ' · ${t.notice}' : ''}', style: TextStyle(fontSize: 12.5, color: c.muted)),
                      links(t.links),
                      const SizedBox(height: 4),
                      Wrap(spacing: 6, runSpacing: 4, children: [for (final g in t.tags) Badge2(label: g)]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: Space.sm),
        Text('Die Liste stammt aus assets/meta/credits.json im Repository und wird dort gepflegt.', style: TextStyle(fontSize: 12, color: c.muted)),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.xxl, 0, Space.xxl, Space.xl),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(bottom: Space.sm), child: SectionLabel(title)),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Space.xl),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(color: c.border),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child, this.hint});

  final String label;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: Space.md,
      spacing: Space.xl,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
              if (hint != null) ...[
                const SizedBox(height: 2),
                Text(hint!, style: TextStyle(fontSize: 12.5, color: c.muted), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.name, required this.selected, required this.onTap});

  final Color color;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: name,
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Akzentfarbe $name',
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          child: AnimatedContainer(
            duration: Motion.of(context, Motion.fast),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                width: 2,
              ),
            ),
            child: selected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
          ),
        ),
      ),
    );
  }
}
