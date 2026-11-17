import 'package:flutter/material.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../info/data/policies_repository.dart';
import '../../../info/domain/models/policy_document.dart';
import '../../../info/presentation/widgets/policy_body.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_feedback.dart';
import '../atelier/atelier_studio.dart';
import '../atelier/atelier_theme.dart';

/// Seller Privacy Policy — Atelier studio reading experience.
class SellerPrivacyScreen extends StatelessWidget {
  const SellerPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SellerLegalDocumentScreen(policyId: 'privacy');
  }
}

/// Seller Terms & Conditions — Atelier studio reading experience.
class SellerTermsScreen extends StatelessWidget {
  const SellerTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SellerLegalDocumentScreen(policyId: 'terms');
  }
}

/// Seller policy detail for any marketplace policy id.
class SellerPolicyDetailScreen extends StatelessWidget {
  const SellerPolicyDetailScreen({required this.policyId, super.key});

  final String policyId;

  @override
  Widget build(BuildContext context) {
    return _SellerLegalDocumentScreen(policyId: policyId);
  }
}

class _SellerLegalDocumentScreen extends StatefulWidget {
  const _SellerLegalDocumentScreen({required this.policyId});

  final String policyId;

  @override
  State<_SellerLegalDocumentScreen> createState() =>
      _SellerLegalDocumentScreenState();
}

class _SellerLegalDocumentScreenState
    extends State<_SellerLegalDocumentScreen> {
  Locale? _locale;
  Future<PolicyDocument?>? _future;
  List<GlobalKey> _sectionKeys = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_locale?.languageCode == locale.languageCode && _future != null) return;
    _locale = locale;
    _reload();
  }

  @override
  void didUpdateWidget(covariant _SellerLegalDocumentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.policyId != widget.policyId) _reload();
  }

  void _reload() {
    _future =
        PoliciesRepository.loadById(
          widget.policyId,
          _locale ?? Localizations.localeOf(context),
        ).then((doc) {
          if (doc != null && mounted) {
            setState(() {
              _sectionKeys = List.generate(
                doc.sections.length,
                (_) => GlobalKey(),
              );
            });
          }
          return doc;
        });
    setState(() {});
  }

  Future<void> _jumpTo(int index) async {
    if (index < 0 || index >= _sectionKeys.length) return;
    AppHaptics.selection();
    final ctx = _sectionKeys[index].currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: context.reduceMotion ? Duration.zero : AtelierMotion.slow,
      curve: AtelierMotion.emphasized,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;

    return FutureBuilder<PolicyDocument?>(
      future: _future,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;
        final doc = snapshot.data;
        final failed =
            snapshot.connectionState == ConnectionState.done &&
            (snapshot.hasError || doc == null);

        return AtelierPage(
          onRefresh: () async => _reload(),
          maxWidth: 860,
          children: [
            AtelierHero(
              title: loading
                  ? context.tr(RemainingL10n.policy)
                  : (doc?.title ?? context.tr(RemainingL10n.policy)),
              action: failed
                  ? AtelierButton(
                      label: context.tr(RemainingL10n.retry),
                      icon: Icons.refresh_rounded,
                      onPressed: _reload,
                    )
                  : AtelierButton(
                      label: context.tr(RemainingL10n.allPolicies),
                      variant: AtelierButtonVariant.secondary,
                      icon: Icons.menu_book_outlined,
                      onPressed: () =>
                          context.openRoute(AppRouteNames.sellerPolicies),
                    ),
            ),
            const SizedBox(height: 14),
            if (loading)
              const PolicyDocumentSkeleton()
            else if (failed)
              AtelierEmptyState(
                title: context.tr(RemainingL10n.policyNotFound),
                message: context.tr(RemainingL10n.unableLoadPolicies),
                icon: Icons.menu_book_outlined,
                actionLabel: context.tr(RemainingL10n.viewAllPolicies),
                onAction: () => context.openRoute(AppRouteNames.sellerPolicies),
              )
            else ...[
              if (doc!.sections.length > 3) ...[
                PolicySectionRail(sections: doc.sections, onSelect: _jumpTo),
                const SizedBox(height: 12),
              ],
              PolicyDocumentBody(document: doc, sectionKeys: _sectionKeys),
              const SizedBox(height: 6),
              AtelierCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(RemainingL10n.needHelp),
                      style: AtelierType.title(p.ink),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr(
                        RemainingL10n.forQuestionsAboutThisPolicyOrders,
                      ),
                      style: AtelierType.body(p.inkSoft, size: 14),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AtelierButton(
                          label: context.tr(RemainingL10n.helpCenter2),
                          icon: Icons.support_agent_outlined,
                          onPressed: () =>
                              context.openRoute(AppRouteNames.sellerHelpCenter),
                        ),
                        AtelierButton(
                          label: context.tr(RemainingL10n.aboutGemWorld),
                          variant: AtelierButtonVariant.ghost,
                          onPressed: () =>
                              context.openRoute(AppRouteNames.sellerAbout),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
