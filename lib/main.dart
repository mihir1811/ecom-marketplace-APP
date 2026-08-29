import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/l10n/app_localizations.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    
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
                      color: Color(0xFFDC2626),
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
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
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

    runApp(
      const ProviderScope(
        child: GemWorldApp(),
      ),
    );
  }, (Object error, StackTrace stack) {
    // Catch-all for async zones/isolates exceptions
  });
}
