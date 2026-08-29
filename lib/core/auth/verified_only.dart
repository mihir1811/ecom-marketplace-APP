import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

/// Hides buy/sell chrome while admin KYC is still pending.
class VerifiedOnly extends ConsumerWidget {
  const VerifiedOnly({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(
      authProvider.select((s) => s.isVerificationPending),
    );
    if (pending) return const SizedBox.shrink();
    return child;
  }
}
