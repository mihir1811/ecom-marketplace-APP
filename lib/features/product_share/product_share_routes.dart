import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import 'presentation/screens/shared_product_screen.dart';

final List<RouteBase> productShareRoutes = [
  GoRoute(
    path: AppRouteNames.productShare,
    builder: (context, state) => SharedProductScreen(
      token: state.pathParameters['token'] ?? '',
    ),
  ),
];
