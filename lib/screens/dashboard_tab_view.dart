import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../models/dashboard_tab.dart';
import '../widgets/ui.dart';

/// Zeigt die lokale `index.html` eines Projekts (das `/dashboard`).
///
/// Sicherheitsgrenzen: Es wird nur die Datei selbst und Dateien innerhalb
/// des Projektordners geladen. Externe http(s)-Links öffnen im
/// Systembrowser, jede andere Navigation wird blockiert. Es gibt keine
/// Brücke zwischen Seite und App, die Seite kann also keine Dateien lesen
/// oder Befehle ausführen.
class DashboardTabView extends StatelessWidget {
  const DashboardTabView({super.key, required this.tab});

  final DashboardTab tab;

  static bool isInsideProject(Uri uri, String projectDir) {
    if (uri.scheme != 'file') return false;
    return p.isWithin(projectDir, uri.toFilePath()) ||
        p.equals(projectDir, uri.toFilePath());
  }

  Future<void> _openExternally() =>
      launchUrl(Uri.file(tab.indexPath), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final isLinux = !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;
    if (kIsWeb || isLinux) {
      return EmptyState(
        icon: Icons.open_in_browser,
        title: tab.projectName,
        message: 'Auf dieser Plattform gibt es kein eingebettetes WebView. Das Dashboard öffnet im Standardbrowser.',
        action: FilledButton.icon(
          onPressed: _openExternally,
          icon: const Icon(Icons.open_in_browser, size: 18),
          label: const Text('Dashboard im Browser öffnen'),
        ),
      );
    }

    final dirUri = Uri.directory(tab.projectDir);
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(Uri.file(tab.indexPath).toString())),
      initialSettings: InAppWebViewSettings(
        allowingReadAccessTo: WebUri(dirUri.toString()),
        allowFileAccessFromFileURLs: false,
        allowUniversalAccessFromFileURLs: false,
        javaScriptCanOpenWindowsAutomatically: false,
        supportZoom: false,
      ),
      shouldOverrideUrlLoading: (controller, action) async {
        final url = action.request.url;
        if (url == null) return NavigationActionPolicy.CANCEL;
        final uri = Uri.parse(url.toString());
        if (isInsideProject(uri, tab.projectDir)) {
          return NavigationActionPolicy.ALLOW;
        }
        if (uri.scheme == 'https' || uri.scheme == 'http') {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        return NavigationActionPolicy.CANCEL;
      },
    );
  }
}
