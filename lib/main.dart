import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/l10n/app_localizations.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/theme_preference_provider.dart';
import 'features/diamond_education/simulation/sim_renderer.dart';
import 'features/notifications/application/push_messaging_service.dart';
import 'features/product_detail/presentation/transition/product_sheet_launch.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      // Lets product detail grow out of whichever card was tapped.
      ProductTapTracker.attach();
      await PushMessagingService.initializeFirebase();
      // Restore the palette before the first frame so it never flashes.
      final palette = await PalettePreference.load();

      // Layer 3 Error Boundary - Degrades gracefully in production rather than showing the red screen
      ErrorWidget.builder = (FlutterErrorDetails details) {
        return Builder(
          builder: (context) => Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr(CoreL10n.somethingWentWrong),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr(CoreL10n.unexpectedError),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      };

      FlutterError.onError = (FlutterErrorDetails details) {
        // In production, report to crash reporting (e.g. Sentry/Firebase Crashlytics)
        FlutterError.presentError(details);
      };

      // Compiles the diamond tracer behind the splash, not on the first
      // screen that shows a stone.
      unawaited(SimRenderer.warmUp());

      runApp(
        ProviderScope(
          overrides: [
            palettePreferenceProvider.overrideWith(
              (ref) => PalettePreference(palette.palette, palette.lastLight),
            ),
          ],
          child: const GemWorldApp(),
        ),
      );
    },
    (Object error, StackTrace stack) {
      // Catch-all for async zones/isolates exceptions
    },
  );
}
