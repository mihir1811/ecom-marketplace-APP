import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/router/app_navigation.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/language_menu_button.dart';
import 'auth_hero.dart';
import 'auth_theme_data.dart';
import 'auth_tokens.dart';

/// Width at which auth screens split into showcase + form.
const double kAuthWideBreakpoint = 960;

bool authIsWide(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kAuthWideBreakpoint;

/// Frame shared by every auth screen: a plain background, a quiet top bar
/// (back · wordmark · language · theme) and a centred, scrollable column.
/// On wide screens a showcase panel with a large live gem sits on the left.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.child,
    this.showBack = true,
    this.fallbackLocation = AppRouteNames.login,
    this.showWordmark = true,
  });

  final Widget child;
  final bool showBack;
  final String fallbackLocation;

  /// Whether the compact top bar shows the GemWorld wordmark.
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final palette = AuthPalette.of(context);
    final wide = authIsWide(context);

    final column = _AuthColumn(
      showBack: showBack,
      fallbackLocation: fallbackLocation,
      showWordmark: showWordmark,
      child: child,
    );

    return Theme(
      data: authThemeData(Theme.of(context), palette),
      child: AppScaffold(
        backgroundColor: palette.bg,
        enableAppDrawer: false,
        safeTop: false,
        safeBottom: false,
        body: SafeArea(
          child: wide
              ? Row(
                  children: [
                    const Expanded(child: _ShowcasePanel()),
                    Container(width: 1, color: palette.hairline),
                    SizedBox(width: 560, child: column),
                  ],
                )
              : column,
        ),
      ),
    );
  }
}

class _AuthColumn extends StatelessWidget {
  const _AuthColumn({
    required this.child,
    required this.showBack,
    required this.fallbackLocation,
    required this.showWordmark,
  });

  final Widget child;
  final bool showBack;
  final String fallbackLocation;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          _AuthTopBar(
            showBack: showBack,
            fallbackLocation: fallbackLocation,
            showWordmark: showWordmark,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, viewport) {
                const padding = EdgeInsets.fromLTRB(
                  AuthSpace.s24,
                  AuthSpace.s8,
                  AuthSpace.s24,
                  AuthSpace.s40,
                );
                // Fill at least the viewport so short forms sit in the
                // vertical centre; taller ones still scroll.
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: padding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (viewport.maxHeight - padding.vertical).clamp(
                        0.0,
                        double.infinity,
                      ),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AuthSpace.contentMaxWidth,
                        ),
                        child: child,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTopBar extends StatelessWidget {
  const _AuthTopBar({
    required this.showBack,
    required this.fallbackLocation,
    required this.showWordmark,
  });

  final bool showBack;
  final String fallbackLocation;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    final wide = authIsWide(context);
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AuthSpace.s12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!wide && showWordmark) const AuthWordmark(),
            Row(
              children: [
                if (showBack)
                  AuthIconCircle(
                    icon: Icons.arrow_back_rounded,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: () => AppNavigation.back(
                      context,
                      fallbackLocation: fallbackLocation,
                    ),
                  ),
                const Spacer(),
                IconTheme.merge(
                  data: IconThemeData(color: p.inkSoft),
                  child: const LanguageMenuButton(iconSize: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small circular glass button used for back/close affordances.
class AuthIconCircle extends StatelessWidget {
  const AuthIconCircle({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: p.surface,
        shape: CircleBorder(side: BorderSide(color: p.hairline)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 44,
            child: Icon(icon, size: 20, color: p.ink),
          ),
        ),
      ),
    );
  }
}

class _ShowcasePanel extends StatelessWidget {
  const _ShowcasePanel();

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    final reduced = AuthMotion.reduced(context);
    Widget reveal(Widget child, int i) => reduced
        ? child
        : child
              .animate(delay: AuthMotion.stagger(i))
              .fadeIn(duration: AuthMotion.entrance, curve: AuthMotion.ease)
              .moveY(begin: 24, end: 0, curve: AuthMotion.ease);

    return Padding(
      padding: const EdgeInsets.fromLTRB(64, 40, 48, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthWordmark(),
          const Spacer(),
          reveal(
            Text(
              context.tr(AuthL10n.showcaseTitle),
              style: AuthType.display(p).copyWith(fontSize: 54, height: 1.0),
            ),
            1,
          ),
          const SizedBox(height: AuthSpace.s16),
          reveal(
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                context.tr(AuthL10n.showcaseBody),
                style: AuthType.body(p).copyWith(fontSize: 16),
              ),
            ),
            2,
          ),
          const SizedBox(height: AuthSpace.s32),
          reveal(
            Wrap(
              spacing: AuthSpace.s24,
              runSpacing: AuthSpace.s12,
              children: [
                _TrustMark(
                  icon: Icons.verified_outlined,
                  label: context.tr(AuthL10n.trustVerified),
                ),
                _TrustMark(
                  icon: Icons.diamond_outlined,
                  label: context.tr(AuthL10n.trustCertified),
                ),
                _TrustMark(
                  icon: Icons.lock_outline_rounded,
                  label: context.tr(AuthL10n.trustSecure),
                ),
              ],
            ),
            3,
          ),
        ],
      ),
    );
  }
}

class _TrustMark extends StatelessWidget {
  const _TrustMark({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: p.accent),
        const SizedBox(width: AuthSpace.s8),
        Text(label, style: AuthType.caption(p).copyWith(color: p.inkSoft)),
      ],
    );
  }
}
