import 'package:flutter/material.dart';

/// Non-web stub.
class CertificateIFrame extends StatelessWidget {
  const CertificateIFrame({
    required this.url,
    required this.onLoaded,
    super.key,
  });

  final String url;
  final VoidCallback onLoaded;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
