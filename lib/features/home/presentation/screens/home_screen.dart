import 'dart:async';

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
import '../../../../core/widgets/pause_when_offscreen.dart';
import '../../../ai_chat/application/ai_chat_providers.dart';
import '../../../live_shows/presentation/widgets/home_live_shows.dart';
import '../theme/home_tokens.dart';
import '../widgets/hero/home_hero.dart';
import '../widgets/home_collections.dart';
import '../widgets/home_ai_search_card.dart';
import '../widgets/home_footer.dart';
import '../widgets/home_gem_stage.dart';
import '../widgets/home_live_auctions.dart';
import '../widgets/home_sell_card.dart';
import '../widgets/home_section.dart';
import '../../../spotlight/presentation/widgets/spotlight_featured_sellers.dart';

/// GemWorld home: an immersive hero stage followed by editorial sections.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();
  final _offset = ValueNotifier<double>(0);

  Timer? _stageWarmup;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      _offset.value = _scroll.offset;
      // Leaving the hero: settle the closing gem stage's quality now, well
      // before it scrolls into view.
      if (_scroll.offset > 200) _warmUpStage();
    });
    // Or once the screen has been open a moment, whichever comes first.
    _stageWarmup = Timer(const Duration(seconds: 3), _warmUpStage);
  }

  void _warmUpStage() {
    if (_stageWarmup == null || !mounted) return;
    _stageWarmup!.cancel();
    _stageWarmup = null;
    final media = MediaQuery.of(context);
    HomeGemStage.warmUp(
      context,
      height: media.size.height - media.padding.top - SectionTopBar.height,
    );
  }

  @override
  void dispose() {
    _stageWarmup?.cancel();
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
    // Height actually visible between the shared tab bar and the floating
    // dock.
    final visibleHeight =
        media.size.height -
        media.padding.top -
        SectionTopBar.height -
        media.padding.bottom;
    // The stage is a header, not a screen: the spotlight overlaps its foot
    // and the collections heading plus the first tiles peek above the fold,
    // so the page never reads as finished at the first screen.
    final heroHeight = (visibleHeight * 0.62).clamp(340.0, 520.0);
    final gutter = homeGutter(context);

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
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HomeHero(
                      height: heroHeight,
                      topInset: 8,
                      scrollOffset: _offset,
                    ),
                    const HomeCollections(topSpacing: 24),
                  ],
                ),
              ),
              // HOME_FEATURED_SELLER: a row of seller cards.
              SliverToBoxAdapter(
                child: SpotlightFeaturedSellers(
                  gutter: gutter,
                  padding: const EdgeInsets.only(top: HomeSpace.section),
                  heading: (title, tag) =>
                      HomeSectionHeading(title: title, trailing: tag),
                ),
              ),
              // Looping shimmers / pulses / ambient motion pause while these
              // sections are scrolled away, so an idle home stops redrawing.
              const SliverToBoxAdapter(
                child: PauseWhenOffscreen(child: HomeLiveShows()),
              ),
              const SliverToBoxAdapter(
                child: PauseWhenOffscreen(child: HomeLiveAuctions()),
              ),
              SliverToBoxAdapter(
                child: PauseWhenOffscreen(
                  child: HomeAiSearchCard(onAsk: _askGemAi),
                ),
              ),
              if (!auth.isSeller)
                SliverToBoxAdapter(
                  child: PauseWhenOffscreen(
                    child: HomeSellCard(
                      isAuthenticatedIndividual: auth.isAuthenticated,
                      onTap: () => startSellingFlow(context, ref),
                    ),
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
