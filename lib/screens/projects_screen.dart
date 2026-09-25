import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../app_state.dart';
import '../models/mgd_project.dart';
import '../models/platform_info.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'document_viewer_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final app = widget.appState;
    final dateFormat = DateFormat('dd.MM.yyyy, HH:mm');
    final q = _query.toLowerCase();
    final projects = app.projects.where((x) => q.isEmpty || x.name.toLowerCase().contains(q)).toList();
    final dashboards = app.projects.where((x) => x.dashboardFile != null).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Projekte',
          subtitle: app.lastScan == null
              ? 'Noch nicht gescannt'
              : '${app.projects.length} Projekte · $dashboards mit Dashboard · zuletzt gescannt ${dateFormat.format(app.lastScan!)}',
          actions: [
            SizedBox(
              width: 240,
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, size: 18),
                  hintText: 'Projekte suchen',
                ),
              ),
            ),
            const SizedBox(width: Space.sm),
            IconButton.outlined(
              tooltip: 'Neu scannen',
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: app.rescan,
            ),
          ],
        ),
        if (app.lastScanError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.xxl),
            child: Badge2(label: 'Scan-Fehler: ${app.lastScanError}', tone: Tone.warning, icon: Icons.error_outline),
          ),
        Expanded(
          child: app.projects.isEmpty
              ? const EmptyState(
                  icon: Icons.folder_off_outlined,
                  title: 'Keine Projekte gefunden',
                  message: 'Ein Projekt ist ein Unterordner mit .git, README.md, AGENTS.md, pubspec.yaml, package.json oder PROJEKT/.mgd-ai-projektmanager.json oder MGD_PLATFORM.yml. Den Projektordner änderst du in den Einstellungen.',
                )
              : projects.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off,
                      title: 'Kein Treffer',
                      message: 'Kein Projekt enthält „$_query".',
                    )
                  : LayoutBuilder(
                      builder: (context, box) {
                        final cols = (box.maxWidth / 380).floor().clamp(1, 4);
                        return CustomScrollView(
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(Space.xxl, Space.sm, Space.xxl, Space.lg),
                              sliver: SliverGrid(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  mainAxisSpacing: Space.lg,
                                  crossAxisSpacing: Space.lg,
                                  mainAxisExtent: 220,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) => _ProjectCard(
                                    project: projects[i],
                                    dateFormat: dateFormat,
                                    onOpenDashboard: projects[i].dashboardFile == null
                                        ? null
                                        : () => app.openDashboard(projects[i]),
                                  ),
                                  childCount: projects.length,
                                ),
                              ),
                            ),
                            if (app.skippedFolders.isNotEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(Space.xxl, 0, Space.xxl, Space.xxl),
                                  child: _SkippedHint(names: app.skippedFolders),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

/// Text des Plattform-Badges in der Projektkarte, z. B. „Plattform 0.0.1 Pre-Alpha".
String platformBadgeLabel(PlatformInfo platform) {
  final label = platform.label;
  return label == null ? 'MGD-Plattform' : 'Plattform $label';
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.dateFormat, this.onOpenDashboard});

  final MgdProject project;
  final DateFormat dateFormat;
  final VoidCallback? onOpenDashboard;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final scheme = Theme.of(context).colorScheme;
    final platform = project.platform;
    final features = <(String, Tone)>[
      // Plattform-Stand zuerst, damit er bei vielen Merkmalen sichtbar bleibt.
      if (platform != null) (platformBadgeLabel(platform), Tone.accent),
      if (project.hasGit) ('Git', Tone.neutral),
      if (project.hasLivingDocs) ('Living Docs', Tone.neutral),
      if (project.hasAgentsFile) ('AGENTS.md', Tone.neutral),
      if (project.hasSkillsCatalog || project.hasCapabilitiesCatalog) ('Skills', Tone.neutral),
      if (project.hasIntegrationsCatalog) ('Integrationen', Tone.neutral),
      if (project.hasDashboardConfig) ('Projektmanager', Tone.accent),
    ];
    final initial = project.name.isEmpty ? '?' : project.name.characters.first.toUpperCase();

    return HoverCard(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Text(initial, style: TextStyle(color: context.accentText, fontWeight: FontWeight.w700, fontSize: 17)),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.name, style: t.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Tooltip(
                      message: project.path,
                      child: Text(
                        project.path,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          SizedBox(
            height: 22,
            // Bei schmalen Karten wird rechts abgeschnitten statt überzulaufen.
            child: ClipRect(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: [
                    for (final f in features.take(3)) ...[Badge2(label: f.$1, tone: f.$2), const SizedBox(width: 6)],
                    if (features.length > 3)
                      Tooltip(
                        message: features.skip(3).map((f) => f.$1).join(', '),
                        child: Badge2(label: '+${features.length - 3}'),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          if (project.lastModified != null)
            Text('Geändert ${dateFormat.format(project.lastModified!)}', style: t.bodySmall),
          const SizedBox(height: Space.md),
          Row(
            children: [
              if (onOpenDashboard != null)
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary.withValues(alpha: 0.12),
                    foregroundColor: context.accentText,
                  ),
                  onPressed: onOpenDashboard,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Dashboard öffnen'),
                )
              else
                Tooltip(
                  message: 'Kein Dashboard: Im Projekt fehlt eine index.html. Mit /dashboard im Assistenten anlegen.',
                  child: Text('Kein Dashboard', style: TextStyle(fontSize: 13, color: c.muted)),
                ),
              const Spacer(),
              if (project.documents.isNotEmpty) _DocsMenu(project: project),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocsMenu extends StatelessWidget {
  const _DocsMenu({required this.project});

  final MgdProject project;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        for (final file in project.documents)
          MenuItemButton(
            leadingIcon: const Icon(Icons.description_outlined, size: 18),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DocumentViewerScreen(file: file)),
            ),
            child: Text(p.relative(file.path, from: project.path)),
          ),
      ],
      builder: (context, controller, _) => Tooltip(
        message: 'Dokumente öffnen',
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: Space.md)),
          onPressed: () => controller.isOpen ? controller.close() : controller.open(),
          icon: const Icon(Icons.description_outlined, size: 16),
          label: Text('${project.documents.length}'),
        ),
      ),
    );
  }
}

class _SkippedHint extends StatelessWidget {
  const _SkippedHint({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        leading: Icon(Icons.visibility_off_outlined, size: 18, color: c.muted),
        title: Text(
          '${names.length} ${names.length == 1 ? 'Ordner' : 'Ordner'} ohne Projektmerkmal ausgeblendet',
          style: TextStyle(fontSize: 13, color: c.muted),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(spacing: 6, runSpacing: 6, children: [for (final n in names) Badge2(label: n)]),
          ),
        ],
      ),
    );
  }
}
