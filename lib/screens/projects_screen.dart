import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../models/mgd_project.dart';
import 'document_viewer_screen.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final projects = appState.projects;
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Projekte',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (appState.lastScan != null)
                Text(
                  'Zuletzt gescannt: ${dateFormat.format(appState.lastScan!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Neu scannen',
                icon: const Icon(Icons.refresh),
                onPressed: appState.rescan,
              ),
            ],
          ),
        ),
        if (appState.projectsRoot != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Projekt-Root: ${appState.projectsRoot}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (appState.lastScanError != null)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Scan-Fehler: ${appState.lastScanError}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Expanded(
          child: projects.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Keine Projekte gefunden. Ein Projekt erkennt '
                      'MGD-DevOS an .git, README.md, AGENTS.md, '
                      'pubspec.yaml, package.json oder einer '
                      'PROJEKT/.mgd-ai-projektmanager.json.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    return _ProjectCard(
                      project: projects[index],
                      onOpenDashboard: projects[index].dashboardFile == null
                          ? null
                          : () => appState.openDashboard(projects[index]),
                      dateFormat: dateFormat,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.dateFormat,
    this.onOpenDashboard,
  });

  final MgdProject project;
  final VoidCallback? onOpenDashboard;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (onOpenDashboard != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilledButton.tonalIcon(
                      onPressed: onOpenDashboard,
                      icon: const Icon(Icons.dashboard_outlined, size: 16),
                      label: const Text('Dashboard öffnen'),
                    ),
                  ),
                if (project.lastModified != null)
                  Text(
                    dateFormat.format(project.lastModified!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              project.path,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (project.hasGit) const _Chip(label: 'Git'),
                if (project.hasLivingDocs) const _Chip(label: 'Living Docs'),
                if (project.hasDashboardConfig)
                  const _Chip(label: 'Dashboard-Konfiguration'),
                if (project.hasAgentsFile) const _Chip(label: 'AGENTS.md'),
                if (project.hasCapabilitiesCatalog)
                  const _Chip(label: 'Capabilities-Katalog'),
                if (project.hasIntegrationsCatalog)
                  const _Chip(label: 'Integrations-Katalog'),
                if (project.hasSkillsCatalog)
                  const _Chip(label: 'Skill-Katalog'),
              ],
            ),
            if (project.documents.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Dokumente',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: project.documents.map((file) {
                  final label = file.path
                      .substring(project.path.length)
                      .replaceFirst(RegExp(r'^[\\/]'), '');
                  return ActionChip(
                    avatar: const Icon(Icons.description_outlined, size: 16),
                    label: Text(label),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DocumentViewerScreen(file: file),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
