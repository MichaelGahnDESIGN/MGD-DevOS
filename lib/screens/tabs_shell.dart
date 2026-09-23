import 'package:flutter/material.dart';

import '../app_state.dart';
import 'dashboard_tab_view.dart';
import 'home_shell.dart';

/// Browser-artige Hülle: Tab 0 ist die Übersicht (Projektauswahl), weitere
/// Tabs zeigen die lokalen Dashboards einzelner Projekte.
class TabsShell extends StatelessWidget {
  const TabsShell({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final tabs = appState.dashboardTabs;
    final active = appState.activeTabIndex;

    return Scaffold(
      body: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _TabChip(
                    label: 'Übersicht',
                    icon: Icons.dashboard_outlined,
                    selected: active == 0,
                    onTap: () => appState.selectTab(0),
                  ),
                  for (var i = 0; i < tabs.length; i++)
                    _TabChip(
                      label: tabs[i].projectName,
                      icon: Icons.folder_open,
                      selected: active == i + 1,
                      onTap: () => appState.selectTab(i + 1),
                      onClose: () => appState.closeTab(i + 1),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
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
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? scheme.surface : null,
          border: Border(
            bottom: BorderSide(
              color: selected ? scheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(label),
            if (onClose != null) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: onClose,
                child: const Icon(Icons.close, size: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
