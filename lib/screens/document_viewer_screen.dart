import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

/// Einfache Textansicht für Projektdokumente (README, Living Docs, ...).
///
/// Rendert in dieser ersten Version keine vollständige Markdown-Typografie,
/// zeigt den echten Dateiinhalt aber vollständig, durchsuchbar und
/// auswählbar an. "In Standardprogramm öffnen" nutzt die vorhandene
/// Systemzuordnung, statt den Inhalt selbst zu interpretieren.
class DocumentViewerScreen extends StatefulWidget {
  const DocumentViewerScreen({super.key, required this.file});

  final File file;

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  String? _content;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final content = await widget.file.readAsString();
      if (!mounted) return;
      setState(() => _content = content);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Datei konnte nicht gelesen werden: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = p.basename(widget.file.path);
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            tooltip: 'Im Standardprogramm öffnen',
            icon: const Icon(Icons.open_in_new),
            onPressed: () => launchUrl(Uri.file(widget.file.path)),
          ),
        ],
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : _content == null
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: SelectionArea(
                    child: SingleChildScrollView(
                      child: Text(
                        _content!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
