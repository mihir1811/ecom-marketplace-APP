import 'package:flutter/material.dart';

import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../home/presentation/home_network_images.dart';

/// Public About Us page for GemWorld — mission, values, and marketplace overview.
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  static const _values = <_ValueItem>[
    _ValueItem(
      icon: Icons.verified_outlined,
      title: 'Quality you can verify',
      body:
          'Every listing highlights certification, grading, and seller '
          'credentials — so you can buy with full confidence in authenticity '
          'and quality.',
    ),
    _ValueItem(
      icon: Icons.visibility_outlined,
      title: 'Transparency at every step',
      body:
          'Clear pricing, detailed specifications, and rich product imagery '
          'help you evaluate diamonds, gemstones, jewelry, watches, and '
          'bullion before you commit — no hidden fees or opaque sourcing.',
    ),
    _ValueItem(
      icon: Icons.support_agent_outlined,
      title: 'Expert guidance',
      body:
          'From comparing natural and lab-grown diamonds to evaluating '
          'gemstones, fine jewelry, and timepieces, our tools and support '
          'team help you make informed decisions at every stage.',
    ),
    _ValueItem(
      icon: Icons.handshake_outlined,
      title: 'Built for buyers and sellers',
      body:
          'We connect verified Indian sellers with buyers who expect '
          'professional service, secure transactions, and a marketplace '
          'designed for high-value trade.',
    ),
  ];

  static const _stats = <_StatItem>[
    _StatItem(value: '6', label: 'Core categories'),
    _StatItem(value: 'Pan-India', label: 'Marketplace reach'),
    _StatItem(value: 'GIA · IGI', label: 'Certification'),
    _StatItem(value: '24/7', label: 'Support tickets'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 720;

    return AppScaffold(
      backgroundColor: AppColors.bg(context),
      appBar: SimpleAppTopBar(
        title: 'About GemWorld',
        backgroundColor: AppColors.bg(context),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _HeroBanner(isWide: isWide)),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? AppSpacing.s48 : AppSpacing.s20,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.s32),
                const _Section(
                  eyebrow: 'Our story',
                  title: 'India\'s trusted marketplace for fine goods',
                  body:
                      'GemWorld was built on a simple idea: buying natural '
                      'diamonds, lab-grown diamonds, gemstones, fine jewelry, '
                      'luxury watches, and bullion online should feel '
                      'transparent, detailed, and free from storefront '
                      'pressure.\n\n'
                      'We built a multi-category marketplace for India where '
                      'verified sellers, rich product detail, and direct buyer '
                      'communication help you evaluate every piece before you '
                      'buy.',
                ),
                const SizedBox(height: AppSpacing.s24),
                const _PromiseSection(),
                const SizedBox(height: AppSpacing.s32),
                _StatsRow(stats: _stats, isWide: isWide),
                const SizedBox(height: AppSpacing.s32),
                const _Section(
                  eyebrow: 'What we do',
                  title: 'One platform for the full trade',
                  body:
                      'GemWorld brings together natural diamonds, lab-grown '
                      'diamonds, colored gemstones, fine jewelry, luxury '
                      'watches, and precious bullion on a single platform. '
                      'Whether you are sourcing certified stones, listing a '
                      'designer collection, trading a luxury timepiece, or '
                      'buying investment-grade gold, the experience is designed '
                      'for how India\'s diamond, gemstone, jewelry, and bullion '
                      'trade actually works.',
                ),
                const SizedBox(height: AppSpacing.s20),
                _CategoryChips(isWide: isWide),
                const SizedBox(height: AppSpacing.s32),
                Text(
                  'Our values',
                  style: AppTypography.headline.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                _ValuesGrid(values: _values, isWide: isWide),
                const SizedBox(height: AppSpacing.s32),
                _AudienceCards(isWide: isWide),
                const SizedBox(height: AppSpacing.s32),
                _TrustCard(),
                const SizedBox(height: AppSpacing.s32),
                _ContactCard(
                  onHelpTap: () => context.openRoute(AppRouteNames.buyerHelpCenter),
                  onSellTap: () => context.openRoute(AppRouteNames.login),
                ),
                const SizedBox(height: AppSpacing.s48),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final height = isWide ? 320.0 : 240.0;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const AppNetworkImage(
            url: HomeNetworkImages.hero,
            memCacheWidth: 1600,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66111827),
                  Color(0xCC111827),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? AppSpacing.s48 : AppSpacing.s24,
              vertical: AppSpacing.s24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Expert-driven marketplace\nfor luxury assets and fine goods',
                  style: AppTypography.display.copyWith(
                    color: AppColors.warmWhite,
                    fontSize: isWide ? 34 : 28,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                Text(
                  'India\'s marketplace for diamonds, gemstones, jewelry, watches & bullion',
                  style: AppTypography.body.copyWith(
                    color: AppColors.warmWhite.withValues(alpha: 0.88),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final String eyebrow;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: AppTypography.caption.copyWith(
            color: AppColors.bronze,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          title,
          style: AppTypography.headline.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        Text(
          body,
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondaryLight,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class _PromiseSection extends StatelessWidget {
  const _PromiseSection();

  static const _promises = [
    (
      icon: Icons.diamond_outlined,
      title: 'Certified quality',
      body:
          'GIA, IGI, and AGS-graded diamonds and gemstones with full '
          'specification detail.',
    ),
    (
      icon: Icons.compare_arrows_rounded,
      title: 'Compare with confidence',
      body:
          'Side-by-side tools to evaluate diamonds, gemstones, jewelry, '
          'and watches.',
    ),
    (
      icon: Icons.lock_outline,
      title: 'Secure transactions',
      body: 'Verified sellers, protected payments, and dedicated support.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OUR PROMISE',
          style: AppTypography.caption.copyWith(
            color: AppColors.bronze,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Shop with confidence',
          style: AppTypography.headline.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        for (final promise in _promises) ...[
          _SurfaceCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(promise.icon, color: AppColors.bronze, size: 24),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promise.title,
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        promise.body,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondaryLight,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
        ],
      ],
    );
  }
}

class _StatItem {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats, required this.isWide});

  final List<_StatItem> stats;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s12,
      runSpacing: AppSpacing.s12,
      children: [
        for (final stat in stats)
          SizedBox(
            width: isWide ? 172 : (MediaQuery.sizeOf(context).width - 52) / 2,
            child: _SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.value,
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    stat.label,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.isWide});

  final bool isWide;

  static const _categories = [
    'Natural diamonds',
    'Lab-grown diamonds',
    'Colored gemstones',
    'Fine jewelry',
    'Luxury watches',
    'Gold & silver bullion',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: [
        for (final label in _categories)
          Chip(
            label: Text(label),
            backgroundColor: AppColors.sandSurface,
            side: const BorderSide(color: AppColors.warmBorder),
            labelStyle: AppTypography.label.copyWith(
              color: AppColors.charcoal,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _ValueItem {
  const _ValueItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _ValuesGrid extends StatelessWidget {
  const _ValuesGrid({required this.values, required this.isWide});

  final List<_ValueItem> values;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final columns = isWide ? 2 : 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - (columns - 1) * AppSpacing.s12) / columns;

        return Wrap(
          spacing: AppSpacing.s12,
          runSpacing: AppSpacing.s12,
          children: [
            for (final value in values)
              SizedBox(
                width: itemWidth,
                child: _SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(value.icon, color: AppColors.bronze, size: 26),
                      const SizedBox(height: AppSpacing.s12),
                      Text(
                        value.title,
                        style: AppTypography.title.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        value.body,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondaryLight,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AudienceCards extends StatelessWidget {
  const _AudienceCards({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final children = [
      const _SurfaceCard(
        child: _AudienceBlock(
          icon: Icons.shopping_bag_outlined,
          title: 'For buyers',
          bullets: [
            'Search, filter, and compare across every core category',
            'Certification details and detailed product specifications',
            'Direct inquiries and secure checkout',
            'Pan-India delivery with order tracking',
          ],
        ),
      ),
      const _SurfaceCard(
        child: _AudienceBlock(
          icon: Icons.storefront_outlined,
          title: 'For sellers',
          bullets: [
            'List natural diamonds, lab-grown diamonds, gemstones, jewelry, watches, and bullion',
            'Seller dashboard with analytics and order management',
            'Inquiry inbox and direct buyer messaging',
            'Verified seller onboarding with document review',
          ],
        ),
      ),
    ];

    if (!isWide) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.s12),
            children[i],
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: children[0]),
        const SizedBox(width: AppSpacing.s12),
        Expanded(child: children[1]),
      ],
    );
  }
}

class _AudienceBlock extends StatelessWidget {
  const _AudienceBlock({
    required this.icon,
    required this.title,
    required this.bullets,
  });

  final IconData icon;
  final String title;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.charcoal, size: 28),
        const SizedBox(height: AppSpacing.s12),
        Text(
          title,
          style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.s12),
        for (final bullet in bullets) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Icon(
                  Icons.circle,
                  size: 6,
                  color: AppColors.bronze,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  bullet,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondaryLight,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
      ],
    );
  }
}

class _TrustCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      color: AppColors.charcoal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trust & security',
            style: AppTypography.title.copyWith(
              color: AppColors.warmWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            'High-value trade demands more than a shopping cart. GemWorld '
            'pairs certification verification (GIA, IGI, AGS) with verified '
            'seller checks, secure payment flows, and a dedicated help center — '
            'giving buyers and sellers across India the confidence to transact '
            'online.',
            style: AppTypography.body.copyWith(
              color: AppColors.bronzeLight,
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.onHelpTap,
    required this.onSellTap,
  });

  final VoidCallback onHelpTap;
  final VoidCallback onSellTap;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Get in touch',
            style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Questions about sourcing, selling, or certification in India? '
            'Our support team is here to help.',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondaryLight,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'support@gemworld.com',
            style: AppTypography.label.copyWith(
              color: AppColors.bronze,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Wrap(
            spacing: AppSpacing.s12,
            runSpacing: AppSpacing.s12,
            children: [
              FilledButton.icon(
                onPressed: onHelpTap,
                icon: const Icon(Icons.help_outline, size: 18),
                label: const Text('Help center'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.charcoal,
                  foregroundColor: AppColors.warmWhite,
                ),
              ),
              OutlinedButton.icon(
                onPressed: onSellTap,
                icon: const Icon(Icons.storefront_outlined, size: 18),
                label: const Text('Sell on GemWorld'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.charcoal,
                  side: const BorderSide(color: AppColors.charcoal),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.color,
  });

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        color: color ?? AppColors.warmWhite,
        borderRadius: BorderRadius.circular(AppSpacing.r16),
        border: color == null
            ? const Border.fromBorderSide(BorderSide(color: AppColors.warmBorder))
            : null,
      ),
      child: child,
    );
  }
}
