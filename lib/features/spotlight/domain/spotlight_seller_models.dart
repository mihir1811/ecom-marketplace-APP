import 'spotlight_models.dart';

/// Whether a placement is priced per ad or per sponsored product.
enum SpotlightUnit { ad, product }

/// One rate card entry from GET /spotlight/seller/overview.
class SpotlightRate {
  const SpotlightRate({
    required this.placement,
    required this.label,
    required this.hasCategory,
    required this.unit,
    required this.isOpen,
    required this.pricePerDay,
    required this.slots,
    required this.maxProducts,
    required this.minDays,
    required this.maxDays,
    required this.bookAheadDays,
    this.type,
    this.description,
  });

  final SpotlightPlacement placement;
  final String? type;
  final String label;
  final String? description;
  final bool hasCategory;
  final SpotlightUnit unit;
  final bool isOpen;

  /// Rupees per day (per product for sponsored products).
  final double pricePerDay;
  final int slots;
  final int maxProducts;
  final int minDays;
  final int maxDays;
  final int bookAheadDays;

  bool get isBanner =>
      placement == SpotlightPlacement.homeBanner ||
      placement == SpotlightPlacement.categoryBanner;
  bool get isFeaturedSeller =>
      placement == SpotlightPlacement.homeFeaturedSeller;
  bool get isSponsoredProducts => unit == SpotlightUnit.product;

  static SpotlightRate? fromJson(Object? raw) {
    final j = SpotlightJson.map(raw);
    if (j == null) return null;
    final placement = SpotlightPlacement.fromApi(j['placement']);
    if (placement == null) return null;
    final unit =
        SpotlightJson.text(j['unit'])?.toLowerCase().startsWith('product') ??
            placement.isSponsoredProducts
        ? SpotlightUnit.product
        : SpotlightUnit.ad;
    final minDays = SpotlightJson.integer(j['minDays']) ?? 1;
    return SpotlightRate(
      placement: placement,
      type: SpotlightJson.text(j['type']),
      label: SpotlightJson.text(j['label']) ?? placement.api,
      description: SpotlightJson.text(j['description']),
      hasCategory: j.containsKey('hasCategory')
          ? SpotlightJson.flag(j['hasCategory'])
          : placement.needsCategory,
      unit: unit,
      isOpen: SpotlightJson.flag(j['isOpen']),
      pricePerDay: SpotlightJson.number(j['pricePerDay']) ?? 0,
      slots: SpotlightJson.integer(j['slots']) ?? 0,
      maxProducts: SpotlightJson.integer(j['maxProducts']) ?? 1,
      minDays: minDays < 1 ? 1 : minDays,
      maxDays: SpotlightJson.integer(j['maxDays']) ?? minDays,
      bookAheadDays: SpotlightJson.integer(j['bookAheadDays']) ?? 0,
    );
  }
}

/// GET /spotlight/seller/overview.
class SpotlightOverview {
  const SpotlightOverview({
    required this.canBook,
    required this.placements,
    required this.categories,
    required this.today,
    required this.availableBalance,
    this.blockedReason,
  });

  final bool canBook;

  /// Why booking is off (blocked, or not verified yet).
  final String? blockedReason;

  /// Open placements only.
  final List<SpotlightRate> placements;

  /// Sections this seller sells in.
  final List<SpotlightCategory> categories;

  /// Today's date in India.
  final DateTime today;

  /// Rupees the seller can spend.
  final double availableBalance;

  factory SpotlightOverview.fromJson(Map<String, dynamic> j) {
    final seller = SpotlightJson.map(j['seller']) ?? const {};
    final wallet = SpotlightJson.map(j['wallet']) ?? const {};
    return SpotlightOverview(
      canBook: SpotlightJson.flag(seller['canBook']),
      blockedReason: SpotlightJson.text(seller['blockedReason']),
      placements: [
        for (final raw in SpotlightJson.list(j['placements']))
          if (SpotlightRate.fromJson(raw) case final r? when r.isOpen) r,
      ],
      categories: [
        for (final raw in SpotlightJson.list(j['categories']))
          ?SpotlightCategory.fromApi(
            raw is Map ? (raw['category'] ?? raw['value'] ?? raw['id']) : raw,
          ),
      ],
      today: spotlightDay(SpotlightJson.text(j['today'])) ?? spotlightToday(),
      availableBalance: SpotlightJson.number(wallet['availableBalance']) ?? 0,
    );
  }
}

/// One day of GET /spotlight/seller/availability, counted in units.
class SpotlightDay {
  const SpotlightDay({
    required this.date,
    required this.used,
    required this.free,
  });

  final DateTime date;
  final int used;
  final int free;

  static SpotlightDay? fromJson(Object? raw) {
    final j = SpotlightJson.map(raw);
    final date = spotlightDay(SpotlightJson.text(j?['date']));
    if (j == null || date == null) return null;
    return SpotlightDay(
      date: date,
      used: SpotlightJson.integer(j['used']) ?? 0,
      free: SpotlightJson.integer(j['free']) ?? 0,
    );
  }
}

/// A product the seller can sponsor (GET /spotlight/seller/products).
class SpotlightSellerProduct {
  const SpotlightSellerProduct({
    required this.productType,
    required this.productId,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.stockNumber,
    this.shape,
    this.price,
  });

  final String productType;
  final String productId;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? stockNumber;
  final String? shape;
  final double? price;

  String get key => '$productType:$productId';

  Map<String, dynamic> toBooking() => {
    'productType': productType,
    'productId': productId,
  };

  static SpotlightSellerProduct? fromJson(Object? raw) {
    var j = SpotlightJson.map(raw);
    if (j == null) return null;
    // Booked ads may nest the listing under `product`.
    final nested = SpotlightJson.map(j['product']);
    if (nested != null) j = {...j, ...nested};
    final type = SpotlightJson.text(j['productType']);
    final id =
        SpotlightJson.text(j['productId']) ??
        SpotlightJson.text(j['id']) ??
        SpotlightJson.text(j['_id']);
    if (type == null || id == null) return null;
    return SpotlightSellerProduct(
      productType: type,
      productId: id,
      title:
          SpotlightJson.text(j['title']) ??
          SpotlightJson.text(j['name']) ??
          SpotlightJson.text(j['stockNumber']) ??
          id,
      subtitle: SpotlightJson.text(j['subtitle']),
      imageUrl: SpotlightJson.text(j['imageUrl']),
      stockNumber: SpotlightJson.text(j['stockNumber']),
      shape: SpotlightJson.text(j['shape']),
      price: SpotlightJson.number(j['price']),
    );
  }
}

/// Where a booked ad is in its life.
enum SpotlightAdState {
  pendingReview('PENDING_REVIEW', 'Pending review'),
  scheduled('SCHEDULED', 'Scheduled'),
  live('LIVE', 'Live'),
  ended('ENDED', 'Ended'),
  cancelled('CANCELLED', 'Cancelled'),
  rejected('REJECTED', 'Rejected'),
  expired('EXPIRED', 'Expired'),
  stopped('STOPPED', 'Stopped'),
  unknown('', 'Unknown');

  const SpotlightAdState(this.api, this.label);

  final String api;
  final String label;

  static SpotlightAdState fromApi(Object? value) {
    final raw = value?.toString().trim().toUpperCase();
    for (final s in values) {
      if (s.api == raw && s != unknown) return s;
    }
    return unknown;
  }
}

/// One day's counts on an ad.
class SpotlightDailyStat {
  const SpotlightDailyStat({
    required this.date,
    required this.views,
    required this.clicks,
  });

  final DateTime date;
  final int views;
  final int clicks;
}

/// A seller's booked ad (GET /spotlight/seller and /spotlight/seller/{id}).
class SpotlightSellerAd {
  const SpotlightSellerAd({
    required this.id,
    required this.placement,
    required this.state,
    required this.amount,
    required this.refundedAmount,
    required this.netAmount,
    required this.views,
    required this.clicks,
    required this.canCancel,
    this.category,
    this.placementLabel,
    this.title,
    this.subtitle,
    this.imageUrl,
    this.mobileImageUrl,
    this.startDate,
    this.endDate,
    this.adminNote,
    this.products = const [],
    this.daily = const [],
    this.createdAt,
  });

  final String id;
  final SpotlightPlacement? placement;
  final String? placementLabel;
  final SpotlightCategory? category;
  final SpotlightAdState state;
  final String? title;
  final String? subtitle;
  final String? imageUrl;
  final String? mobileImageUrl;
  final DateTime? startDate;
  final DateTime? endDate;

  /// Rupees charged at booking, refunded so far, and what's left.
  final double amount;
  final double refundedAmount;
  final double netAmount;
  final int views;
  final int clicks;

  /// GemWorld's reason for a rejection or a stop.
  final String? adminNote;
  final bool canCancel;
  final List<SpotlightSellerProduct> products;
  final List<SpotlightDailyStat> daily;
  final DateTime? createdAt;

  int? get days {
    final s = startDate, e = endDate;
    if (s == null || e == null) return null;
    return e.difference(s).inDays + 1;
  }

  /// Click-through rate in percent, or null before any view.
  double? get ctr => views == 0 ? null : clicks / views * 100;

  factory SpotlightSellerAd.fromJson(Map<String, dynamic> j) {
    final amount = SpotlightJson.number(j['amount']) ?? 0;
    final refunded = SpotlightJson.number(j['refundedAmount']) ?? 0;
    final stats = SpotlightJson.map(j['stats']) ?? const {};
    int count(String a, String b) =>
        SpotlightJson.integer(j[a]) ??
        SpotlightJson.integer(j[b]) ??
        SpotlightJson.integer(stats[a]) ??
        SpotlightJson.integer(stats[b]) ??
        0;
    return SpotlightSellerAd(
      id:
          SpotlightJson.text(j['id']) ??
          SpotlightJson.text(j['_id']) ??
          SpotlightJson.text(j['adId']) ??
          '',
      placement: SpotlightPlacement.fromApi(j['placement']),
      placementLabel: SpotlightJson.text(j['placementLabel']),
      category: SpotlightCategory.fromApi(j['category']),
      state: SpotlightAdState.fromApi(j['state'] ?? j['status']),
      title: SpotlightJson.text(j['title']),
      subtitle: SpotlightJson.text(j['subtitle']),
      imageUrl: SpotlightJson.text(j['imageUrl']),
      mobileImageUrl: SpotlightJson.text(j['mobileImageUrl']),
      startDate: spotlightDay(SpotlightJson.text(j['startDate'])),
      endDate: spotlightDay(SpotlightJson.text(j['endDate'])),
      amount: amount,
      refundedAmount: refunded,
      netAmount: SpotlightJson.number(j['netAmount']) ?? amount - refunded,
      views: count('impressions', 'views'),
      clicks: count('clicks', 'clickCount'),
      adminNote: SpotlightJson.text(j['adminNote']),
      canCancel: SpotlightJson.flag(j['canCancel']),
      products: [
        for (final raw in SpotlightJson.list(j['products']))
          ?SpotlightSellerProduct.fromJson(raw),
      ],
      daily: [
        for (final raw in SpotlightJson.list(j['daily']))
          if (SpotlightJson.map(raw) case final d?)
            if (spotlightDay(SpotlightJson.text(d['date'])) case final date?)
              SpotlightDailyStat(
                date: date,
                views:
                    SpotlightJson.integer(d['impressions']) ??
                    SpotlightJson.integer(d['views']) ??
                    0,
                clicks: SpotlightJson.integer(d['clicks']) ?? 0,
              ),
      ],
      createdAt: SpotlightJson.date(j['createdAt']),
    );
  }
}

/// A failed seller call: the server's message (shown as it is) and, for
/// booking, its `code` and extra fields.
class SpotlightError {
  const SpotlightError(
    this.message, {
    this.code,
    this.status,
    this.data = const {},
  });

  final String message;
  final String? code;
  final int? status;
  final Map<String, dynamic> data;

  static const placementClosed = 'AD_PLACEMENT_CLOSED';
  static const slotsFull = 'AD_SLOTS_FULL';
  static const overlapsYourAd = 'AD_OVERLAPS_YOUR_AD';
  static const productAlreadySponsored = 'AD_PRODUCT_ALREADY_SPONSORED';
  static const walletTooLow = 'AD_WALLET_TOO_LOW';
  static const priceChanged = 'AD_PRICE_CHANGED';

  /// AD_WALLET_TOO_LOW / AD_PRICE_CHANGED: the total in rupees.
  double? get amount => SpotlightJson.number(data['amount']);
  double? get availableBalance =>
      SpotlightJson.number(data['availableBalance']);

  /// AD_SLOTS_FULL: the days without room.
  List<SpotlightDay> get fullDays => [
    for (final raw in SpotlightJson.list(data['days']))
      ?SpotlightDay.fromJson(raw),
  ];

  /// AD_PRODUCT_ALREADY_SPONSORED: the product that clashes.
  String? get productId => SpotlightJson.text(data['productId']);
}

/// `yyyy-mm-dd` (or an ISO timestamp) as a local calendar date.
DateTime? spotlightDay(String? value) {
  if (value == null) return null;
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value);
  if (m == null) return null;
  return DateTime(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
  );
}

/// The calendar date in India (UTC+5:30), used until the server says.
DateTime spotlightToday() {
  final ist = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  return DateTime(ist.year, ist.month, ist.day);
}

/// `yyyy-mm-dd` for the API.
String spotlightDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
