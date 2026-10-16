import '../../../../core/router/route_names.dart';

/// Routes where the Gem AI FAB / panel may appear.
abstract final class AiChatVisibility {
  static const _allowedExact = <String>{
    AppRouteNames.home,
    AppRouteNames.diamonds,
    AppRouteNames.diamondResults,
    AppRouteNames.labGrownDiamonds,
    AppRouteNames.labGrownDiamondResults,
    AppRouteNames.gemstones,
    AppRouteNames.gemstoneResults,
    AppRouteNames.jewelry,
    AppRouteNames.jewelryListing,
    AppRouteNames.jewelryFilters,
    AppRouteNames.watches,
    AppRouteNames.watchesFilters,
    AppRouteNames.bullions,
    AppRouteNames.bullionsFilters,
  };

  /// Hard exclusions — catalog allowlist must never win for these.
  static bool _isBlocked(String path) {
    if (path.isEmpty) return true;

    const blockedExact = <String>{
      AppRouteNames.cart,
      AppRouteNames.comparison,
      AppRouteNames.login,
      AppRouteNames.register,
      AppRouteNames.forgotPassword,
      AppRouteNames.verifyOtp,
      AppRouteNames.resetPassword,
      AppRouteNames.aboutUs,
      AppRouteNames.privacyPolicy,
      AppRouteNames.termsAndConditions,
      AppRouteNames.policies,
      AppRouteNames.diamondViewer,
    };
    if (blockedExact.contains(path)) return true;

    const blockedPrefixes = <String>[
      '/cart',
      '/comparison',
      '/product/',
      '/payment/',
      '/share/',
      '/viewer/',
      '/buyer/',
      '/seller/',
      '/login',
      '/register',
      '/forgot-password',
      '/verify-otp',
      '/reset-password',
      '/policies/',
    ];
    for (final prefix in blockedPrefixes) {
      if (path == prefix || path.startsWith(prefix)) return true;
    }
    return false;
  }

  /// Home, catalog filter/finder, and listing/results screens only.
  static bool isVisibleOn(String path) {
    if (_isBlocked(path)) return false;
    if (_allowedExact.contains(path)) return true;
    if (path.startsWith('/watches/brand/')) return true;
    return false;
  }
}
