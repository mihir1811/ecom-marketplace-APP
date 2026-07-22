import 'package:flutter/material.dart';
import 'global_search_bar.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const GlobalSearchBar(),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
