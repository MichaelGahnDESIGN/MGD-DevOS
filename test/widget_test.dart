import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mgd_devos/app_state.dart';
import 'package:mgd_devos/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('zeigt Onboarding, solange kein Projekt-Root gesetzt ist',
      (WidgetTester tester) async {
    final appState = AppState();
    await tester.pumpWidget(MgdDevOsApp(appState: appState));
    await tester.pumpAndSettle();

    expect(find.text('Willkommen bei MGD-DevOS'), findsOneWidget);
    expect(find.text('Loslegen'), findsOneWidget);
  });

  testWidgets('springt nach abgeschlossenem Onboarding zur Projektansicht',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_done_v1': true,
      'projects_root_v1': '/nicht-vorhanden-fuer-test',
    });
    final appState = AppState();
    await tester.pumpWidget(MgdDevOsApp(appState: appState));
    await tester.pumpAndSettle();

    expect(find.text('Projekte'), findsWidgets);
    expect(find.text('Agentic Control Panel'), findsWidgets);
  });
}
