import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_remote_config.dart';

/// Ersatz-Startbildschirm für Linux.
///
/// `flutter_inappwebview` bietet aktuell **kein** eingebettetes WebView für
/// Linux-Desktop (nur Android, iOS, macOS, Windows, Web). Ein eingebettetes,
/// randloses WebView-Fenster ist auf Linux mit den geprüften Flutter-
/// Paketen aktuell nicht zuverlässig umsetzbar. Statt das stillschweigend
/// zu ignorieren oder ein ungetestetes Paket einzubauen, öffnet MGD-DevOS
/// die Ziel-URL hier bewusst im Standardbrowser des Nutzers.
class LinuxLaunchScreen extends StatelessWidget {
  const LinuxLaunchScreen({super.key, required this.config});

  final AppRemoteConfig config;

  Future<void> _open(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final hasTarget = config.targetUrl.trim().isNotEmpty;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  config.appTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Für Linux-Desktop gibt es aktuell kein zuverlässig '
                  'eingebettetes WebView in MGD-DevOS (siehe README.md). '
                  'Die Ziel-Seite öffnet sich stattdessen im '
                  'Standardbrowser.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed:
                      hasTarget ? () => _open(config.targetUrl) : null,
                  icon: const Icon(Icons.open_in_browser),
                  label: Text(
                    hasTarget
                        ? 'Im Browser öffnen'
                        : 'Keine Ziel-URL konfiguriert',
                  ),
                ),
                if (config.isFallback) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Offline-Standardkonfiguration aktiv.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (config.showDonationButton &&
                    config.stripeDonationUrl.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => _open(config.stripeDonationUrl),
                    icon: const Icon(Icons.favorite_outline, size: 18),
                    label: const Text('Projekt unterstützen'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
