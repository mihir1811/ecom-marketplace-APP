class BuyerOrder {
  const BuyerOrder({
    required this.id,
    required this.productLabel,
    required this.sellerName,
    required this.status,
    required this.carrier,
    required this.location,
    required this.trackingNumber,
    required this.updatedAt,
    required this.timeline,
  });

  final String id;
  final String productLabel;
  final String sellerName;
  final String status;
  final String carrier;
  final String location;
  final String trackingNumber;
  final String updatedAt;
  final List<BuyerOrderTimelineEntry> timeline;
}

class BuyerOrderTimelineEntry {
  const BuyerOrderTimelineEntry({
    required this.title,
    required this.subtitle,
    required this.at,
  });

  final String title;
  final String subtitle;
  final String at;
}
