import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import 'ui.dart';

/// Pflicht-Hinweis "supported by: Michael Gahn DESIGN" (siehe NOTICE).
/// Fester Bestandteil der App, nicht entfernen oder ändern.
class SupportedByFooter extends StatelessWidget {
  const SupportedByFooter({super.key});

  static final Uri website = Uri.parse('https://Michael-Gahn.de');

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: c.sidebar,
        border: Border(top: BorderSide(color: c.border)),
      ),
      alignment: Alignment.center,
      child: Tooltip(
        message: 'Michael-Gahn.de öffnen',
        child: Semantics(
          link: true,
          label: 'supported by Michael Gahn DESIGN, Website öffnen',
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => launchUrl(website, mode: LaunchMode.externalApplication),
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 4, Space.md, 4),
              decoration: BoxDecoration(
                color: Brand.red.withValues(alpha: 0.08),
                border: Border.all(color: Brand.red.withValues(alpha: 0.35)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandMark(size: 20),
                    const SizedBox(width: Space.sm),
                    Text('supported by: ', style: TextStyle(fontSize: 12.5, color: c.muted)),
                    Text(
                      'Michael Gahn DESIGN',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: scheme.onSurface),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
