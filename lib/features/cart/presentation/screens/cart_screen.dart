import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../../core/widgets/gem3d/gem_renderer.dart';
import '../../../../core/widgets/gem3d/gem_view.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/navigation/app_tab_top_bar.dart';
import '../../application/cart_provider.dart';
import '../../application/fees_providers.dart';
import '../widgets/cart_address_section.dart';
import '../widgets/cart_checkout_button.dart';
import '../widgets/cart_items_section.dart';
import '../widgets/cart_promo_section.dart';
import '../widgets/cart_totals_section.dart';

/// Buyer cart — loads full cart+delivery once on open; sections watch slices.
///
/// Layout keeps the decision path short: pieces first, then where it ships,
/// promo and payment options, the summary, and a sticky bar that always
/// shows the payable total and the checkout action.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Microtask (not post-frame): runs before CartNotifier's light bootstrap
    // microtask joins this full load — avoids cancel+retry of the same APIs.
    Future.microtask(() {
      if (!mounted) return;
      ref.read(cartProvider.notifier).refresh(mode: CartLoadMode.full);
      ref.read(activeFeesProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    await Future.wait([
      ref
          .read(cartProvider.notifier)
          .refresh(mode: CartLoadMode.full, force: true),
      ref.read(activeFeesProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    final p = LuxePalette.of(context);
    final isLoading = ref.watch(cartIsLoadingProvider);
    final isEmpty = ref.watch(cartIsEmptyProvider);
    final error = ref.watch(cartErrorProvider);

    final Widget body;
    final String state;
    if (isLoading && isEmpty) {
      state = 'loading';
      body = const _CartSkeleton();
    } else if (error != null && isEmpty) {
      state = 'error';
      body = LuxeStateView(
        icon: Icons.cloud_off_rounded,
        tone: LuxeTone.error,
        title: context.tr(ExperienceL10n.cartLoadError),
        message: error,
        actionLabel: context.tr(AccountCommerceL10n.retry),
        onAction: _reload,
      );
    } else if (isEmpty) {
      state = 'empty';
      body = const _CartEmptyState();
    } else {
      state = 'content';
      body = RefreshIndicator(
        onRefresh: _reload,
        color: p.accent,
        child: ListView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            LuxeSpace.gutter - 4,
            8,
            LuxeSpace.gutter - 4,
            28,
          ),
          children: [
            const CartItemsSection(),
            const SizedBox(height: 6),
            ..._staggered(const [
              CartAddressSection(),
              CartPromoSection(),
              CartPaymentOptions(),
              CartTotalsSection(),
            ]),
          ],
        ),
      );
    }

    return AppScaffold(
      backgroundColor: p.canvas,
      appBar: const AppTabTopBar(),
      body: AnimatedSwitcher(
        duration: LuxeMotion.medium,
        switchInCurve: LuxeMotion.settle,
        child: KeyedSubtree(key: ValueKey(state), child: body),
      ),
      bottomNavigationBar: state == 'content' ? const CartCheckoutBar() : null,
    );
  }

  List<Widget> _staggered(List<Widget> sections) {
    final still = MediaQuery.disableAnimationsOf(context);
    return [
      for (var i = 0; i < sections.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: still
              ? sections[i]
              : sections[i]
                    .animate()
                    .fadeIn(delay: (140 + 70 * i).ms, duration: 420.ms)
                    .moveY(
                      begin: 16,
                      end: 0,
                      delay: (140 + 70 * i).ms,
                      duration: 640.ms,
                      curve: LuxeMotion.settle,
                    ),
        ),
    ];
  }
}

class _CartSkeleton extends StatelessWidget {
  const _CartSkeleton();

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    Widget card() => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(LuxeSpace.radius),
        border: Border.all(color: p.hairline),
      ),
      child: const Row(
        children: [
          LuxeSkeleton(width: 92, height: 92, radius: 14),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LuxeSkeleton(height: 16),
                SizedBox(height: 8),
                LuxeSkeleton(width: 110, height: 12),
                SizedBox(height: 22),
                LuxeSkeleton(width: 80, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        card(),
        card(),
        const LuxeSkeleton(height: 96, radius: LuxeSpace.radius),
        const SizedBox(height: 12),
        const LuxeSkeleton(height: 180, radius: LuxeSpace.radius),
      ],
    );
  }
}

class _CartEmptyState extends StatelessWidget {
  const _CartEmptyState();

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    Widget view = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 168,
              height: 168,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFF26252B), LuxeStage.obsidian],
                ),
              ),
              alignment: Alignment.center,
              child: const GemView(
                size: 140,
                cut: GemCut.cushion,
                look: GemLook.champagne,
                interactive: true,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              context.tr(AccountCommerceL10n.cartEmpty),
              textAlign: TextAlign.center,
              style: LuxeType.display(30, p.ink),
            ),
            const SizedBox(height: 10),
            Text(
              context.tr(ExperienceL10n.cartEmptyBody),
              textAlign: TextAlign.center,
              style: LuxeType.body(p.inkMuted, size: 14),
            ),
            const SizedBox(height: 26),
            LuxeButton(
              label: context.tr(AccountCommerceL10n.continueShopping),
              trailingIcon: Icons.arrow_forward_rounded,
              onPressed: () => context.goBack(),
            ),
          ],
        ),
      ),
    );
    if (!MediaQuery.disableAnimationsOf(context)) {
      view = view
          .animate()
          .fadeIn(duration: 500.ms)
          .moveY(begin: 18, end: 0, duration: 700.ms, curve: LuxeMotion.settle);
    }
    return view;
  }
}
