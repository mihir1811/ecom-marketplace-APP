import 'package:flutter/material.dart';
import 'global_search_bar.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            GlobalSearchBar(isDark: isDark),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
