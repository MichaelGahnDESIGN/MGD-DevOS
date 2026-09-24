import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mgd_devos/app_state.dart';
import 'package:mgd_devos/native_app.dart';
import 'package:mgd_devos/screens/dashboard_tab_view.dart';

/// Startet die echte Desktop-App, öffnet eine lokale index.html im
/// eingebetteten Webview und prüft Laden, Navigation im Projekt und die
/// Sperre für Dateien außerhalb des Projektordners.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late Directory project;

  setUpAll(() async {
    root = await Directory.systemTemp.createTemp('mgd_it_');
    project = Directory(p.join(root.path, 'IT-Projekt'))..createSync();
    Directory(p.join(project.path, '.git')).createSync();
    File(p.join(project.path, 'index.html')).writeAsStringSync(
      '<!doctype html><title>IT-Dashboard</title><p id="x">Hallo</p>'
      '<script>try{localStorage.setItem("k","v");document.title+=" | ls="+localStorage.getItem("k")}catch(e){document.title+=" | ls=gesperrt"}</script>',
    );
    File(p.join(project.path, 'sub.html')).writeAsStringSync('<!doctype html><title>IT-Unterseite</title>');
    final secret = File(p.join(root.path, 'ausserhalb.html'))..writeAsStringSync('<title>AUSSERHALB</title>');
    expect(secret.existsSync(), isTrue);
  });

  tearDownAll(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> waitFor(bool Function() cond, WidgetTester t, {int seconds = 20}) async {
    final end = DateTime.now().add(Duration(seconds: seconds));
    while (!cond() && DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('Dashboard-Tab lädt lokale index.html und sperrt Pfade außerhalb', (t) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_done_v1': true,
      'projects_root_v1': root.path,
    });
    final state = AppState();
    await t.pumpWidget(NativeMgdDevOsApp(appState: state));
    await waitFor(() => state.projects.isNotEmpty, t);
    await settle(t);
    expect(state.projects.single.name, 'IT-Projekt');

    await t.tap(find.text('Dashboard öffnen'));
    if (Platform.isLinux) {
      // Linux: kein eingebettetes WebView, der Tab bietet das Öffnen im Browser an.
      await settle(t);
      expect(find.text('Dashboard im Browser öffnen'), findsOneWidget);
      expect(state.dashboardTabs, hasLength(1));
      return;
    }
    await waitFor(() => DashboardTabView.debugLastLoaded.value != null, t, seconds: 30);

    final loaded = DashboardTabView.debugLastLoaded.value;
    expect(loaded, isNotNull, reason: 'Webview hat index.html nicht geladen');
    expect(p.basename(loaded!.toFilePath()), 'index.html');

    final controller = DashboardTabView.debugController.value!;
    final title = await controller.getTitle();
    // ignore: avoid_print
    print('IT: Titel nach Laden: $title');
    expect(title, startsWith('IT-Dashboard'));
    final text = await controller.evaluateJavascript(source: 'document.getElementById("x").textContent');
    expect(text, 'Hallo');

    await controller.evaluateJavascript(source: 'location.href="sub.html"');
    await waitFor(() => DashboardTabView.debugLastLoaded.value?.path.endsWith('sub.html') ?? false, t);
    expect(await controller.getTitle(), 'IT-Unterseite');

    final outside = Uri.file(p.join(root.path, 'ausserhalb.html')).toString();
    await controller.evaluateJavascript(source: 'location.href="$outside"');
    await t.pump(const Duration(seconds: 2));
    await settle(t);
    // Erste Schutzebene: WebKit darf nur im Projektordner lesen.
    expect(await controller.getTitle(), 'IT-Unterseite', reason: 'Datei außerhalb des Projekts wurde geladen');

    // Zweite Schutzebene: die App-Sperre für alle anderen Schemata.
    await controller.evaluateJavascript(source: 'location.href="mgd-test://nicht-erlaubt"');
    await waitFor(() => find.text('Navigation blockiert').evaluate().isNotEmpty, t, seconds: 10);
    // ignore: avoid_print
    print('IT: Navigationslog ${DashboardTabView.debugNavigationLog}');
    expect(find.text('Navigation blockiert'), findsOneWidget);
    expect(await controller.getTitle(), 'IT-Unterseite');

    // Andere Schemata (z. B. javascript:, data:) als Hauptnavigation bleiben gesperrt.
    await controller.evaluateJavascript(source: 'location.href="data:text/html,<title>DATA</title>"');
    await t.pump(const Duration(seconds: 1));
    expect(await controller.getTitle(), 'IT-Unterseite');

    await t.tap(find.byTooltip('IT-Projekt schließen'));
    await settle(t);
    expect(state.dashboardTabs, isEmpty);
  });

  testWidgets('Echtes Control-Plane-Dashboard funktioniert im Tab', skip: Platform.isLinux, (t) async {
    final real = Directory(p.join(root.path, 'Echt'))..createSync();
    Directory(p.join(real.path, '.git')).createSync();
    File('index.html').copySync(p.join(real.path, 'index.html'));
    SharedPreferences.setMockInitialValues({
      'onboarding_done_v1': true,
      'projects_root_v1': root.path,
    });
    DashboardTabView.debugLastLoaded.value = null;
    final state = AppState();
    await t.pumpWidget(NativeMgdDevOsApp(appState: state));
    await waitFor(() => state.projects.length == 2, t);
    await settle(t);
    state.openDashboard(state.projects.firstWhere((x) => x.name == 'Echt'));
    await waitFor(() => DashboardTabView.debugLastLoaded.value?.path.endsWith('Echt/index.html') ?? false, t, seconds: 30);
    final c = DashboardTabView.debugController.value!;
    expect(await c.getTitle(), contains('MGD-DevOS'));

    Future<dynamic> js(String code) => c.evaluateJavascript(source: code);
    await js('document.dispatchEvent(new KeyboardEvent("keydown",{key:"2"}))');
    expect(await js('document.getElementById("aufgaben").classList.contains("active")'), true);
    expect(await js('document.querySelectorAll("#openCopy li").length'), 2);
    await js('document.dispatchEvent(new KeyboardEvent("keydown",{key:"1"}))');
    await t.pump(const Duration(milliseconds: 300));
    expect(await js('document.querySelectorAll("#edges path").length'), 3);
    expect(await js('!!document.querySelector("[data-mgd-supported-by] a[href=\'https://Michael-Gahn.de\']")'), true);

    await js('document.getElementById("settingsButton").click();document.getElementById("theme").value="dark";document.getElementById("accent").value="mgd";document.getElementById("saveSettings").click();');
    await c.reload();
    await waitFor(() => false, t, seconds: 2);
    expect(await js('document.documentElement.dataset.theme'), 'dark', reason: 'Einstellung hat den Neuladen nicht überlebt');
    expect(await js('getComputedStyle(document.documentElement).getPropertyValue("--accent").trim()'), '#cd1616');
    // ignore: avoid_print
    print('IT: Control-Plane-Dashboard ok, Einstellungen bleiben nach Neuladen erhalten');
  });
}
