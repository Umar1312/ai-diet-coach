import 'package:url_launcher/url_launcher.dart';

class LegalLinks {
  LegalLinks._();

  static final privacyPolicy = Uri.parse('https://nextmeal.pages.dev/privacy');
  static final termsOfUse = Uri.parse('https://nextmeal.pages.dev/terms');
  static final healthSources = Uri.parse(
    'https://nextmeal.pages.dev/health-sources.html',
  );

  static Future<bool> openPrivacyPolicy() => _open(privacyPolicy);

  static Future<bool> openTermsOfUse() => _open(termsOfUse);

  static Future<bool> openHealthSources() => _open(healthSources);

  static Future<bool> _open(Uri url) =>
      launchUrl(url, mode: LaunchMode.inAppBrowserView);
}
