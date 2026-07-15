import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';

/// Landing page/Home Screen displaying the GemWorld Diamond Marketplace.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'GemWorld',
          style: AppTypography.title.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s16),
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: AppSpacing.s8,
                ),
                side: const BorderSide(color: AppColors.charcoal, width: 1.0),
              ),
              child: const Text('LOGIN'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Announcement Bar
            Container(
              width: double.infinity,
              color: AppColors.sandSurface,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.gpp_good_outlined, size: 16, color: AppColors.bronze),
                  const SizedBox(width: AppSpacing.s4),
                  Text(
                    'GIA Certified Diamonds',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s16),
                  const Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.bronze),
                  const SizedBox(width: AppSpacing.s4),
                  Text(
                    'Worldwide Shipping',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Hero Section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CERTIFIED DIAMOND MARKETPLACE',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.bronze,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Text(
                    'Buy and sell verified diamonds with clarity.',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  Text(
                    'Browse authenticated diamonds, gemstones, fine jewelry, watches, and bullion in one quiet, transparent marketplace.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondaryLight,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  
                  // Search Bar Card
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.r8),
                      border: Border.all(color: AppColors.warmBorder),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s4),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by shape, carat, certificate...',
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search, color: AppColors.charcoal),
                          onPressed: () {},
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.s20),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Explore Diamonds'),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      TextButton(
                        onPressed: () {},
                        child: Row(
                          children: const [
                            Text('Become a seller'),
                            SizedBox(width: AppSpacing.s4),
                            Icon(Icons.arrow_forward, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(),

            // Shop by Category Section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Marketplace Collections',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Browse all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  
                  // Horizontal Grid or column of category cards
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppSpacing.s16,
                    mainAxisSpacing: AppSpacing.s16,
                    childAspectRatio: 0.85,
                    children: [
                      _CategoryCard(
                        title: 'Diamonds',
                        desc: 'Certified natural and lab grown stones.',
                        icon: Icons.diamond_outlined,
                      ),
                      _CategoryCard(
                        title: 'Gemstones',
                        desc: 'Sapphires, rubies, emeralds, and more.',
                        icon: Icons.brightness_high_outlined,
                      ),
                      _CategoryCard(
                        title: 'Fine Jewelry',
                        desc: 'Rings, earrings, bracelets, and more.',
                        icon: Icons.star_border,
                      ),
                      _CategoryCard(
                        title: 'Bullion',
                        desc: 'Investment grade metals and coins.',
                        icon: Icons.currency_bitcoin_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(),

            // Featured Highlights (3 items in a clean row/column)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: Column(
                children: const [
                  _HighlightTile(
                    title: 'Verified listings',
                    desc: 'Seller and certificate information is surfaced clearly before inquiry or checkout.',
                    icon: Icons.verified_user_outlined,
                  ),
                  SizedBox(height: AppSpacing.s24),
                  _HighlightTile(
                    title: 'Secure transactions',
                    desc: 'Structured buying flows keep product, seller, and payment details easy to review.',
                    icon: Icons.lock_outline,
                  ),
                  SizedBox(height: AppSpacing.s24),
                  _HighlightTile(
                    title: 'Global sourcing',
                    desc: 'Browse across diamonds, gemstones, jewelry, watches, and bullion from one account.',
                    icon: Icons.public,
                  ),
                ],
              ),
            ),

            // Footer Bottom Info
            Container(
              color: AppColors.charcoal,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24, vertical: AppSpacing.s40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GemWorld',
                    style: AppTypography.title.copyWith(
                      color: AppColors.warmWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Text(
                    'A focused marketplace for certified diamonds, gemstones, fine jewelry, watches, and bullion.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s32),
                  Text(
                    '© 2026 GemWorld. All rights reserved.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMutedDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;

  const _CategoryCard({
    required this.title,
    required this.desc,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.warmBorder),
        boxShadow: AppShadows.cardLight,
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.s8),
            decoration: const BoxDecoration(
              color: AppColors.creamBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.bronze, size: 24),
          ),
          const Spacer(),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            desc,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryLight,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;

  const _HighlightTile({
    required this.title,
    required this.desc,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.s12),
          decoration: BoxDecoration(
            color: AppColors.sandSurface,
            borderRadius: BorderRadius.circular(AppSpacing.r8),
          ),
          child: Icon(icon, color: AppColors.bronze, size: 24),
        ),
        const SizedBox(width: AppSpacing.s16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                desc,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
