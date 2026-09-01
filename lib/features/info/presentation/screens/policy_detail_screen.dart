import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../data/policies_repository.dart';
import '../../domain/models/policy_document.dart';

import '../../../../core/l10n/app_localizations.dart';

/// Renders any policy by [policyId] from [assets/policies/policies.json].
class PolicyDetailScreen extends StatefulWidget {
  const PolicyDetailScreen({super.key, required this.policyId});

  final String policyId;

  @override
  State<PolicyDetailScreen> createState() => _PolicyDetailScreenState();
}

class _PolicyDetailScreenState extends State<PolicyDetailScreen> {
  Locale? _loadedLocale;
  late Future<PolicyDocument?> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_loadedLocale?.languageCode == locale.languageCode) return;
    _loadedLocale = locale;
    _future = PoliciesRepository.loadById(widget.policyId, locale);
  }

  @override
  void didUpdateWidget(covariant PolicyDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.policyId != widget.policyId) {
      _future = PoliciesRepository.loadById(
        widget.policyId,
        _loadedLocale ?? Localizations.localeOf(context),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 720;
    final horizontal = isWide ? AppSpacing.s48 : AppSpacing.s20;

    return AppScaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppTopBar(
        title: context.tr(RemainingL10n.policy),
        backgroundColor: AppColors.bg(context),
        titleWidget: FutureBuilder<PolicyDocument?>(
          future: _future,
          builder: (context, snapshot) {
            return Text(
              snapshot.data?.title ?? context.tr(RemainingL10n.policy),
              style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
            );
          },
        ),
      ),
      body: FutureBuilder<PolicyDocument?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final document = snapshot.data;
          if (document == null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontal),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr(RemainingL10n.policyNotFound),
                      style: AppTypography.title.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    TextButton(
                      onPressed: () =>
                          context.openRoute(AppRouteNames.policies),
                      child: Text(context.tr(RemainingL10n.viewAllPolicies)),
                    ),
                  ],
                ),
              ),
            );
          }

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
                      document.eyebrow,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.bronze,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      document.title,
                      style: AppTypography.headline.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      context.tr(RemainingL10n.effectiveDateValue, {
                        'date': document.effectiveDate,
                      }),
                      style: AppTypography.label.copyWith(
                        color: AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s20),
                    Text(
                      document.intro,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondaryLight,
                        height: 1.55,
                      ),
                    ),
                    if (document.secondaryIntro != null) ...[
                      const SizedBox(height: AppSpacing.s12),
                      Text(
                        document.secondaryIntro!,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondaryLight,
                          height: 1.55,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.s24),
                    for (final section in document.sections) ...[
                      _SectionCard(section: section),
                      const SizedBox(height: AppSpacing.s16),
                    ],
                    const _PolicySupportCard(),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final PolicySection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${section.number}. ${section.title}',
            style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.s12),
          for (var i = 0; i < section.paragraphs.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.s8),
            Text(
              section.paragraphs[i],
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondaryLight,
                height: 1.55,
                fontSize: 15,
              ),
            ),
          ],
          if (section.bullets.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s8),
            for (final bullet in section.bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.bronze,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Text(
                        bullet,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondaryLight,
                          height: 1.55,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (section.closing != null) ...[
            const SizedBox(height: AppSpacing.s8),
            Text(
              section.closing!,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondaryLight,
                height: 1.55,
                fontSize: 15,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PolicySupportCard extends StatelessWidget {
  const _PolicySupportCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(RemainingL10n.needHelp),
            style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            context.tr(RemainingL10n.forQuestionsAboutThisPolicyOrders),
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondaryLight,
              height: 1.55,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              OutlinedButton(
                onPressed: () => context.push(AppRouteNames.buyerHelpCenter),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.charcoal,
                  side: const BorderSide(color: AppColors.warmBorder),
                ),
                child: Text(context.tr(RemainingL10n.helpCenter2)),
              ),
              TextButton(
                onPressed: () => context.push(AppRouteNames.policies),
                child: Text(
                  context.tr(RemainingL10n.allPolicies),
                  style: AppTypography.label.copyWith(
                    color: AppColors.bronze,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRouteNames.aboutUs),
                child: Text(
                  context.tr(RemainingL10n.aboutGemWorld),
                  style: AppTypography.label.copyWith(
                    color: AppColors.bronze,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
