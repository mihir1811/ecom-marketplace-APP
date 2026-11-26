import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/deep_links/order_links.dart';
import 'core/l10n/app_localizations.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/theme_preference_provider.dart';
import 'features/notifications/application/push_messaging_service.dart';
import 'features/product_detail/presentation/transition/product_sheet_launch.dart';
import 'core/device/device_tier.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      // Budget phones / battery saver skip backdrop blurs (DeviceTier).
      DeviceTier.init();
      // Lets product detail grow out of whichever card was tapped.
      ProductTapTracker.attach();
      // WhatsApp order links tapped while the app runs (before the router).
      OrderLinks.attach();
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
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr(CoreL10n.somethingWentWrong),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
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
        if (kDebugMode) FlutterError.presentError(details);
      };

      runApp(
        ProviderScope(
          // Riverpod 3 retries failing providers automatically; this app
          // shows its own error/retry UI, so keep Riverpod 2 behaviour.
          retry: (_, _) => null,
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
      // Uncaught async errors: logged in debug only.
      if (kDebugMode) debugPrint('Uncaught: $error\n$stack');
    },
  );
}
