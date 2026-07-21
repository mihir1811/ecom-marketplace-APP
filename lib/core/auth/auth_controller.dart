import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_state.dart';
import 'auth_user.dart';
import 'auth_validators.dart';

/// UI-only auth controller to drive the authenticated drawer.
///
/// This app doesn't include a backend API yet, so these methods simulate success
/// after validating the inputs.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> login({
    required String username,
    required String password,
    required bool rememberDevice,
  }) async {
    _setLoading();
    _clearEphemeralFlags();

    try {
      final u = username.trim();
      if (u.isEmpty) {
        state = state.copyWith(errorMessage: 'Username is required.');
        return;
      }
      if (password.isEmpty) {
        state = state.copyWith(errorMessage: 'Password is required.');
        return;
      }

      // Basic minimum check for login (strength gating belongs to Register).
      if (password.length < 8) {
        state = state.copyWith(
          errorMessage: 'Password must be at least 8 characters.',
        );
        return;
      }

      // Simulated success.
      await Future<void>.delayed(const Duration(milliseconds: 550));

      state = AuthState(
        user: AuthUser(
          fullName: u,
          username: u,
          email: '$u@example.com',
        ),
      );
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Something went wrong. Please try again.',
      );
    } finally {
      _setNotLoading();
    }
  }

  Future<void> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required bool acceptTerms,
  }) async {
    _setLoading();
    _clearEphemeralFlags();

    try {
      final name = fullName.trim();
      final u = username.trim();
      final e = email.trim();

      if (name.isEmpty) {
        state = state.copyWith(errorMessage: 'Full name is required.');
        return;
      }
      if (u.isEmpty) {
        state = state.copyWith(errorMessage: 'Username is required.');
        return;
      }
      if (!isValidEmail(e)) {
        state = state.copyWith(errorMessage: 'Enter a valid email address.');
        return;
      }
      final strength = evaluatePasswordStrength(password);
      if (!strength.isStrong) {
        state = state.copyWith(errorMessage: strength.message);
        return;
      }
      if (!acceptTerms) {
        state = state.copyWith(
          errorMessage:
              'Please agree to the Terms of Service and Ethical Sourcing Policy.',
        );
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 650));

      state = AuthState(
        user: AuthUser(
          fullName: name,
          username: u,
          email: e,
        ),
      );
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Something went wrong. Please try again.',
      );
    } finally {
      _setNotLoading();
    }
  }

  Future<void> sendResetLink({required String email}) async {
    _setLoading();
    state = state.copyWith(
      errorMessage: null,
      resetLinkSent: false,
    );

    try {
      final e = email.trim();
      if (!isValidEmail(e)) {
        state = state.copyWith(errorMessage: 'Enter a valid email address.');
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 550));

      state = state.copyWith(resetLinkSent: true);
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Something went wrong. Please try again.',
      );
    } finally {
      _setNotLoading();
    }
  }

  void logout() => state = const AuthState();

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void setErrorMessage(String message) {
    state = state.copyWith(errorMessage: message, isLoading: false);
  }

  void _setLoading() {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );
  }

  void _setNotLoading() {
    state = state.copyWith(isLoading: false);
  }

  void _clearEphemeralFlags() {
    state = state.copyWith(
      resetLinkSent: false,
      errorMessage: null,
    );
  }
}

