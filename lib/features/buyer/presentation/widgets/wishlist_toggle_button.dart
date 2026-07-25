import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../application/wishlist_provider.dart';
import '../../domain/models/wishlist_item.dart';

/// Heart toggle that adds/removes a catalog item from the buyer wishlist.
class WishlistToggleButton extends ConsumerWidget {
  const WishlistToggleButton({
    required this.item,
    this.size = 18,
    this.padded = true,
    super.key,
  });

  final WishlistItem item;
  final double size;
  final bool padded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlisted = ref.watch(isInWishlistProvider(item.id));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          final added =
              ref.read(wishlistProvider.notifier).toggle(item);
          final messenger = ScaffoldMessenger.maybeOf(context);
          messenger?.hideCurrentSnackBar();
          messenger?.showSnackBar(
            SnackBar(
              content: Text(
                added ? 'Added to wishlist' : 'Removed from wishlist',
              ),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Padding(
          padding: padded ? const EdgeInsets.all(6) : EdgeInsets.zero,
          child: Icon(
            wishlisted ? Icons.favorite : Icons.favorite_border,
            size: size,
            color: wishlisted ? AppColors.error : AppColors.textMutedLight,
          ),
        ),
      ),
    );
  }
}
