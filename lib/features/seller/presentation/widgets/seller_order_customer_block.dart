import 'package:flutter/material.dart';

import '../atelier/atelier_components.dart';
import '../atelier/atelier_theme.dart';

/// Customer contact shown on every order and refund row.
///
/// Only fields the seller APIs return for the seller's own orders are shown
/// (name, and email / phone when present); nothing is fetched separately.
class SellerOrderCustomerBlock extends StatelessWidget {
  const SellerOrderCustomerBlock({
    required this.name,
    this.email,
    this.phone,
    super.key,
  });

  final String name;
  final String? email;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final contacts = [
      if (email != null && email!.trim().isNotEmpty)
        (Icons.alternate_email_rounded, email!.trim()),
      if (phone != null && phone!.trim().isNotEmpty)
        (Icons.phone_outlined, phone!.trim()),
    ];
    return Row(
      children: [
        AtelierMonogram(name: name, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtelierType.label(p.ink, size: 13.5),
              ),
              if (contacts.isNotEmpty) ...[
                const SizedBox(height: 3),
                Wrap(
                  spacing: 12,
                  runSpacing: 2,
                  children: [
                    for (final (icon, text) in contacts)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 12, color: p.muted),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Text(
                              text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AtelierType.caption(p.inkSoft, size: 11.5),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
