import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/navigator_keys.dart';
import '../../core/router/route_names.dart';
import 'application/diamond_simulator_controller.dart';
import 'domain/diamond_shape.dart';
import 'presentation/screens/diamond_education_screen.dart';
import 'presentation/screens/diamond_simulator_screen.dart';

/// Diamond education page and the full-screen 3D simulator.
final List<RouteBase> diamondEducationRoutes = [
  GoRoute(
    path: AppRouteNames.diamondEducation,
    builder: (context, state) => const DiamondEducationScreen(),
  ),
  GoRoute(
    path: AppRouteNames.diamondSimulator,
    parentNavigatorKey: rootNavigatorKey,
    builder: (context, state) {
      final name = state.uri.queryParameters['shape'];
      final shape = SimShape.values.where((s) => s.name == name).firstOrNull;
      return ProviderScope(
        overrides: [
          simulatorStartShapeProvider.overrideWithValue(
            shape ?? SimShape.round,
          ),
        ],
        child: const DiamondSimulatorScreen(),
      );
    },
  ),
];
