/// Centralized route name constants for type-safe navigation.
class AppRouteNames {
  const AppRouteNames._();

  static const String home = '/';
  static const String aboutUs = '/about';
  static const String privacyPolicy = '/privacy';
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
  static const String watchesFilters = '/watches/filters';
  static const String comparison = '/comparison';
  static const String cart = '/cart';
  static const String paymentConfirmation = '/payment/confirmation/:orderId';
  static String paymentConfirmationPath(String orderId) =>
      '/payment/confirmation/$orderId';
  static const String brandWatch = '/watches/brand/:brandName';
  static const String brandWatchFilters = '/watches/brand/:brandName/filters';
  static String brandWatchFiltersPath(String brandName) =>
      '/watches/brand/${Uri.encodeComponent(brandName)}/filters';
  static const String bullions = '/bullions';
  static const String bullionsFilters = '/bullions/filters';
  static const String jewelry = '/jewelry';
  static const String jewelryListing = '/jewelry/listing';
  static const String jewelryFilters = '/jewelry/filters';
  static const String jewelryHouses = '/jewelry/houses';
  static const String jewelryPremium = '/jewelry/premium';
  static const String jewelryHouse = '/jewelry/house/:slug';
  static String jewelryHousePath(String slug) =>
      '/jewelry/house/${Uri.encodeComponent(slug)}';

  /// One collection (category) of one house.
  static const String jewelryHouseCollection =
      '/jewelry/house/:slug/collection/:category';
  static String jewelryHouseCollectionPath(String slug, String category) =>
      '/jewelry/house/${Uri.encodeComponent(slug)}'
      '/collection/${Uri.encodeComponent(category)}';

  /// Jewellery marketplace bag (on-device), checkout and orders.
  static const String jewelryBag = '/jewelry/bag';
  static const String jewelryCheckout = '/jewelry/checkout';
  static const String jewelryOrders = '/jewelry/orders';
  static const String jewelryOrderDetail = '/jewelry/orders/:orderId';
  static String jewelryOrderDetailPath(String orderId) =>
      '/jewelry/orders/${Uri.encodeComponent(orderId)}';
  static const String jewelryOrderInvoice = '/jewelry/orders/:orderId/invoice';
  static String jewelryOrderInvoicePath(String orderId) =>
      '/jewelry/orders/${Uri.encodeComponent(orderId)}/invoice';

  /// A jewellery shop's paid orders (seller studio); [openOrderId] opens
  /// one of them (WhatsApp "Open order" button).
  static const String jewelryShopOrders = '/jewelry/shop/orders';
  static String jewelryShopOrdersPath({String? openOrderId}) =>
      openOrderId == null || openOrderId.isEmpty
      ? jewelryShopOrders
      : '$jewelryShopOrders?o=${Uri.encodeQueryComponent(openOrderId)}';

  /// Shared product detail page used by every catalog segment.
  static const String productDetail = '/product/:segment/:productId';
  static String productDetailPath(String segment, String productId) =>
      '/product/$segment/${Uri.encodeComponent(productId)}';

  /// A seller's public shop, opened from featured sellers and banners.
  static const String sellerShop = '/shop/:sellerId';
  static String sellerShopPath(String sellerId) =>
      '/shop/${Uri.encodeComponent(sellerId)}';

  /// Everything one seller has for sale in one section (shop "View all").
  static const String sellerShopSection = '/shop/:sellerId/:segment';
  static String sellerShopSectionPath(String sellerId, String segment) =>
      '/shop/${Uri.encodeComponent(sellerId)}/${Uri.encodeComponent(segment)}';

  /// Public product share deep link (`GET /product-share/{token}`).
  static const String productShare = '/share/:token';
  static String productSharePath(String token) =>
      '/share/${Uri.encodeComponent(token)}';

  /// Fullscreen interactive Vision360 / WebGL product viewer.
  static const String diamondViewer = '/viewer/360';

  /// Diamond and jewelry education pages.
  static const String diamondEducation = '/learn/diamonds';
  static const String jewelryEducation = '/learn/jewelry';

  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyOtp = '/verify-otp';
  static const String resetPassword = '/reset-password';
  static const String recoverAccount = '/recover-account';

  // Buyer (home drawer) — buyer paths; shared UI widgets may be reused
  static const String buyerProfile = '/buyer/profile';
  static const String buyerOrders = '/buyer/orders';
  static const String buyerWallet = '/buyer/wallet';
  static const String buyerRewards = '/buyer/rewards';
  static const String buyerOrderDetail = '/buyer/orders/:orderId';
  static String buyerOrderDetailPath(String orderId) =>
      '/buyer/orders/$orderId';
  static const String buyerRefunds = '/buyer/refunds';
  static const String buyerOffers = '/buyer/offers';

  /// My offers, then straight to paying this accepted offer (the
  /// `OFFER_ACCEPTED` push link `/user/offers?pay=<offerId>`).
  static String buyerOfferPayPath(String offerId) =>
      '/buyer/offers?pay=${Uri.encodeQueryComponent(offerId)}';

  /// My offers, then straight to answering this counter-offer (the
  /// `OFFER_COUNTERED` push link `/user/offers?counter=<offerId>`).
  static String buyerOfferCounterPath(String offerId) =>
      '/buyer/offers?counter=${Uri.encodeQueryComponent(offerId)}';
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
  static const String buyerNotifications = '/buyer/notifications';
  static const String buyerAbout = '/buyer/about';
  static const String buyerPrivacy = '/buyer/privacy';
  static const String buyerTerms = '/buyer/terms';
  static const String buyerPolicies = '/buyer/policies';
  static const String buyerPolicyDetail = '/buyer/policies/:policyId';
  static String buyerPolicyPath(String policyId) =>
      '/buyer/policies/${Uri.encodeComponent(policyId)}';
  static const String auctions = '/auctions';
  static const String auctionActivity = '/auctions/activity';
  static const String auctionWins = '/auctions/wins';
  static const String auctionDetail = '/auctions/:auctionId';
  static String auctionDetailPath(String auctionId) =>
      '/auctions/${Uri.encodeComponent(auctionId)}';
  static const String liveShows = '/live';
  static const String liveShow = '/live/:showId';
  static String liveShowPath(String showId) =>
      '/live/${Uri.encodeComponent(showId)}';

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
  static const String sellerNotifications = '/seller/notifications';
  static const String sellerReferences = '/seller/references';
  static const String sellerPromotions = '/seller/promotions';

  /// Seller Advertising studio (paid spotlight placements). Same path as the
  /// website, which push links (`/seller/spotlight/<adId>`) point at.
  static const String sellerSpotlight = '/seller/spotlight';
  static const String sellerSpotlightNew = '/seller/spotlight/new';
  static const String sellerSpotlightDetail = '/seller/spotlight/:adId';
  static String sellerSpotlightDetailPath(String adId) =>
      '/seller/spotlight/${Uri.encodeComponent(adId)}';
  static const String sellerProfile = '/seller/profile';
  static const String sellerApiKeys = '/seller/api-keys';
  static const String sellerSettings = '/seller/settings';
  static const String sellerAbout = '/seller/about';
  static const String sellerPrivacy = '/seller/privacy';
  static const String sellerTerms = '/seller/terms';
  static const String sellerPolicies = '/seller/policies';
  static const String sellerPolicyDetail = '/seller/policies/:policyId';
  static String sellerPolicyPath(String policyId) =>
      '/seller/policies/${Uri.encodeComponent(policyId)}';
}
