import 'models/home_search_result.dart';

/// Relevance ranking ported from web `liveSearchRelevance.ts`.
abstract final class HomeSearchRelevance {
  static List<HomeSearchResult> sort(
    List<HomeSearchResult> items,
    String query, {
    int Function(HomeSearchKind kind)? kindPriority,
    bool requireTextMatch = true,
  }) {
    final priority = kindPriority ?? ((_) => 2);
    final scored = <({HomeSearchResult item, int relevance, int kindRank})>[];

    for (final item in items) {
      final relevance = score(item, query);
      if (requireTextMatch && relevance <= 0) continue;
      scored.add((
        item: item,
        relevance: relevance,
        kindRank: priority(item.kind),
      ));
    }

    scored.sort((a, b) {
      final byRelevance = b.relevance.compareTo(a.relevance);
      if (byRelevance != 0) return byRelevance;
      return a.kindRank.compareTo(b.kindRank);
    });
    return scored.map((e) => e.item).toList(growable: false);
  }

  static int score(HomeSearchResult product, String query) {
    final tokens = _tokenize(query);
    final title = _normalize(product.title);
    final subtitle = _normalize(product.subtitle);
    final hay = '$title $subtitle';
    final phrase = _normalize(query);

    var score = 0;
    var matchedTokens = 0;

    final queryCarat = _extractQueryCarat(query);
    final productCarats = _extractProductCarats(hay);
    if (queryCarat != null && productCarats.isNotEmpty) {
      final nearest = productCarats.reduce(
        (best, ct) =>
            (ct - queryCarat).abs() < (best - queryCarat).abs() ? ct : best,
      );
      final delta = (nearest - queryCarat).abs();
      if (delta <= 0.05) {
        score += 70;
        matchedTokens += 1;
      } else if (delta <= 0.15) {
        score += 45;
        matchedTokens += 1;
      } else if (delta <= 0.35) {
        score += 20;
        matchedTokens += 1;
      }
    }

    if (tokens.isEmpty && matchedTokens == 0) return 0;

    if (phrase.isNotEmpty && hay.contains(phrase)) score += 120;
    if (phrase.isNotEmpty && title.startsWith(phrase)) score += 80;
    if (phrase.isNotEmpty && title.contains(phrase)) score += 50;

    for (final token in tokens) {
      if (_isCaratToken(token, queryCarat != null)) continue;

      final titleWords = title.split(' ');
      final hayWords = hay.split(' ');

      if (title.startsWith(token) || titleWords.contains(token)) {
        score += 40;
        matchedTokens += 1;
        continue;
      }
      if (titleWords.any(
        (w) => w.startsWith(token) || (token.length >= 4 && token.startsWith(w)),
      )) {
        score += 28;
        matchedTokens += 1;
        continue;
      }
      if (hay.contains(token) || hayWords.any((w) => w.startsWith(token))) {
        score += 16;
        matchedTokens += 1;
      }
    }

    if (matchedTokens == 0) return 0;
    score += matchedTokens * 8;
    if (tokens.isNotEmpty && matchedTokens >= tokens.length) score += 25;
    return score;
  }

  static bool _isCaratToken(String token, bool hasQueryCarat) {
    if (token == 'carat' || token == 'carats' || token == 'ct') return true;
    if (RegExp(r'^\d+(?:\.\d+)?\s*ct$').hasMatch(token)) return true;
    if (hasQueryCarat && RegExp(r'^\d+(?:\.\d+)?$').hasMatch(token)) {
      return true;
    }
    return false;
  }

  static double? _extractQueryCarat(String query) {
    final match = RegExp(r'(\d+(?:\.\d+)?)\s*(?:ct|carats?)\b', caseSensitive: false)
            .firstMatch(query) ??
        RegExp(r'^(\d+(?:\.\d+)?)$').firstMatch(query.trim());
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  static List<double> _extractProductCarats(String hay) {
    final values = <double>[];
    for (final match in RegExp(r'(\d+)\s+(\d{1,3})\s*ct\b').allMatches(hay)) {
      final value = double.tryParse('${match.group(1)}.${match.group(2)}');
      if (value != null) values.add(value);
    }
    for (final match in RegExp(r'(\d+(?:\.\d+)?)\s*ct\b').allMatches(hay)) {
      final value = double.tryParse(match.group(1)!);
      if (value != null) values.add(value);
    }
    return values;
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<String> _tokenize(String query) {
    return _normalize(query)
        .split(' ')
        .where((t) => t.length >= 2)
        .toList(growable: false);
  }
}
