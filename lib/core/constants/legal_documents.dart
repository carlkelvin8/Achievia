/// The ACHIEVIA Privacy Policy and Terms of Service, bundled as the published
/// PDFs in assets/legal/. To update one, replace its PDF.
library;

class LegalDocument {
  final String title;
  final String asset;

  const LegalDocument({required this.title, required this.asset});
}

const termsOfService = LegalDocument(
  title: 'Terms of Service',
  asset: 'assets/legal/terms_of_service.pdf',
);

const privacyPolicy = LegalDocument(
  title: 'Privacy Policy',
  asset: 'assets/legal/privacy_policy.pdf',
);
