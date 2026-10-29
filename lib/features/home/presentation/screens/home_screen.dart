import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/navigation/top_bar/section_top_bar.dart';
import '../../../../core/widgets/app_system_back_scope.dart';
import '../../../../core/widgets/luxe/scroll_reveal.dart';
import '../../../../core/widgets/navigation/start_selling_flow.dart';
import '../../../ai_chat/application/ai_chat_providers.dart';
import '../../../live_shows/presentation/widgets/home_live_shows.dart';
import '../theme/home_tokens.dart';
import '../widgets/hero/home_hero.dart';
import '../widgets/home_collections.dart';
import '../widgets/home_ai_search_card.dart';
import '../widgets/home_footer.dart';
import '../widgets/home_live_auctions.dart';
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

  void _askGemAi() {
    if (!ref.read(authProvider).isAuthenticated) {
      context.openRoute(AppRouteNames.login);
      return;
    }
    ref.read(aiChatUiProvider.notifier).open();
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
    // The hero runs from the shared tab bar to the screen's bottom edge,
    // under the floating dock; its spotlight stays clear of the dock.
    final dockClearance = media.padding.bottom;
    final viewHeight =
        media.size.height - media.padding.top - SectionTopBar.height;
    final heroHeight = viewHeight.clamp(
      560.0 + dockClearance,
      940.0 + dockClearance,
    );

    return AppSystemBackScope(
      child: AppScaffold(
        backgroundColor: palette.canvas,
        safeBottom: false,
        appBar: const SectionTopBar(),
        body: ScrollRevealScope(
          child: CustomScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // One sliver so the collections paint above the hero's fade:
              // the viewport paints earlier slivers on top of later ones.
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HomeHero(
                      height: heroHeight,
                      topInset: 8,
                      bottomInset: dockClearance,
                      overlap: 72,
                      scrollOffset: _offset,
                    ),
                    // Rides up into the hero's fade so both read as one
                    // surface.
                    const HomeCollections(topSpacing: 8),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: HomeLiveShows()),
              const SliverToBoxAdapter(child: HomeLiveAuctions()),
              SliverToBoxAdapter(child: HomeAiSearchCard(onAsk: _askGemAi)),
              if (!auth.isSeller)
                SliverToBoxAdapter(
                  child: HomeSellCard(
                    isAuthenticatedIndividual: auth.isAuthenticated,
                    onTap: () => startSellingFlow(context, ref),
                  ),
                ),
              // Last stage fills the viewport and runs to the screen's bottom
              // edge behind the floating dock; its links clear the dock.
              SliverToBoxAdapter(
                child: HomeFooter(
                  stageHeight:
                      media.size.height -
                      media.padding.top -
                      SectionTopBar.height,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
