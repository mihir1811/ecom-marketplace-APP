import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

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
    final contacts = [
      if (email != null && email!.trim().isNotEmpty)
        (Icons.mail_outline, email!.trim()),
      if (phone != null && phone!.trim().isNotEmpty)
        (Icons.phone_outlined, phone!.trim()),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row(context, Icons.person_outline, name, strong: true),
        for (final (icon, text) in contacts) ...[
          const SizedBox(height: 4),
          _row(context, icon, text),
        ],
      ],
    );
  }

  Widget _row(
    BuildContext context,
    IconData icon,
    String text, {
    bool strong = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted(context)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: strong
                  ? AppColors.textPrimary(context)
                  : AppColors.textSecondary(context),
              fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
