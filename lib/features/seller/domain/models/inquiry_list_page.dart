import 'seller_inquiry.dart';

/// Paginated inquiry list from `GET /{category}-inquiry/all`.
class InquiryListPage {
  const InquiryListPage({
    required this.items,
    required this.total,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.hasMore,
  });

  final List<SellerInquiry> items;
  final int total;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final bool hasMore;

  static const empty = InquiryListPage(
    items: [],
    total: 0,
    currentPage: 1,
    lastPage: 0,
    perPage: 10,
    hasMore: false,
  );
}
