import 'dart:typed_data';

enum InquiryCategory {
  diamond('Diamond', 'Diamond inquiries'),
  gemstone('Gemstone', 'Gemstone inquiries'),
  bullion('Bullion', 'Bullion inquiries'),
  watch('Watch', 'Watch inquiries'),
  jewelry('Jewelry', 'Jewelry inquiries');

  const InquiryCategory(this.label, this.listTitle);
  final String label;
  final String listTitle;

  /// API path segment, e.g. `diamond-inquiry`.
  String get apiSegment => switch (this) {
        InquiryCategory.diamond => 'diamond-inquiry',
        InquiryCategory.gemstone => 'gemstone-inquiry',
        InquiryCategory.bullion => 'bullion-inquiry',
        InquiryCategory.watch => 'watch-inquiry',
        InquiryCategory.jewelry => 'jewellery-inquiry',
      };

  /// Image field name on create/update (jewellery uses `referenceImage`).
  String get imageFieldKey =>
      this == InquiryCategory.jewelry ? 'referenceImage' : 'imageUrl';

  /// Primary submit button copy for the matching category form.
  String get submitLabel => this == InquiryCategory.jewelry
      ? 'Submit jewellery inquiry'
      : 'Submit ${label.toLowerCase()} inquiry';

  static InquiryCategory? fromRouteName(String name) {
    final lower = name.toLowerCase();
    for (final c in InquiryCategory.values) {
      if (c.name == lower) return c;
    }
    return null;
  }
}

/// Who submitted the inquiry. All inquiries route to admin (not peer-to-peer).
enum InquirySenderRole { buyer, seller }

class SellerInquiry {
  SellerInquiry({
    required this.id,
    required this.category,
    required this.buyerName,
    required this.buyerEmail,
    required this.userId,
    required this.summary,
    required this.createdAtLabel,
    required this.updatedAtLabel,
    required this.createdAtLong,
    required this.fields,
    this.sentBy = InquirySenderRole.buyer,
    this.referenceImages = const [],
    this.imageUrl,
    this.adminReply,
    this.adminReplyAt,
    this.adminReplyImages = const [],
  });

  final String id;
  final InquiryCategory category;
  final String buyerName;
  final String buyerEmail;
  final String userId;
  final String summary;
  final String createdAtLabel;
  String updatedAtLabel;
  final String createdAtLong;
  final Map<String, String> fields;

  /// Buyer or seller who submitted — replies come from admin only.
  final InquirySenderRole sentBy;

  /// Sender-uploaded reference images ("I want something like this").
  final List<Uint8List> referenceImages;

  /// Remote image URL from API (`imageUrl` or `referenceImage`).
  final String? imageUrl;

  /// Admin response visible to the inquiry sender (markdown-lite plain text).
  String? adminReply;
  String? adminReplyAt;

  /// Admin-uploaded reference images ("We have something like this").
  List<Uint8List> adminReplyImages;

  bool get hasAdminReply =>
      (adminReply != null && adminReply!.trim().isNotEmpty) ||
      adminReplyImages.isNotEmpty;
}
