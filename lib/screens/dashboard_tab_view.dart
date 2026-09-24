import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../models/dashboard_tab.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Zeigt die lokale `index.html` eines Projekts (das `/dashboard`).
///
/// Sicherheitsgrenzen: Es wird nur die Datei selbst und Dateien innerhalb
/// des Projektordners geladen. Externe http(s)-Links öffnen im
/// Systembrowser, jede andere Navigation wird blockiert. Es gibt keine
/// Brücke zwischen Seite und App, die Seite kann also keine Dateien lesen
/// oder Befehle ausführen.
class DashboardTabView extends StatefulWidget {
  const DashboardTabView({super.key, required this.tab});

  final DashboardTab tab;

  /// Letzter Webview-Controller, nur für Integrationstests.
  @visibleForTesting
  static final ValueNotifier<InAppWebViewController?> debugController = ValueNotifier(null);

  /// Entscheidungen der Navigationssperre, nur für Integrationstests.
  @visibleForTesting
  static final List<String> debugNavigationLog = [];

  /// Zuletzt erfolgreich geladene Adresse, nur für Integrationstests.
  @visibleForTesting
  static final ValueNotifier<Uri?> debugLastLoaded = ValueNotifier(null);

  static bool isInsideProject(Uri uri, String projectDir) {
    if (uri.scheme != 'file') return false;
    return p.isWithin(projectDir, uri.toFilePath()) ||
        p.equals(projectDir, uri.toFilePath());
  }

  @override
  State<DashboardTabView> createState() => _DashboardTabViewState();
}

class _DashboardTabViewState extends State<DashboardTabView> {
  InAppWebViewController? _controller;
  bool _loading = true;
  String? _error;
  String? _blocked;

  DashboardTab get tab => widget.tab;

  Future<void> _openExternally() =>
      launchUrl(Uri.file(tab.indexPath), mode: LaunchMode.externalApplication);

  Future<void> _reload() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    await _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(Uri.file(tab.indexPath).toString())));
  }

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

    final c = context.colors;
    final dirUri = Uri.directory(tab.projectDir);
    return Column(
      children: [
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: Space.md),
          decoration: BoxDecoration(color: c.sidebar, border: Border(bottom: BorderSide(color: c.border))),
          child: Row(
            children: [
              Icon(Icons.lock_outline, size: 14, color: c.muted),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Tooltip(
                  message: tab.indexPath,
                  child: Text(tab.indexPath, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.muted)),
                ),
              ),
              if (_blocked != null)
                Padding(
                  padding: const EdgeInsets.only(right: Space.sm),
                  child: Tooltip(message: _blocked!, child: const Badge2(label: 'Navigation blockiert', tone: Tone.warning)),
                ),
              IconButton(
                tooltip: 'Neu laden',
                visualDensity: VisualDensity.compact,
                onPressed: _reload,
                icon: const Icon(Icons.refresh, size: 16),
              ),
              IconButton(
                tooltip: 'Im Standardbrowser öffnen',
                visualDensity: VisualDensity.compact,
                onPressed: _openExternally,
                icon: const Icon(Icons.open_in_new, size: 16),
              ),
            ],
          ),
        ),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(Uri.file(tab.indexPath).toString())),
                initialSettings: InAppWebViewSettings(
                  // Ohne dieses Flag ruft flutter_inappwebview shouldOverrideUrlLoading nie auf.
                  useShouldOverrideUrlLoading: true,
                  allowingReadAccessTo: WebUri(dirUri.toString()),
                  allowFileAccessFromFileURLs: false,
                  allowUniversalAccessFromFileURLs: false,
                  javaScriptCanOpenWindowsAutomatically: false,
                  supportZoom: false,
                  isInspectable: kDebugMode,
                ),
                onWebViewCreated: (controller) {
                  _controller = controller;
                  DashboardTabView.debugController.value = controller;
                },
                onLoadStart: (_, _) => setState(() => _loading = true),
                onLoadStop: (_, url) {
                  setState(() => _loading = false);
                  if (url != null) DashboardTabView.debugLastLoaded.value = Uri.parse(url.toString());
                },
                onReceivedError: (_, request, error) {
                  if (request.isForMainFrame != true) return;
                  setState(() {
                    _loading = false;
                    _error = error.description;
                  });
                },
                shouldOverrideUrlLoading: (controller, action) async {
                  final url = action.request.url;
                  if (url == null) return NavigationActionPolicy.CANCEL;
                  final uri = Uri.parse(url.toString());
                  if (kDebugMode) DashboardTabView.debugNavigationLog.add(uri.toString());
                  if (DashboardTabView.isInsideProject(uri, tab.projectDir) || uri.scheme == 'about') {
                    return NavigationActionPolicy.ALLOW;
                  }
                  if (uri.scheme == 'https' || uri.scheme == 'http') {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else if (mounted) {
                    setState(() => _blocked = 'Blockiert: $uri (außerhalb des Projektordners)');
                  }
                  return NavigationActionPolicy.CANCEL;
                },
              ),
              if (_error != null)
                Positioned.fill(
                  child: ColoredBox(
                    color: c.canvas,
                    child: EmptyState(
                      icon: Icons.error_outline,
                      title: 'Dashboard konnte nicht geladen werden',
                      message: _error!,
                      action: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh, size: 16), label: const Text('Erneut versuchen')),
                          const SizedBox(width: Space.sm),
                          OutlinedButton(onPressed: _openExternally, child: const Text('Im Browser öffnen')),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
