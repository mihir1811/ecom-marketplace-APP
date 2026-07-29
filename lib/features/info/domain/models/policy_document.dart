/// A section inside a GemWorld policy document.
class PolicySection {
  const PolicySection({
    required this.number,
    required this.title,
    required this.paragraphs,
    this.bullets = const [],
    this.closing,
  });

  final String number;
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
  final String? closing;

  factory PolicySection.fromJson(Map<String, dynamic> json) {
    return PolicySection(
      number: json['number'] as String? ?? '',
      title: json['title'] as String? ?? '',
      paragraphs: (json['paragraphs'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      bullets: (json['bullets'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      closing: json['closing'] as String?,
    );
  }
}

/// Full policy loaded from [assets/policies/policies.json].
class PolicyDocument {
  const PolicyDocument({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.effectiveDate,
    required this.intro,
    required this.sections,
    this.eyebrow = 'GemWorld Marketplace',
    this.secondaryIntro,
  });

  final String id;
  final String title;
  final String subtitle;
  final String eyebrow;
  final String effectiveDate;
  final String intro;
  final String? secondaryIntro;
  final List<PolicySection> sections;

  factory PolicyDocument.fromJson(Map<String, dynamic> json) {
    return PolicyDocument(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      eyebrow: json['eyebrow'] as String? ?? 'GemWorld Marketplace',
      effectiveDate: json['effectiveDate'] as String? ?? '',
      intro: json['intro'] as String? ?? '',
      secondaryIntro: json['secondaryIntro'] as String?,
      sections: (json['sections'] as List<dynamic>? ?? const [])
          .map((e) => PolicySection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
