import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/auth/auth_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/keyboard_aware.dart';
import 'features/ai_chat/presentation/widgets/gem_ai_overlay.dart';
import 'features/auth/application/user_profile_providers.dart';

/// The root application widget configuring themes and GoRouter navigation.
class GemWorldApp extends StatelessWidget {
  const GemWorldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GemWorld Diamond Marketplace',
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
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
            ],
          ),
        );
      },
    );
  }
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
