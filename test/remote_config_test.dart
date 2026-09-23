import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:mgd_devos/models/app_remote_config.dart';
import 'package:mgd_devos/services/remote_config_service.dart';

void main() {
  test('AppRemoteConfig.fromJson liest alle Felder korrekt', () {
    final config = AppRemoteConfig.fromJson({
      'app_title': 'MGD AI-Projektmanager',
      'target_url': 'https://example.invalid/app',
      'stripe_donation_url': 'https://donate.example.invalid',
      'show_donation_button': true,
    });

    expect(config.appTitle, 'MGD AI-Projektmanager');
    expect(config.targetUrl, 'https://example.invalid/app');
    expect(config.stripeDonationUrl, 'https://donate.example.invalid');
    expect(config.showDonationButton, isTrue);
    expect(config.isFallback, isFalse);
  });

  test('RemoteConfigService laedt gueltiges JSON von der konfigurierten URL',
      () async {
    final mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'app_title': 'Test-Titel',
          'target_url': 'https://example.invalid',
          'stripe_donation_url': 'https://example.invalid/spenden',
          'show_donation_button': true,
        }),
        200,
      );
    });

    final service = RemoteConfigService(client: mockClient);
    final config = await service.load();

    expect(config.appTitle, 'Test-Titel');
    expect(config.isFallback, isFalse);
  });

  test('RemoteConfigService faellt bei Netzwerkfehler auf den Standard zurueck',
      () async {
    final mockClient = MockClient((request) async {
      throw const SocketExceptionStub();
    });

    final service = RemoteConfigService(client: mockClient);
    final config = await service.load();

    expect(config.isFallback, isTrue);
    expect(config.appTitle, RemoteConfigDefaults.appTitle);
  });

  test('RemoteConfigService faellt bei HTTP-Fehlerstatus auf den Standard zurueck',
      () async {
    final mockClient = MockClient((request) async {
      return http.Response('Not found', 404);
    });

    final service = RemoteConfigService(client: mockClient);
    final config = await service.load();

    expect(config.isFallback, isTrue);
  });

  test('RemoteConfigService faellt bei ungueltigem JSON auf den Standard zurueck',
      () async {
    final mockClient = MockClient((request) async {
      return http.Response('kein-json', 200);
    });

    final service = RemoteConfigService(client: mockClient);
    final config = await service.load();

    expect(config.isFallback, isTrue);
  });
}

/// Minimaler Ersatz fuer einen echten Netzwerkfehler in Tests.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
