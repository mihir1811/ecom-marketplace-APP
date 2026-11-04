import 'package:flutter/material.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../../core/widgets/gem3d/gem_renderer.dart';
import '../../data/policies_repository.dart';
import '../../domain/models/policy_document.dart';
import '../widgets/policy_body.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';

/// Public policy reader (terms, privacy, and any policy from the hub).
class PolicyDetailScreen extends StatefulWidget {
  const PolicyDetailScreen({super.key, required this.policyId});

  final String policyId;

  @override
  State<PolicyDetailScreen> createState() => _PolicyDetailScreenState();
}

class _PolicyDetailScreenState extends State<PolicyDetailScreen> {
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
  void didUpdateWidget(covariant PolicyDetailScreen oldWidget) {
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
    final cut = widget.policyId == 'privacy'
        ? GemCut.oval
        : widget.policyId == 'terms'
        ? GemCut.emerald
        : GemCut.cushion;
    final look = widget.policyId == 'privacy' ? GemLook.ice : GemLook.champagne;

    return AppScaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        backgroundColor: p.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: AtelierIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () =>
              context.goBack(fallbackLocation: AppRouteNames.policies),
          filled: true,
        ),
      ),
      body: FutureBuilder<PolicyDocument?>(
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
                cut: cut,
                look: look,
                action: AtelierButton(
                  label: context.tr(RemainingL10n.allPolicies),
                  variant: AtelierButtonVariant.secondary,
                  icon: Icons.menu_book_outlined,
                  onPressed: () => context.openRoute(AppRouteNames.policies),
                ),
              ),
              const SizedBox(height: 14),
              if (loading)
                const PolicyDocumentSkeleton()
              else if (failed)
                AtelierEmptyState(
                  title: context.tr(RemainingL10n.policyNotFound),
                  message: context.tr(RemainingL10n.unableLoadPolicies),
                  actionLabel: context.tr(RemainingL10n.viewAllPolicies),
                  onAction: () => context.openRoute(AppRouteNames.policies),
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
                            label: context.tr(RemainingL10n.aboutGemWorld),
                            icon: Icons.diamond_outlined,
                            onPressed: () =>
                                context.openRoute(AppRouteNames.aboutUs),
                          ),
                          AtelierButton(
                            label: context.tr(RemainingL10n.allPolicies),
                            variant: AtelierButtonVariant.ghost,
                            onPressed: () =>
                                context.openRoute(AppRouteNames.policies),
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
      ),
    );
  }
}
