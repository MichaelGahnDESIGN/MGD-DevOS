import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/supported_by_footer.dart';
import '../widgets/ui.dart';
import 'dashboard_tab_view.dart';
import 'home_shell.dart';

/// Browser-artige Hülle: Tab „Übersicht" plus je ein Tab pro geöffnetem
/// Projekt-Dashboard. Einstellungen oben rechts.
class TabsShell extends StatelessWidget {
  const TabsShell({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final tabs = appState.dashboardTabs;
    final active = appState.activeTabIndex;
    final c = context.colors;

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: c.sidebar,
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: Space.md),
            child: Row(
              children: [
                const BrandMark(size: 22),
                const SizedBox(width: Space.md),
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _Tab(
                        label: 'Übersicht',
                        icon: Icons.space_dashboard_outlined,
                        selected: active == 0,
                        onTap: () => appState.selectTab(0),
                      ),
                      for (var i = 0; i < tabs.length; i++)
                        _Tab(
                          label: tabs[i].projectName,
                          icon: Icons.web_asset_outlined,
                          selected: active == i + 1,
                          onTap: () => appState.selectTab(i + 1),
                          onClose: () => appState.closeTab(i + 1),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Einstellungen',
                  icon: const Icon(Icons.settings_outlined, size: 20),
                  onPressed: () => appState.showOverviewSection(2),
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: active,
              children: [
                HomeShell(appState: appState),
                for (final tab in tabs)
                  DashboardTabView(key: ValueKey(tab.id), tab: tab),
              ],
            ),
          ),
          const SupportedByFooter(),
        ],
      ),
    );
  }
}

class _Tab extends StatefulWidget {
  const _Tab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.onClose,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onClose;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final scheme = Theme.of(context).colorScheme;
    final bg = widget.selected
        ? scheme.surfaceContainerHighest
        : _hover
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : Colors.transparent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
      child: Semantics(
        selected: widget.selected,
        button: true,
        label: 'Tab ${widget.label}',
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: AnimatedContainer(
            duration: Motion.of(context, Motion.fast),
            constraints: const BoxConstraints(maxWidth: 220),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Radii.sm)),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(Radii.sm),
              child: Padding(
                padding: EdgeInsets.only(left: Space.md, right: widget.onClose == null ? Space.md : Space.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 16, color: widget.selected ? context.accentText : c.muted),
                    const SizedBox(width: Space.sm),
                    Flexible(
                      child: Text(
                        widget.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                          color: widget.selected ? scheme.onSurface : c.muted,
                        ),
                      ),
                    ),
                    if (widget.onClose != null) ...[
                      const SizedBox(width: 2),
                      IconButton(
                        tooltip: '${widget.label} schließen',
                        onPressed: widget.onClose,
                        visualDensity: VisualDensity.compact,
                        iconSize: 14,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        icon: const Icon(Icons.close),
                      ),
                    ],
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
