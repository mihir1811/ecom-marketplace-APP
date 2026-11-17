import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/navigation/bottom_nav/app_bottom_nav_bar.dart';
import '../theme/home_tokens.dart';
import 'home_section.dart';

/// Whether the jewelry education link shows in the footer.
const _showJewelryEducation = false;

/// Closing section of home: education, about and legal links, clear of the
/// floating dock.
class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final gutter = homeGutter(context);

    Widget link(String key, String route) => TextButton(
      onPressed: () => context.openRoute(route),
      style: TextButton.styleFrom(
        foregroundColor: HomeStage.ink,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        minimumSize: const Size(44, 44),
      ),
      child: Text(context.tr(key), style: HomeType.label(HomeStage.inkMuted)),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        gutter,
        HomeSpace.section,
        gutter,
        AppBottomNavBar.clearance(media.padding.bottom),
      ),
      child: Column(
        children: [
          Container(width: 48, height: 1, color: HomeStage.glassBorder),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            children: [
              link(EducationL10n.navEducation, AppRouteNames.diamondEducation),
              // Jewelry education is hidden for now; its route and engine
              // stay in place.
              if (_showJewelryEducation)
                link(
                  JewelryEduL10n.navEducation,
                  AppRouteNames.jewelryEducation,
                ),
              link(RemainingL10n.aboutGemWorld, AppRouteNames.aboutUs),
              link(
                AccountCommerceL10n.privacyPolicy,
                AppRouteNames.privacyPolicy,
              ),
              link(
                RemainingL10n.termsConditions,
                AppRouteNames.termsAndConditions,
              ),
              link(RemainingL10n.policies, AppRouteNames.policies),
            ],
          ),
        ],
      ),
    );
  }
}
