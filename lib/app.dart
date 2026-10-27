import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/auth/auth_providers.dart';
import 'core/l10n/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_palette.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_preference_provider.dart';
import 'core/widgets/keyboard_aware.dart';
import 'core/widgets/navigation/bottom_nav/app_bottom_nav_host.dart';
import 'features/ai_chat/presentation/widgets/gem_ai_overlay.dart';
import 'features/auth/application/user_profile_providers.dart';
import 'features/gem_agent/gem_agent.dart';
import 'features/jewelry_checkout/application/jewelry_bag_sync.dart';
import 'features/notifications/application/notifications_provider.dart';
import 'features/notifications/presentation/widgets/in_app_notification_host.dart';

/// The root application widget configuring themes and GoRouter navigation.
class GemWorldApp extends ConsumerWidget {
  const GemWorldApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.byId(ref.watch(palettePreferenceProvider));
    final theme = AppTheme.build(palette);
    ref.listen(palettePreferenceProvider, (previous, next) {
      if (previous != next) _repaintAll(context);
    });
    final locale = ref.watch(localePreferenceProvider);
    ref.watch(notificationSessionProvider);
    ref.watch(jewelryBagSyncProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => context.tr(CoreL10n.appTitle),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: theme,
      darkTheme: theme,
      themeMode: palette.isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return AppFocusedFieldRevealer(
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppBottomNavHost(
                router: appRouter,
                child: child ?? const SizedBox.shrink(),
              ),
              const Positioned.fill(child: GemAgentOverlay()),
              const Positioned.fill(child: GemAiOverlay()),
              const _AccountProfileSync(),
              const _PreferenceHydrator(child: SizedBox.shrink()),
              const InAppNotificationHost(),
            ],
          ),
        );
      },
    );
  }
}

/// Rebuilds and repaints the whole tree after a palette switch so widgets
/// and painters that read context-free tokens ([AppPalette.current]) pick
/// up the new colours without losing state.
void _repaintAll(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    void visit(Element element) {
      element.markNeedsBuild();
      element.renderObject?.markNeedsPaint();
      element.visitChildren(visit);
    }

    (context as Element).visitChildren(visit);
  });
}

class _PreferenceHydrator extends ConsumerStatefulWidget {
  const _PreferenceHydrator({required this.child});
  final Widget child;

  @override
  ConsumerState<_PreferenceHydrator> createState() =>
      _PreferenceHydratorState();
}

class _PreferenceHydratorState extends ConsumerState<_PreferenceHydrator> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localePreferenceProvider.notifier).hydrate();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AccountProfileSync extends ConsumerWidget {
  const _AccountProfileSync();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authProvider.select((s) => s.user != null));
    if (signedIn) {
      ref.watch(userProfileProvider);
    }
    return const SizedBox.shrink();
  }
}
