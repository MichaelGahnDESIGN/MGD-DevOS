import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mgd_devos/app_state.dart';
import 'package:mgd_devos/native_app.dart';
import 'package:mgd_devos/services/pin_service.dart';

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

  testWidgets('Mit PIN startet die App gesperrt und entsperrt mit richtiger PIN', (tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_done_v1': true,
      'projects_root_v1': '/nicht-vorhanden-fuer-test',
    });
    await tester.runAsync(() => PinService().setPin('2468', 4));
    final appState = AppState();
    await tester.pumpWidget(NativeMgdDevOsApp(appState: appState));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('MGD-DevOS ist gesperrt'), findsOneWidget);
    expect(find.textContaining('Version 0.5.1'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '2468');
    await tester.tap(find.text('Entsperren'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(appState.locked, isFalse);
    expect(find.text('MGD-DevOS ist gesperrt'), findsNothing);
  });

  testWidgets('Einstellungen sind durchsuchbar, Credits stehen zuletzt', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'onboarding_done_v1': true,
      'projects_root_v1': '/nicht-vorhanden-fuer-test',
    });
    final appState = AppState();
    await tester.pumpWidget(NativeMgdDevOsApp(appState: appState));
    await tester.pumpAndSettle();
    appState.showOverviewSection(2);
    await tester.pumpAndSettle();

    // Credits stehen in der Bereichsleiste ganz unten, unter "Über".
    expect(tester.getTopLeft(find.text('Credits')).dy, greaterThan(tester.getTopLeft(find.text('Über')).dy));

    await tester.enterText(find.widgetWithText(TextField, 'Einstellungen durchsuchen'), 'pin');
    await tester.pumpAndSettle();
    expect(find.text('PIN festlegen'), findsOneWidget);
    expect(find.text('Farbschema'), findsNothing);

    await tester.enterText(find.widgetWithText(TextField, 'Einstellungen durchsuchen'), 'gibtsnicht');
    await tester.pumpAndSettle();
    expect(find.text('Keine Einstellung gefunden.'), findsOneWidget);
  });
}
