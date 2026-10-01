/// Central place for company / legal identifiers shown in legal texts.
///
/// IMPORTANT: Replace the placeholder values below with your real legal
/// entity details before publishing to the App Store / Play Store. These
/// appear verbatim in the Privacy Policy and Terms of Service.
class AppInfo {
  AppInfo._();

  static const String appName = '60+ Friends';

  /// The data controller under the GDPR (Art. 4(7)).
  static const String companyName = '60+ Friends';
  static const String companyAddress =
      'Cortijo las Padillas 10, 29749 Vélez-Málaga, Spain';
  static const String contactEmail = 'appfactorymalaga@gmail.com';
  static const String supportEmail = 'appfactorymalaga@gmail.com';

  /// Art. 37 GDPR: a DPO is not mandatory for this operation.
  static const String dpoContact =
      'A Data Protection Officer is not appointed; for any data protection '
      'matter please contact us at the email above';

  /// Spain's supervisory authority. Users may also contact the authority in
  /// their own EU/EEA country of residence.
  static const String supervisoryAuthority =
      'the Spanish Data Protection Agency (Agencia Española de Protección de '
      'Datos, AEPD, www.aepd.es)';

  static const String lastUpdated = '22 September 2026';
  static const int minimumAge = 18;
}
