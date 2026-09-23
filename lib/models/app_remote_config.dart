/// Konfiguration, die MGD-DevOS bei jedem Start als JSON von einer
/// öffentlichen URL lädt (siehe [RemoteConfigService]). Enthält bewusst
/// keine Secrets: nur Anzeigetitel, Ziel-URL, Spendenlink und ein Flag.
class AppRemoteConfig {
  const AppRemoteConfig({
    required this.appTitle,
    required this.targetUrl,
    required this.stripeDonationUrl,
    required this.showDonationButton,
    required this.isFallback,
  });

  final String appTitle;
  final String targetUrl;
  final String stripeDonationUrl;
  final bool showDonationButton;

  /// true, wenn diese Konfiguration nicht online geladen werden konnte und
  /// stattdessen der eingebaute Standardwert verwendet wird. Die UI zeigt
  /// das als dezenten Hinweis an, statt einen Online-Zustand vorzutäuschen.
  final bool isFallback;

  factory AppRemoteConfig.fromJson(Map<String, dynamic> json) {
    return AppRemoteConfig(
      appTitle: (json['app_title'] as String?)?.trim().isNotEmpty == true
          ? json['app_title'] as String
          : RemoteConfigDefaults.appTitle,
      targetUrl: (json['target_url'] as String?) ?? '',
      stripeDonationUrl: (json['stripe_donation_url'] as String?) ?? '',
      showDonationButton: json['show_donation_button'] == true,
      isFallback: false,
    );
  }
}

/// Eingebaute Standardwerte, falls die Online-Konfiguration nicht geladen
/// werden kann (z. B. offline, GitHub nicht erreichbar, JSON ungültig).
///
/// `targetUrl` ist absichtlich leer: MGD-DevOS zeigt in diesem Fall eine
/// lokale Hinweisseite statt einer erfundenen URL, weil aktuell noch keine
/// öffentlich erreichbare Web-Version von MGD_AI-Projektmanager existiert.
abstract final class RemoteConfigDefaults {
  static const appTitle = 'MGD-DevOS';
  static const targetUrl = '';
  static const stripeDonationUrl = '';
  static const showDonationButton = false;

  static const fallback = AppRemoteConfig(
    appTitle: appTitle,
    targetUrl: targetUrl,
    stripeDonationUrl: stripeDonationUrl,
    showDonationButton: showDonationButton,
    isFallback: true,
  );
}
