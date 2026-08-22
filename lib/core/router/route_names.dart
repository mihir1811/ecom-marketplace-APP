/// Centralized route name constants for type-safe navigation.
class AppRouteNames {
  const AppRouteNames._();

  static const String home = '/';
  static const String aboutUs = '/about';
  static const String termsAndConditions = '/terms';
  static const String policies = '/policies';
  static const String policyDetail = '/policies/:policyId';
  static String policyPath(String policyId) => '/policies/$policyId';
  static const String diamonds = '/diamonds';
  static const String diamondResults = '/diamonds/results';
  static const String labGrownDiamonds = '/diamonds/lab-grown';
  static const String labGrownDiamondResults = '/diamonds/lab-grown/results';
  static const String diamondProject = '/diamonds/project';
  static const String savedDiamondProjects = '/diamonds/projects';
  static const String gemstones = '/gemstones';
  static const String gemstoneResults = '/gemstones/results';
  static const String watches = '/watches';
  static const String comparison = '/comparison';
  static const String cart = '/cart';
  static const String paymentConfirmation = '/payment/confirmation/:orderId';
  static String paymentConfirmationPath(String orderId) =>
      '/payment/confirmation/$orderId';
  static const String brandWatch = '/watches/brand/:brandName';
  static const String bullions = '/bullions';
  static const String jewelry = '/jewelry';
  static const String jewelryListing = '/jewelry/listing';
  static const String jewelryFilters = '/jewelry/filters';

  /// Shared product detail page used by every catalog segment.
  static const String productDetail = '/product/:segment/:productId';
  static String productDetailPath(String segment, String productId) =>
      '/product/$segment/${Uri.encodeComponent(productId)}';

  /// Public product share deep link (`GET /product-share/{token}`).
  static const String productShare = '/share/:token';
  static String productSharePath(String token) =>
      '/share/${Uri.encodeComponent(token)}';

  /// Fullscreen interactive Vision360 / WebGL product viewer.
  static const String diamondViewer = '/viewer/360';

  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyOtp = '/verify-otp';
  static const String resetPassword = '/reset-password';

  // Buyer (home drawer) — buyer paths; shared UI widgets may be reused
  static const String buyerProfile = '/buyer/profile';
  static const String buyerOrders = '/buyer/orders';
  static const String buyerWallet = '/buyer/wallet';
  static const String buyerOrderDetail = '/buyer/orders/:orderId';
  static String buyerOrderDetailPath(String orderId) =>
      '/buyer/orders/$orderId';
  static const String buyerRefunds = '/buyer/refunds';
  static const String buyerReferences = '/buyer/references';
  static const String buyerInquiries = '/buyer/inquiries';
  static const String buyerInquiryNew = '/buyer/inquiries/new';
  static const String buyerInquiryDetail =
      '/buyer/inquiries/:category/:inquiryId';
  static String buyerInquiryDetailPath(String category, String inquiryId) =>
      '/buyer/inquiries/$category/$inquiryId';
  static const String buyerHelpCenter = '/buyer/help-center';
  static const String buyerWishlist = '/buyer/wishlist';
  static const String buyerRecentlyViewed = '/buyer/recently-viewed';
  static const String buyerReviews = '/buyer/reviews';
  static const String buyerMessages = '/buyer/messages';
  static const String buyerChatDetail = '/buyer/messages/:chatId';
  static String buyerChatDetailPath(String chatId) =>
      '/buyer/messages/${Uri.encodeComponent(chatId)}';
  static const String buyerSettings = '/buyer/settings';

  // Seller (dashboard workspace)
  static const String sellerDashboard = '/seller/dashboard';
  static const String sellerProducts = '/seller/products';
  static const String sellerProductEdit = '/seller/products/:productId/edit';
  static String sellerProductEditPath(String productId) =>
      '/seller/products/$productId/edit';
  static const String sellerOrders = '/seller/orders';
  static const String sellerWallet = '/seller/wallet';
  static const String sellerOrderDetail = '/seller/orders/:orderId';
  static String sellerOrderDetailPath(String orderId) =>
      '/seller/orders/$orderId';
  static const String sellerInquiries = '/seller/inquiries';
  static const String sellerInquiryNew = '/seller/inquiries/new';
  static const String sellerInquiryDetail =
      '/seller/inquiries/:category/:inquiryId';
  static String sellerInquiryDetailPath(String category, String inquiryId) =>
      '/seller/inquiries/$category/$inquiryId';
  static const String sellerOffers = '/seller/offers';
  static const String sellerAuctions = '/seller/auctions';
  static const String sellerAnalytics = '/seller/analytics';
  static const String sellerChat = '/seller/chat';
  static const String sellerChatDetail = '/seller/chat/:chatId';
  static String sellerChatDetailPath(String chatId) =>
      '/seller/chat/${Uri.encodeComponent(chatId)}';
  static const String sellerHelpCenter = '/seller/help-center';
  static const String sellerReferences = '/seller/references';
  static const String sellerPromotions = '/seller/promotions';
  static const String sellerProfile = '/seller/profile';
  static const String sellerLoginHistory = '/seller/login-history';
}
