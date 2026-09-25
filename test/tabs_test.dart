import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:mgd_devos/app_state.dart';
import 'package:mgd_devos/models/mgd_project.dart';
import 'package:mgd_devos/screens/dashboard_tab_view.dart';

MgdProject _project(String name, {bool withDashboard = true}) {
  final dir = Directory('/tmp/$name');
  return MgdProject(
    name: name,
    directory: dir,
    hasGit: true,
    hasLivingDocs: false,
    hasDashboardConfig: false,
    hasAgentsFile: false,
    hasCapabilitiesCatalog: false,
    hasIntegrationsCatalog: false,
    hasSkillsCatalog: false,
    dashboardFile: withDashboard ? File(p.join(dir.path, 'index.html')) : null,
    lastModified: null,
    documents: const [],
  );
}

void main() {
  test('openDashboard öffnet Tab und wechselt dorthin, ohne Duplikate', () {
    final state = AppState();
    final a = _project('a');
    final b = _project('b');

    state.openDashboard(a);
    state.openDashboard(b);
    state.openDashboard(a);

    expect(state.dashboardTabs.map((t) => t.projectName), ['a', 'b']);
    expect(state.activeTabIndex, 1);
  });

  test('Projekt ohne index.html öffnet keinen Tab', () {
    final state = AppState();
    state.openDashboard(_project('x', withDashboard: false));
    expect(state.dashboardTabs, isEmpty);
    expect(state.activeTabIndex, 0);
  });

  test('closeTab entfernt Tab und wählt Nachbarn; Übersicht nicht schließbar',
      () {
    final state = AppState();
    state.openDashboard(_project('a'));
    state.openDashboard(_project('b'));

    state.closeTab(0);
    expect(state.dashboardTabs, hasLength(2));

    state.closeTab(2);
    expect(state.dashboardTabs.map((t) => t.projectName), ['a']);
    expect(state.activeTabIndex, 1);

    state.closeTab(1);
    expect(state.dashboardTabs, isEmpty);
    expect(state.activeTabIndex, 0);
  });

  test('Navigation nur innerhalb des Projektordners erlaubt', () {
    expect(
      DashboardTabView.isInsideProject(
          Uri.file('/proj/a/index.html'), '/proj/a'),
      isTrue,
    );
    expect(
      DashboardTabView.isInsideProject(
          Uri.file('/proj/a/sub/x.html'), '/proj/a'),
      isTrue,
    );
    expect(
      DashboardTabView.isInsideProject(Uri.file('/etc/passwd'), '/proj/a'),
      isFalse,
    );
    expect(
      DashboardTabView.isInsideProject(
          Uri.file('/proj/a/../b/index.html'), '/proj/a'),
      isFalse,
    );
    expect(
      DashboardTabView.isInsideProject(
          Uri.parse('https://example.com'), '/proj/a'),
      isFalse,
    );
  });
}
