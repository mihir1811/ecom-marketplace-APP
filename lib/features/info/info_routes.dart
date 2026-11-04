import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import 'presentation/screens/about_us_screen.dart';
import 'presentation/screens/policies_hub_screen.dart';
import 'presentation/screens/policy_detail_screen.dart';

/// Public informational pages (About, Privacy, Terms, Policies hub).
/// Buyer and seller workspaces use their own dedicated screens.
final List<RouteBase> infoRoutes = [
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.aboutUs,
    builder: (context, state) => const AboutUsScreen(),
  ),
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.privacyPolicy,
    builder: (context, state) => const PolicyDetailScreen(policyId: 'privacy'),
  ),
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.termsAndConditions,
    builder: (context, state) => const PolicyDetailScreen(policyId: 'terms'),
  ),
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.policies,
    builder: (context, state) => const PoliciesHubScreen(),
  ),
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.policyDetail,
    builder: (context, state) =>
        PolicyDetailScreen(policyId: state.pathParameters['policyId'] ?? ''),
  ),
];
