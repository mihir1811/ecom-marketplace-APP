enum AiChatLanguage {
  en,
  gu,
  hi,
  mr;

  String get apiValue => name;

  String get label => switch (this) {
    AiChatLanguage.en => 'English',
    AiChatLanguage.gu => 'Gujarati',
    AiChatLanguage.hi => 'Hindi',
    AiChatLanguage.mr => 'Marathi',
  };

  static AiChatLanguage fromApi(String? value) {
    return switch (value) {
      'gu' => AiChatLanguage.gu,
      'hi' => AiChatLanguage.hi,
      'mr' => AiChatLanguage.mr,
      _ => AiChatLanguage.en,
    };
  }
}
