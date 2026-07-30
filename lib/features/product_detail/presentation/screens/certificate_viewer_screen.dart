import 'package:url_launcher/url_launcher.dart';

/// Opens a certificate URL in the system browser. No in-app viewer.
Future<void> openCertificateViewer({
  required String url,
  String title = 'Certificate',
}) async {
  final resolved = _resolveCertificateUrl(url);
  final uri = Uri.tryParse(resolved);
  if (uri == null) return;
  await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
    webOnlyWindowName: '_blank',
  );
}

String _resolveCertificateUrl(String url) {
  var resolved = url.trim();
  if (resolved.toLowerCase().startsWith('www.')) {
    resolved = 'https://$resolved';
  }
  return resolved;
}
