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
  const SellerInquiry({
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
  });

  final String id;
  final InquiryCategory category;
  final String buyerName;
  final String buyerEmail;
  final String userId;
  final String summary;
  final String createdAtLabel;
  final String updatedAtLabel;
  final String createdAtLong;
  final Map<String, String> fields;
}
