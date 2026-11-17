import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/wishlist_provider.dart';
import '../../domain/models/wishlist_item.dart';

/// Adds/removes a catalog item via `/favorites`. Requires a signed-in session.
Future<bool?> toggleWishlistItem(
  BuildContext context,
  WidgetRef ref,
  WishlistItem item, {
  VoidCallback? onAdded,
  String? addedMessage,
  String? removedMessage,
}) async {
  if (!ref.read(authProvider).isAuthenticated) {
    context.openRoute(AppRouteNames.login);
    return null;
  }

  final wasInList = ref.read(isInWishlistProvider(item.id));
  final added = await ref.read(wishlistProvider.notifier).toggle(item);
  if (added && !wasInList) onAdded?.call();
  if (!context.mounted) return added;
  final error = ref.read(wishlistProvider).errorMessage;
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.hideCurrentSnackBar();
  if (error != null && error.isNotEmpty) {
    AppHaptics.error();
  } else {
    AppHaptics.medium();
  }
  messenger?.showSnackBar(
    SnackBar(
      content: Text(
        error != null && error.isNotEmpty
            ? error
            : (added
                  ? addedMessage ??
                        context.tr(AccountCommerceL10n.addedWishlist)
                  : removedMessage ??
                        context.tr(AccountCommerceL10n.removedWishlist)),
      ),
      // Floating so it rests just above the bottom dock on every screen.
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      duration: const Duration(seconds: 1),
    ),
  );
  return added;
}

/// Heart toggle that adds/removes a catalog item from the buyer wishlist.
class WishlistToggleButton extends ConsumerWidget {
  const WishlistToggleButton({
    required this.item,
    this.onAdded,
    this.size = listingIconSize,
    this.padded = true,
    super.key,
  });

  /// Shared listing control hit target (matches project-pick / compare circles).
  static const double listingHitSize = 24;

  /// Default heart icon size on listing cards.
  static const double listingIconSize = 22;

  final WishlistItem item;

  /// Called after the item is newly added so callers can cache product detail.
  final VoidCallback? onAdded;
  final double size;
  final bool padded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlisted = ref.watch(isInWishlistProvider(item.id));
    final box = padded ? listingHitSize : size;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => toggleWishlistItem(context, ref, item, onAdded: onAdded),
      child: Semantics(
        button: true,
        label: context.tr(
          wishlisted
              ? AccountCommerceL10n.removeWishlist
              : AccountCommerceL10n.addWishlist,
        ),
        child: SizedBox(
          width: box,
          height: box,
          child: Center(
            child: Icon(
              wishlisted ? Icons.favorite : Icons.favorite_border,
              size: size,
              color: wishlisted
                  ? AppColors.error
                  : AppColors.textPrimary(context),
            ),
          ),
        ),
      ),
    );
  }
}
