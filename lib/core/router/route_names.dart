/// Centralized route name constants for type-safe navigation.
class AppRouteNames {
  const AppRouteNames._();

  static const String home = '/';
  static const String diamonds = '/diamonds';
  static const String diamondResults = '/diamonds/results';
  static const String labGrownDiamonds = '/diamonds/lab-grown';
  static const String labGrownDiamondResults = '/diamonds/lab-grown/results';
  static const String gemstones = '/gemstones';
  static const String gemstoneResults = '/gemstones/results';
  static const String watches = '/watches';
  static const String comparison = '/comparison';
  static const String cart = '/cart';
  static const String brandWatch = '/watches/brand/:brandName';
  static const String bullions = '/bullions';
  static const String jewelry = '/jewelry';
  static const String jewelryListing = '/jewelry/listing';
  static const String jewelryFilters = '/jewelry/filters';

  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Seller/User (authenticated) side
  static const String sellerDashboard = '/seller/dashboard';
  static const String sellerProducts = '/seller/products';
  static const String sellerProductEdit = '/seller/products/:productId/edit';
  static String sellerProductEditPath(String productId) =>
      '/seller/products/$productId/edit';
  static const String sellerOrders = '/seller/orders';
  static const String sellerOrderDetail = '/seller/orders/:orderId';
  static String sellerOrderDetailPath(String orderId) =>
      '/seller/orders/$orderId';
  static const String sellerRefunds = '/seller/refunds';
  static const String sellerInquiries = '/seller/inquiries';
  static const String sellerInquiryNew = '/seller/inquiries/new';
  static const String sellerInquiryDetail =
      '/seller/inquiries/:category/:inquiryId';
  static String sellerInquiryDetailPath(String category, String inquiryId) =>
      '/seller/inquiries/$category/$inquiryId';
  static const String sellerOffers = '/seller/offers';
  static const String sellerAuctions = '/seller/auctions';
  static const String sellerAnalytics = '/seller/analytics';
  static const String sellerInventory = '/seller/inventory';
  static const String sellerChat = '/seller/chat';
  static const String sellerChatDetail = '/seller/chat/:chatId';
  static String sellerChatDetailPath(String chatId) => '/seller/chat/$chatId';
  static const String sellerHelpCenter = '/seller/help-center';
  static const String sellerPromotions = '/seller/promotions';
  static const String sellerProfile = '/seller/profile';
}
