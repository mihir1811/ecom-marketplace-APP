/// Basic email validation for UI forms (no backend call).
bool isValidEmail(String value) {
  final v = value.trim();
  if (v.isEmpty) return false;
  // Practical RFC5322-ish check; avoids overly strict false negatives.
  final emailRegex = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
  return emailRegex.hasMatch(v);
}

/// Indian PAN format: 5 letters + 4 digits + 1 letter.
bool isValidPan(String value) {
  return RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$')
      .hasMatch(value.trim().toUpperCase());
}

/// Aadhaar: 12 digits.
bool isValidAadhaar(String value) {
  return RegExp(r'^\d{12}$').hasMatch(value.trim());
}

/// IFSC: 4 letters + 0 + 6 alphanumeric (e.g. HDFC0001234).
bool isValidIfsc(String value) {
  return RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$')
      .hasMatch(value.trim().toUpperCase());
}

/// Bank account number: 8–20 digits.
bool isValidBankAccountNumber(String value) {
  return RegExp(r'^\d{8,20}$').hasMatch(value.trim());
}

class PasswordStrength {
  const PasswordStrength({
    required this.isStrong,
    required this.message,
  });

  final bool isStrong;
  final String message;
}

/// Strength rules:
/// - >= 8 chars
/// - at least 1 uppercase
/// - at least 1 lowercase
/// - at least 1 number
/// - at least 1 symbol
PasswordStrength evaluatePasswordStrength(String value) {
  final v = value;
  if (v.isEmpty) {
    return const PasswordStrength(
      isStrong: false,
      message: 'Password is required.',
    );
  }

  if (v.length < 8) {
    return const PasswordStrength(
      isStrong: false,
      message: 'Use at least 8 characters.',
    );
  }

  final hasUpper = RegExp(r'[A-Z]').hasMatch(v);
  final hasLower = RegExp(r'[a-z]').hasMatch(v);
  final hasNumber = RegExp(r'\d').hasMatch(v);
  final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(v);

  final missing = <String>[
    if (!hasUpper) 'an uppercase letter',
    if (!hasLower) 'a lowercase letter',
    if (!hasNumber) 'a number',
    if (!hasSymbol) 'a symbol',
  ];

  if (missing.isNotEmpty) {
    return PasswordStrength(
      isStrong: false,
      message: 'Add ${missing.join(', ')} to strengthen your password.',
    );
  }

  return const PasswordStrength(
    isStrong: true,
    message: 'Strong password.',
  );
}
