import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_remote_config.dart';

const _noTargetHtml = '''
<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="utf-8" />
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: #14161a;
      color: #e6e6e6;
      display: flex;
      align-items: center;
      justify-content: center;
      height: 100vh;
      margin: 0;
      text-align: center;
      padding: 24px;
      box-sizing: border-box;
    }
    div { max-width: 480px; }
    h1 { font-size: 1.25rem; margin-bottom: 8px; }
    p { opacity: 0.75; line-height: 1.5; }
  </style>
</head>
<body>
  <div>
    <h1>Keine Ziel-URL konfiguriert</h1>
    <p>
      MGD-DevOS konnte keine erreichbare <code>target_url</code> laden.
      Entweder ist die Online-Konfiguration nicht erreichbar, oder für
      MGD_AI-Projektmanager existiert noch keine öffentlich erreichbare
      Web-Version. Bitte die Konfiguration prüfen (siehe README.md).
    </p>
  </div>
</body>
</html>
''';

/// Eingebetteter, randloser Webview für [config.targetUrl] mit optionalem
/// Spenden-Button. Nur für Plattformen mit echter flutter_inappwebview-
/// Unterstützung (macOS, Windows, Web) gedacht — siehe README.md für die
/// Linux-Einschränkung und [LinuxLaunchScreen].
class WebviewHomeScreen extends StatelessWidget {
  const WebviewHomeScreen({super.key, required this.config});

  final AppRemoteConfig config;

  Future<void> _openDonationLink() async {
    final url = config.stripeDonationUrl;
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final hasTarget = config.targetUrl.trim().isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: hasTarget
                ? InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri(config.targetUrl),
                    ),
                  )
                : InAppWebView(
                    initialData: InAppWebViewInitialData(data: _noTargetHtml),
                  ),
          ),
          if (config.isFallback)
            Positioned(
              top: 12,
              left: 12,
              child: _StatusPill(
                icon: Icons.cloud_off,
                label: 'Offline-Standardkonfiguration aktiv',
              ),
            ),
          if (config.showDonationButton && config.stripeDonationUrl.isNotEmpty)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: _openDonationLink,
                icon: const Icon(Icons.favorite_outline, size: 18),
                label: const Text('Projekt unterstützen'),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
