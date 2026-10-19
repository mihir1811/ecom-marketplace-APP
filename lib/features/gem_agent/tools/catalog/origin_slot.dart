import '../../domain/tool_result.dart';

/// Natural vs lab-grown, required before any stone search runs.
enum StoneOrigin {
  natural,
  labGrown,
  unspecified;

  static StoneOrigin parse(Object? value) =>
      switch (value?.toString().trim().toLowerCase()) {
        'natural' => natural,
        'lab_grown' || 'lab-grown' || 'lab grown' || 'lab' => labGrown,
        _ => unspecified,
      };

  static const schema = {
    'type': 'string',
    'enum': ['natural', 'lab_grown', 'unspecified'],
    'description':
        'natural = earth-mined; lab_grown = lab/CVD/HPHT. '
        '"unspecified" unless the user said it.',
  };

  /// Words that show the user really named an origin (English, Hindi,
  /// Gujarati, incl. transliterations), so a model guess never slips through.
  static final _evidence = RegExp(
    r'natural|nature|mined|earth|real|lab|grown|cvd|hpht|synthetic|man[\s-]?made|created|'
    r'नेचुरल|नैचुरल|प्राकृतिक|असली|लैब|लेब|નેચરલ|કુદરતી|અસલી|લેબ',
    caseSensitive: false,
  );

  /// Clarification when the origin is missing or was never stated.
  static ToolNeedsInput? require(
    StoneOrigin origin,
    List<String> userUtterances, {
    required String noun,
  }) {
    final stated = userUtterances.any(_evidence.hasMatch);
    if (origin != unspecified && stated) return null;
    return ToolNeedsInput(
      question: 'Do you want a natural $noun or a lab-grown $noun?',
      missing: const ['origin'],
      options: const ['Natural', 'Lab-grown'],
    );
  }
}
