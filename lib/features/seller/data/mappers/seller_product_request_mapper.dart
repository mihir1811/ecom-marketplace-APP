import 'package:dio/dio.dart';

import '../../domain/models/seller_product.dart';

/// Maps [SellerProduct] fields to PATCH multipart bodies.
abstract final class SellerProductRequestMapper {
  static FormData toUpdateFormData(SellerProduct product) {
    final fields = product.isNatural
        ? _naturalFields(product)
        : _meleeFields(product);
    return FormData.fromMap(fields);
  }

  static Map<String, dynamic> _naturalFields(SellerProduct product) {
    final out = <String, dynamic>{};
    void put(String apiKey, String columnId) {
      final value = _text(product.field(columnId));
      if (value != null) out[apiKey] = value;
    }

    put('stockNumber', 'stock_number');
    put('available', 'available');
    put('comment', 'comment');
    put('origin', 'origin');
    put('pricePerCarat', 'price_per_carat');
    put('totalPrice', 'total_price');
    put('caratWeight', 'carat_weight');
    put('rap', 'rap');
    final discount = _discount(product.field('discount'));
    if (discount != null) out['discount'] = discount;
    put('color', 'color');
    put('fancyColor', 'fancy_color');
    put('fancyIntencity', 'fancy_intensity');
    put('fancyOvertone', 'fancy_overtone');
    put('shade', 'shade');
    put('shape', 'shape');
    put('clarity', 'clarity');
    put('cut', 'cut');
    put('symmetry', 'symmetry');
    put('polish', 'polish');
    put('fluorescenceIntensity', 'fluorescence_intensity');
    put('fluorescenceColor', 'fluorescence_color');
    put('ratio', 'ratio');
    put('table', 'table');
    put('depth', 'depth');
    put('measurement', 'measurement');
    put('gridleMin', 'gridle_min');
    put('gridleMax', 'gridle_max');
    put('gridlePercentage', 'gridle_percentage');
    put('crownHeight', 'crown_height');
    put('crownAngle', 'crown_angle');
    put('pavilionAngle', 'pavilion_angle');
    put('pavilionDepth', 'pavilion_depth');
    put('culetSize', 'culet_size');
    put('gridleCondition', 'gridle_condition');
    put('starLength', 'star_length');
    put('culetCondition', 'culet_condition');
    put('certificateNumber', 'certificate_number');
    put('certificateCompanyName', 'certificate_company_name');
    put('enhancement', 'enhancement');
    put('laserInscription', 'laser_inscription');
    put('growthType', 'growth_type');
    put('videoURL', 'video_url');
    put('inclusionsType', 'inclusions_type');
    put('milky', 'milky');
    put('matchingPairNumber', 'matching_pair_number');
    put('roughSource', 'rough_source');
    put('keyToSymbols', 'key_to_symbols');
    put('certComment', 'cert_comment');
    put('tinge', 'tinge');
    put('luster', 'luster');
    put('tags', 'tags');

    final eyeClean = _asBool(product.field('eye_clean'));
    if (eyeClean != null) out['eyeClean'] = eyeClean;
    final bgm = _asBool(product.field('bgm'));
    if (bgm != null) out['BGM'] = bgm;
    final ha = _asBool(product.field('ha'));
    if (ha != null) out['HA'] = ha;
    out['isExpired'] = product.isExpired;
    return out;
  }

  static Map<String, dynamic> _meleeFields(SellerProduct product) {
    final out = <String, dynamic>{};
    void put(String apiKey, String columnId) {
      final value = _text(product.field(columnId));
      if (value != null) out[apiKey] = value;
    }

    put('stockNumber', 'stock_number');
    put('available', 'available');
    put('shape', 'shape');
    put('colorFrom', 'color_from');
    put('colorTo', 'color_to');
    if (!out.containsKey('colorFrom')) put('colorFrom', 'color');
    put('clarityMin', 'clarity_min');
    put('clarityMax', 'clarity_max');
    if (!out.containsKey('clarityMin')) put('clarityMin', 'clarity');
    final totalCarat = _asNum(product.field('carat_weight'));
    if (totalCarat != null) out['totalCaratWeight'] = totalCarat;
    final discount = _asNum(_discount(product.field('discount')));
    if (discount != null) out['discount'] = discount;
    final ppc = _asNum(product.field('price_per_carat'));
    if (ppc != null) out['pricePerCarat'] = ppc;
    final total = _asNum(product.field('total_price'));
    if (total != null) out['totalPrice'] = total;
    put('ratio', 'ratio');
    put('certificateCompanyName', 'certificate_company_name');
    put('certificateNumber', 'certificate_number');
    final cert = _text(product.field('certification'));
    if (cert != null && _isUrl(cert)) out['certification'] = cert;
    put('origin', 'origin');
    put('description', 'description');
    if (!out.containsKey('description')) put('description', 'comment');
    put('cutFrom', 'cut');
    put('polishFrom', 'polish');
    put('symmetryFrom', 'symmetry');
    put('fluoreScenceIntensityFrom', 'fluorescence_intensity');
    put('growthType', 'growth_type');
    put('roughSource', 'rough_source');
    put('certComment', 'cert_comment');
    put('tinge', 'tinge');
    put('luster', 'luster');
    put('tags', 'tags');
    put('videoURL', 'video_url');
    out['isExpired'] = product.isExpired;

    for (var i = 1; i <= 6; i++) {
      final url = _text(product.field('image$i'));
      if (url != null && _isUrl(url)) out['image$i'] = url;
    }
    return out;
  }

  static String? _text(String? value) {
    if (value == null) return null;
    final t = value.trim();
    if (t.isEmpty ||
        t == '-' ||
        t == '—' ||
        t == '–' ||
        t.toLowerCase() == 'n/a' ||
        t.toLowerCase() == 'placeholder') {
      return null;
    }
    return t;
  }

  static String? _discount(String? value) {
    final t = _text(value);
    if (t == null) return null;
    return t.replaceAll('%', '').trim();
  }

  static bool? _asBool(String? value) {
    final t = _text(value)?.toLowerCase();
    if (t == null) return null;
    if (t == 'true' || t == 'yes' || t == '1') return true;
    if (t == 'false' || t == 'no' || t == '0') return false;
    return null;
  }

  static num? _asNum(String? value) {
    final t = _text(value);
    if (t == null) return null;
    return num.tryParse(t.replaceAll(',', ''));
  }

  static bool _isUrl(String value) =>
      value.startsWith('http://') || value.startsWith('https://');
}
