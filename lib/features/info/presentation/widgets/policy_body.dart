import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../domain/models/policy_document.dart';

/// Effective-date chip shown under a policy title.
class PolicyEffectiveChip extends StatelessWidget {
  const PolicyEffectiveChip({required this.date, super.key});

  final String date;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: p.sunken,
        borderRadius: BorderRadius.circular(AtelierRadius.pill),
        border: Border.all(color: p.hairline),
      ),
      child: Text(
        context.tr(RemainingL10n.effectiveDateValue, {'date': date}),
        style: AtelierType.caption(p.muted, size: 11.5),
      ),
    );
  }
}

/// Horizontal jump list for long policy documents.
class PolicySectionRail extends StatelessWidget {
  const PolicySectionRail({
    required this.sections,
    required this.onSelect,
    super.key,
  });

  final List<PolicySection> sections;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final s = sections[i];
          return Pressable(
            onTap: () => onSelect(i),
            scale: 0.97,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(AtelierRadius.pill),
                border: Border.all(color: p.hairline),
              ),
              child: Text(
                '${s.number}. ${s.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtelierType.label(p.inkSoft, size: 12),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One numbered policy section as a calm card.
class PolicySectionCard extends StatelessWidget {
  const PolicySectionCard({
    required this.section,
    this.initiallyExpanded = true,
    super.key,
  });

  final PolicySection section;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return AtelierCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          iconColor: p.gold,
          collapsedIconColor: p.muted,
          title: Text(
            '${section.number}. ${section.title}',
            style: AtelierType.title(p.ink, size: 15.5),
          ),
          children: [
            for (var i = 0; i < section.paragraphs.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              Text(
                section.paragraphs[i],
                style: AtelierType.body(p.inkSoft, size: 14.5),
              ),
            ],
            if (section.bullets.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final bullet in section.bullets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: p.gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bullet,
                          style: AtelierType.body(p.inkSoft, size: 14.5),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (section.closing != null) ...[
              const SizedBox(height: 8),
              Text(
                section.closing!,
                style: AtelierType.body(p.inkSoft, size: 14.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton placeholders while a policy asset loads.
class PolicyDocumentSkeleton extends StatelessWidget {
  const PolicyDocumentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    Widget bar({double w = double.infinity, double h = 14}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: p.sunken,
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        bar(w: 120, h: 12),
        const SizedBox(height: 8),
        bar(w: 240, h: 28),
        const SizedBox(height: 8),
        bar(w: 160, h: 22),
        const SizedBox(height: 14),
        bar(h: 56),
        const SizedBox(height: 8),
        for (var i = 0; i < 4; i++) ...[bar(h: 72), const SizedBox(height: 8)],
      ],
    );
  }
}

/// Intro + expandable sections for a [PolicyDocument].
class PolicyDocumentBody extends StatelessWidget {
  const PolicyDocumentBody({
    required this.document,
    required this.sectionKeys,
    this.expandFirstOnly = true,
    super.key,
  });

  final PolicyDocument document;
  final List<GlobalKey> sectionKeys;
  final bool expandFirstOnly;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          document.eyebrow.toUpperCase(),
          style: AtelierType.overline(p.gold),
        ),
        const SizedBox(height: 8),
        Text(document.title, style: AtelierType.display(p.ink, size: 32)),
        const SizedBox(height: 8),
        PolicyEffectiveChip(date: document.effectiveDate),
        const SizedBox(height: 12),
        Text(document.intro, style: AtelierType.body(p.inkSoft, size: 15)),
        if (document.secondaryIntro != null) ...[
          const SizedBox(height: 8),
          Text(
            document.secondaryIntro!,
            style: AtelierType.body(p.inkSoft, size: 15),
          ),
        ],
        const SizedBox(height: 14),
        for (var i = 0; i < document.sections.length; i++) ...[
          KeyedSubtree(
            key: i < sectionKeys.length ? sectionKeys[i] : null,
            child: Reveal(
              index: (i % 6) + 1,
              child: PolicySectionCard(
                section: document.sections[i],
                initiallyExpanded: expandFirstOnly ? i == 0 : true,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
