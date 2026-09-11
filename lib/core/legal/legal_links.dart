import 'package:url_launcher/url_launcher.dart';

class LegalLinks {
  LegalLinks._();

  static final privacyPolicy = Uri.parse('https://nextmeal.pages.dev/privacy');
  static final termsOfUse = Uri.parse('https://nextmeal.pages.dev/terms');

  static Future<bool> openPrivacyPolicy() => _open(privacyPolicy);

  static Future<bool> openTermsOfUse() => _open(termsOfUse);

  static Future<bool> _open(Uri url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);
}
