import 'package:flutter/material.dart';

import '../../domain/models/product_detail.dart';

/// Certification trust row on product detail (availability shown on media dot).
class ProductDetailAssurance extends StatelessWidget {
  const ProductDetailAssurance({
    required this.certification,
    super.key,
  });

  final ProductCertification? certification;

  @override
  Widget build(BuildContext context) {
    // Availability is shown as a dot on the hero media — no label row here.
    return const SizedBox.shrink();
  }
}
