import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/auth_brand_header.dart';
import '../widgets/auth_theme.dart';

/// OTP verification screen after registration.
class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key, this.email});

  final String? email;

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _didAutoRedirect = false;
  bool _resendBusy = false;

  String get _email {
    final fromState =
        ref.read(authProvider).pendingVerificationEmail?.trim() ?? '';
    if (fromState.isNotEmpty) return fromState;
    return widget.email?.trim() ?? '';
  }

  @override
  void dispose() {
    _otpController.dispose();
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
          pendingEmail: s.pendingVerificationEmail,
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

    final email = (authState.pendingEmail?.trim().isNotEmpty == true)
        ? authState.pendingEmail!.trim()
        : _email;

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
                      AuthBrandHeader(
                        eyebrow: context.tr(AccountCommerceL10n.verifyEmail),
                        subtitle: context.tr(AccountCommerceL10n.enterCodeSent),
                      ),
                      const SizedBox(height: AppSpacing.s24),
                      Text(
                        context.tr(AccountCommerceL10n.verifyOtp),
                        style: AppTypography.display.copyWith(
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      Text(
                        email.isEmpty
                            ? context.tr(AccountCommerceL10n.enterSixDigitCode)
                            : context.tr(AccountCommerceL10n.codeSentToEmail, {
                                'email': email,
                              }),
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s24),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              maxLength: 6,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: context.tr(AccountCommerceL10n.otp),
                                prefixIcon: const Icon(Icons.pin_outlined),
                                counterText: '',
                              ),
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (v.length != 6) {
                                  return context.tr(
                                    AccountCommerceL10n.enterOtp,
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
                                onPressed: authState.isLoading || email.isEmpty
                                    ? null
                                    : () async {
                                        ref
                                            .read(authProvider.notifier)
                                            .clearError();
                                        final ok =
                                            _formKey.currentState?.validate() ??
                                            false;
                                        if (!ok) return;
                                        await ref
                                            .read(authProvider.notifier)
                                            .verifyOtp(
                                              email: email,
                                              otp: _otpController.text,
                                            );
                                      },
                                style: authFilledButtonStyle(context),
                                child: authState.isLoading
                                    ? authButtonSpinner(context)
                                    : Text(
                                        'Verify \u2192',
                                        style: AppTypography.label.copyWith(
                                          color: AppColors.onSelected(context),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s16),
                            TextButton(
                              onPressed:
                                  authState.isLoading ||
                                      _resendBusy ||
                                      email.isEmpty
                                  ? null
                                  : () async {
                                      setState(() => _resendBusy = true);
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      final ok = await ref
                                          .read(authProvider.notifier)
                                          .resendOtp(email: email);
                                      if (!mounted) return;
                                      setState(() => _resendBusy = false);
                                      if (ok) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              // ignore: use_build_context_synchronously
                                              context.tr(
                                                AccountCommerceL10n.otpSent,
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              child: Text(
                                context.tr(AccountCommerceL10n.resendOtp),
                                style: AppTypography.label.copyWith(
                                  color: AppColors.textPrimary(context),
                                  decoration: TextDecoration.underline,
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
                                  context.tr(AccountCommerceL10n.backToLogin),
                                  style: AppTypography.label.copyWith(
                                    color: AppColors.textPrimary(context),
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
