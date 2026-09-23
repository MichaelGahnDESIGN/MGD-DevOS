import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';

const List<Color> _accentSwatches = [
  Color(0xFF2F6FED),
  Color(0xFF2E9E6E),
  Color(0xFFB8452D),
  Color(0xFF8B5CF6),
  Color(0xFFD9A441),
  Color(0xFF0EA5A5),
];

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.appState});

  final AppState appState;

  Future<void> _changeProjectsRoot(BuildContext context) async {
    final directory = await getDirectoryPath(
      confirmButtonText: 'Diesen Ordner verwenden',
    );
    if (directory != null) {
      await appState.setProjectsRoot(directory);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Einstellungen', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        Text('Darstellung', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.system,
              label: Text('System'),
              icon: Icon(Icons.brightness_auto),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              label: Text('Hell'),
              icon: Icon(Icons.light_mode),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text('Dunkel'),
              icon: Icon(Icons.dark_mode),
            ),
          ],
          selected: {appState.themeMode},
          onSelectionChanged: (selection) {
            appState.setThemeMode(selection.first);
          },
        ),
        const SizedBox(height: 24),
        Text('Akzentfarbe', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: _accentSwatches.map((color) {
            final selected = color.toARGB32() == appState.accentColor.toARGB32();
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => appState.setAccentColor(color),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: selected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                          width: 2,
                        )
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text('Projekt-Root', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(appState.projectsRoot ?? '(nicht gesetzt)'),
            ),
            OutlinedButton.icon(
              onPressed: () => _changeProjectsRoot(context),
              icon: const Icon(Icons.folder_open),
              label: const Text('Ändern'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Sicherheit',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'App-Sperre, Secret-Verwaltung über den OS-Schlüsselbund und '
          'eine sichere lokale Bridge zu Codex/Claude Code sind in dieser '
          'ersten Version noch nicht umgesetzt. MGD-DevOS speichert '
          'aktuell ausschließlich Darstellung und den Projekt-Root-Pfad '
          'lokal und liest keine Zugangsdaten.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
