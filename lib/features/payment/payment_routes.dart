import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import 'presentation/screens/payment_confirmation_screen.dart';

final List<RouteBase> paymentRoutes = [
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.paymentConfirmation,
    builder: (context, state) => PaymentConfirmationScreen(
      orderId: state.pathParameters['orderId'] ?? '',
    ),
  ),
];
