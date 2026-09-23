import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'agentic_control_panel_screen.dart';
import 'projects_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.appState});

  final AppState appState;

  static const _items = [
    (Icons.folder_outlined, Icons.folder, 'Projekte'),
    (Icons.hub_outlined, Icons.hub, 'Agentic Control Panel'),
    (Icons.tune_outlined, Icons.tune, 'Einstellungen'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final index = appState.overviewSection;
    final pages = [
      ProjectsScreen(appState: appState),
      AgenticControlPanelScreen(appState: appState),
      SettingsScreen(appState: appState),
    ];

    return Row(
      children: [
        Container(
          width: 240,
          decoration: BoxDecoration(
            color: c.sidebar,
            border: Border(right: BorderSide(color: c.border)),
          ),
          padding: const EdgeInsets.all(Space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(Space.sm, Space.md, Space.sm, Space.sm),
                child: SectionLabel('Übersicht'),
              ),
              for (var i = 0; i < _items.length; i++)
                _NavItem(
                  icon: _items[i].$1,
                  selectedIcon: _items[i].$2,
                  label: _items[i].$3,
                  selected: index == i,
                  badge: i == 0 && appState.projects.isNotEmpty ? '${appState.projects.length}' : null,
                  onTap: () => appState.showOverviewSection(i),
                ),
              const Spacer(),
              if (appState.projectsRoot != null)
                _RootInfo(appState: appState),
            ],
          ),
        ),
        Expanded(child: pages[index]),
      ],
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = context.colors;
    final fg = widget.selected ? context.accentText : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Semantics(
        selected: widget.selected,
        button: true,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: AnimatedContainer(
            duration: Motion.of(context, Motion.fast),
            decoration: BoxDecoration(
              color: widget.selected
                  ? scheme.primary.withValues(alpha: 0.10)
                  : _hover
                      ? scheme.surfaceContainerHighest
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(Radii.sm),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 10),
                child: Row(
                  children: [
                    Icon(widget.selected ? widget.selectedIcon : widget.icon, size: 18, color: widget.selected ? context.accentText : c.muted),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Text(
                        widget.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500, color: fg),
                      ),
                    ),
                    if (widget.badge != null) Badge2(label: widget.badge!),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RootInfo extends StatelessWidget {
  const _RootInfo({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Projektordner'),
          const SizedBox(height: Space.xs),
          Tooltip(
            message: appState.projectsRoot!,
            child: Text(
              appState.projectsRoot!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: c.muted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
