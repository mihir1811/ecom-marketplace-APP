import 'jewelry.dart';

/// One top-level category of the Premium segment with its piece count.
typedef JewelryPremiumCategory = ({String slug, String name, int count});

/// A page of `GET /marketplace/premium`: pieces whose starting price is at
/// or above [thresholdInr], an amount GemWorld sets in ohana-admin and can
/// change at any time (never hard-code it).
class JewelryPremiumPage {
  const JewelryPremiumPage({
    required this.items,
    required this.total,
    required this.page,
    required this.hasMore,
    required this.thresholdInr,
    this.categories = const [],
    this.available = true,
  });

  /// The route isn't deployed (404): hide Premium everywhere.
  const JewelryPremiumPage.unavailable()
    : items = const [],
      total = 0,
      page = 1,
      hasMore = false,
      thresholdInr = 0,
      categories = const [],
      available = false;

  final List<Jewelry> items;
  final int total;
  final int page;
  final bool hasMore;

  /// Rupees.
  final double thresholdInr;

  /// Premium pieces per top-level category across the whole segment,
  /// whatever category, sort or page was asked for.
  final List<JewelryPremiumCategory> categories;
  final bool available;

  /// Shown only with something to show.
  bool get isVisible => available && total > 0;
}
