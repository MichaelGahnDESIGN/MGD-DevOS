import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../app_state.dart';
import '../services/project_scanner.dart';
import '../theme/app_theme.dart';
import '../widgets/supported_by_footer.dart';
import '../widgets/ui.dart';

/// Standard-Entwicklungspfad, falls der Nutzer beim ersten Start keinen
/// eigenen Projekt-Root auswählt. In den Einstellungen jederzeit änderbar.
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
  Timer? _debounce;
  bool _saving = false;
  int? _detected;
  bool _exists = true;

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController(
      text: widget.appState.projectsRoot ?? defaultProjectsRoot(),
    );
    _preview();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pathController.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _preview);
  }

  Future<void> _preview() async {
    final path = _pathController.text.trim();
    final exists = path.isNotEmpty && await Directory(path).exists();
    final found = exists ? (await ProjectScanner().scan(path)).length : null;
    if (!mounted || path != _pathController.text.trim()) return;
    setState(() {
      _exists = exists;
      _detected = found;
    });
  }

  Future<void> _pickFolder() async {
    final directory = await getDirectoryPath(
      confirmButtonText: 'Diesen Ordner verwenden',
      initialDirectory: _exists ? _pathController.text.trim() : null,
    );
    if (directory != null) {
      _pathController.text = directory;
      await _preview();
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
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                if (wide) const Expanded(flex: 5, child: _BrandPanel()),
                Expanded(flex: 6, child: _form(context)),
              ],
            ),
          ),
          const SupportedByFooter(),
        ],
      ),
    );
  }

  Widget _form(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final status = !_exists
        ? Badge2(label: 'Ordner nicht gefunden', tone: Tone.warning, icon: Icons.error_outline)
        : _detected == null
            ? const Badge2(label: 'Prüfe Ordner …')
            : _detected == 0
                ? const Badge2(label: 'Keine Projekte erkannt', tone: Tone.warning, icon: Icons.info_outline)
                : Badge2(
                    label: '$_detected ${_detected == 1 ? 'Projekt' : 'Projekte'} erkannt',
                    tone: Tone.success,
                    icon: Icons.check_circle_outline,
                  );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Schritt 1 von 1'),
              const SizedBox(height: Space.sm),
              Semantics(
                header: true,
                child: Text('Willkommen bei MGD-DevOS', style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.6)),
              ),
              const SizedBox(height: Space.md),
              Text(
                'Wähle den Ordner, in dem deine Projekte liegen. MGD-DevOS liest ihn nur und verändert nichts.',
                style: t.bodyLarge?.copyWith(color: c.muted, height: 1.5),
              ),
              const SizedBox(height: Space.xxl),
              Text('Projektordner', style: t.labelLarge),
              const SizedBox(height: Space.sm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pathController,
                      onChanged: _onChanged,
                      onSubmitted: (_) => _finish(),
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.folder_outlined, size: 18),
                        hintText: '/Pfad/zu/deinen/Projekten',
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  OutlinedButton(
                    onPressed: _pickFolder,
                    child: const Text('Wählen'),
                  ),
                ],
              ),
              const SizedBox(height: Space.md),
              AnimatedSwitcher(duration: Motion.of(context, Motion.normal), child: KeyedSubtree(key: ValueKey('$_exists$_detected'), child: status)),
              const SizedBox(height: Space.sm),
              Text(
                'Erkannt wird ein Unterordner mit .git, README.md, AGENTS.md, pubspec.yaml, package.json oder PROJEKT/.mgd-ai-projektmanager.json.',
                style: t.bodySmall,
              ),
              const SizedBox(height: Space.xxl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _finish,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  child: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Text('Loslegen'), SizedBox(width: Space.sm), Icon(Icons.arrow_forward, size: 18)],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    const fg = Colors.white;
    Widget item(IconData icon, String title, String text) => Padding(
          padding: const EdgeInsets.only(bottom: Space.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: fg.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Radii.sm)),
                child: Icon(icon, color: fg, size: 18),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(text, style: TextStyle(color: fg.withValues(alpha: 0.72), fontSize: 13.5, height: 1.45)),
                  ],
                ),
              ),
            ],
          ),
        );

    return Container(
      color: const Color(0xFF111827),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            BrandMark(size: 36),
            SizedBox(width: Space.md),
            Text('MGD-DevOS', style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
          ]),
          const Spacer(),
          const Text(
            'Deine Projekte.\nEin Fenster.',
            style: TextStyle(color: fg, fontSize: 40, height: 1.1, fontWeight: FontWeight.w700, letterSpacing: -1.2),
          ),
          const SizedBox(height: Space.lg),
          Container(width: 48, height: 4, decoration: BoxDecoration(color: Brand.red, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: Space.xxl),
          item(Icons.tab_outlined, 'Dashboards in Tabs', 'Wechsle zwischen den Dashboards aller Projekte wie in einem Browser.'),
          item(Icons.hub_outlined, 'Agenten und Skills im Blick', 'Sieh, welche Agenten, Skills und Integrationen deine Projekte nutzen.'),
          item(Icons.lock_outline, 'Lokal und privat', 'Keine Konten, keine Telemetrie. Deine Daten bleiben auf diesem Rechner.'),
          const Spacer(),
        ],
      ),
    );
  }
}
