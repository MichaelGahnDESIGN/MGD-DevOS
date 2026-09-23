import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_remote_config.dart';

/// Lädt [AppRemoteConfig] als JSON von einer öffentlich erreichbaren URL.
///
/// WICHTIG: Diese URL muss **öffentlich ohne Authentifizierung** abrufbar
/// sein (z. B. ein separates öffentliches Repository, ein öffentliches
/// Gist oder GitHub Pages). `MGD_AI-Projektmanager` ist ein privates
/// Repository; eine raw.githubusercontent.com-URL daraus liefert für
/// anonyme Anfragen 404, weil kein Token im Client hinterlegt werden darf
/// (siehe Sicherheitsregeln: keine Secrets im Flutter-Client).
class RemoteConfigService {
  RemoteConfigService({
    this.configUrl =
        'https://raw.githubusercontent.com/MichaelGahnDESIGN/MGD-DevOS-config/main/mgd-devos-config.json',
    http.Client? client,
    this.timeout = const Duration(seconds: 6),
  }) : _client = client ?? http.Client();

  /// Öffentliche URL der JSON-Konfiguration. In den Einstellungen änderbar
  /// (siehe `SettingsStore`), Standardwert zeigt auf ein noch anzulegendes
  /// separates öffentliches Repository (siehe README.md).
  final String configUrl;
  final Duration timeout;
  final http.Client _client;

  Future<AppRemoteConfig> load() async {
    try {
      final response = await _client
          .get(Uri.parse(configUrl))
          .timeout(timeout);
      if (response.statusCode != 200) {
        return RemoteConfigDefaults.fallback;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return RemoteConfigDefaults.fallback;
      }
      return AppRemoteConfig.fromJson(decoded);
    } catch (_) {
      // Offline, Timeout, ungültiges JSON, o. Ä.: bewusst auf den
      // eingebauten Standard zurückfallen statt einen Fehlerzustand zu
      // erzwingen, den der Nutzer nicht beeinflussen kann.
      return RemoteConfigDefaults.fallback;
    }
  }
}
