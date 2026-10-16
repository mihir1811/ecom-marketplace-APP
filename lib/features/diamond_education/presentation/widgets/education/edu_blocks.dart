import 'package:flutter/material.dart';

import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import '../../../../../core/widgets/luxe/scroll_reveal.dart';

/// Eyebrow, serif title and lead paragraph opening a page section.
class EduSectionHeader extends StatelessWidget {
  const EduSectionHeader({
    required this.title,
    this.eyebrow,
    this.body,
    super.key,
  });

  final String? eyebrow;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(eyebrow!, style: LuxeType.eyebrow(p.accent)),
          const SizedBox(height: 10),
        ],
        Semantics(
          header: true,
          child: Text(title, style: LuxeType.display(30, p.ink)),
        ),
        if (body != null) ...[
          const SizedBox(height: 12),
          Text(body!, style: LuxeType.body(p.inkMuted)),
        ],
      ],
    );
  }
}

/// Raised surface card used throughout the page.
class EduCard extends StatelessWidget {
  const EduCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(LuxeSpace.radius),
        border: Border.all(color: p.hairline),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Icon, bold title and supporting line.
class EduPoint extends StatelessWidget {
  const EduPoint({
    required this.title,
    required this.body,
    this.icon,
    this.leading,
    super.key,
  });

  final IconData? icon;
  final Widget? leading;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        leading ??
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: p.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: p.accent),
            ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: LuxeType.label(p.ink, size: 14.5)),
              const SizedBox(height: 3),
              Text(body, style: LuxeType.body(p.inkMuted, size: 13.5)),
            ],
          ),
        ),
      ],
    );
  }
}

/// A sub-heading inside a section.
class EduSubhead extends StatelessWidget {
  const EduSubhead(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Semantics(
      header: true,
      child: Text(text, style: LuxeType.display(22, p.ink)),
    );
  }
}

/// Section wrapper: reveal on scroll, consistent vertical rhythm.
class EduSection extends StatelessWidget {
  const EduSection({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ScrollReveal(
      child: Padding(
        padding: const EdgeInsets.only(top: 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// Forces the night palette for always-dark stages, so luxe controls on
/// them stay legible in the light theme too.
class EduDarkScope extends StatelessWidget {
  const EduDarkScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
    data: AppTheme.build(AppPalette.resolve(context).night),
    child: child,
  );
}
