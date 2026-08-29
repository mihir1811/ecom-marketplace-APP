/// One localized frontend message in every supported language.
class LocalizedMessage {
  const LocalizedMessage({
    required this.english,
    required this.hindi,
    required this.gujarati,
  });

  final String english;
  final String hindi;
  final String gujarati;

  String forLanguage(String languageCode) {
    return switch (languageCode) {
      'hi' => hindi,
      'gu' => gujarati,
      _ => english,
    };
  }
}
