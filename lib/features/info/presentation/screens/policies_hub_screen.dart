import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../data/policies_repository.dart';
import '../../domain/models/policy_document.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/translations/remaining_messages.dart';

/// Index of GemWorld Terms and marketplace policies (from JSON).
class PoliciesHubScreen extends StatefulWidget {
  const PoliciesHubScreen({super.key});

  @override
  State<PoliciesHubScreen> createState() => _PoliciesHubScreenState();
}

class _PoliciesHubScreenState extends State<PoliciesHubScreen> {
  Locale? _loadedLocale;
  late Future<List<PolicyDocument>> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_loadedLocale?.languageCode == locale.languageCode) return;
    _loadedLocale = locale;
    _future = PoliciesRepository.loadAll(locale);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 720;
    final horizontal = isWide ? AppSpacing.s48 : AppSpacing.s20;

    return AppScaffold(
      backgroundColor: AppColors.bg(context),
      appBar: SimpleAppTopBar(
        title: context.tr(RemainingL10n.policiesLegal),
        backgroundColor: AppColors.bg(context),
      ),
      body: FutureBuilder<List<PolicyDocument>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Text(
                context.tr(RemainingL10n.unableLoadPolicies),
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            );
          }

          final policies = snapshot.data!;
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  AppSpacing.s8,
                  horizontal,
                  AppSpacing.s48,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      'GemWorld Marketplace',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.bronze,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      context.tr(RemainingL10n.policiesLegal),
                      style: AppTypography.headline.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    Text(
                      context.tr(RemainingL10n.readTheTermsAndCategoryPolicies),
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondaryLight,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    for (final policy in policies) ...[
                      _PolicyTile(policy: policy),
                      const SizedBox(height: AppSpacing.s12),
                    ],
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PolicyTile extends StatelessWidget {
  const _PolicyTile({required this.policy});

  final PolicyDocument policy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warmWhite,
      borderRadius: BorderRadius.circular(AppSpacing.r12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        onTap: () => context.push(AppRouteNames.policyPath(policy.id)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.s20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.r12),
            border: Border.all(color: AppColors.warmBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      policy.title,
                      style: AppTypography.title.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      policy.subtitle,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondaryLight,
                        height: 1.4,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMutedLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
