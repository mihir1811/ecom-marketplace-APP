/// User-facing formatting for diamond catalog values from the API.
abstract final class DiamondDisplay {
  static const notAvailable = 'Not available';

  /// True when a raw API/UI value should not be shown as-is.
  static bool isMissing(String? value) {
    if (value == null) return true;
    final t = value.trim();
    if (t.isEmpty) return true;
    if (t == '-' || t == '—' || t == '–' || t == 'N/A' || t == 'n/a') {
      return true;
    }
    return false;
  }

  /// Returns a friendly label, or [notAvailable] when missing.
  static String text(String? value, {bool uppercase = false}) {
    if (isMissing(value)) return notAvailable;
    final t = value!.trim();
    return uppercase ? t.toUpperCase() : _titleCaseWords(t);
  }

  /// Null when missing so [specSection] can omit the row.
  static String? optional(String? value, {bool uppercase = false}) {
    if (isMissing(value)) return null;
    final t = value!.trim();
    return uppercase ? t.toUpperCase() : _titleCaseWords(t);
  }

  /// Short grade codes for chips (VG, E, VVS2, IGI).
  static String gradeChip(String? value) {
    if (isMissing(value)) return 'N/A';
    return value!.trim().toUpperCase();
  }

  static String shape(String? value) {
    if (isMissing(value)) return notAvailable;
    return _titleCaseWords(value!.trim());
  }

  static String availability(String? value) {
    if (isMissing(value)) return notAvailable;
    return switch (value!.trim().toLowerCase()) {
      'yes' => 'Available',
      'hold' => 'On hold',
      'memo' => 'On memo',
      _ => _titleCaseWords(value.trim()),
    };
  }

  static String? boolLabel(bool? value, {String yes = 'Yes', String no = 'No'}) {
    if (value == null) return null;
    return value ? yes : no;
  }

  static String? number(num? value, {int decimals = 2, String? suffix}) {
    if (value == null) return null;
    final text = value is int
        ? value.toString()
        : value.toStringAsFixed(decimals);
    return suffix == null ? text : '$text$suffix';
  }

  static String _titleCaseWords(String input) {
    return input.split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return word;
      // Keep known short grade-like tokens uppercase when already short.
      if (word.length <= 4 && RegExp(r'^[a-z0-9.]+$', caseSensitive: false).hasMatch(word)) {
        return word.toUpperCase();
      }
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }
}
