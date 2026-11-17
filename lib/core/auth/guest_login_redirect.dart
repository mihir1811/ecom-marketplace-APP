import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/route_names.dart';

/// Placeholder for signed-in-only layouts when nobody is signed in.
///
/// Swaps the current page for the single `/login` route instead of rendering
/// a second, embedded copy of the login screen under another URL.
class GuestLoginRedirect extends StatefulWidget {
  const GuestLoginRedirect({super.key});

  @override
  State<GuestLoginRedirect> createState() => _GuestLoginRedirectState();
}

class _GuestLoginRedirectState extends State<GuestLoginRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final router = GoRouter.of(context);
      if (router.canPop()) {
        router.pushReplacement(AppRouteNames.login);
      } else {
        router.go(AppRouteNames.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: Theme.of(context).scaffoldBackgroundColor);
}
