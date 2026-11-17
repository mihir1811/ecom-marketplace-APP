import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/theme_preference_provider.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../maison/maison_kit.dart';
import '../maison/maison_layout.dart';
import '../widgets/settings/settings_parts.dart';

/// Preferences: who is signed in, look and language as visual choices,
/// then account, about / legal and session rows — destructive actions last
/// and confirmed in place.
///
/// Shared by both sides; [seller] points every row at the seller routes and
/// leaves the chrome to the seller shell.
class BuyerSettingsScreen extends ConsumerWidget {
  const BuyerSettingsScreen({this.seller = false, super.key});

  final bool seller;

  String _route(String buyer, String sellerRoute) =>
      seller ? sellerRoute : buyer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.atelier;
    final palette = ref.watch(palettePreferenceProvider);
    final locale = ref.watch(localePreferenceProvider);
    final auth = ref.watch(
      authProvider.select(
        (s) => (
          user: s.user,
          isSeller: s.isSeller,
          verified: !s.isVerificationPending,
        ),
      ),
    );
    final user = auth.user;
    final name = user == null
        ? context.tr(AccountCommerceL10n.accountLabel)
        : user.fullName.trim().isNotEmpty
        ? user.fullName.trim()
        : user.username.trim().isNotEmpty
        ? user.username.trim()
        : context.tr(AccountCommerceL10n.accountLabel);
    final gutter = AtelierSpace.gutter(MediaQuery.sizeOf(context).width);

    var i = 2;
    Widget reveal(Widget child) => Reveal(index: i++, child: child);

    final body = ListView(
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
              MaisonHeader(title: context.tr(CoreL10n.settings)),
              const SizedBox(height: 16),
              reveal(
                SettingsIdentityCard(
                  displayName: name,
                  email: user?.email ?? '',
                  imageUrl: user?.profilePicture,
                  isSeller: auth.isSeller,
                  verified: auth.verified,
                  onTap: () => context.openRoute(
                    _route(
                      AppRouteNames.buyerProfile,
                      AppRouteNames.sellerProfile,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              reveal(MaisonGroupLabel(label: context.tr(CoreL10n.appearance))),
              reveal(
                SettingsThemeChooser(
                  selected: palette,
                  onChanged: (id) {
                    AppHaptics.selection();
                    ref.read(palettePreferenceProvider.notifier).setPalette(id);
                  },
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(CoreL10n.paletteDescription),
                style: AtelierType.caption(p.muted, size: 11.5),
              ),
              const SizedBox(height: 8),
              reveal(MaisonGroupLabel(label: context.tr(CoreL10n.language))),
              reveal(
                SettingsLanguageChooser(
                  selected: locale,
                  onChanged: (l) {
                    AppHaptics.selection();
                    ref.read(localePreferenceProvider.notifier).setLocale(l);
                  },
                ),
              ),
              const SizedBox(height: 8),
              reveal(MaisonGroupLabel(label: context.tr(CoreL10n.account))),
              reveal(
                SettingsGroup(
                  children: [
                    SettingsRow(
                      icon: Icons.person_outline_rounded,
                      title: context.tr(AccountCommerceL10n.myProfile),
                      caption: 'Personal details and account status',
                      onTap: () => context.openRoute(
                        _route(
                          AppRouteNames.buyerProfile,
                          AppRouteNames.sellerProfile,
                        ),
                      ),
                    ),
                    SettingsRow(
                      icon: Icons.support_agent_outlined,
                      title: context.tr(AccountCommerceL10n.helpCenter),
                      caption: 'Answers, tickets and support',
                      onTap: () => context.openRoute(
                        _route(
                          AppRouteNames.buyerHelpCenter,
                          AppRouteNames.sellerHelpCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              reveal(const MaisonGroupLabel(label: 'About')),
              reveal(
                SettingsGroup(
                  children: [
                    SettingsRow(
                      icon: Icons.diamond_outlined,
                      title: context.tr(AccountCommerceL10n.aboutGemWorld),
                      caption: 'Our story, promise and marketplace',
                      onTap: () => context.openRoute(
                        _route(
                          AppRouteNames.buyerAbout,
                          AppRouteNames.sellerAbout,
                        ),
                      ),
                    ),
                    SettingsRow(
                      icon: Icons.privacy_tip_outlined,
                      title: context.tr(AccountCommerceL10n.privacyPolicy),
                      caption: 'How we collect and use your data',
                      onTap: () => context.openRoute(
                        _route(
                          AppRouteNames.buyerPrivacy,
                          AppRouteNames.sellerPrivacy,
                        ),
                      ),
                    ),
                    SettingsRow(
                      icon: Icons.description_outlined,
                      title: context.tr(AccountCommerceL10n.termsConditions),
                      caption: 'Marketplace rules of use',
                      onTap: () => context.openRoute(
                        _route(
                          AppRouteNames.buyerTerms,
                          AppRouteNames.sellerTerms,
                        ),
                      ),
                    ),
                    SettingsRow(
                      icon: Icons.menu_book_outlined,
                      title: context.tr(AccountCommerceL10n.policiesLegal),
                      caption: 'All policies in one place',
                      onTap: () => context.openRoute(
                        _route(
                          AppRouteNames.buyerPolicies,
                          AppRouteNames.sellerPolicies,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              reveal(const MaisonGroupLabel(label: 'Session')),
              reveal(
                SettingsGroup(
                  children: [
                    SettingsRow(
                      icon: Icons.logout_rounded,
                      title: context.tr(AccountCommerceL10n.signOut),
                      caption: user?.email,
                      chevron: false,
                      onTap: () => _signOut(context, ref),
                    ),
                    SettingsRow(
                      icon: Icons.delete_forever_outlined,
                      title: context.tr(AccountCommerceL10n.deleteAccount),
                      caption: context.tr(
                        AccountCommerceL10n.deleteRecoveryWindow,
                      ),
                      tone: AtelierTone.ruby,
                      chevron: false,
                      onTap: () => _deleteAccount(context, ref),
                    ),
                  ],
                ),
              ),
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
    if (seller) return ColoredBox(color: p.canvas, child: body);
    return MaisonLayout(detail: true, child: body);
  }

  static void _noop() {}

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAtelierConfirm(
      context: context,
      title: context.tr(AccountCommerceL10n.signOutTitle),
      message: context.tr(AccountCommerceL10n.signOutBody),
      confirmLabel: context.tr(AccountCommerceL10n.signOut),
      cancelLabel: context.tr(CoreL10n.cancel),
      icon: Icons.logout_rounded,
    );
    if (!confirmed || !context.mounted) return;
    AppHaptics.warning();
    ref.read(authProvider.notifier).logout();
    context.resetTo(AppRouteNames.home);
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final palette = context.atelier;
    final ok = await showDeleteAccountDialog(context);
    if (!ok || !context.mounted) return;

    final deletion = ref.read(authProvider);
    final until = deletion.accountDeletionRecoverUntil;
    final base =
        deletion.accountDeletionMessage ??
        'Your account is scheduled for deletion.';
    final detail = until == null
        ? base
        : '$base Recover by ${atelierDateTime(until.toLocal())}.';

    AppHaptics.heavy();
    showAtelierToastOn(
      messenger,
      palette,
      detail,
      tone: AtelierTone.amber,
      icon: Icons.schedule_rounded,
    );
    context.resetTo(AppRouteNames.recoverAccount);
  }
}
