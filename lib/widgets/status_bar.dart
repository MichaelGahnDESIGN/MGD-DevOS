import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../theme/app_theme.dart';
import 'ui.dart';

/// Statusleiste unten: lokaler Status, Projektzahl, letzter Scan und der
/// Pflicht-Label "powered by: Michael Gahn DESIGN" (siehe NOTICE und LICENSE).
class StatusBar extends StatelessWidget {
  const StatusBar({super.key, required this.appState});

  final AppState appState;

  static final Uri website = Uri.parse('https://michael-gahn.de');

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final scan = appState.lastScan;
    final style = TextStyle(fontSize: 12, color: c.muted);
    Widget sep() => Container(
      width: 1,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: Space.md),
      color: c.border,
    );

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: Space.md),
      decoration: BoxDecoration(
        color: c.sidebar,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          // Linker Teil darf abgeschnitten werden, der Pflicht-Hinweis rechts bleibt immer sichtbar.
          Expanded(
            child: ClipRect(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: c.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('Lokal', style: style),
                    sep(),
                    Text('MGD-DevOS ${appState.meta.label}', style: style),
                    sep(),
                    Text('${appState.projects.length} Projekte', style: style),
                    if (scan != null) ...[
                      sep(),
                      Text(
                        'Gescannt ${DateFormat('HH:mm').format(scan)}',
                        style: style,
                      ),
                    ],
                    if (appState.dashboardTabs.isNotEmpty) ...[
                      sep(),
                      Text(
                        '${appState.dashboardTabs.length} Dashboard${appState.dashboardTabs.length == 1 ? '' : 's'} offen',
                        style: style,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: Space.md),
          const PoweredByPill(),
        ],
      ),
    );
  }
}

/// Pflicht-Hinweis als Pille. Fester Bestandteil der App, nicht entfernen.
class PoweredByPill extends StatelessWidget {
  const PoweredByPill({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: 'michael-gahn.de im Browser öffnen',
      child: Semantics(
        link: true,
        label: 'powered by Michael Gahn DESIGN, Website im Browser öffnen',
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => launchUrl(
            StatusBar.website,
            mode: LaunchMode.externalApplication,
          ),
          child: Container(
            height: 24,
            padding: const EdgeInsets.fromLTRB(3, 0, Space.md, 0),
            decoration: BoxDecoration(
              color: Brand.red.withValues(alpha: 0.08),
              border: Border.all(color: Brand.red.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandMark(size: 18),
                  const SizedBox(width: Space.sm),
                  Text(
                    'powered by: ',
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
                  Text(
                    'Michael Gahn DESIGN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kleine Statuspille in der Titelleiste (z. B. "LOKAL").
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.tooltip,
  });

  final String label;
  final Color color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pill = Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 0,
                  spreadRadius: 2.5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: c.muted,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
    return tooltip == null ? pill : Tooltip(message: tooltip!, child: pill);
  }
}
