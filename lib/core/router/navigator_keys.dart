import 'package:flutter/material.dart';

/// Root navigator key — kept outside [appRouter] to avoid circular imports
/// from feature route modules that need [parentNavigatorKey].
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
