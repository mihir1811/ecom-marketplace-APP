import '../../domain/models/seller_product.dart';

/// Maps diamond / melee diamond JSON rows onto [SellerProduct].
abstract final class SellerProductMapper {
  static SellerProduct fromJson(
    Map<String, dynamic> json, {
    required bool isNatural,
  }) {
    final fields = <String, String?>{};
    json.forEach((key, value) {
      if (value is Map || value is List) return;
      final columnId = _columnId(key);
      fields[columnId] = _display(key, value);
    });

    fields['color'] ??= _display('color', json['colorFrom']);
    fields['clarity'] ??= _display('clarity', json['clarityMin']);
    fields['cut'] ??= _display('cut', json['cutFrom']);
    fields['polish'] ??= _display('polish', json['polishFrom']);
    fields['symmetry'] ??= _display('symmetry', json['symmetryFrom']);
    fields['carat_weight'] ??= _display(
      'caratWeight',
      json['caratWeight'] ?? json['totalCaratWeight'],
    );
    fields['comment'] ??= _display('comment', json['description']);
    fields['measurement'] ??= _display(
      'measurement',
      json['measurement'] ?? json['measurementMin'],
    );
    fields['fluorescence_intensity'] ??= _display(
      'fluorescenceIntensity',
      json['fluorescenceIntensity'] ?? json['fluoreScenceIntensityFrom'],
    );
    fields['fancy_color'] ??= _display(
      'fancyColor',
      json['fancyColor'] ?? json['fancyColorFrom'],
    );
    fields['fancy_intensity'] ??= _display(
      'fancyIntencity',
      json['fancyIntencity'] ?? json['fancyIntencityFrom'],
    );

    final id = json['id']?.toString() ?? '';
    final seller = json['seller'];
    final nestedSellerId = seller is Map<String, dynamic>
        ? seller['id']?.toString()
        : null;
    final sellerId = json['sellerId']?.toString() ?? nestedSellerId ?? '';
    final stock = fields['stock_number'] ?? '';

    return SellerProduct(
      id: id,
      sellerId: sellerId,
      stockNumber: stock,
      isNatural: isNatural,
      isExpired: json['isExpired'] == true,
      isDeleted: json['isDeleted'] == true,
      isOnAuction: json['isOnAuction'] == true,
      isSold: json['isSold'] == true,
      fields: fields,
    );
  }

  static String _columnId(String apiKey) {
    return _apiToColumn[apiKey] ?? _camelToSnake(apiKey);
  }

  static String? _display(String apiKey, Object? value) {
    if (value == null) return null;
    if (value is bool) return value ? 'yes' : 'no';
    if (apiKey == 'createdAt' ||
        apiKey == 'updatedAt' ||
        apiKey == 'auctionStartTime' ||
        apiKey == 'auctionEndTime') {
      return _date(value);
    }
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return text;
  }

  static String? _date(Object? value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return raw;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  static String _camelToSnake(String key) {
    final buf = StringBuffer();
    for (var i = 0; i < key.length; i++) {
      final ch = key[i];
      final isUpper = ch.toUpperCase() == ch && ch.toLowerCase() != ch;
      if (isUpper && i > 0) buf.write('_');
      buf.write(ch.toLowerCase());
    }
    return buf.toString();
  }

  static const _apiToColumn = <String, String>{
    'stockNumber': 'stock_number',
    'sellerId': 'seller_id',
    'caratWeight': 'carat_weight',
    'totalCaratWeight': 'carat_weight',
    'pricePerCarat': 'price_per_carat',
    'totalPrice': 'total_price',
    'certificateCompanyName': 'certificate_company_name',
    'certificateNumber': 'certificate_number',
    'fluorescenceIntensity': 'fluorescence_intensity',
    'fluorescenceColor': 'fluorescence_color',
    'fluoreScenceIntensityFrom': 'fluorescence_intensity',
    'fluoreScenceColorFrom': 'fluorescence_color',
    'fancyColor': 'fancy_color',
    'fancyIntencity': 'fancy_intensity',
    'fancyOvertone': 'fancy_overtone',
    'videoURL': 'video_url',
    'eyeClean': 'eye_clean',
    'BGM': 'bgm',
    'HA': 'ha',
    'laserInscription': 'laser_inscription',
    'inclusionsType': 'inclusions_type',
    'matchingPairNumber': 'matching_pair_number',
    'roughSource': 'rough_source',
    'keyToSymbols': 'key_to_symbols',
    'certComment': 'cert_comment',
    'gridleMin': 'gridle_min',
    'gridleMax': 'gridle_max',
    'gridlePercentage': 'gridle_percentage',
    'gridleCondition': 'gridle_condition',
    'crownHeight': 'crown_height',
    'crownAngle': 'crown_angle',
    'pavilionAngle': 'pavilion_angle',
    'pavilionDepth': 'pavilion_depth',
    'culetSize': 'culet_size',
    'culetCondition': 'culet_condition',
    'starLength': 'star_length',
    'isOnAuction': 'is_on_auction',
    'isSold': 'is_sold',
    'isExpired': 'is_expired',
    'isDeleted': 'is_deleted',
    'createdAt': 'created_at',
    'updatedAt': 'updated_at',
    'auctionStartTime': 'auction_start_time',
    'auctionEndTime': 'auction_end_time',
    'colorFrom': 'color_from',
    'colorTo': 'color_to',
    'clarityMin': 'clarity_min',
    'clarityMax': 'clarity_max',
  };
}
