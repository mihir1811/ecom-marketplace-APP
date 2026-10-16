import 'package:flutter/material.dart';

/// Quiet icon for a marketplace policy id.
IconData policyIconFor(String id) => switch (id) {
  'terms' => Icons.gavel_outlined,
  'privacy' => Icons.privacy_tip_outlined,
  'cookies' => Icons.cookie_outlined,
  'refund-return' => Icons.replay_outlined,
  'shipping-delivery' => Icons.local_shipping_outlined,
  'seller' => Icons.storefront_outlined,
  'buyer' => Icons.shopping_bag_outlined,
  'auction' => Icons.gavel_rounded,
  'payment' => Icons.payments_outlined,
  'product-listing' => Icons.diamond_outlined,
  'intellectual-property' => Icons.copyright_outlined,
  'contact-dispute' => Icons.support_agent_outlined,
  _ => Icons.description_outlined,
};
