import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/translations/account_commerce_messages.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_validators.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/auth_theme.dart';

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
    message: AccountCommerceL10n.passwordRequired,
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
                        context.tr(AccountCommerceL10n.resetPassword),
                        style: AppTypography.display.copyWith(
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      Text(
                        token.isEmpty
                            ? context.tr(AccountCommerceL10n.missingResetToken)
                            : context.tr(AccountCommerceL10n.chooseNewPassword),
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s24),
                      if (authState.passwordResetSuccess) ...[
                        Text(
                          context.tr(AccountCommerceL10n.passwordResetSuccess),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => context.go(AppRouteNames.login),
                            style: authFilledButtonStyle(context),
                            child: Text(
                              context.tr(AccountCommerceL10n.goToLogin),
                            ),
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
                                  labelText: context.tr(
                                    AccountCommerceL10n.newPassword,
                                  ),
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePassword
                                        ? context.tr(
                                            AccountCommerceL10n.showPassword,
                                          )
                                        : context.tr(
                                            AccountCommerceL10n.hidePassword,
                                          ),
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
                              const SizedBox(height: AppSpacing.s8),
                              Text(
                                localizePasswordStrength(context, _strength),
                                style: AppTypography.caption.copyWith(
                                  color: _strength.isStrong
                                      ? AppColors.success
                                      : AppColors.textSecondary(context),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.s16),
                              TextFormField(
                                controller: _confirmController,
                                obscureText: _obscureConfirm,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: context.tr(
                                    AccountCommerceL10n.confirmPassword,
                                  ),
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _obscureConfirm
                                        ? context.tr(
                                            AccountCommerceL10n.showPassword,
                                          )
                                        : context.tr(
                                            AccountCommerceL10n.hidePassword,
                                          ),
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
                                    return context.tr(
                                      AccountCommerceL10n.passwordsDoNotMatch,
                                    );
                                  }
                                  return null;
                                },
                              ),
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
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed:
                                      authState.isLoading || token.isEmpty
                                      ? null
                                      : () async {
                                          ref
                                              .read(authProvider.notifier)
                                              .clearError();
                                          final ok =
                                              _formKey.currentState
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
                                  style: authFilledButtonStyle(context),
                                  child: authState.isLoading
                                      ? authButtonSpinner(context)
                                      : Text(
                                          context.tr(
                                            AccountCommerceL10n
                                                .resetPasswordAction,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSpacing.s24),
                      Center(
                        child: TextButton(
                          onPressed: authState.isLoading
                              ? null
                              : () => context.go(AppRouteNames.login),
                          child: Text(
                            context.tr(AccountCommerceL10n.backToLogin),
                            style: AppTypography.label.copyWith(
                              color: AppColors.textPrimary(context),
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
