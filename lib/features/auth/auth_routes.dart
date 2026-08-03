import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import 'presentation/screens/forgot_password_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/reset_password_screen.dart';
import 'presentation/screens/verify_otp_screen.dart';

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
  GoRoute(
    path: AppRouteNames.verifyOtp,
    builder: (context, state) {
      final email = state.uri.queryParameters['email'];
      return VerifyOtpScreen(email: email);
    },
  ),
  GoRoute(
    path: AppRouteNames.resetPassword,
    builder: (context, state) {
      final token = state.uri.queryParameters['token'] ??
          state.uri.queryParameters['accessToken'];
      return ResetPasswordScreen(resetToken: token);
    },
  ),
];
