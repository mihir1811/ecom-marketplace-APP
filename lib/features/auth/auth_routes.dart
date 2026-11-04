import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../../core/auth/business_registration_data.dart';
import '../../core/widgets/app_system_back_scope.dart';
import 'presentation/screens/forgot_password_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/recover_account_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/reset_password_screen.dart';
import 'presentation/screens/verify_otp_screen.dart';

/// Modular routes list for the Auth feature.
final List<RouteBase> authRoutes = [
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.login,
    builder: (context, state) => const LoginScreen(),
  ),
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.register,
    builder: (context, state) {
      final type = state.uri.queryParameters['type']?.trim().toLowerCase();
      final initial = type == 'business' || type == 'seller'
          ? RegistrationAccountType.business
          : RegistrationAccountType.individual;
      return AppSystemBackScope(
        fallbackLocation: AppRouteNames.login,
        child: RegisterScreen(initialAccountType: initial),
      );
    },
  ),
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.forgotPassword,
    builder: (context, state) => const AppSystemBackScope(
      fallbackLocation: AppRouteNames.login,
      child: ForgotPasswordScreen(),
    ),
  ),
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.verifyOtp,
    builder: (context, state) {
      final email = state.uri.queryParameters['email'];
      return AppSystemBackScope(
        fallbackLocation: AppRouteNames.login,
        child: VerifyOtpScreen(email: email),
      );
    },
  ),
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.resetPassword,
    builder: (context, state) {
      final token =
          state.uri.queryParameters['token'] ??
          state.uri.queryParameters['accessToken'];
      return AppSystemBackScope(
        fallbackLocation: AppRouteNames.login,
        child: ResetPasswordScreen(resetToken: token),
      );
    },
  ),
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.recoverAccount,
    builder: (context, state) {
      final token = state.uri.queryParameters['token'];
      return AppSystemBackScope(
        fallbackLocation: AppRouteNames.login,
        child: RecoverAccountScreen(recoveryToken: token),
      );
    },
  ),
];
