import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';

import '../domain/models/policy_document.dart';

/// Loads marketplace policies from the asset matching the active locale.
class PoliciesRepository {
  PoliciesRepository._();

  static final _cache = <String, List<PolicyDocument>>{};

  /// Returns all policies (cached after first load).
  static Future<List<PolicyDocument>> loadAll(Locale locale) async {
    final languageCode = switch (locale.languageCode) {
      'hi' => 'hi',
      'gu' => 'gu',
      _ => 'en',
    };
    final cached = _cache[languageCode];
    if (cached != null) return cached;

    final assetPath = languageCode == 'en'
        ? 'assets/policies/policies.json'
        : 'assets/policies/policies_$languageCode.json';
    final raw = await rootBundle.loadString(assetPath);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final list = (decoded['policies'] as List<dynamic>? ?? const [])
        .map((e) => PolicyDocument.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache[languageCode] = list;
    return list;
  }

  /// Looks up one policy by [id] (e.g. `terms`, `privacy`).
  static Future<PolicyDocument?> loadById(String id, Locale locale) async {
    final all = await loadAll(locale);
    for (final policy in all) {
      if (policy.id == id) return policy;
    }
    return null;
  }
}
