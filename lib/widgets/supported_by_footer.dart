import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pflicht-Hinweis "supported by: Michael Gahn DESIGN" (siehe NOTICE).
/// Fester Bestandteil der App, nicht entfernen oder ändern.
class SupportedByFooter extends StatelessWidget {
  const SupportedByFooter({super.key});

  static final Uri website = Uri.parse('https://Michael-Gahn.de');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(
            child: Tooltip(
              message: 'Michael-Gahn.de öffnen',
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () =>
                    launchUrl(website, mode: LaunchMode.externalApplication),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.45),
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.asset(
                          'assets/brand/logo-64.png',
                          width: 18,
                          height: 18,
                          semanticLabel: 'Michael Gahn DESIGN Logo',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'supported by: ',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const Text(
                        'Michael Gahn DESIGN',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
