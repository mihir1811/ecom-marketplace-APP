import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import 'presentation/screens/forgot_password_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/register_screen.dart';

/// Modular routes list for the Auth feature.
final List<RouteBase> authRoutes = [
  GoRoute(
    path: AppRouteNames.login,
    builder: (context, state) => const LoginScreen(),
  ),
  GoRoute(
    path: AppRouteNames.register,
    builder: (context, state) => const RegisterScreen(),
  ),
  GoRoute(
    path: AppRouteNames.forgotPassword,
    builder: (context, state) => const ForgotPasswordScreen(),
  ),
];

