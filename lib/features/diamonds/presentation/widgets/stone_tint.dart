import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The colour a loose stone is drawn in, read from its catalog wording.
///
/// A fancy colour sets the hue; its intensity (Faint … Fancy Dark) moves
/// saturation and lightness, and an overtone pulls the shaded side towards
/// its own hue. A fancy colour with neither is drawn in one universal shade
/// of that hue. Without a fancy colour, a D–Z grade runs from icy white to a
/// pale cape yellow, and a gemstone falls back on its colour name or its
/// species (`Ruby`). Nothing at all reads as a colourless diamond.
@immutable
class StoneTint {
  const StoneTint._({
    required this.light,
    required this.body,
    required this.deep,
    this.spectrum,
  });

  /// Lit side, body colour and shaded side of the stone.
  final Color light;
  final Color body;
  final Color deep;

  /// Hues swept round the stone for multi-colour stones; null otherwise.
  final List<Color>? spectrum;

  factory StoneTint.resolve({
    String? grade,
    String? fancyColor,
    String? intensity,
    String? overtone,
    String? species,
  }) {
    final fancy = _clean(fancyColor);
    final words = _words(fancy);
    final level = _level('${_clean(intensity) ?? ''} ${fancy ?? ''}');

    if (words.any((w) => w == 'multi' || w == 'other' || w == 'rainbow')) {
      return StoneTint._multi(level);
    }

    final base = _primary(words) ?? _primary(words, modifiers: true);
    if (base != null) {
      // "Purplish Pink" carries its own overtone when the field is blank.
      final tone =
          _primary(_words(_clean(overtone)), modifiers: true) ??
          _modifier(words);
      return StoneTint._shade(base, level: level, overtone: tone);
    }

    final letter = _gradeLetter(grade);
    if (letter != null) return StoneTint._grade(letter);

    final named =
        _primary(_words(_clean(grade)), modifiers: true) ??
        _speciesHue(_clean(species));
    if (named != null) {
      return StoneTint._shade(
        named,
        level: _level(_clean(intensity) ?? ''),
        overtone: _modifier(_words(_clean(grade))),
      );
    }
    return StoneTint._grade(0);
  }

  /// Diagonal light → body → shade, or a sweep for multi-colour stones.
  Shader shader(Rect bounds) {
    final spectrum = this.spectrum;
    if (spectrum != null) {
      return SweepGradient(
        colors: [...spectrum, spectrum.first],
        transform: const GradientRotation(-math.pi / 4),
      ).createShader(bounds);
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [light, body, deep],
      stops: const [0.05, 0.5, 0.95],
    ).createShader(bounds);
  }

  /// Hue swatch for a colour name, or null when it names no colour.
  static Color? hueOf(String name) => _hues[name.trim().toLowerCase()];

  static const _iceWhite = Color(0xFFF3F7FB);
  static const _capeYellow = Color(0xFFF1D27A);

  factory StoneTint._grade(double yellow) {
    final body = Color.lerp(_iceWhite, _capeYellow, yellow)!;
    return StoneTint._(
      light: Colors.white,
      body: body,
      // Steel shade so a white stone still reads on a light frame.
      deep: Color.lerp(
        const Color(0xFF8D9AAB),
        const Color(0xFFA88A3C),
        yellow,
      )!,
    );
  }

  factory StoneTint._multi(int? level) {
    const hues = [0.0, 45.0, 120.0, 200.0, 275.0, 330.0];
    final (sat, light) = _intensity(level) ?? (0.75, 0.58);
    return StoneTint._(
      light: Colors.white,
      body: HSLColor.fromAHSL(1, 275, sat, light).toColor(),
      deep: HSLColor.fromAHSL(1, 200, sat, light - 0.18).toColor(),
      spectrum: [
        for (final h in hues) HSLColor.fromAHSL(1, h, sat, light).toColor(),
      ],
    );
  }

  factory StoneTint._shade(Color hue, {int? level, Color? overtone}) {
    var body = hue;
    final tuned = _intensity(level);
    if (tuned != null) {
      final (sat, light) = tuned;
      final hsl = HSLColor.fromColor(hue);
      body = hsl
          .withSaturation((hsl.saturation * sat).clamp(0.0, 1.0))
          .withLightness(_lerp(hsl.lightness, light, 0.75).clamp(0.08, 0.92))
          .toColor();
    }
    var deep = _shift(body, -0.2);
    if (overtone != null) {
      // Matched to the body's depth so a pale stone gets a pale overtone.
      final o = HSLColor.fromColor(overtone);
      final b = HSLColor.fromColor(body);
      final toned = o
          .withLightness(b.lightness)
          .withSaturation(math.min(o.saturation, b.saturation + 0.15))
          .toColor();
      body = Color.lerp(body, toned, 0.18)!;
      deep = Color.lerp(_shift(body, -0.16), _shift(toned, -0.12), 0.6)!;
    }
    return StoneTint._(light: _shift(body, 0.22), body: body, deep: deep);
  }

  /// (saturation factor, target lightness) for an intensity step.
  static (double, double)? _intensity(int? level) => switch (level) {
    0 => (0.28, 0.88), // Faint
    1 => (0.38, 0.83), // Very Light
    2 => (0.5, 0.77), // Light
    3 => (0.65, 0.7), // Fancy Light
    4 => (0.8, 0.6), // Fancy
    5 => (0.92, 0.52), // Fancy Intense
    6 => (1.1, 0.5), // Fancy Vivid
    7 => (0.85, 0.36), // Fancy Deep
    8 => (0.55, 0.26), // Fancy Dark
    _ => null,
  };

  /// Intensity step named anywhere in [text], or null.
  static int? _level(String text) {
    final t = ' ${text.toLowerCase().replaceAll(RegExp('[^a-z]+'), ' ')} ';
    if (t.contains(' faint ')) return 0;
    if (t.contains(' very light ') || t.contains(' pale ')) return 1;
    if (t.contains(' fancy light ')) return 3;
    if (t.contains(' light ')) return 2;
    if (t.contains(' vivid ')) return 6;
    if (t.contains(' intense ') || t.contains(' strong ')) return 5;
    if (t.contains(' deep ')) return 7;
    if (t.contains(' dark ')) return 8;
    if (t.contains(' fancy ') || t.contains(' medium ')) return 4;
    return null;
  }

  /// Yellow share (0 at D … 1 at Z) of a D–Z grade such as `G` or `G-H`.
  static double? _gradeLetter(String? grade) {
    final g = _clean(grade)?.toUpperCase();
    if (g == null || !RegExp(r'^[D-Z]([-/ ]?[D-Z])?\+?$').hasMatch(g)) {
      return null;
    }
    return (g.codeUnitAt(0) - 'D'.codeUnitAt(0)) /
        ('Z'.codeUnitAt(0) - 'D'.codeUnitAt(0));
  }

  /// Last pure hue word; with [modifiers] also `-ish` / `-y` forms.
  static Color? _primary(List<String> words, {bool modifiers = false}) {
    for (final w in words.reversed) {
      final hue = _hues[w] ?? (modifiers ? _hues[_modifiers[w]] : null);
      if (hue != null) return hue;
    }
    return null;
  }

  /// First `-ish` / `-y` word (`Purplish` in "Purplish Pink").
  static Color? _modifier(List<String> words) {
    for (final w in words) {
      final hue = _hues[_modifiers[w]];
      if (hue != null) return hue;
    }
    return null;
  }

  static Color? _speciesHue(String? species) {
    if (species == null) return null;
    final s = species.toLowerCase();
    for (final entry in _species.entries) {
      if (s.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static String? _clean(String? s) {
    final t = s?.trim();
    if (t == null || t.isEmpty || t == '-' || t.toLowerCase() == 'n/a') {
      return null;
    }
    return t;
  }

  static List<String> _words(String? s) => s == null
      ? const []
      : s
            .toLowerCase()
            .split(RegExp('[^a-z]+'))
            .where((w) => w.isNotEmpty)
            .toList();

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static Color _shift(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.05, 0.97))
        .toColor();
  }

  static const Map<String, Color> _hues = {
    'yellow': Color(0xFFF7C726),
    'canary': Color(0xFFF7C726),
    'golden': Color(0xFFE8B53A),
    'gold': Color(0xFFE8B53A),
    'orange': Color(0xFFF7841F),
    'blue': Color(0xFF2F6FEB),
    'red': Color(0xFFD8232F),
    'pink': Color(0xFFF26BAE),
    'rose': Color(0xFFF26BAE),
    'green': Color(0xFF1FA559),
    'olive': Color(0xFF8C8A1E),
    'brown': Color(0xFF9A6236),
    'chocolate': Color(0xFF6E4126),
    'champagne': Color(0xFFE2BE8C),
    'cognac': Color(0xFFA0521D),
    'purple': Color(0xFF8E3BE0),
    'violet': Color(0xFF6A3FD8),
    'lavender': Color(0xFFB79CE0),
    'grey': Color(0xFF9AA3AE),
    'gray': Color(0xFF9AA3AE),
    'black': Color(0xFF2A2F38),
    'white': Color(0xFFE9ECF1),
    'colorless': Color(0xFFF3F7FB),
    'colourless': Color(0xFFF3F7FB),
    'teal': Color(0xFF16B3A3),
    'aqua': Color(0xFF6FCFDD),
    'chameleon': Color(0xFF7F8E3C),
    'peach': Color(0xFFF4B48A),
    'padparadscha': Color(0xFFF59A7A),
  };

  /// Overtone wording onto its hue name.
  static const Map<String, String> _modifiers = {
    'yellowish': 'yellow',
    'orangy': 'orange',
    'orangey': 'orange',
    'orangish': 'orange',
    'bluish': 'blue',
    'blueish': 'blue',
    'reddish': 'red',
    'pinkish': 'pink',
    'greenish': 'green',
    'brownish': 'brown',
    'purplish': 'purple',
    'violetish': 'violet',
    'grayish': 'gray',
    'greyish': 'grey',
    'blackish': 'black',
    'whiteish': 'white',
    'whitish': 'white',
  };

  /// Typical body colour of a gem species.
  static const Map<String, Color> _species = {
    'ruby': Color(0xFFC3122E),
    'emerald': Color(0xFF138A4E),
    'sapphire': Color(0xFF1F4FC8),
    'amethyst': Color(0xFF8E3BE0),
    'citrine': Color(0xFFF2A72B),
    'aquamarine': Color(0xFF7FD3E0),
    'peridot': Color(0xFF8DB82A),
    'tanzanite': Color(0xFF5B4BD6),
    'garnet': Color(0xFF8E1426),
    'spinel': Color(0xFFD8326B),
    'morganite': Color(0xFFF2A9B8),
    'tourmaline': Color(0xFFE0558E),
    'topaz': Color(0xFF4FA8E0),
    'opal': Color(0xFFE6EEF2),
    'alexandrite': Color(0xFF2E8C6E),
    'turquoise': Color(0xFF34C3C0),
    'kunzite': Color(0xFFE3A4D6),
    'zircon': Color(0xFF5CC3E8),
    'pearl': Color(0xFFF1ECE2),
  };

  @override
  bool operator ==(Object other) =>
      other is StoneTint &&
      other.light == light &&
      other.body == body &&
      other.deep == deep &&
      other.spectrum == spectrum;

  @override
  int get hashCode => Object.hash(light, body, deep, spectrum);
}
