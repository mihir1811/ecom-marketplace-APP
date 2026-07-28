import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_validators.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/auth_brand_header.dart';

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
  late final TapGestureRecognizer _termsTapRecognizer;

  bool _obscurePassword = true;
  bool _acceptTerms = false;
  String _profileImageLabel = 'Upload profile image';

  PasswordStrength _strength = const PasswordStrength(
    isStrong: false,
    message: 'Password is required.',
  );

  bool _didAutoRedirect = false;

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
    super.dispose();
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
                      const AuthBrandHeader(
                        eyebrow: 'NEW ACCOUNT',
                        subtitle: 'Join GemWorld',
                      ),
                      SizedBox(height: AppSpacing.s24),
                      Text(
                        'Register',
                        style: AppTypography.display.copyWith(
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      SizedBox(height: AppSpacing.s24),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _fullNameController,
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
                            SizedBox(height: AppSpacing.s16),
                            TextFormField(
                              controller: _usernameController,
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
                            SizedBox(height: AppSpacing.s16),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (v.isEmpty) return 'Email is required';
                                if (!isValidEmail(v)) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: AppSpacing.s16),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              onChanged: (v) {
                                setState(() {
                                  _strength = evaluatePasswordStrength(v);
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                final v = value ?? '';
                                final strength =
                                    evaluatePasswordStrength(v.trim());
                                if (!strength.isStrong) return strength.message;
                                return null;
                              },
                            ),

                            SizedBox(height: AppSpacing.s8),
                            Text(
                              _strength.message,
                              style: AppTypography.caption.copyWith(
                                color: _strength.isStrong
                                    ? AppColors.success
                                    : AppColors.textSecondaryLight,
                              ),
                            ),

                            SizedBox(height: AppSpacing.s16),

                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : () {
                                        // No file-picking dependency configured yet.
                                        setState(() {
                                          _profileImageLabel =
                                              'Profile image selected';
                                        });
                                      },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.s16,
                                    horizontal: AppSpacing.s24,
                                  ),
                                  side: BorderSide(
                                    color: AppColors.warmBorder,
                                    width: 1.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppSpacing.r8),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.upload_outlined),
                                    SizedBox(width: AppSpacing.s12),
                                    Text(_profileImageLabel),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: AppSpacing.s12),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _acceptTerms,
                                  onChanged: authState.isLoading
                                      ? null
                                      : (v) {
                                          setState(() {
                                            _acceptTerms = v ?? false;
                                          });
                                        },
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
                                          recognizer: _termsTapRecognizer,
                                        ),
                                        const TextSpan(text: ' and '),
                                        TextSpan(
                                          text: 'Ethical Sourcing Policy.',
                                          style: AppTypography.body.copyWith(
                                            color: AppColors.charcoal,
                                            decoration: TextDecoration.underline,
                                          ),
                                          recognizer: _termsTapRecognizer,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (authState.errorMessage != null) ...[
                              SizedBox(height: AppSpacing.s16),
                              Text(
                                authState.errorMessage!,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ],

                            SizedBox(height: AppSpacing.s16),

                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : () async {
                                        ref
                                            .read(authProvider.notifier)
                                            .clearError();

                                        final ok = _formKey.currentState
                                                ?.validate() ??
                                            false;
                                        if (!ok) return;
                                        if (!_acceptTerms) {
                                          ref
                                              .read(authProvider.notifier)
                                              .setErrorMessage(
                                                'Please agree to the Terms of Service (including chatbot data use) and Ethical Sourcing Policy.',
                                              );
                                          return;
                                        }

                                        await ref
                                            .read(authProvider.notifier)
                                            .register(
                                              fullName:
                                                  _fullNameController.text,
                                              username:
                                                  _usernameController.text,
                                              email: _emailController.text,
                                              password:
                                                  _passwordController.text,
                                              acceptTerms: _acceptTerms,
                                            );
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.charcoal,
                                  foregroundColor: AppColors.warmWhite,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.s16,
                                    horizontal: AppSpacing.s24,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppSpacing.r8),
                                  ),
                                ),
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

                            SizedBox(height: AppSpacing.s24),

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

