/// Single metal spot quote for the bullions price ticker.
class MetalSpotPrice {
  const MetalSpotPrice({
    required this.id,
    required this.name,
    required this.code,
    required this.priceUsd,
    required this.changePercent,
    this.unitLabel = '/oz',
  });

  final String id;
  final String name;
  final String code;
  final double priceUsd;
  final double changePercent;

  /// Display suffix, e.g. `/oz` or `/lb` (copper futures).
  final String unitLabel;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'priceUsd': priceUsd,
        'changePercent': changePercent,
        'unitLabel': unitLabel,
      };

  factory MetalSpotPrice.fromJson(Map<String, dynamic> json) {
    return MetalSpotPrice(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      priceUsd: (json['priceUsd'] as num?)?.toDouble() ?? 0,
      changePercent: (json['changePercent'] as num?)?.toDouble() ?? 0,
      unitLabel: json['unitLabel']?.toString() ?? '/oz',
    );
  }
}
