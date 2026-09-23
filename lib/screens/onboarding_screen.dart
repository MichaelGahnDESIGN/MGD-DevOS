import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../app_state.dart';

/// Standard-Entwicklungspfad, falls der Nutzer beim ersten Start keinen
/// eigenen Projekt-Root auswählt. Wird dokumentiert (siehe README.md) und
/// kann in den Einstellungen jederzeit geändert werden.
String defaultProjectsRoot() =>
    p.join(Platform.environment['HOME'] ?? '.', 'Developer');

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final TextEditingController _pathController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController(
      text: widget.appState.projectsRoot ?? defaultProjectsRoot(),
    );
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _pickFolder() async {
    final directory = await getDirectoryPath(
      confirmButtonText: 'Diesen Ordner verwenden',
    );
    if (directory != null) {
      setState(() => _pathController.text = directory);
    }
  }

  Future<void> _finish() async {
    final chosen = _pathController.text.trim();
    if (chosen.isEmpty) return;
    setState(() => _saving = true);
    await widget.appState.completeOnboarding(chosen);
    if (!mounted) return;
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Willkommen bei MGD-DevOS',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'MGD-DevOS ist deine lokale Projektzentrale: Projekte, '
                  'Living Documentation, Skills, MCP-Verbindungen und '
                  'Agenten an einem ruhigen Ort. Alle Daten bleiben auf '
                  'diesem Rechner.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Text(
                  'Wo liegen deine Projekte?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Wähle den Ordner, der deine Projekt-Unterordner enthält '
                  '(z. B. einen Ordner mit mehreren Git-Repositories). '
                  'MGD-DevOS liest diesen Ordner nur; nichts wird '
                  'automatisch verändert.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _pathController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Projekt-Root-Pfad',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _pickFolder,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Wählen'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _finish,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward),
                    label: const Text('Loslegen'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
