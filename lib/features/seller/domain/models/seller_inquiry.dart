enum InquiryCategory {
  diamond('Diamond', 'Diamond inquiries'),
  gemstone('Gemstone', 'Gemstone inquiries'),
  bullion('Bullion', 'Bullion inquiries'),
  watch('Watch', 'Watch inquiries'),
  jewelry('Jewelry', 'Jewelry inquiries');

  const InquiryCategory(this.label, this.listTitle);
  final String label;
  final String listTitle;
}

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
    this.sellerReply,
    this.sellerReplyAt,
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

  /// Seller response visible to the buyer (markdown-lite plain text).
  String? sellerReply;
  String? sellerReplyAt;
}
