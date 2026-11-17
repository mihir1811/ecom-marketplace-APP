import 'package:flutter/material.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../info/data/policies_repository.dart';
import '../../../info/domain/models/policy_document.dart';
import '../../../info/presentation/widgets/policy_body.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../maison/maison_kit.dart';
import '../maison/maison_layout.dart';

/// Buyer Privacy Policy — Maison shell, jump rail, expandable sections.
class BuyerPrivacyScreen extends StatelessWidget {
  const BuyerPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _BuyerLegalDocumentScreen(
      policyId: 'privacy',
      helpRoute: AppRouteNames.buyerHelpCenter,
      policiesRoute: AppRouteNames.buyerPolicies,
      aboutRoute: AppRouteNames.buyerAbout,
    );
  }
}

/// Buyer Terms & Conditions — Maison shell, same legal reading experience.
class BuyerTermsScreen extends StatelessWidget {
  const BuyerTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _BuyerLegalDocumentScreen(
      policyId: 'terms',
      helpRoute: AppRouteNames.buyerHelpCenter,
      policiesRoute: AppRouteNames.buyerPolicies,
      aboutRoute: AppRouteNames.buyerAbout,
    );
  }
}

/// Buyer policy detail for any id from the policies hub.
class BuyerPolicyDetailScreen extends StatelessWidget {
  const BuyerPolicyDetailScreen({required this.policyId, super.key});

  final String policyId;

  @override
  Widget build(BuildContext context) {
    return _BuyerLegalDocumentScreen(
      policyId: policyId,
      helpRoute: AppRouteNames.buyerHelpCenter,
      policiesRoute: AppRouteNames.buyerPolicies,
      aboutRoute: AppRouteNames.buyerAbout,
    );
  }
}

class _BuyerLegalDocumentScreen extends StatefulWidget {
  const _BuyerLegalDocumentScreen({
    required this.policyId,
    required this.helpRoute,
    required this.policiesRoute,
    required this.aboutRoute,
  });

  final String policyId;
  final String helpRoute;
  final String policiesRoute;
  final String aboutRoute;

  @override
  State<_BuyerLegalDocumentScreen> createState() =>
      _BuyerLegalDocumentScreenState();
}

class _BuyerLegalDocumentScreenState extends State<_BuyerLegalDocumentScreen> {
  Locale? _locale;
  Future<PolicyDocument?>? _future;
  final _scroll = ScrollController();
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
  void didUpdateWidget(covariant _BuyerLegalDocumentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.policyId != widget.policyId) _reload();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
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
    final gutter = AtelierSpace.gutter(MediaQuery.sizeOf(context).width);
    var i = 1;
    Widget reveal(Widget child) => Reveal(index: i++, child: child);

    return MaisonLayout(
      detail: true,
      child: FutureBuilder<PolicyDocument?>(
        future: _future,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState != ConnectionState.done;
          final doc = snapshot.data;
          final failed =
              snapshot.connectionState == ConnectionState.done &&
              (snapshot.hasError || doc == null);

          return ListView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 48),
            children: [
              MaisonCentered(
                maxWidth: 720,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MaisonHeader(
                      title: loading
                          ? context.tr(RemainingL10n.policy)
                          : (doc?.title ?? context.tr(RemainingL10n.policy)),
                    ),
                    const SizedBox(height: 14),
                    if (loading)
                      reveal(const PolicyDocumentSkeleton())
                    else if (failed)
                      reveal(
                        MaisonEmptyState(
                          title: context.tr(RemainingL10n.policyNotFound),
                          message: context.tr(RemainingL10n.unableLoadPolicies),
                          actionLabel: context.tr(
                            RemainingL10n.viewAllPolicies,
                          ),
                          onAction: () =>
                              context.openRoute(widget.policiesRoute),
                        ),
                      )
                    else ...[
                      if (doc!.sections.length > 3)
                        reveal(
                          PolicySectionRail(
                            sections: doc.sections,
                            onSelect: _jumpTo,
                          ),
                        ),
                      if (doc.sections.length > 3) const SizedBox(height: 12),
                      reveal(
                        PolicyDocumentBody(
                          document: doc,
                          sectionKeys: _sectionKeys,
                        ),
                      ),
                      const SizedBox(height: 6),
                      reveal(
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
                                  RemainingL10n
                                      .forQuestionsAboutThisPolicyOrders,
                                ),
                                style: AtelierType.body(p.inkSoft, size: 14),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  AtelierButton(
                                    label: context.tr(
                                      RemainingL10n.helpCenter2,
                                    ),
                                    icon: Icons.support_agent_outlined,
                                    onPressed: () =>
                                        context.openRoute(widget.helpRoute),
                                  ),
                                  AtelierButton(
                                    label: context.tr(
                                      RemainingL10n.allPolicies,
                                    ),
                                    variant: AtelierButtonVariant.secondary,
                                    onPressed: () =>
                                        context.openRoute(widget.policiesRoute),
                                  ),
                                  AtelierButton(
                                    label: context.tr(
                                      RemainingL10n.aboutGemWorld,
                                    ),
                                    variant: AtelierButtonVariant.ghost,
                                    onPressed: () =>
                                        context.openRoute(widget.aboutRoute),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const MaisonListFooter(
                      loadingMore: false,
                      hasMore: false,
                      onLoadMore: _noop,
                      endLabel: 'GemWorld · for collectors',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static void _noop() {}
}
