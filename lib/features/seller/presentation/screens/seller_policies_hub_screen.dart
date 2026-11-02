import 'package:flutter/material.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../../core/widgets/gem3d/gem_renderer.dart';
import '../../../info/data/policies_repository.dart';
import '../../../info/domain/models/policy_document.dart';
import '../../../info/presentation/widgets/policy_body.dart';
import '../../../info/presentation/widgets/policy_icons.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_feedback.dart';
import '../atelier/atelier_motion.dart';
import '../atelier/atelier_studio.dart';
import '../atelier/atelier_theme.dart';

/// Seller policies index — Atelier studio hub with search and quick jumps.
class SellerPoliciesHubScreen extends StatefulWidget {
  const SellerPoliciesHubScreen({super.key});

  @override
  State<SellerPoliciesHubScreen> createState() =>
      _SellerPoliciesHubScreenState();
}

class _SellerPoliciesHubScreenState extends State<SellerPoliciesHubScreen> {
  Locale? _locale;
  Future<List<PolicyDocument>>? _future;
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_locale?.languageCode == locale.languageCode && _future != null) {
      return;
    }
    _locale = locale;
    _reload();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    _future = PoliciesRepository.loadAll(
      _locale ?? Localizations.localeOf(context),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;

    return FutureBuilder<List<PolicyDocument>>(
      future: _future,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;
        final policies = snapshot.data ?? const <PolicyDocument>[];
        final failed =
            snapshot.connectionState == ConnectionState.done &&
            (snapshot.hasError || snapshot.data == null);
        final q = _query.trim().toLowerCase();
        final visible = q.isEmpty
            ? policies
            : policies
                  .where(
                    (d) =>
                        d.title.toLowerCase().contains(q) ||
                        d.subtitle.toLowerCase().contains(q),
                  )
                  .toList();

        return AtelierPage(
          onRefresh: () async => _reload(),
          maxWidth: 860,
          children: [
            AtelierHero(
              title: context.tr(RemainingL10n.policiesLegal),
              cut: GemCut.asscher,
              look: GemLook.ice,
              action: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AtelierButton(
                    label: context.tr(AccountCommerceL10n.privacyPolicy),
                    icon: Icons.privacy_tip_outlined,
                    variant: AtelierButtonVariant.gold,
                    onPressed: () =>
                        context.openRoute(AppRouteNames.sellerPrivacy),
                  ),
                  AtelierButton(
                    label: context.tr(AccountCommerceL10n.termsConditions),
                    icon: Icons.gavel_outlined,
                    variant: AtelierButtonVariant.secondary,
                    onPressed: () =>
                        context.openRoute(AppRouteNames.sellerTerms),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.tr(RemainingL10n.readTheTermsAndCategoryPolicies),
              style: AtelierType.body(p.inkSoft, size: 15),
            ),
            const SizedBox(height: 12),
            AtelierSearchField(
              controller: _searchCtrl,
              hint: 'Search policies',
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            if (loading)
              const PolicyDocumentSkeleton()
            else if (failed)
              AtelierEmptyState(
                title: context.tr(RemainingL10n.unableLoadPolicies),
                message: context.tr(
                  RemainingL10n.readTheTermsAndCategoryPolicies,
                ),
                actionLabel: context.tr(RemainingL10n.retry),
                onAction: _reload,
              )
            else if (visible.isEmpty)
              const AtelierEmptyState(
                title: 'No matching policies',
                message: 'Try a different search term.',
                icon: Icons.search_off_rounded,
              )
            else
              for (final policy in visible) ...[
                Reveal(
                  child: AtelierCard(
                    onTap: () {
                      AppHaptics.selection();
                      context.openRoute(
                        AppRouteNames.sellerPolicyPath(policy.id),
                      );
                    },
                    semanticLabel: policy.title,
                    child: Row(
                      children: [
                        AtelierIconBadge(icon: policyIconFor(policy.id)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                policy.title,
                                style: AtelierType.title(p.ink, size: 15.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                policy.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AtelierType.body(p.inkSoft, size: 13),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: p.muted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
          ],
        );
      },
    );
  }
}
