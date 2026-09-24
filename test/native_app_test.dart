import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mgd_devos/app_state.dart';
import 'package:mgd_devos/native_app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('zeigt Onboarding, solange kein Projekt-Root gesetzt ist',
      (WidgetTester tester) async {
    final appState = AppState();
    await tester.pumpWidget(NativeMgdDevOsApp(appState: appState));
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
    await tester.pumpWidget(NativeMgdDevOsApp(appState: appState));
    await tester.pumpAndSettle();

    expect(find.text('Michael Gahn DESIGN'), findsOneWidget);
    expect(find.text('Projekte'), findsWidgets);
    expect(find.byTooltip('Agentic Control Panel  ⌘ 2'), findsOneWidget);
    expect(find.text('LOKAL'), findsOneWidget);
    expect(find.text('0 Projekte'), findsOneWidget);
  });

  testWidgets('Tastenkürzel wechseln Bereiche, Icon-Leiste ist bedienbar',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_done_v1': true,
      'projects_root_v1': '/nicht-vorhanden-fuer-test',
    });
    final appState = AppState();
    await tester.pumpWidget(NativeMgdDevOsApp(appState: appState));
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pumpAndSettle();
    expect(appState.overviewSection, 1);
    expect(find.text('Agentic Control Panel'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.comma);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(appState.overviewSection, 2);

    await tester.tap(find.byTooltip('Projekte  ⌘ 1'));
    await tester.pumpAndSettle();
    expect(appState.overviewSection, 0);
  });
}
