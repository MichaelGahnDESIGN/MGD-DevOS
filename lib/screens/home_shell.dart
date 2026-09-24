import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme/app_theme.dart';
import 'agentic_control_panel_screen.dart';
import 'projects_screen.dart';
import 'settings_screen.dart';

/// Übersicht mit schmaler Icon-Leiste (wie in einem Desktop-Programm).
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.appState});

  final AppState appState;

  static const items = [
    (Icons.folder_outlined, Icons.folder, 'Projekte', '⌘ 1'),
    (Icons.hub_outlined, Icons.hub, 'Agentic Control Panel', '⌘ 2'),
    (Icons.tune_outlined, Icons.tune, 'Einstellungen', '⌘ 3'),
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
          width: 56,
          decoration: BoxDecoration(color: c.sidebar, border: Border(right: BorderSide(color: c.border))),
          padding: const EdgeInsets.symmetric(vertical: Space.md),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++)
                if (i < items.length - 1)
                  _RailButton(item: items[i], selected: index == i, onTap: () => appState.showOverviewSection(i))
                else ...[
                  const Spacer(),
                  _RailButton(item: items[i], selected: index == i, onTap: () => appState.showOverviewSection(i)),
                ],
            ],
          ),
        ),
        Expanded(child: pages[index]),
      ],
    );
  }
}

class _RailButton extends StatefulWidget {
  const _RailButton({required this.item, required this.selected, required this.onTap});

  final (IconData, IconData, String, String) item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_RailButton> createState() => _RailButtonState();
}

class _RailButtonState extends State<_RailButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final scheme = Theme.of(context).colorScheme;
    final (icon, selectedIcon, label, shortcut) = widget.item;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: '$label  $shortcut',
        preferBelow: false,
        verticalOffset: 0,
        margin: const EdgeInsets.only(left: 56),
        child: Semantics(
          button: true,
          selected: widget.selected,
          label: label,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: Motion.of(context, Motion.fast),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.selected || _hover ? scheme.surfaceContainerHighest : Colors.transparent,
                    borderRadius: BorderRadius.circular(Radii.sm + 2),
                    border: Border.all(color: widget.selected ? c.border : Colors.transparent),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Radii.sm + 2),
                    onTap: widget.onTap,
                    child: Icon(
                      widget.selected ? selectedIcon : icon,
                      size: 19,
                      color: widget.selected ? scheme.onSurface : c.muted,
                    ),
                  ),
                ),
                if (widget.selected)
                  Positioned(
                    left: -8,
                    top: 10,
                    bottom: 10,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
                      ),
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
