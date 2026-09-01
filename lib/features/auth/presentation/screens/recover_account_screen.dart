import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_validators.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/auth_theme.dart';

/// Public screen to recover a scheduled-for-deletion account.
class RecoverAccountScreen extends ConsumerStatefulWidget {
  const RecoverAccountScreen({super.key, this.recoveryToken});

  final String? recoveryToken;

  @override
  ConsumerState<RecoverAccountScreen> createState() =>
      _RecoverAccountScreenState();
}

class _RecoverAccountScreenState extends ConsumerState<RecoverAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _useToken = true;
  bool _didAutoRedirect = false;

  @override
  void initState() {
    super.initState();
    final token = widget.recoveryToken?.trim() ?? '';
    if (token.isNotEmpty) {
      _tokenController.text = token;
      _useToken = true;
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
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
          accountRecovered: s.accountRecovered,
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

    if (authState.accountRecovered && !_didAutoRedirect) {
      _didAutoRedirect = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr(AccountCommerceL10n.accountRecovered)),
          ),
        );
        context.go(AppRouteNames.login);
      });
    }

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
                        context.tr(AccountCommerceL10n.recoverAccount),
                        style: AppTypography.display.copyWith(
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      Text(
                        'If your account was scheduled for deletion, recover '
                        'it within 7 days using the email token or your '
                        'email and password.',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s24),
                      SegmentedButton<bool>(
                        segments: [
                          ButtonSegment(
                            value: true,
                            label: Text(
                              context.tr(AccountCommerceL10n.emailToken),
                            ),
                            icon: const Icon(Icons.link),
                          ),
                          ButtonSegment(
                            value: false,
                            label: Text(
                              context.tr(AccountCommerceL10n.emailAndPassword),
                            ),
                            icon: const Icon(Icons.lock_outline),
                          ),
                        ],
                        selected: {_useToken},
                        onSelectionChanged: authState.isLoading
                            ? null
                            : (next) {
                                setState(() => _useToken = next.first);
                                ref.read(authProvider.notifier).clearError();
                              },
                      ),
                      const SizedBox(height: AppSpacing.s24),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (_useToken)
                              TextFormField(
                                controller: _tokenController,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: context.tr(
                                    AccountCommerceL10n.recoveryToken,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.vpn_key_outlined,
                                  ),
                                ),
                                validator: (value) {
                                  if (!_useToken) return null;
                                  if ((value?.trim() ?? '').isEmpty) {
                                    return context.tr(
                                      AccountCommerceL10n.recoveryTokenRequired,
                                    );
                                  }
                                  return null;
                                },
                              )
                            else ...[
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: context.tr(
                                    AccountCommerceL10n.email,
                                  ),
                                  prefixIcon: const Icon(Icons.mail_outline),
                                ),
                                validator: (value) {
                                  if (_useToken) return null;
                                  final v = value?.trim() ?? '';
                                  if (v.isEmpty) {
                                    return context.tr(
                                      AccountCommerceL10n.emailRequired,
                                    );
                                  }
                                  if (!isValidEmail(v)) {
                                    return context.tr(
                                      AccountCommerceL10n.validEmail,
                                    );
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.s16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: context.tr(
                                    AccountCommerceL10n.password,
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
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (_useToken) return null;
                                  if ((value ?? '').isEmpty) {
                                    return 'Password is required';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: AppSpacing.s16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: authState.isLoading ? null : _submit,
                                style: authFilledButtonStyle(context),
                                child: authState.isLoading
                                    ? authButtonSpinner(context)
                                    : Text(
                                        context.tr(
                                          AccountCommerceL10n.recoverAccount,
                                        ),
                                      ),
                              ),
                            ),
                            if (authState.errorMessage != null) ...[
                              const SizedBox(height: AppSpacing.s12),
                              Text(
                                authState.errorMessage!,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ],
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

  Future<void> _submit() async {
    ref.read(authProvider.notifier).clearError();
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    await ref
        .read(authProvider.notifier)
        .recoverAccount(
          token: _useToken ? _tokenController.text : null,
          email: _useToken ? null : _emailController.text,
          password: _useToken ? null : _passwordController.text,
        );
  }
}
