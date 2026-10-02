import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_system_back_scope.dart';
import '../../../ai_chat/application/ai_chat_providers.dart';
import '../theme/home_tokens.dart';
import '../widgets/hero/home_hero.dart';
import '../widgets/home_atelier_links.dart';
import '../widgets/home_collections.dart';
import '../widgets/home_concierge_card.dart';
import '../widgets/home_footer.dart';
import '../widgets/home_header.dart';
import '../widgets/home_live_auctions.dart';
import '../widgets/home_promise.dart';
import '../widgets/home_search_overlay.dart';
import '../widgets/home_sell_card.dart';
import '../widgets/home_shape_atelier.dart';

/// GemWorld home: an immersive hero stage followed by editorial sections.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();
  final _offset = ValueNotifier<double>(0);
  final _collectionsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => _offset.value = _scroll.offset);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _offset.dispose();
    super.dispose();
  }

  void _openSearch() => showHomeSearch(context);

  void _askGemAi() {
    if (!ref.read(authProvider).isAuthenticated) {
      context.openRoute(AppRouteNames.login);
      return;
    }
    ref.read(aiChatUiProvider.notifier).open();
  }

  void _exploreCollections() {
    final target = _collectionsKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 1100),
      curve: HomeMotion.settle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final auth = ref.watch(
      authProvider.select(
        (s) => (isAuthenticated: s.isAuthenticated, isSeller: s.isSeller),
      ),
    );
    final media = MediaQuery.of(context);
    final topInset = media.padding.top + HomeHeader.barHeight;
    final heroHeight = (media.size.height - 28).clamp(620.0, 940.0);

    return AppSystemBackScope(
      child: AppScaffold(
        backgroundColor: palette.canvas,
        safeTop: false,
        body: Stack(
          children: [
            CustomScrollView(
              controller: _scroll,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: HomeHero(
                    height: heroHeight,
                    topInset: topInset,
                    scrollOffset: _offset,
                    onSearch: _openSearch,
                    onAskAi: _askGemAi,
                    onExplore: _exploreCollections,
                  ),
                ),
                if (auth.isAuthenticated)
                  const SliverToBoxAdapter(child: HomeAtelierLinks()),
                SliverToBoxAdapter(
                  key: _collectionsKey,
                  child: const HomeCollections(),
                ),
                const SliverToBoxAdapter(child: HomeLiveAuctions()),
                const SliverToBoxAdapter(child: HomeShapeAtelier()),
                SliverToBoxAdapter(child: HomeConciergeCard(onAsk: _askGemAi)),
                const SliverToBoxAdapter(child: HomePromise()),
                if (!auth.isSeller)
                  SliverToBoxAdapter(
                    child: HomeSellCard(
                      isAuthenticatedIndividual: auth.isAuthenticated,
                      onTap: () => _onSellTap(context, ref),
                    ),
                  ),
                const SliverToBoxAdapter(child: HomeFooter()),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: HomeHeader(
                scrollOffset: _offset,
                solidAfter: heroHeight - topInset,
                onSearch: _openSearch,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _onSellTap(BuildContext context, WidgetRef ref) async {
  final isAuthenticated = ref.read(authProvider).isAuthenticated;
  if (!isAuthenticated) {
    context.openRoute('${AppRouteNames.register}?type=business');
    return;
  }

  final goRegister = await showAppDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.tr(RemainingL10n.sellerAccountRequired)),
      content: Text(context.tr(RemainingL10n.sellerAccountRequiredBody)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.tr(RemainingL10n.notNow)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.tr(RemainingL10n.createSellerAccount)),
        ),
      ],
    ),
  );
  if (goRegister != true || !context.mounted) return;
  await ref.read(authProvider.notifier).logout();
  if (!context.mounted) return;
  context.resetTo('${AppRouteNames.register}?type=business');
}
