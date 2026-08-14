import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_validators.dart';
import '../../../../core/auth/business_registration_data.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/auth_brand_header.dart';
import '../widgets/business_registration_fields.dart';

/// Registration screen matching the provided UI reference.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralEmailController = TextEditingController();
  final _referralCodeController = TextEditingController();
  final _businessFields = BusinessRegistrationFieldsController();
  late final TapGestureRecognizer _termsTapRecognizer;

  RegistrationAccountType _accountType = RegistrationAccountType.individual;
  int _sellerStep = 0;
  bool _obscurePassword = true;
  bool _acceptTerms = false;
  String _profileImageLabel = 'Upload profile image';
  XFile? _profilePicture;

  PasswordStrength _strength = const PasswordStrength(
    isStrong: false,
    message: 'Password is required.',
  );

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
  }

  @override
  void dispose() {
    _termsTapRecognizer.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralEmailController.dispose();
    _referralCodeController.dispose();
    _businessFields.dispose();
    super.dispose();
  }

  void _onAccountTypeChanged(RegistrationAccountType type) {
    setState(() {
      _accountType = type;
      _sellerStep = 0;
    });
    ref.read(authProvider.notifier).clearError();
  }

  bool _validateCurrentStep() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return false;

    if (_isSeller && _sellerStep == 1) {
      final logoError = _businessFields.missingCompanyLogoMessage();
      if (logoError != null) {
        ref.read(authProvider.notifier).setErrorMessage(logoError);
        return false;
      }
    }
    return true;
  }

  void _continueSeller() {
    ref.read(authProvider.notifier).clearError();
    if (!_validateCurrentStep()) return;
    if (_isLastSellerStep) {
      _submit();
      return;
    }
    setState(() => _sellerStep += 1);
  }

  void _backSeller() {
    ref.read(authProvider.notifier).clearError();
    if (_sellerStep == 0) return;
    setState(() => _sellerStep -= 1);
  }

  Future<void> _submit() async {
    ref.read(authProvider.notifier).clearError();

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    if (!_acceptTerms) {
      ref.read(authProvider.notifier).setErrorMessage(
            'Please agree to the Terms of Service (including chatbot data use) and Ethical Sourcing Policy.',
          );
      return;
    }

    BusinessRegistrationData? business;
    if (_isSeller) {
      final filesError = _businessFields.missingFilesMessage();
      if (filesError != null) {
        ref.read(authProvider.notifier).setErrorMessage(filesError);
        return;
      }
      business = _businessFields.toData();
      if (business == null) {
        ref.read(authProvider.notifier).setErrorMessage(
              'Seller registration details are incomplete.',
            );
        return;
      }
    }

    final registered = await ref.read(authProvider.notifier).register(
          fullName: _fullNameController.text,
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          acceptTerms: _acceptTerms,
          registrationType: _accountType,
          business: business,
          profilePicture: _profilePicture,
          referralEmail: _referralEmailController.text,
          referralCode: _referralCodeController.text,
        );
    if (!mounted || !registered) return;
    final pending = ref.read(authProvider).pendingVerificationEmail;
    if (pending != null && pending.isNotEmpty) {
      context.go(
        '${AppRouteNames.verifyOtp}?email=${Uri.encodeComponent(pending)}',
      );
    }
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

    return AppScaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuthBrandHeader(
                        eyebrow: _isSeller ? 'SELLER ACCOUNT' : 'NEW ACCOUNT',
                        subtitle: _isSeller
                            ? 'For Businesses'
                            : 'Join GemWorld',
                      ),
                      const SizedBox(height: AppSpacing.s24),
                      Text(
                        _isSeller ? 'Seller registration' : 'Register',
                        style: AppTypography.display.copyWith(
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      Text(
                        'Choose how you want to join',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      _AccountTypeSelector(
                        value: _accountType,
                        enabled: !authState.isLoading,
                        onChanged: _onAccountTypeChanged,
                      ),
                      const SizedBox(height: AppSpacing.s24),
                      if (_isSeller) ...[
                        SellerRegistrationStepHeader(currentStep: _sellerStep),
                        const SizedBox(height: AppSpacing.s16),
                      ],
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (!_isSeller || _sellerStep == 0)
                              _BasicDetailsFields(
                                fullNameController: _fullNameController,
                                usernameController: _usernameController,
                                emailController: _emailController,
                                passwordController: _passwordController,
                                referralEmailController:
                                    _referralEmailController,
                                referralCodeController: _referralCodeController,
                                obscurePassword: _obscurePassword,
                                strength: _strength,
                                profileImageLabel: _profileImageLabel,
                                isLoading: authState.isLoading,
                                onToggleObscure: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                onPasswordChanged: (v) {
                                  setState(() {
                                    _strength = evaluatePasswordStrength(v);
                                  });
                                },
                                onPickProfile: () async {
                                  final picker = ImagePicker();
                                  final file = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 85,
                                  );
                                  if (file == null || !mounted) return;
                                  setState(() {
                                    _profilePicture = file;
                                    _profileImageLabel = file.name;
                                  });
                                },
                              ),
                            if (_isSeller && _sellerStep == 1)
                              BusinessCompanyStep(
                                controller: _businessFields,
                                enabled: !authState.isLoading,
                                onChanged: () => setState(() {}),
                              ),
                            if (_isSeller && _sellerStep == 2)
                              BusinessAddressStep(
                                controller: _businessFields,
                                enabled: !authState.isLoading,
                              ),
                            if (_isSeller && _sellerStep == 3)
                              BusinessContactsKycStep(
                                controller: _businessFields,
                                enabled: !authState.isLoading,
                                onChanged: () => setState(() {}),
                              ),
                            if (_isSeller && _sellerStep == 4)
                              BusinessBankStep(
                                controller: _businessFields,
                                enabled: !authState.isLoading,
                                onChanged: () => setState(() {}),
                              ),
                            if (!_isSeller || _isLastSellerStep) ...[
                              const SizedBox(height: AppSpacing.s12),
                              _TermsCheckbox(
                                acceptTerms: _acceptTerms,
                                enabled: !authState.isLoading,
                                recognizer: _termsTapRecognizer,
                                onChanged: (v) {
                                  setState(() => _acceptTerms = v);
                                },
                              ),
                            ],
                            if (authState.errorMessage != null) ...[
                              const SizedBox(height: AppSpacing.s16),
                              Text(
                                authState.errorMessage!,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.s16),
                            if (_isSeller)
                              _SellerStepActions(
                                step: _sellerStep,
                                isLoading: authState.isLoading,
                                isLastStep: _isLastSellerStep,
                                onBack: _backSeller,
                                onContinue: _continueSeller,
                              )
                            else
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed:
                                      authState.isLoading ? null : _submit,
                                  style: _primaryButtonStyle,
                                  child: authState.isLoading
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.warmWhite,
                                          ),
                                        )
                                      : Text(
                                          'Create account \u2192',
                                          style: AppTypography.label.copyWith(
                                            color: AppColors.warmWhite,
                                          ),
                                        ),
                                ),
                              ),
                            const SizedBox(height: AppSpacing.s24),
                            Center(
                              child: TextButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : () => context.go(AppRouteNames.login),
                                child: Text(
                                  'Already registered? Sign in',
                                  style: AppTypography.label.copyWith(
                                    color: AppColors.charcoal,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

ButtonStyle get _primaryButtonStyle => FilledButton.styleFrom(
      backgroundColor: AppColors.charcoal,
      foregroundColor: AppColors.warmWhite,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.s16,
        horizontal: AppSpacing.s24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.r8),
      ),
    );

class _BasicDetailsFields extends StatelessWidget {
  const _BasicDetailsFields({
    required this.fullNameController,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.referralEmailController,
    required this.referralCodeController,
    required this.obscurePassword,
    required this.strength,
    required this.profileImageLabel,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onPasswordChanged,
    required this.onPickProfile,
  });

  final TextEditingController fullNameController;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController referralEmailController;
  final TextEditingController referralCodeController;
  final bool obscurePassword;
  final PasswordStrength strength;
  final String profileImageLabel;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onPickProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: fullNameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Full name',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) {
            final v = value?.trim() ?? '';
            if (v.isEmpty) return 'Full name is required';
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.s16),
        TextFormField(
          controller: usernameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Username',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) {
            final v = value?.trim() ?? '';
            if (v.isEmpty) return 'Username is required';
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.s16),
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Email address',
            prefixIcon: Icon(Icons.mail_outline),
          ),
          validator: (value) {
            final v = value?.trim() ?? '';
            if (v.isEmpty) return 'Email is required';
            if (!isValidEmail(v)) return 'Enter a valid email address';
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.s16),
        TextFormField(
          controller: passwordController,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.next,
          onChanged: onPasswordChanged,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: obscurePassword ? 'Show password' : 'Hide password',
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: onToggleObscure,
            ),
          ),
          validator: (value) {
            final strength = evaluatePasswordStrength((value ?? '').trim());
            if (!strength.isStrong) return strength.message;
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.s8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            strength.message,
            style: AppTypography.caption.copyWith(
              color: strength.isStrong
                  ? AppColors.success
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPickProfile,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.s16,
                horizontal: AppSpacing.s24,
              ),
              side: const BorderSide(color: AppColors.warmBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.r8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.upload_outlined),
                const SizedBox(width: AppSpacing.s12),
                Flexible(
                  child: Text(
                    profileImageLabel,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        TextFormField(
          controller: referralEmailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Referral email (optional)',
            prefixIcon: Icon(Icons.mail_outline),
          ),
          validator: (value) {
            final v = value?.trim() ?? '';
            if (v.isEmpty) return null;
            if (!isValidEmail(v)) return 'Enter a valid referral email';
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.s16),
        TextFormField(
          controller: referralCodeController,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Referral code (optional)',
            prefixIcon: Icon(Icons.card_giftcard_outlined),
          ),
        ),
      ],
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.acceptTerms,
    required this.enabled,
    required this.recognizer,
    required this.onChanged,
  });

  final bool acceptTerms;
  final bool enabled;
  final TapGestureRecognizer recognizer;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: acceptTerms,
          onChanged: enabled ? (v) => onChanged(v ?? false) : null,
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              children: [
                const TextSpan(
                  text:
                      'I agree to the Terms of Service (including chatbot data use for AI training) and ',
                ),
                TextSpan(
                  text: 'Terms of Service',
                  style: AppTypography.body.copyWith(
                    color: AppColors.charcoal,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: recognizer,
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Ethical Sourcing Policy.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.charcoal,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: recognizer,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SellerStepActions extends StatelessWidget {
  const _SellerStepActions({
    required this.step,
    required this.isLoading,
    required this.isLastStep,
    required this.onBack,
    required this.onContinue,
  });

  final int step;
  final bool isLoading;
  final bool isLastStep;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (step > 0) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: isLoading ? null : onBack,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.s16,
                  horizontal: AppSpacing.s16,
                ),
                side: const BorderSide(color: AppColors.warmBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.r8),
                ),
              ),
              child: Text(
                'Back',
                style: AppTypography.label.copyWith(
                  color: AppColors.charcoal,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
        ],
        Expanded(
          flex: step > 0 ? 2 : 1,
          child: FilledButton(
            onPressed: isLoading ? null : onContinue,
            style: _primaryButtonStyle,
            child: isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.warmWhite,
                    ),
                  )
                : Text(
                    isLastStep
                        ? 'Create seller account \u2192'
                        : 'Continue \u2192',
                    style: AppTypography.label.copyWith(
                      color: AppColors.warmWhite,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _AccountTypeSelector extends StatelessWidget {
  const _AccountTypeSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final RegistrationAccountType value;
  final bool enabled;
  final ValueChanged<RegistrationAccountType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AccountTypeCard(
            selected: value == RegistrationAccountType.individual,
            enabled: enabled,
            icon: Icons.person_outline,
            title: 'For Individual',
            subtitle: 'Buy and browse as a personal account',
            onTap: () => onChanged(RegistrationAccountType.individual),
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: _AccountTypeCard(
            selected: value == RegistrationAccountType.business,
            enabled: enabled,
            icon: Icons.storefront_outlined,
            title: 'For Businesses',
            subtitle: 'Business account to list and sell products',
            onTap: () => onChanged(RegistrationAccountType.business),
          ),
        ),
      ],
    );
  }
}

class _AccountTypeCard extends StatelessWidget {
  const _AccountTypeCard({
    required this.selected,
    required this.enabled,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final bool enabled;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.sandSurface : AppColors.warmWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        side: BorderSide(
          color: selected ? AppColors.charcoal : AppColors.warmBorder,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: selected
                    ? AppColors.charcoal
                    : AppColors.textSecondaryLight,
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                title,
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
