import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
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

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.appState});

  final AppState appState;

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
    return ListView(
      padding: const EdgeInsets.only(bottom: Space.xxl),
      children: [
        const PageHeader(title: 'Einstellungen', subtitle: 'Darstellung, Projektordner und Informationen'),
        _Section(
          title: 'Darstellung',
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
        ),
        _Section(
          title: 'Projekte',
          children: [
            _Row(
              label: 'Projektordner',
              hint: appState.projectsRoot ?? 'Nicht gesetzt',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: appState.rescan,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Neu scannen'),
                  ),
                  const SizedBox(width: Space.sm),
                  FilledButton.icon(
                    onPressed: _changeProjectsRoot,
                    icon: const Icon(Icons.folder_open_outlined, size: 16),
                    label: const Text('Ändern'),
                  ),
                ],
              ),
            ),
          ],
        ),
        _Section(
          title: 'Datenschutz und Sicherheit',
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 20, color: c.success),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Text(
                    'Alles bleibt lokal: keine Konten, keine Telemetrie, keine Zugangsdaten. Gespeichert werden nur Farbschema, Akzentfarbe und der Projektordner. '
                    'App-Sperre und Schlüsselbund-Verwaltung sind geplant.',
                    style: TextStyle(fontSize: 13.5, height: 1.5, color: c.muted),
                  ),
                ),
              ],
            ),
          ],
        ),
        _Section(
          title: 'Über',
          children: [
            Row(
              children: [
                const BrandMark(size: 40),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MGD-DevOS', style: Theme.of(context).textTheme.titleMedium),
                      Text('Lizenz: PolyForm Noncommercial 1.0.0', style: TextStyle(fontSize: 12.5, color: c.muted)),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse('https://github.com/MichaelGahnDESIGN/MGD-DevOS'),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('GitHub'),
                ),
              ],
            ),
          ],
        ),
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
