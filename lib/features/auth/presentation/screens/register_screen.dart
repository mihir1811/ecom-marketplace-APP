import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_validators.dart';
import '../../../../core/auth/business_registration_data.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../widgets/business_registration_fields.dart';
import '../widgets/kit/auth_kit.dart';

/// Registration for individual buyers (single page) and businesses
/// (five guided steps).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({
    this.initialAccountType = RegistrationAccountType.individual,
    super.key,
  });

  final RegistrationAccountType initialAccountType;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _stepperKey = GlobalKey();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralController = TextEditingController();
  final _businessFields = BusinessRegistrationFieldsController();
  late final TapGestureRecognizer _termsTapRecognizer;

  late RegistrationAccountType _accountType = widget.initialAccountType;
  int _sellerStep = 0;
  bool _stepForward = true;
  bool _acceptTerms = false;
  bool _termsError = false;
  bool _logoError = false;
  bool _referralOpen = false;
  XFile? _profilePicture;
  DateTime? _dateOfBirth;
  int _shake = 0;

  bool _didAutoRedirect = false;

  bool get _isSeller => _accountType == RegistrationAccountType.business;
  bool get _isLastSellerStep =>
      _sellerStep >= SellerRegistrationSteps.count - 1;

  @override
  void initState() {
    super.initState();
    _termsTapRecognizer = TapGestureRecognizer()
      ..onTap = () {
        if (!mounted) return;
        context.push(AppRouteNames.termsAndConditions);
      };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _termsTapRecognizer.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralController.dispose();
    _businessFields.dispose();
    super.dispose();
  }

  void _fail() {
    AppHaptics.error();
    setState(() => _shake++);
  }

  void _onAccountTypeChanged(RegistrationAccountType type) {
    if (type == _accountType) return;
    AppHaptics.selection();
    ref.read(authProvider.notifier).clearError();
    setState(() {
      _stepForward = type == RegistrationAccountType.business;
      _accountType = type;
      _sellerStep = 0;
    });
    // Typed values persist in controllers; only the visible sections change.
  }

  bool _validateCurrentStep() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) {
      _revealReferralIfInvalid();
      return false;
    }

    if (_isSeller && _sellerStep == 1) {
      final logoError = _businessFields.missingCompanyLogoMessage();
      if (logoError != null) {
        setState(() => _logoError = true);
        ref.read(authProvider.notifier).setErrorMessage(logoError);
        return false;
      }
    }
    return true;
  }

  void _revealReferralIfInvalid() {
    final value = _referralController.text.trim();
    if (!_referralOpen && _isReferralEmail(value) && !isValidEmail(value)) {
      setState(() => _referralOpen = true);
    }
  }

  void _goToStep(int step) {
    setState(() {
      _stepForward = step > _sellerStep;
      _sellerStep = step;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _stepperKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        duration: AuthMotion.slow,
        curve: AuthMotion.ease,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    });
  }

  void _continueSeller() {
    if (ref.read(authProvider).isLoading) return;
    ref.read(authProvider.notifier).clearError();
    if (!_validateCurrentStep()) {
      _fail();
      return;
    }
    if (_isLastSellerStep) {
      _submit();
      return;
    }
    AppHaptics.selection();
    _goToStep(_sellerStep + 1);
  }

  void _backSeller() {
    ref.read(authProvider.notifier).clearError();
    if (_sellerStep == 0) return;
    _goToStep(_sellerStep - 1);
  }

  Future<void> _submit() async {
    if (ref.read(authProvider).isLoading) return;
    final notifier = ref.read(authProvider.notifier);
    notifier.clearError();

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) {
      _revealReferralIfInvalid();
      _fail();
      return;
    }

    if (!_acceptTerms) {
      setState(() => _termsError = true);
      notifier.setErrorMessage(context.tr(AccountCommerceL10n.termsAgreement));
      _fail();
      return;
    }

    BusinessRegistrationData? business;
    if (_isSeller) {
      final filesError = _businessFields.missingFilesMessage();
      if (filesError != null) {
        notifier.setErrorMessage(filesError);
        _fail();
        return;
      }
      business = _businessFields.toData();
      if (business == null) {
        notifier.setErrorMessage(
          context.tr(AccountCommerceL10n.sellerIncomplete),
        );
        _fail();
        return;
      }
    }

    final registered = await notifier.register(
      fullName: _fullNameController.text,
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      acceptTerms: _acceptTerms,
      registrationType: _accountType,
      business: business,
      profilePicture: _profilePicture,
      referralEmail: _isReferralEmail(_referralController.text.trim())
          ? _referralController.text
          : null,
      referralCode: _isReferralEmail(_referralController.text.trim())
          ? null
          : _referralController.text,
      dateOfBirth: _isSeller ? null : _dateOfBirth,
    );
    if (!mounted) return;
    if (!registered) {
      _fail();
      return;
    }
    AppHaptics.success();
    final pending = ref.read(authProvider).pendingVerificationEmail;
    if (pending != null && pending.isNotEmpty) {
      context.go(
        '${AppRouteNames.verifyOtp}?email=${Uri.encodeComponent(pending)}',
      );
    }
  }

  Future<void> _pickProfile() async {
    final file = await pickAuthImage();
    if (file == null || !mounted) return;
    AppHaptics.selection();
    setState(() => _profilePicture = file);
  }

  Widget _stepBody(bool loading) {
    if (!_isSeller || _sellerStep == 0) {
      return _BasicDetailsFields(
        fullNameController: _fullNameController,
        usernameController: _usernameController,
        emailController: _emailController,
        passwordController: _passwordController,
        referralController: _referralController,
        profilePicture: _profilePicture,
        isLoading: loading,
        showDateOfBirth: !_isSeller,
        showPasswordRules: !_isSeller,
        dateOfBirth: _dateOfBirth,
        referralOpen: _referralOpen,
        onToggleReferral: () => setState(() => _referralOpen = !_referralOpen),
        onDateOfBirthChanged: (value) => setState(() => _dateOfBirth = value),
        onPickProfile: _pickProfile,
      );
    }
    return switch (_sellerStep) {
      1 => BusinessCompanyStep(
        controller: _businessFields,
        enabled: !loading,
        logoError: _logoError,
        onChanged: () => setState(() {}),
      ),
      2 => BusinessAddressStep(controller: _businessFields, enabled: !loading),
      3 => BusinessContactsKycStep(
        controller: _businessFields,
        enabled: !loading,
        onChanged: () => setState(() {}),
      ),
      _ => BusinessBankStep(
        controller: _businessFields,
        enabled: !loading,
        onChanged: () => setState(() {}),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(
      authProvider.select(
        (s) => (
          isAuthenticated: s.isAuthenticated,
          isLoading: s.isLoading,
          errorMessage: s.errorMessage,
        ),
      ),
    );

    if (authState.isAuthenticated && !_didAutoRedirect) {
      _didAutoRedirect = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.go(AppRouteNames.home);
      });
    }

    final loading = authState.isLoading;
    final p = AuthPalette.of(context);
    final showTerms = !_isSeller || _isLastSellerStep;
    final dir = _stepForward ? 1.0 : -1.0;

    return AuthShell(
      showWordmark: !_isSeller,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHero(
                eyebrow: context.tr(
                  _isSeller
                      ? AccountCommerceL10n.sellerAccount
                      : AccountCommerceL10n.newAccount,
                ),
                title: _isSeller ? null : context.tr(AuthL10n.registerTitle),
                subtitle: _isSeller
                    ? null
                    : Text(
                        context.tr(AuthL10n.registerSubtitle),
                        textAlign: TextAlign.center,
                      ),
              ),
              const SizedBox(height: AuthSpace.s24),
              AuthReveal(
                index: 4,
                child: AuthSegmented<RegistrationAccountType>(
                  value: _accountType,
                  enabled: !loading,
                  onChanged: _onAccountTypeChanged,
                  segments: [
                    AuthSegment(
                      value: RegistrationAccountType.individual,
                      label: context.tr(AuthL10n.individual),
                      icon: Icons.person_outline_rounded,
                    ),
                    AuthSegment(
                      value: RegistrationAccountType.business,
                      label: context.tr(AuthL10n.business),
                      icon: Icons.storefront_outlined,
                    ),
                  ],
                ),
              ),
              if (!_isSeller) ...[
                const SizedBox(height: AuthSpace.s12),
                AuthReveal(
                  index: 5,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: p.inkMuted,
                        ),
                      ),
                      const SizedBox(width: AuthSpace.s8),
                      Expanded(
                        child: Text(
                          context.tr(AuthL10n.individualHint),
                          style: AuthType.caption(p),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: _isSeller ? AuthSpace.s24 : AuthSpace.s32),
              AnimatedSize(
                duration: AuthMotion.base,
                curve: AuthMotion.ease,
                alignment: Alignment.topCenter,
                child: _isSeller
                    ? Padding(
                        key: _stepperKey,
                        padding: const EdgeInsets.only(bottom: AuthSpace.s24),
                        child: AuthStepper(
                          current: _sellerStep,
                          titles: [
                            for (final t in SellerRegistrationSteps.titles)
                              context.tr(t),
                          ],
                          hints: [
                            for (final h in SellerRegistrationSteps.hints)
                              context.tr(h),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              AuthReveal(
                index: 6,
                child: AuthShake(
                  trigger: _shake,
                  child: AnimatedSwitcher(
                    duration: AuthMotion.slow,
                    switchInCurve: AuthMotion.ease,
                    switchOutCurve: Curves.easeIn,
                    layoutBuilder: (top, rest) => Stack(
                      alignment: Alignment.topCenter,
                      children: [...rest, ?top],
                    ),
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(
                          begin: Offset(0.06 * dir, 0),
                          end: Offset.zero,
                        ).animate(a),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey('${_accountType.name}-$_sellerStep'),
                      child: _stepBody(loading),
                    ),
                  ),
                ),
              ),
              if (showTerms) ...[
                const SizedBox(height: AuthSpace.s20),
                AuthCheckbox(
                  value: _acceptTerms,
                  enabled: !loading,
                  error: _termsError && !_acceptTerms,
                  onChanged: (v) => setState(() {
                    _acceptTerms = v;
                    if (v) _termsError = false;
                  }),
                  child: Text.rich(
                    TextSpan(
                      style: AuthType.caption(
                        p,
                      ).copyWith(fontSize: 13.5, color: p.inkSoft),
                      children: [
                        TextSpan(
                          text: context.tr(
                            AccountCommerceL10n.agreeToTermsIntro,
                          ),
                        ),
                        TextSpan(
                          text: context.tr(
                            AccountCommerceL10n.termsOfServiceLink,
                          ),
                          style: TextStyle(
                            color: p.accent,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: p.accent.withValues(alpha: 0.5),
                          ),
                          recognizer: _termsTapRecognizer,
                        ),
                        TextSpan(
                          text: context.tr(AccountCommerceL10n.agreeToTermsAnd),
                        ),
                        TextSpan(
                          text: context.tr(
                            AccountCommerceL10n.ethicalSourcingPolicyLink,
                          ),
                          style: TextStyle(
                            color: p.accent,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: p.accent.withValues(alpha: 0.5),
                          ),
                          recognizer: _termsTapRecognizer,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AuthSpace.s20),
              AuthErrorBanner(
                message: authState.errorMessage,
                onDismiss: () => ref.read(authProvider.notifier).clearError(),
              ),
              if (_isSeller)
                Row(
                  children: [
                    AnimatedSize(
                      duration: AuthMotion.base,
                      curve: AuthMotion.ease,
                      child: _sellerStep > 0
                          ? Padding(
                              padding: const EdgeInsets.only(
                                right: AuthSpace.s12,
                              ),
                              child: SizedBox(
                                width: 112,
                                child: AuthSecondaryButton(
                                  label: context.tr(AuthL10n.back),
                                  icon: Icons.arrow_back_rounded,
                                  onPressed: loading ? null : _backSeller,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    Expanded(
                      child: AuthPrimaryButton(
                        label: context.tr(
                          _isLastSellerStep
                              ? AuthL10n.createSellerAccount
                              : AuthL10n.continueAction,
                        ),
                        icon: _isLastSellerStep
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        loading: loading,
                        onPressed: _continueSeller,
                      ),
                    ),
                  ],
                )
              else
                AuthPrimaryButton(
                  label: context.tr(AuthL10n.createAccount),
                  loading: loading,
                  onPressed: _submit,
                ),
              const SizedBox(height: AuthSpace.s24),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AuthSpace.s8,
                children: [
                  Text(
                    context.tr(AuthL10n.haveAccount),
                    style: AuthType.caption(p).copyWith(fontSize: 13.5),
                  ),
                  AuthTextLink(
                    emphasis: true,
                    label: context.tr(AuthL10n.signIn),
                    onPressed: loading
                        ? null
                        : () => context.go(AppRouteNames.login),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BasicDetailsFields extends StatelessWidget {
  const _BasicDetailsFields({
    required this.fullNameController,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.referralController,
    required this.profilePicture,
    required this.isLoading,
    required this.showDateOfBirth,
    required this.showPasswordRules,
    required this.dateOfBirth,
    required this.referralOpen,
    required this.onToggleReferral,
    required this.onDateOfBirthChanged,
    required this.onPickProfile,
  });

  final TextEditingController fullNameController;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController referralController;
  final XFile? profilePicture;
  final bool isLoading;
  final bool showDateOfBirth;
  final bool showPasswordRules;
  final DateTime? dateOfBirth;
  final bool referralOpen;
  final VoidCallback onToggleReferral;
  final ValueChanged<DateTime?> onDateOfBirthChanged;
  final VoidCallback onPickProfile;

  Future<DateTime?> _pickDateOfBirth(BuildContext context) async {
    final now = DateTime.now();
    final adultCutoff = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: dateOfBirth ?? adultCutoff,
      firstDate: DateTime(1900),
      lastDate: adultCutoff,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDatePickerMode: DatePickerMode.year,
      helpText: context.tr(AccountCommerceL10n.selectDateOfBirth),
    );
    if (picked == null) return null;
    onDateOfBirthChanged(picked);
    return picked;
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: AuthSpace.s12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: AuthAvatarPicker(
            file: profilePicture,
            enabled: !isLoading,
            onPick: onPickProfile,
          ),
        ),
        const SizedBox(height: AuthSpace.s24),
        AuthSectionLabel(context.tr(AuthL10n.sectionDetails)),
        AuthTextField(
          controller: fullNameController,
          label: context.tr(AccountCommerceL10n.fullName),
          icon: Icons.person_outline_rounded,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          enabled: !isLoading,
          validator: (value) {
            final v = value?.trim() ?? '';
            if (v.isEmpty) {
              return context.tr(AccountCommerceL10n.fullNameRequired);
            }
            return null;
          },
        ),
        gap,
        AuthTextField(
          controller: usernameController,
          label: context.tr(AccountCommerceL10n.username),
          icon: Icons.alternate_email_rounded,
          autofillHints: const [AutofillHints.newUsername],
          enabled: !isLoading,
          validator: (value) {
            final v = value?.trim() ?? '';
            if (v.isEmpty) {
              return context.tr(AccountCommerceL10n.usernameRequired);
            }
            return null;
          },
        ),
        gap,
        AuthTextField(
          controller: emailController,
          label: context.tr(AccountCommerceL10n.emailAddress),
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          enabled: !isLoading,
          validator: (value) {
            final v = value?.trim() ?? '';
            if (v.isEmpty) return context.tr(AccountCommerceL10n.emailRequired);
            if (!isValidEmail(v)) {
              return context.tr(AccountCommerceL10n.validEmail);
            }
            return null;
          },
        ),
        if (showDateOfBirth) ...[
          gap,
          AuthDateField(
            label: context.tr(AccountCommerceL10n.dateOfBirth),
            placeholder: context.tr(AccountCommerceL10n.selectDateOfBirth),
            value: dateOfBirth,
            format: formatDateOfBirthDisplay,
            enabled: !isLoading,
            onPick: () => _pickDateOfBirth(context),
            validator: (_) {
              if (dateOfBirth == null) {
                return context.tr(AccountCommerceL10n.dateOfBirthRequired);
              }
              final error = validateDateOfBirth(dateOfBirth);
              if (error == null) return null;
              if (error ==
                  AccountCommerceL10n.english(
                    AccountCommerceL10n.dateOfBirthTooYoung,
                  )) {
                return context.tr(AccountCommerceL10n.dateOfBirthTooYoung);
              }
              return context.tr(AccountCommerceL10n.dateOfBirthInvalid);
            },
          ),
        ],
        const SizedBox(height: AuthSpace.s24),
        AuthSectionLabel(context.tr(AuthL10n.sectionSecurity)),
        AuthPasswordField(
          controller: passwordController,
          label: context.tr(AccountCommerceL10n.password),
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          enabled: !isLoading,
          validator: (value) {
            final strength = evaluatePasswordStrength((value ?? '').trim());
            if (!strength.isStrong) {
              return localizePasswordStrength(context, strength);
            }
            return null;
          },
        ),
        ListenableBuilder(
          listenable: passwordController,
          builder: (context, _) => AuthPasswordMeter(
            password: passwordController.text,
            showRules: showPasswordRules,
          ),
        ),
        const SizedBox(height: AuthSpace.s16),
        AuthCollapsible(
          title: context.tr(AuthL10n.referralToggle),
          trailing: context.tr(AuthL10n.optional),
          icon: Icons.card_giftcard_outlined,
          open: referralOpen,
          onToggle: onToggleReferral,
          child: AuthTextField(
            controller: referralController,
            label: context.tr(AccountCommerceL10n.referralEmailOrCode),
            icon: Icons.card_giftcard_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            enabled: !isLoading,
            validator: (value) {
              final v = value?.trim() ?? '';
              if (_isReferralEmail(v) && !isValidEmail(v)) {
                return context.tr(AccountCommerceL10n.validReferralEmail);
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}

/// A referral entry containing `@` is treated as an email; anything else is a
/// referral code.
bool _isReferralEmail(String value) => value.contains('@');
