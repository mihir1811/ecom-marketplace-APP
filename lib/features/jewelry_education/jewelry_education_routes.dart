import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/navigator_keys.dart';
import '../../core/router/route_names.dart';
import 'application/jewelry_simulator_controller.dart';
import 'domain/jewelry_design.dart';
import 'presentation/screens/jewelry_education_screen.dart';
import 'presentation/screens/jewelry_simulator_screen.dart';

/// Jewelry education page and the full-screen 3D jewelry simulator.
final List<RouteBase> jewelryEducationRoutes = [
  GoRoute(
    path: AppRouteNames.jewelryEducation,
    builder: (context, state) => const JewelryEducationScreen(),
  ),
  GoRoute(
    path: AppRouteNames.jewelrySimulator,
    parentNavigatorKey: rootNavigatorKey,
    builder: (context, state) {
      final name = state.uri.queryParameters['type'];
      final type = JewelryType.values.where((t) => t.name == name).firstOrNull;
      return ProviderScope(
        overrides: [
          jewelryStartTypeProvider.overrideWithValue(type ?? JewelryType.ring),
        ],
        child: const JewelrySimulatorScreen(),
      );
    },
  ),
];
