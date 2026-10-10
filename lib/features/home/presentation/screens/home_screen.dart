import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/navigation/app_tab_top_bar.dart';
import '../../../../core/widgets/app_system_back_scope.dart';
import '../../../../core/widgets/navigation/start_selling_flow.dart';
import '../../../ai_chat/application/ai_chat_providers.dart';
import '../theme/home_tokens.dart';
import '../widgets/hero/home_hero.dart';
import '../widgets/home_atelier_links.dart';
import '../widgets/home_collections.dart';
import '../widgets/home_ai_search_card.dart';
import '../widgets/home_footer.dart';
import '../widgets/home_live_auctions.dart';
import '../widgets/home_search_overlay.dart';
import '../widgets/home_sell_card.dart';

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
    // The hero fills the view between the shared tab bar and the bottom nav.
    final viewHeight =
        media.size.height - media.padding.vertical - AppTabTopBar.height;
    final heroHeight = (viewHeight - 28).clamp(560.0, 940.0);

    return AppSystemBackScope(
      child: AppScaffold(
        backgroundColor: palette.canvas,
        safeBottom: false,
        appBar: const AppTabTopBar(),
        body: CustomScrollView(
          controller: _scroll,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: HomeHero(
                height: heroHeight,
                topInset: 8,
                scrollOffset: _offset,
                onSearch: _openSearch,
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
            SliverToBoxAdapter(child: HomeAiSearchCard(onAsk: _askGemAi)),
            if (!auth.isSeller)
              SliverToBoxAdapter(
                child: HomeSellCard(
                  isAuthenticatedIndividual: auth.isAuthenticated,
                  onTap: () => startSellingFlow(context, ref),
                ),
              ),
            const SliverToBoxAdapter(child: HomeFooter()),
            // The page scrolls behind the floating dock; end clear of it.
            SliverToBoxAdapter(child: SizedBox(height: media.padding.bottom)),
          ],
        ),
      ),
    );
  }
}
