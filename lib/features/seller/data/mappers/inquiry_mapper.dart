import '../../domain/models/seller_inquiry.dart';

/// Maps live inquiry API JSON to [SellerInquiry].
abstract final class InquiryMapper {
  static const _metaKeys = {'id', 'userId', 'createdAt', 'updatedAt', 'user'};

  static SellerInquiry fromJson(
    Map<String, dynamic> json, {
    required InquiryCategory category,
  }) {
    final user = json['user'];
    final userMap = user is Map<String, dynamic> ? user : null;

    final fields = <String, String>{};
    for (final entry in json.entries) {
      if (_metaKeys.contains(entry.key)) continue;
      final value = entry.value;
      if (value == null) continue;
      fields[entry.key] = _displayValue(value);
    }

    final createdAt = _parseDate(json['createdAt']);
    final updatedAt = _parseDate(json['updatedAt']) ?? createdAt;

    return SellerInquiry(
      id: json['id']?.toString() ?? '',
      category: category,
      buyerName: userMap?['name']?.toString() ?? 'You',
      buyerEmail: userMap?['email']?.toString() ?? '',
      userId: json['userId']?.toString() ?? userMap?['id']?.toString() ?? '',
      summary: _summaryFor(category, json),
      createdAtLabel: _shortLabel(createdAt),
      updatedAtLabel: _shortLabel(updatedAt),
      createdAtLong: _longLabel(createdAt),
      fields: fields,
      imageUrl: _imageUrl(category, json),
    );
  }

  static String? _imageUrl(
    InquiryCategory category,
    Map<String, dynamic> json,
  ) {
    final key = category.imageFieldKey;
    final value = json[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String _summaryFor(
    InquiryCategory category,
    Map<String, dynamic> json,
  ) {
    String pick(List<String> keys) {
      for (final key in keys) {
        final v = json[key];
        if (v != null && v.toString().trim().isNotEmpty) {
          return v.toString().trim();
        }
      }
      return '—';
    }

    return switch (category) {
      InquiryCategory.diamond =>
        '${pick(['shape'])} · ${pick(['caratMin'])}–${pick(['caratMax'])} ct',
      InquiryCategory.gemstone =>
        '${pick(['gemstoneType'])} · ${pick(['caratWeightMin', 'caratMin'])}–${pick(['caratWeightMax', 'caratMax'])} ct',
      InquiryCategory.bullion =>
        '${pick(['metalType'])} · ${pick(['shapeFormat'])}',
      InquiryCategory.watch => '${pick(['brand'])} · ${pick(['model'])}',
      InquiryCategory.jewelry =>
        '${pick(['subCategory'])} · ${pick(['metalType'])}',
    };
  }

  static String _displayValue(Object value) {
    if (value is bool) return value ? 'Yes' : 'No';
    return value.toString();
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  static String _shortLabel(DateTime? date) {
    if (date == null) return '—';
    return '${date.day} ${_month(date.month)} ${date.year}, '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  static String _longLabel(DateTime? date) {
    if (date == null) return '—';
    return '${_weekday(date.weekday)}, ${date.day} ${_month(date.month)} '
        '${date.year} at ${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  static String _month(int m) => const [
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
  ][m - 1];

  static String _weekday(int d) => const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][d - 1];
}
