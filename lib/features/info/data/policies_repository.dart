import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/models/policy_document.dart';

/// Loads marketplace policies from a single JSON asset.
class PoliciesRepository {
  PoliciesRepository._();

  static const assetPath = 'assets/policies/policies.json';

  static List<PolicyDocument>? _cache;

  /// Returns all policies (cached after first load).
  static Future<List<PolicyDocument>> loadAll() async {
    if (_cache != null) return _cache!;

    final raw = await rootBundle.loadString(assetPath);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final list = (decoded['policies'] as List<dynamic>? ?? const [])
        .map((e) => PolicyDocument.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = list;
    return list;
  }

  /// Looks up one policy by [id] (e.g. `terms`, `privacy`).
  static Future<PolicyDocument?> loadById(String id) async {
    final all = await loadAll();
    for (final policy in all) {
      if (policy.id == id) return policy;
    }
    return null;
  }
}
