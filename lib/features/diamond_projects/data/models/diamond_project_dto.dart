/// Raw API shape for a diamond project. Never used outside data/.
class DiamondProjectDto {
  const DiamondProjectDto({
    required this.json,
  });

  final Map<String, dynamic> json;

  factory DiamondProjectDto.fromJson(Map<String, dynamic> json) =>
      DiamondProjectDto(json: json);

  String? get id => _str(json['id']);
  String? get name => _str(json['name']);
  String? get userId => _str(json['userId']);
  String? get sellerId => _str(json['sellerId']);
  String? get diamondType => _str(json['diamondType']);
  Map<String, dynamic> get filters => _map(json['filters']);
  Map<String, dynamic> get analytics => _map(json['analytics']);
  int get itemCount =>
      _num(json['itemCount'])?.toInt() ??
      _num(_map(json['_count'])['items'])?.toInt() ??
      0;
  num? get totalCarat => _num(json['totalCarat']);
  num? get totalPrice => _num(json['totalPrice']);
  num? get avgPrice => _num(json['avgPrice']);
  num? get avgPpc => _num(json['avgPpc']);
  DateTime? get createdAt => _date(json['createdAt']);
  DateTime? get updatedAt => _date(json['updatedAt']);
  String? get ownerName => _str(_map(json['user'])['name']);
  String? get companyName => _str(_map(json['seller'])['companyName']);

  List<Map<String, dynamic>> get items {
    final raw = json['items'];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map<String, dynamic>) item,
    ];
  }

  static String? _str(Object? value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static num? _num(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return const {};
  }
}

/// Paginated list envelope from GET /diamond-projects.
class DiamondProjectListDto {
  const DiamondProjectListDto({
    required this.items,
    required this.total,
    required this.page,
    required this.hasMore,
  });

  final List<DiamondProjectDto> items;
  final int total;
  final int page;
  final bool hasMore;

  factory DiamondProjectListDto.fromJson(Map<String, dynamic>? root) {
    final dataNode = root?['data'];
    final payload = dataNode is Map<String, dynamic>
        ? dataNode
        : const <String, dynamic>{};
    final list = payload['data'];
    final meta = payload['meta'];
    final metaMap = meta is Map<String, dynamic>
        ? meta
        : const <String, dynamic>{};

    final items = <DiamondProjectDto>[];
    if (list is List) {
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          items.add(DiamondProjectDto.fromJson(item));
        }
      }
    }

    final page = DiamondProjectDto._num(metaMap['currentPage'])?.toInt() ?? 1;
    final last = DiamondProjectDto._num(metaMap['lastPage'])?.toInt();
    final hasMore = metaMap.containsKey('next')
        ? metaMap['next'] != null
        : (last != null ? page < last : false);

    return DiamondProjectListDto(
      items: items,
      total: DiamondProjectDto._num(metaMap['total'])?.toInt() ?? items.length,
      page: page,
      hasMore: hasMore,
    );
  }
}
