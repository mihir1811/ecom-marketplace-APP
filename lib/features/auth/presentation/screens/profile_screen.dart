import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_user.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/router/workspace_mode.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../../core/widgets/gem3d/gem_renderer.dart';
import '../../../../core/widgets/gem3d/gem_view.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../application/user_profile_providers.dart';
import '../../domain/models/user_profile.dart';
import '../../../user_bank_account/application/user_bank_account_providers.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../../../core/theme/luxe_tokens.dart';

/// Account profile shared by the buyer and seller shells (read-only):
/// identity at a glance, then one section at a time. Seller accounts also
/// get business, tax & KYC and payouts; links stay on the side the user is
/// on.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

enum _Section { account, business, compliance, payouts }

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  _Section _section = _Section.account;
  final Set<String> _revealed = {};

  Future<void> _refresh() async {
    final business = ref.read(authProvider).isSeller;
    await Future.wait<void>([
      ref.refresh(userProfileProvider.future).then((_) {}, onError: (_) {}),
      if (business) ref.read(userBankAccountProvider.notifier).load(),
    ]);
  }

  void _select(_Section s) {
    if (s == _section) return;
    AppHaptics.selection();
    setState(() => _section = s);
  }

  void _toggleReveal(String id) {
    AppHaptics.selection();
    setState(
      () => _revealed.contains(id) ? _revealed.remove(id) : _revealed.add(id),
    );
  }

  Future<void> _copy(String label, String value) async {
    await atelierCopy(value);
    if (!mounted) return;
    showAtelierToast(context, '$label copied', icon: Icons.copy_rounded);
  }

  Future<String?> _requestDeletion(String password) async {
    final ok = await ref
        .read(authProvider.notifier)
        .requestAccountDeletion(password: password);
    if (ok) return null;
    if (!mounted) return '';
    return ref.read(authProvider).errorMessage ??
        context.tr(RemainingL10n.couldNotDeleteAccount);
  }

  Future<void> _deleteAccount() async {
    final deleted = await showAtelierDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteAccountDialog(onConfirm: _requestDeletion),
    );
    if (deleted != true || !mounted) return;

    final deletion = ref.read(authProvider);
    final until = deletion.accountDeletionRecoverUntil;
    final base =
        deletion.accountDeletionMessage ??
        context.tr(RemainingL10n.accountScheduledForDeletion);
    final detail = until == null
        ? base
        : '$base ${context.tr(RemainingL10n.recoverByDate, {'date': until.toLocal().toString()})}';

    AppHaptics.heavy();
    showAtelierToast(context, detail, icon: Icons.schedule_rounded);
    context.resetTo(AppRouteNames.recoverAccount);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final authUser = ref.watch(authProvider.select((s) => s.user));
    if (authUser == null) {
      return ColoredBox(
        color: p.canvas,
        child: Center(
          child: AtelierEmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'You’re signed out',
            message: context.tr(RemainingL10n.signInToViewYourProfile),
          ),
        ),
      );
    }

    final profileAsync = ref.watch(userProfileProvider);
    // Payout details exist only for seller (business) accounts.
    final bank = authUser.isSeller
        ? ref.watch(userBankAccountProvider)
        : const UserBankAccountState();

    final Widget page = profileAsync.when(
      skipLoadingOnReload: true,
      loading: () => const _ProfileSkeleton(),
      error: (e, _) => _body(
        userProfileFromAuth(authUser),
        authUser,
        bank,
        loadError: e is Failure ? e.message : e.toString(),
      ),
      data: (profile) => _body(profile, authUser, bank),
    );
    return ColoredBox(color: p.canvas, child: page);
  }

  Widget _body(
    UserProfile profile,
    AuthUser authUser,
    UserBankAccountState bankState, {
    String? loadError,
  }) {
    final bank = _BankView.from(profile, bankState);
    final facts = _ProfileFacts(profile, bank);
    final business = profile.isSeller;
    final seller = currentWorkspace(context) == AppWorkspace.seller;
    // An individual account only has the account section.
    if (!business && _section != _Section.account) _section = _Section.account;

    return AtelierPage(
      onRefresh: _refresh,
      maxWidth: 1080,
      children: [
        _IdentityHero(profile: profile, user: authUser, facts: facts),
        if (loadError != null) ...[
          const SizedBox(height: AtelierSpace.s16),
          Reveal(
            child: AtelierNotice(
              tone: AtelierTone.amber,
              icon: Icons.cloud_off_rounded,
              text:
                  '${context.tr(RemainingL10n.showingSignedInAccountDetailsFullProfile)}$loadError',
              actionLabel: context.tr(RemainingL10n.retry),
              onAction: () => ref.invalidate(userProfileProvider),
            ),
          ),
        ],
        const SizedBox(height: AtelierSpace.s24),
        if (business) ...[
          _GlanceRow(facts: facts, selected: _section, onSelect: _select),
          const SizedBox(height: AtelierSpace.s24),
        ],
        AnimatedSize(
          duration: AtelierMotion.slow,
          curve: AtelierMotion.emphasized,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: AtelierMotion.slow,
            switchInCurve: AtelierMotion.emphasized,
            switchOutCurve: Curves.easeIn,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, ?current],
            ),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.025),
                  end: Offset.zero,
                ).animate(a),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(_section),
              child: _sectionBody(profile, facts, bank),
            ),
          ),
        ),
        const SizedBox(height: AtelierSpace.s24),
        Reveal(
          index: 6,
          child: AtelierNotice(
            icon: Icons.lock_outline_rounded,
            text: context.tr(RemainingL10n.profileDetailsAreReadOnlyContact),
            actionLabel: 'Contact support',
            onAction: () => context.switchToRoute(
              seller
                  ? AppRouteNames.sellerHelpCenter
                  : AppRouteNames.buyerHelpCenter,
            ),
          ),
        ),
        const SizedBox(height: AtelierSpace.s40),
        Reveal(index: 7, child: _DangerZone(onDelete: _deleteAccount)),
      ],
    );
  }

  Widget _sectionBody(UserProfile p, _ProfileFacts facts, _BankView bank) {
    Widget grid(List<_Field> fields) => _FieldGrid(
      fields: fields,
      revealed: _revealed,
      onReveal: _toggleReveal,
      onCopy: _copy,
    );
    final tr = context.tr;
    switch (_section) {
      case _Section.account:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AtelierPanel(
              overline: 'Account',
              title: tr(RemainingL10n.personalDetails),
              subtitle: p.isSeller
                  ? 'How you sign in and how buyers see you.'
                  : 'How you sign in and how sellers see you.',
              child: grid([
                _Field(
                  tr(RemainingL10n.fullName),
                  p.fullName,
                  Icons.badge_outlined,
                ),
                _Field(
                  tr(RemainingL10n.username),
                  p.username,
                  Icons.alternate_email_rounded,
                  copyable: true,
                ),
                _Field(
                  tr(RemainingL10n.email),
                  p.email,
                  Icons.mail_outline_rounded,
                  copyable: true,
                ),
                _Field(
                  tr(RemainingL10n.verification),
                  p.isVerified
                      ? tr(RemainingL10n.verified)
                      : tr(AccountCommerceL10n.verificationPending),
                  Icons.verified_outlined,
                  pillTone: p.isVerified
                      ? AtelierTone.emerald
                      : AtelierTone.amber,
                ),
                _Field(
                  tr(AccountCommerceL10n.accountType),
                  p.isSeller
                      ? tr(AccountCommerceL10n.sellerBusiness)
                      : tr(AccountCommerceL10n.individualBuyer),
                  Icons.person_outline_rounded,
                ),
                _Field('Role', p.role, Icons.security_outlined),
              ]),
            ),
            if (facts.missing.isNotEmpty) ...[
              const SizedBox(height: AtelierSpace.s16),
              _MissingPanel(facts: facts, onSelect: _select),
            ],
          ],
        );
      case _Section.business:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CompanyPanel(profile: p),
            const SizedBox(height: AtelierSpace.s16),
            AtelierPanel(
              overline: 'Location',
              title: tr(AccountCommerceL10n.businessAddress),
              trailing: facts.address.isEmpty
                  ? null
                  : AtelierIconButton(
                      icon: Icons.copy_rounded,
                      tooltip: 'Copy address',
                      filled: true,
                      onPressed: () => _copy('Address', facts.address),
                    ),
              child: grid([
                _Field(
                  tr(AccountCommerceL10n.addressLine1),
                  p.addressLine1,
                  Icons.home_outlined,
                ),
                _Field(
                  tr(AccountCommerceL10n.addressLine2),
                  p.addressLine2,
                  Icons.home_work_outlined,
                ),
                _Field(
                  tr(AccountCommerceL10n.city),
                  p.city,
                  Icons.location_city_outlined,
                ),
                _Field(
                  tr(AccountCommerceL10n.state),
                  p.state,
                  Icons.map_outlined,
                ),
                _Field(
                  tr(AccountCommerceL10n.country),
                  p.country,
                  Icons.public_outlined,
                ),
                _Field(
                  tr(AccountCommerceL10n.postalCodeCaps),
                  p.zipCode,
                  Icons.markunread_mailbox_outlined,
                  copyable: true,
                ),
              ]),
            ),
            const SizedBox(height: AtelierSpace.s16),
            AtelierPanel(
              overline: 'People',
              title: tr(AccountCommerceL10n.businessContacts),
              child: grid([
                _Field(
                  'Phone 1',
                  p.businessPhone1,
                  Icons.phone_outlined,
                  copyable: true,
                ),
                _Field(
                  'Phone 2',
                  p.businessPhone2,
                  Icons.phone_outlined,
                  copyable: true,
                ),
                _Field(
                  'Representative 1',
                  p.representativeName1,
                  Icons.person_outline_rounded,
                ),
                _Field(
                  'Representative 2',
                  p.representativeName2,
                  Icons.person_outline_rounded,
                ),
              ]),
            ),
          ],
        );
      case _Section.compliance:
        return AtelierPanel(
          overline: 'Compliance',
          title: tr(AccountCommerceL10n.taxKyc),
          subtitle:
              '${facts.kycOnFile} of ${_ProfileFacts.kycTotal} on file · '
              'sensitive numbers stay hidden until you reveal them.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AtelierMeter(
                value: facts.kycOnFile / _ProfileFacts.kycTotal,
                color: facts.kycOnFile == _ProfileFacts.kycTotal
                    ? context.atelier.emerald
                    : null,
              ),
              const SizedBox(height: AtelierSpace.s20),
              grid([
                _Field(
                  'PAN',
                  p.panCardNumber,
                  Icons.credit_card_outlined,
                  copyable: true,
                  sensitive: true,
                ),
                _Field(
                  'Aadhaar',
                  p.aadhaarNumber,
                  Icons.fingerprint_rounded,
                  copyable: true,
                  sensitive: true,
                ),
                _Field(
                  'GST',
                  p.gstNumber,
                  Icons.receipt_long_outlined,
                  copyable: true,
                ),
                _Field(
                  'IEC',
                  p.iecNumber,
                  Icons.public_rounded,
                  copyable: true,
                ),
                _Field.document(
                  'PAN document',
                  p.panCardUrl,
                  Icons.upload_file_outlined,
                ),
              ]),
            ],
          ),
        );
      case _Section.payouts:
        if (bank.loading) {
          return const AtelierSkeletonList(count: 2, height: 140);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (bank.error != null && !bank.linked) ...[
              AtelierNotice(
                tone: AtelierTone.ruby,
                icon: Icons.error_outline_rounded,
                text: bank.error!,
                actionLabel: context.tr(RemainingL10n.retry),
                onAction: () =>
                    ref.read(userBankAccountProvider.notifier).load(),
              ),
              const SizedBox(height: AtelierSpace.s16),
            ],
            AtelierPanel(
              overline: 'Payouts',
              title: tr(RemainingL10n.bankDetails),
              subtitle: bank.linked
                  ? 'Where your sale proceeds are settled.'
                  : 'No payout account linked yet.',
              trailing: bank.linked
                  ? const AtelierPill(
                      label: 'Linked',
                      tone: AtelierTone.emerald,
                      icon: Icons.check_rounded,
                    )
                  : const AtelierPill(
                      label: 'Not linked',
                      tone: AtelierTone.ruby,
                    ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (bank.linked) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _PayoutCard(
                        bank: bank,
                        revealed: _revealed.contains('card'),
                        onReveal: () => _toggleReveal('card'),
                      ),
                    ),
                    const SizedBox(height: AtelierSpace.s24),
                  ],
                  grid([
                    _Field(
                      tr(RemainingL10n.accountHolder),
                      bank.holder,
                      Icons.account_circle_outlined,
                    ),
                    _Field(
                      tr(RemainingL10n.accountNumber),
                      bank.number,
                      Icons.pin_outlined,
                      copyable: true,
                      sensitive: true,
                    ),
                    _Field(
                      tr(RemainingL10n.ifscCode),
                      bank.ifsc,
                      Icons.qr_code_2_rounded,
                      copyable: true,
                    ),
                    _Field(
                      tr(RemainingL10n.bankName),
                      bank.name,
                      Icons.account_balance_outlined,
                    ),
                    _Field(
                      tr(RemainingL10n.accountType),
                      bank.type,
                      Icons.savings_outlined,
                    ),
                    _Field(
                      tr(RemainingL10n.upiId),
                      bank.upi,
                      Icons.payments_outlined,
                      copyable: true,
                    ),
                  ]),
                ],
              ),
            ),
          ],
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Derived view data
// ---------------------------------------------------------------------------

String? _clean(String? v) {
  final t = v?.trim() ?? '';
  return t.isEmpty ? null : t;
}

String _mask(String v) {
  final s = v.replaceAll(RegExp(r'\s'), '');
  if (s.length <= 4) return '••••';
  return '•••• ${s.substring(s.length - 4)}';
}

/// Bank details, preferring `/user-bank-account` over the profile snapshot.
class _BankView {
  const _BankView({
    required this.loading,
    required this.error,
    this.holder,
    this.number,
    this.ifsc,
    this.name,
    this.type,
    this.upi,
  });

  factory _BankView.from(UserProfile profile, UserBankAccountState state) {
    final a = state.account;
    return _BankView(
      loading: state.isLoading,
      error: state.errorMessage,
      holder: _clean(a?.accountHolderName ?? profile.accountHolderName),
      number: _clean(a?.accountNumber ?? profile.accountNumber),
      ifsc: _clean(a?.ifscCode ?? profile.ifscCode),
      name: _clean(a?.bankName ?? profile.bankName),
      type: _clean(a?.accountType?.label ?? profile.accountType),
      upi: _clean(a?.upiId ?? profile.upiId),
    );
  }

  final bool loading;
  final String? error;
  final String? holder;
  final String? number;
  final String? ifsc;
  final String? name;
  final String? type;
  final String? upi;

  bool get linked => number != null || upi != null;
}

/// One required profile detail and the section it lives in.
class _Requirement {
  const _Requirement(this.label, this.value, this.section);

  final String label;
  final String? value;
  final _Section section;

  bool get met => _clean(value) != null;
}

class _ProfileFacts {
  _ProfileFacts(this.profile, this.bank)
    : requirements = [
        for (final r in _all(profile, bank))
          if (profile.isSeller || r.section == _Section.account) r,
      ];

  static List<_Requirement> _all(UserProfile profile, _BankView bank) => [
    _Requirement('Full name', profile.fullName, _Section.account),
    _Requirement('Username', profile.username, _Section.account),
    _Requirement('Email', profile.email, _Section.account),
    _Requirement('Company name', profile.companyName, _Section.business),
    _Requirement('Seller type', profile.sellerType, _Section.business),
    _Requirement('Company logo', profile.companyLogoUrl, _Section.business),
    _Requirement(
      'Storefront banner',
      profile.bannerImageUrl,
      _Section.business,
    ),
    _Requirement('Address', profile.addressLine1, _Section.business),
    _Requirement('City', profile.city, _Section.business),
    _Requirement('State', profile.state, _Section.business),
    _Requirement('Country', profile.country, _Section.business),
    _Requirement('Postal code', profile.zipCode, _Section.business),
    _Requirement('Business phone', profile.businessPhone1, _Section.business),
    _Requirement(
      'Representative',
      profile.representativeName1,
      _Section.business,
    ),
    _Requirement('PAN', profile.panCardNumber, _Section.compliance),
    _Requirement('Aadhaar', profile.aadhaarNumber, _Section.compliance),
    _Requirement('IEC', profile.iecNumber, _Section.compliance),
    _Requirement('GST', profile.gstNumber, _Section.compliance),
    _Requirement('PAN document', profile.panCardUrl, _Section.compliance),
    _Requirement('Account holder', bank.holder, _Section.payouts),
    _Requirement('Account number', bank.number, _Section.payouts),
    _Requirement('IFSC code', bank.ifsc, _Section.payouts),
    _Requirement('Bank name', bank.name, _Section.payouts),
  ];

  static const kycTotal = 5;

  final UserProfile profile;
  final _BankView bank;
  final List<_Requirement> requirements;

  List<_Requirement> get missing => [
    for (final r in requirements)
      // Bank rows are unknown while loading; don't flag them yet.
      if (!r.met && !(bank.loading && r.section == _Section.payouts)) r,
  ];

  double get completeness =>
      requirements.where((r) => r.met).length / requirements.length;

  int get kycOnFile => requirements
      .where((r) => r.section == _Section.compliance && r.met)
      .length;

  String get address => [
    profile.addressLine1,
    profile.addressLine2,
    profile.city,
    profile.state,
    profile.zipCode,
    profile.country,
  ].map(_clean).whereType<String>().join(', ');
}

// ---------------------------------------------------------------------------
// Identity hero
// ---------------------------------------------------------------------------

class _IdentityHero extends StatelessWidget {
  const _IdentityHero({
    required this.profile,
    required this.user,
    required this.facts,
  });

  final UserProfile profile;
  final AuthUser user;
  final _ProfileFacts facts;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final soft = p.onOnyx.withValues(alpha: 0.62);
    final business = profile.isSeller;
    final name =
        _clean(profile.fullName) ??
        _clean(profile.username) ??
        (business ? 'Seller' : 'Your account');
    final picture =
        _clean(profile.profilePicture) ?? _clean(user.profilePicture) ?? '';
    final handle = _clean(profile.username);
    final email = _clean(profile.email);
    final pct = (facts.completeness * 100).round();

    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 640;
        final avatar = wide ? 42.0 : 34.0;
        final ring = avatar * 2 + 14;
        return ClipRRect(
          borderRadius: BorderRadius.circular(AtelierRadius.xl),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: LuxeStage.vault,
              border: Border.all(
                color: p.isDark ? p.hairline : Colors.transparent,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(
                    height: 1.2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          p.gold.withValues(alpha: 0),
                          p.gold.withValues(alpha: 0.8),
                          p.gold.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                if (wide)
                  const Positioned(
                    right: 26,
                    top: 18,
                    child: Reveal(
                      delay: Duration(milliseconds: 220),
                      child: GemView(
                        cut: GemCut.cushion,
                        look: GemLook.champagne,
                        size: 128,
                        spin: 0.28,
                        tilt: 0.36,
                        interactive: true,
                        semanticLabel: 'Rotating gem. Drag to turn it.',
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(wide ? 30 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Reveal(
                            index: 1,
                            child: Semantics(
                              label: 'Profile $pct% complete',
                              child: _RingedAvatar(
                                name: name,
                                url: picture,
                                radius: avatar,
                                ring: ring,
                                value: facts.completeness,
                              ),
                            ),
                          ),
                          SizedBox(width: wide ? 20 : 14),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: wide ? 120 : 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Reveal(
                                    index: 2,
                                    child: Text(
                                      name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AtelierType.display(
                                        p.onOnyx,
                                        size: wide ? 40 : 28,
                                        weight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Reveal(
                                    index: 3,
                                    child: Text(
                                      [
                                        if (handle != null) '@$handle',
                                        ?email,
                                      ].join('  ·  '),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AtelierType.body(soft, size: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: wide ? 20 : 16),
                      Reveal(
                        index: 4,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AtelierPill(
                              label: profile.isVerified
                                  ? (business
                                        ? context.tr(
                                            RemainingL10n.verifiedSellerAccount,
                                          )
                                        : context.tr(RemainingL10n.verified))
                                  : context.tr(
                                      AccountCommerceL10n.verificationPending,
                                    ),
                              tone: profile.isVerified
                                  ? AtelierTone.emerald
                                  : AtelierTone.amber,
                              icon: profile.isVerified
                                  ? Icons.verified_rounded
                                  : Icons.schedule_rounded,
                            ),
                            if (_clean(profile.companyName) != null)
                              AtelierPill(
                                label: profile.companyName!.trim(),
                                tone: AtelierTone.gold,
                                icon: Icons.storefront_outlined,
                              ),
                            if (_clean(profile.sellerType) != null)
                              AtelierPill(label: profile.sellerType!.trim()),
                          ],
                        ),
                      ),
                      SizedBox(height: wide ? 24 : 20),
                      Reveal(
                        index: 5,
                        child: Container(
                          height: 1,
                          color: p.onOnyx.withValues(alpha: 0.1),
                        ),
                      ),
                      SizedBox(height: wide ? 18 : 16),
                      Reveal(
                        index: 6,
                        child: AtelierHeroStats(
                          stats: !business
                              ? [
                                  AtelierHeroStat(
                                    label: 'Profile',
                                    value: '$pct%',
                                    caption: facts.missing.isEmpty
                                        ? 'Complete'
                                        : '${facts.missing.length} details missing',
                                    tone: facts.missing.isEmpty
                                        ? AtelierTone.emerald
                                        : AtelierTone.amber,
                                  ),
                                  AtelierHeroStat(
                                    label: 'Account',
                                    value: 'Individual',
                                    caption: context.tr(
                                      AccountCommerceL10n.individualBuyer,
                                    ),
                                  ),
                                  AtelierHeroStat(
                                    label: 'Status',
                                    value: profile.isVerified
                                        ? 'Verified'
                                        : 'Pending',
                                    caption: profile.isVerified
                                        ? 'Ready to buy'
                                        : 'Verification in review',
                                    tone: profile.isVerified
                                        ? AtelierTone.emerald
                                        : AtelierTone.amber,
                                  ),
                                ]
                              : [
                                  AtelierHeroStat(
                                    label: 'Profile',
                                    value: '$pct%',
                                    caption: facts.missing.isEmpty
                                        ? 'Complete'
                                        : '${facts.missing.length} details missing',
                                    tone: facts.missing.isEmpty
                                        ? AtelierTone.emerald
                                        : AtelierTone.amber,
                                  ),
                                  AtelierHeroStat(
                                    label: 'Tax & KYC',
                                    value:
                                        '${facts.kycOnFile}/${_ProfileFacts.kycTotal}',
                                    caption: 'Documents on file',
                                  ),
                                  AtelierHeroStat(
                                    label: 'Payouts',
                                    value: facts.bank.loading
                                        ? '—'
                                        : facts.bank.linked
                                        ? 'Linked'
                                        : 'Not linked',
                                    caption: facts.bank.number == null
                                        ? (facts.bank.upi ?? 'Bank account')
                                        : _mask(facts.bank.number!),
                                    tone: facts.bank.loading
                                        ? null
                                        : facts.bank.linked
                                        ? AtelierTone.emerald
                                        : AtelierTone.ruby,
                                  ),
                                ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Avatar wrapped in a gold ring that fills to the profile's completeness.
class _RingedAvatar extends StatelessWidget {
  const _RingedAvatar({
    required this.name,
    required this.url,
    required this.radius,
    required this.ring,
    required this.value,
  });

  final String name;
  final String url;
  final double radius;
  final double ring;
  final double value;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return AtelierRing(
      value: value,
      size: ring,
      stroke: 2.4,
      color: value >= 1 ? p.emerald : p.gold,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: p.onOnyx.withValues(alpha: 0.12)),
        ),
        child: ProfileAvatar(displayName: name, imageUrl: url, radius: radius),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// At-a-glance tiles (also the section switcher)
// ---------------------------------------------------------------------------

class _GlanceRow extends StatelessWidget {
  const _GlanceRow({
    required this.facts,
    required this.selected,
    required this.onSelect,
  });

  final _ProfileFacts facts;
  final _Section selected;
  final ValueChanged<_Section> onSelect;

  int _missingIn(_Section s) =>
      facts.missing.where((r) => r.section == s).length;

  @override
  Widget build(BuildContext context) {
    final profile = facts.profile;
    final bank = facts.bank;
    final verified = profile.isVerified;
    final kyc = facts.kycOnFile;

    String gaps(_Section s, String fallback) {
      final n = _missingIn(s);
      return n == 0 ? fallback : '$n to complete';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Reveal(
          index: 1,
          child: AtelierSectionHeader(title: 'Your account'),
        ),
        const SizedBox(height: AtelierSpace.s16),
        AtelierTileGrid(
          columns: 4,
          minTileWidth: 150,
          children: [
            _GlanceTile(
              icon: Icons.verified_user_outlined,
              label: 'Account',
              value: verified ? 'Verified' : 'Pending',
              caption: gaps(_Section.account, 'Identity & sign-in'),
              tone: verified ? AtelierTone.emerald : AtelierTone.amber,
              attention: !verified,
              selected: selected == _Section.account,
              onTap: () => onSelect(_Section.account),
            ),
            _GlanceTile(
              icon: Icons.storefront_outlined,
              label: 'Business',
              value: _clean(profile.companyName) ?? 'Not set',
              caption: gaps(
                _Section.business,
                _clean(profile.sellerType) ?? 'Company & address',
              ),
              selected: selected == _Section.business,
              onTap: () => onSelect(_Section.business),
            ),
            _GlanceTile(
              icon: Icons.shield_outlined,
              label: 'Tax & KYC',
              value: '$kyc of ${_ProfileFacts.kycTotal}',
              caption: kyc == _ProfileFacts.kycTotal
                  ? 'All documents on file'
                  : 'Documents on file',
              tone: kyc == _ProfileFacts.kycTotal
                  ? AtelierTone.emerald
                  : AtelierTone.gold,
              selected: selected == _Section.compliance,
              onTap: () => onSelect(_Section.compliance),
            ),
            _GlanceTile(
              icon: Icons.account_balance_outlined,
              label: 'Payouts',
              value: bank.loading
                  ? 'Loading…'
                  : bank.name ?? (bank.linked ? 'Linked' : 'Not linked'),
              caption: bank.number != null
                  ? _mask(bank.number!)
                  : (bank.upi ?? 'Add a bank account'),
              tone: bank.loading || bank.linked
                  ? AtelierTone.gold
                  : AtelierTone.ruby,
              attention: !bank.loading && !bank.linked,
              selected: selected == _Section.payouts,
              onTap: () => onSelect(_Section.payouts),
            ),
          ],
        ),
      ],
    );
  }
}

class _GlanceTile extends StatelessWidget {
  const _GlanceTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.selected,
    required this.onTap,
    this.tone = AtelierTone.gold,
    this.attention = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final AtelierTone tone;
  final bool attention;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Semantics(
      selected: selected,
      child: Pressable(
        onTap: onTap,
        semanticLabel: '$label, $value',
        borderRadius: BorderRadius.circular(AtelierRadius.lg),
        child: AnimatedContainer(
          duration: AtelierMotion.base,
          curve: AtelierMotion.emphasized,
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
          decoration: BoxDecoration(
            color: selected ? p.goldSoft : p.surface,
            borderRadius: BorderRadius.circular(AtelierRadius.lg),
            border: Border.all(
              color: selected ? p.gold : p.hairline,
              width: selected ? 1.3 : 1,
            ),
            boxShadow: selected ? null : p.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  AtelierIconBadge(icon: icon, tone: tone, size: 34),
                  const Spacer(),
                  if (attention) AtelierPulseDot(tone: tone),
                  AnimatedRotation(
                    turns: selected ? 0.25 : 0,
                    duration: AtelierMotion.base,
                    curve: AtelierMotion.emphasized,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: selected ? p.gold : p.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtelierType.overline(selected ? p.ink : p.muted),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtelierType.display(p.ink, size: 22),
              ),
              const SizedBox(height: 4),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtelierType.caption(p.muted, size: 11.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fields
// ---------------------------------------------------------------------------

class _Field {
  const _Field(
    this.label,
    this.value,
    this.icon, {
    this.copyable = false,
    this.sensitive = false,
    this.pillTone,
  }) : document = false;

  /// A file the seller uploaded: shown as "On file" / "Not provided".
  const _Field.document(this.label, this.value, this.icon)
    : copyable = false,
      sensitive = false,
      pillTone = null,
      document = true;

  final String label;
  final String? value;
  final IconData icon;
  final bool copyable;
  final bool sensitive;
  final bool document;
  final AtelierTone? pillTone;
}

class _FieldGrid extends StatelessWidget {
  const _FieldGrid({
    required this.fields,
    required this.revealed,
    required this.onReveal,
    required this.onCopy,
  });

  final List<_Field> fields;
  final Set<String> revealed;
  final ValueChanged<String> onReveal;
  final void Function(String label, String value) onCopy;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = AtelierSpace.s10;
        final cols = c.maxWidth >= 720 ? 3 : (c.maxWidth >= 420 ? 2 : 1);
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < fields.length; i++)
              SizedBox(
                width: w,
                child: Reveal(
                  index: i,
                  offset: 8,
                  child: _FieldCell(
                    field: fields[i],
                    revealed: revealed.contains(fields[i].label),
                    onReveal: () => onReveal(fields[i].label),
                    onCopy: onCopy,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FieldCell extends StatelessWidget {
  const _FieldCell({
    required this.field,
    required this.revealed,
    required this.onReveal,
    required this.onCopy,
  });

  final _Field field;
  final bool revealed;
  final VoidCallback onReveal;
  final void Function(String label, String value) onCopy;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final value = _clean(field.value);
    final empty = value == null;
    final hidden = field.sensitive && !revealed && !empty;
    final notProvided = context.tr(AccountCommerceL10n.notProvided);

    final Widget valueWidget;
    if (field.document) {
      valueWidget = AtelierPill(
        dense: true,
        label: empty ? notProvided : context.tr(AccountCommerceL10n.onFile),
        tone: empty ? AtelierTone.neutral : AtelierTone.emerald,
        icon: empty ? Icons.remove_rounded : Icons.check_rounded,
      );
    } else if (field.pillTone != null && !empty) {
      valueWidget = AtelierPill(
        dense: true,
        label: value,
        tone: field.pillTone!,
      );
    } else {
      valueWidget = AnimatedSwitcher(
        duration: AtelierMotion.base,
        transitionBuilder: (child, a) =>
            FadeTransition(opacity: a, child: child),
        child: Text(
          empty ? notProvided : (hidden ? _mask(value) : value),
          key: ValueKey('${field.label}-$hidden'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: empty
              ? AtelierType.body(
                  p.muted,
                  size: 13.5,
                ).copyWith(fontStyle: FontStyle.italic)
              : AtelierType.label(
                  p.ink,
                  size: 14,
                ).copyWith(letterSpacing: hidden ? 1.4 : null),
        ),
      );
    }

    final canCopy = field.copyable && !empty;
    final cell = Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: p.sunken.withValues(alpha: p.isDark ? 0.7 : 0.55),
        borderRadius: BorderRadius.circular(AtelierRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(field.icon, size: 13, color: p.gold),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        field.label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AtelierType.overline(p.muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                valueWidget,
              ],
            ),
          ),
          if (field.sensitive && !empty)
            _MiniAction(
              icon: revealed
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              tooltip: revealed ? 'Hide ${field.label}' : 'Show ${field.label}',
              onTap: onReveal,
            ),
          if (canCopy)
            _MiniAction(
              icon: Icons.copy_rounded,
              tooltip: 'Copy ${field.label}',
              onTap: () => onCopy(field.label, value),
            ),
        ],
      ),
    );
    return cell;
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onTap,
        semanticLabel: tooltip,
        scale: 0.86,
        borderRadius: BorderRadius.circular(AtelierRadius.pill),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 16, color: p.inkSoft),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section extras
// ---------------------------------------------------------------------------

class _MissingPanel extends StatelessWidget {
  const _MissingPanel({required this.facts, required this.onSelect});

  final _ProfileFacts facts;
  final ValueChanged<_Section> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final missing = facts.missing;
    return AtelierPanel(
      overline: 'Finish your profile',
      title: '${missing.length} details to complete',
      subtitle: facts.profile.isSeller
          ? 'Complete profiles earn buyer trust faster. Tap one to see where it lives.'
          : 'A complete profile speeds up verification. Tap one to see where it lives.',
      trailing: AtelierRing(
        value: facts.completeness,
        size: 52,
        stroke: 4,
        child: Text(
          '${(facts.completeness * 100).round()}%',
          style: AtelierType.figure(p.ink, size: 12),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < missing.length; i++)
            Reveal(
              index: i,
              offset: 6,
              child: AtelierChoiceChip(
                label: missing[i].label,
                icon: Icons.add_rounded,
                selected: false,
                onTap: () => onSelect(missing[i].section),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompanyPanel extends StatelessWidget {
  const _CompanyPanel({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final company = _clean(profile.companyName);
    final type = _clean(profile.sellerType);
    final banner = _clean(profile.bannerImageUrl);
    final logo = _clean(profile.companyLogoUrl);
    final notProvided = context.tr(AccountCommerceL10n.notProvided);
    final onFile = context.tr(AccountCommerceL10n.onFile);

    return AtelierCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AtelierRadius.lg),
            ),
            child: AspectRatio(
              aspectRatio: 3.6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [p.goldSoft, p.sunken],
                      ),
                    ),
                  ),
                  if (banner != null)
                    AppNetworkImage(
                      url: banner,
                      fit: BoxFit.cover,
                      memCacheWidth: 1400,
                      error: const SizedBox.shrink(),
                    )
                  else
                    Center(
                      child: Text(
                        'No storefront banner yet',
                        style: AtelierType.caption(p.muted),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AtelierSpace.s20),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AtelierRadius.sm),
                    boxShadow: p.softShadow,
                  ),
                  child: AtelierThumb(
                    url: logo,
                    size: 60,
                    icon: Icons.storefront_outlined,
                  ),
                ),
                const SizedBox(width: AtelierSpace.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(AccountCommerceL10n.company).toUpperCase(),
                        style: AtelierType.overline(p.gold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        company ?? notProvided,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AtelierType.display(
                          company == null ? p.muted : p.ink,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${context.tr(AccountCommerceL10n.sellerType)} · ${type ?? notProvided}',
                        style: AtelierType.caption(p.muted, size: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const AtelierHairline(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AtelierPill(
                  label: 'Logo · ${logo == null ? notProvided : onFile}',
                  tone: logo == null
                      ? AtelierTone.neutral
                      : AtelierTone.emerald,
                  icon: Icons.image_outlined,
                ),
                AtelierPill(
                  label: 'Banner · ${banner == null ? notProvided : onFile}',
                  tone: banner == null
                      ? AtelierTone.neutral
                      : AtelierTone.emerald,
                  icon: Icons.panorama_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Onyx payout card that tilts toward the pointer.
class _PayoutCard extends StatelessWidget {
  const _PayoutCard({
    required this.bank,
    required this.revealed,
    required this.onReveal,
  });

  final _BankView bank;
  final bool revealed;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final ink = LuxeStage.ink;
    final soft = ink.withValues(alpha: 0.6);
    final number = bank.number;
    final shown = number == null
        ? (bank.upi ?? '—')
        : revealed
        ? number
        : _mask(number);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: SizedBox(
        height: 212,
        child: TiltSurface(
          maxTilt: 0.1,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AtelierRadius.lg),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [LuxeStage.vaultTop, LuxeStage.vaultBottom],
              ),
              border: Border.all(color: p.gold.withValues(alpha: 0.35)),
              boxShadow: p.floatShadow,
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            bank.name ?? 'Payout account',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtelierType.display(ink, size: 22),
                          ),
                        ),
                        Pressable(
                          onTap: onReveal,
                          scale: 0.86,
                          semanticLabel: revealed
                              ? 'Hide account number'
                              : 'Show account number',
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              revealed
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: p.gold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: 38,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: p.goldGradient,
                      ),
                    ),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: AtelierMotion.base,
                      child: FittedBox(
                        key: ValueKey(shown),
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          shown,
                          style: AtelierType.figure(
                            ink,
                            size: 20,
                          ).copyWith(letterSpacing: 2.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _CardLabel(
                            label: 'Holder',
                            value: bank.holder ?? '—',
                            soft: soft,
                          ),
                        ),
                        _CardLabel(
                          label: 'IFSC',
                          value: bank.ifsc ?? '—',
                          soft: soft,
                          end: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardLabel extends StatelessWidget {
  const _CardLabel({
    required this.label,
    required this.value,
    required this.soft,
    this.end = false,
  });

  final String label;
  final String value;
  final Color soft;
  final bool end;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: end
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AtelierType.overline(soft)),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AtelierType.label(LuxeStage.ink, size: 13),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Danger zone & deletion
// ---------------------------------------------------------------------------

class _DangerZone extends StatelessWidget {
  const _DangerZone({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DANGER ZONE', style: AtelierType.overline(p.ruby)),
        const SizedBox(height: 6),
        Text(
          context.tr(RemainingL10n.deleteAccount),
          style: AtelierType.title(p.ink),
        ),
        const SizedBox(height: 4),
        Text(
          'Your account is scheduled for deletion and can be recovered '
          'within 7 days.',
          style: AtelierType.caption(p.muted, size: 12.5),
        ),
      ],
    );
    final button = AtelierButton(
      label: context.tr(RemainingL10n.deleteAccount),
      icon: Icons.delete_outline_rounded,
      variant: AtelierButtonVariant.danger,
      compact: true,
      onPressed: onDelete,
    );
    return AtelierCard(
      elevated: false,
      color: Colors.transparent,
      borderColor: p.ruby.withValues(alpha: 0.25),
      child: LayoutBuilder(
        builder: (context, c) => c.maxWidth >= 520
            ? Row(
                children: [
                  Expanded(child: text),
                  const SizedBox(width: 16),
                  button,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [text, const SizedBox(height: 16), button],
              ),
      ),
    );
  }
}

/// Collects the password and runs the deletion request in place, so a
/// wrong password is shown inline instead of closing the dialog.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.onConfirm});

  /// Returns null on success, otherwise the message to show.
  final Future<String?> Function(String password) onConfirm;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();
  final _focus = FocusNode();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _password.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final password = _password.text;
    if (password.trim().isEmpty) {
      AppHaptics.error();
      setState(() => _error = 'Enter your current password to continue.');
      return;
    }
    AppHaptics.warning();
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.onConfirm(password);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    AppHaptics.error();
    setState(() {
      _busy = false;
      _error = error.isEmpty ? null : error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final focused = _focus.hasFocus;
    final edge = _error != null
        ? p.ruby.withValues(alpha: 0.7)
        : focused
        ? p.gold.withValues(alpha: 0.75)
        : Colors.transparent;
    final passwordLabel = context.tr(AccountCommerceL10n.currentPassword);

    return PopScope(
      canPop: !_busy,
      child: AtelierDialogFrame(
        icon: Icons.delete_outline_rounded,
        tone: AtelierTone.ruby,
        title: context.tr(AccountCommerceL10n.deleteAccountTitle),
        message:
            'Your account will be scheduled for deletion. You have 7 days to '
            'recover it from the email link or the recover account screen.',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              passwordLabel.toUpperCase(),
              style: AtelierType.overline(focused ? p.gold : p.muted),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: AtelierMotion.base,
              curve: AtelierMotion.emphasized,
              height: 50,
              padding: const EdgeInsets.only(left: 16, right: 4),
              decoration: BoxDecoration(
                color: focused ? p.surface : p.sunken,
                borderRadius: BorderRadius.circular(AtelierRadius.md),
                border: Border.all(color: edge, width: 1.2),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 16, color: p.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _password,
                      focusNode: _focus,
                      autofocus: true,
                      enabled: !_busy,
                      obscureText: _obscure,
                      cursorColor: p.gold,
                      style: AtelierType.body(p.ink),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        hintText: passwordLabel,
                        hintStyle: AtelierType.body(p.muted),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: _obscure
                        ? context.tr(AccountCommerceL10n.showPassword)
                        : context.tr(AccountCommerceL10n.hidePassword),
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: p.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            AtelierFieldError(error: _error),
          ],
        ),
        actions: [
          AtelierButton(
            label: context.tr(CoreL10n.cancel),
            variant: AtelierButtonVariant.secondary,
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          ),
          AtelierButton(
            label: context.tr(AccountCommerceL10n.deleteAccount),
            variant: AtelierButtonVariant.danger,
            loading: _busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading
// ---------------------------------------------------------------------------

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return AtelierPage(
      onRefresh: () async {},
      maxWidth: 1080,
      children: [
        Container(
          height: 260,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: LuxeStage.vault,
            borderRadius: BorderRadius.circular(AtelierRadius.xl),
            border: Border.all(
              color: p.isDark ? p.hairline : Colors.transparent,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: LuxeStage.gold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AtelierSpace.s24),
        AtelierTileGrid(
          columns: 4,
          minTileWidth: 150,
          children: [
            for (var i = 0; i < 4; i++) const AtelierSkeletonCard(height: 132),
          ],
        ),
        const SizedBox(height: AtelierSpace.s24),
        const AtelierSkeletonList(count: 2, height: 160),
      ],
    );
  }
}
