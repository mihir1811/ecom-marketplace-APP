import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_validators.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Reset password screen opened from email deep link (`?token=`).
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.resetToken});

  final String? resetToken;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  PasswordStrength _strength = const PasswordStrength(
    isStrong: false,
    message: 'Password is required.',
  );

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(
      authProvider.select(
        (s) => (
          isLoading: s.isLoading,
          errorMessage: s.errorMessage,
          passwordResetSuccess: s.passwordResetSuccess,
        ),
      ),
    );

    final token = widget.resetToken?.trim() ?? '';

    return AppScaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reset Password',
                        style: AppTypography.display.copyWith(
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      SizedBox(height: AppSpacing.s12),
                      Text(
                        token.isEmpty
                            ? 'This reset link is missing a token. Open the link from your email again.'
                            : 'Choose a new password for your account.',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      SizedBox(height: AppSpacing.s24),
                      if (authState.passwordResetSuccess) ...[
                        Text(
                          'Password reset successfully. You can sign in now.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                        SizedBox(height: AppSpacing.s16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => context.go(AppRouteNames.login),
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
                            child: const Text('Go to login'),
                          ),
                        ),
                      ] else
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
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
                                  labelText: 'New password',
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
                                  final strength = evaluatePasswordStrength(
                                    value ?? '',
                                  );
                                  if (!strength.isStrong) {
                                    return strength.message;
                                  }
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
                              TextFormField(
                                controller: _confirmController,
                                obscureText: _obscureConfirm,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: 'Confirm password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _obscureConfirm
                                        ? 'Show password'
                                        : 'Hide password',
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirm = !_obscureConfirm;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match.';
                                  }
                                  return null;
                                },
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
                                  onPressed: authState.isLoading ||
                                          token.isEmpty
                                      ? null
                                      : () async {
                                          ref
                                              .read(authProvider.notifier)
                                              .clearError();
                                          final ok = _formKey.currentState
                                                  ?.validate() ??
                                              false;
                                          if (!ok) return;
                                          await ref
                                              .read(authProvider.notifier)
                                              .resetPassword(
                                                resetToken: token,
                                                newPassword:
                                                    _passwordController.text,
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
                                      : const Text('Reset password'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: AppSpacing.s24),
                      Center(
                        child: TextButton(
                          onPressed: authState.isLoading
                              ? null
                              : () => context.go(AppRouteNames.login),
                          child: Text(
                            'Back to login',
                            style: AppTypography.label.copyWith(
                              color: AppColors.charcoal,
                              decoration: TextDecoration.underline,
                            ),
                          ),
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
