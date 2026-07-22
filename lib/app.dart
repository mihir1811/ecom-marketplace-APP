import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

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
    );
  }
}
