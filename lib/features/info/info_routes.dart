import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import 'presentation/screens/about_us_screen.dart';
import 'presentation/screens/policies_hub_screen.dart';
import 'presentation/screens/policy_detail_screen.dart';

/// Public informational pages (About, Privacy, Terms, Policies hub).
/// Buyer and seller workspaces use their own dedicated screens.
final List<RouteBase> infoRoutes = [
  GoRoute(
    path: AppRouteNames.aboutUs,
    builder: (context, state) => const AboutUsScreen(),
  ),
  GoRoute(
    path: AppRouteNames.privacyPolicy,
    builder: (context, state) =>
        const PolicyDetailScreen(policyId: 'privacy'),
  ),
  GoRoute(
    path: AppRouteNames.termsAndConditions,
    builder: (context, state) => const PolicyDetailScreen(policyId: 'terms'),
  ),
  GoRoute(
    path: AppRouteNames.policies,
    builder: (context, state) => const PoliciesHubScreen(),
  ),
  GoRoute(
    path: AppRouteNames.policyDetail,
    builder: (context, state) =>
        PolicyDetailScreen(policyId: state.pathParameters['policyId'] ?? ''),
  ),
];
