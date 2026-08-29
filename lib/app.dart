import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/auth/auth_providers.dart';
import 'core/l10n/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_preference_provider.dart';
import 'core/widgets/keyboard_aware.dart';
import 'features/ai_chat/presentation/widgets/gem_ai_overlay.dart';
import 'features/auth/application/user_profile_providers.dart';

/// The root application widget configuring themes and GoRouter navigation.
class GemWorldApp extends ConsumerWidget {
  const GemWorldApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(themePreferenceProvider);
    final locale = ref.watch(localePreferenceProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => context.tr(CoreL10n.appTitle),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return AppFocusedFieldRevealer(
          child: Stack(
            fit: StackFit.expand,
            children: [
              child ?? const SizedBox.shrink(),
              const Positioned.fill(child: GemAiOverlay()),
              const _AccountProfileSync(),
              const _PreferenceHydrator(child: SizedBox.shrink()),
            ],
          ),
        );
      },
    );
  }
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
      ref.read(themePreferenceProvider.notifier).hydrate();
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
