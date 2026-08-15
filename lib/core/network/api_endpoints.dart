/// Path constants relative to [ApiConfig.baseUrl].
abstract final class ApiEndpoints {
  // Auth
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authVerifyOtp = '/auth/verify-otp';
  static const String authResendOtp = '/auth/resend-otp';
  static const String authLogout = '/auth/logout';
  static const String authForgetPassword = '/auth/forget-password';
  static const String authResetPassword = '/auth/reset-password';

  /// List + autocomplete (`search` / `searchBy` query params).
  static const String diamondProjects = '/diamond-projects';
  static String diamondProjectById(String id) => '/diamond-projects/$id';
  static const String diamondProjectsAdmin = '/diamond-projects/admin/all';

  static const String diamond = '/diamond';
  static const String diamondSearch = '/diamond/search';
  static const String diamondFilters = '/diamond/filters';
  static String diamondById(String id) => '/diamond/$id';

  static const String meleeDiamond = '/melee-diamond';
  static String meleeDiamondById(String id) => '/melee-diamond/$id';

  /// List + autocomplete (`search` / `searchBy` query params).
  static const String gemStone = '/gem-stone';
  static const String gemStoneSearch = '/gem-stone/search';
  static const String gemStoneFilters = '/gem-stone/filters';
  static String gemStoneById(String id) => '/gem-stone/$id';

  static const String jewellery = '/jewellery';
  static String jewelleryById(String id) => '/jewellery/$id';
  static const String jewelleryCategories = '/jewellery-categories';

  static const String watchAll = '/watch/all';
  static String watchById(String id) => '/watch/$id';

  static const String bullionAll = '/bullion/all';
  static String bullionById(String id) => '/bullion/$id';
  static const String bullionMetalTypes = '/bullion/metal-types';
  static const String bullionMetalShapes = '/bullion/metal-shapes';
  static const String bullionMetalFineness = '/bullion/metal-fineness';

  // Cart
  static const String cart = '/cart';
  static const String cartAdd = '/cart/add';
  static const String cartSummary = '/cart/summary';
  static const String cartEvents = '/cart/events';
  static const String cartUpdate = '/cart/update';
  static const String cartRemove = '/cart/remove';
  static const String cartApplyPromo = '/cart/apply-promo';
  static const String cartPromoCode = '/cart/promo-code';

  // Delivery options (checkout prerequisite)
  static const String deliveryAddresses = '/delivery-options/addresses';
  static String deliveryAddressById(String id) =>
      '/delivery-options/addresses/$id';
  static const String deliveryCart = '/delivery-options/cart';
  static const String deliveryCartSelect = '/delivery-options/cart/select';

  // Payment
  static const String paymentExchangeRate = '/payment/exchange-rate';
  static const String paymentCreateOrder = '/payment/create-order';
  static const String paymentVerify = '/payment/verify';
  static const String paymentOrders = '/payment/orders';
  static String paymentOrderById(String orderId) => '/payment/orders/$orderId';

  // Wallet
  static const String wallet = '/wallet';
  static const String walletTransactions = '/wallet/transactions';
  static const String walletTopUp = '/wallet/top-up';
  static const String walletTopUpVerify = '/wallet/top-up/verify';

  // Tracking (buyer shipments for a paid order)
  static String trackingOrders(String orderId) => '/tracking/orders/$orderId';
  static String trackingShipment(String id) => '/tracking/shipments/$id';
  static String trackingShipmentComments(String id) =>
      '/tracking/shipments/$id/comments';

  // Seller reviews (buyer rates a seller after a paid order)
  static const String sellerReviews = '/seller-reviews';

  // Product inquiries (buyer + seller submit to admin)
  static const String diamondInquiry = '/diamond-inquiry';
  static const String diamondInquiryAll = '/diamond-inquiry/all';
  static String diamondInquiryById(String id) => '/diamond-inquiry/$id';

  static const String gemstoneInquiry = '/gemstone-inquiry';
  static const String gemstoneInquiryAll = '/gemstone-inquiry/all';
  static String gemstoneInquiryById(String id) => '/gemstone-inquiry/$id';

  static const String bullionInquiry = '/bullion-inquiry';
  static const String bullionInquiryAll = '/bullion-inquiry/all';
  static String bullionInquiryById(String id) => '/bullion-inquiry/$id';

  static const String watchInquiry = '/watch-inquiry';
  static const String watchInquiryAll = '/watch-inquiry/all';
  static String watchInquiryById(String id) => '/watch-inquiry/$id';

  static const String jewelleryInquiry = '/jewellery-inquiry';
  static const String jewelleryInquiryAll = '/jewellery-inquiry/all';
  static String jewelleryInquiryById(String id) => '/jewellery-inquiry/$id';

  // Help center (buyer + seller)
  static const String helpCenterQuestions = '/help-center/questions';
  static const String helpCenterQuestionsMine = '/help-center/questions/mine';
  static String helpCenterQuestionById(String id) =>
      '/help-center/questions/$id';
  static String helpCenterQuestionClose(String id) =>
      '/help-center/questions/$id/close';

  // Chat (buyer + seller) — send is Socket.IO, not REST POST
  static const String chat = '/chat';
  static const String chatProductContext = '/chat/product-context';
  static const String chatRead = '/chat/read';
  static const String chatUploadImage = '/chat/upload-image';
  static String chatMessageById(String messageId) => '/chat/$messageId';

  // Gem AI chat (inventory search + persisted turns)
  static const String aiChat = '/ai-chat';
  static const String aiChatUploadImage = '/ai-chat/upload-image';
  static const String aiChatSessions = '/ai-chat/sessions';
  static String aiChatSessionById(String sessionId) =>
      '/ai-chat/sessions/$sessionId';

  // Refunds (buyer + seller)
  static const String refunds = '/refunds';
  static const String refundsMine = '/refunds/mine';
  static const String refundsSeller = '/refunds/seller';
  static String refundById(String id) => '/refunds/$id';
  static String refundAccept(String id) => '/refunds/$id/accept';
  static String refundReject(String id) => '/refunds/$id/reject';
  static String refundCancel(String id) => '/refunds/$id/cancel';

  // Reference / referrals
  static const String referenceMe = '/reference/me';
  static const String referenceInbound = '/reference/inbound';
  static const String referenceOutbound = '/reference/outbound';
  static const String referencePurchases = '/reference/purchases';
  static const String referenceRequest = '/reference/request';
  static String referenceAccept(String id) => '/reference/$id/accept';
  static String referenceReject(String id) => '/reference/$id/reject';

  // Checkout fee rules
  static const String fees = '/fees';

  // Product share
  static const String productShare = '/product-share';
  static String productShareEmail(String id) => '/product-share/$id/email';
  static String productShareByToken(String token) => '/product-share/$token';

  // Product offer
  static const String productOffer = '/product-offer';
  static String productOfferMine(String productType, String productId) =>
      '/product-offer/mine/$productType/$productId';
  static const String productOfferSeller = '/product-offer/seller';
  static String productOfferRespond(String id) => '/product-offer/$id/respond';

  // Favorites (wishlist)
  static const String favorites = '/favorites';
  static const String favoritesAll = '/favorites/all';
  static const String favoritesRemove = '/favorites/remove';
  static String favoriteByProductId(String productId) =>
      '/favorites/$productId';

  // Recently viewed
  static const String recentlyViewed = '/recently-viewed';
  static const String recentlyViewedIds = '/recently-viewed/ids';
  static const String recentlyViewedClear = '/recently-viewed/clear';

  // User bank account
  static const String userBankAccount = '/user-bank-account';
  static const String userBankAccountStatus = '/user-bank-account/status';

  // Promotions
  static const String promotionsDiscounts = '/promotions/discounts';
  static String promotionsDiscountById(String id) =>
      '/promotions/discounts/$id';
  static const String promotionsPromoCodes = '/promotions/promo-codes';
  static String promotionsPromoCodeById(String id) =>
      '/promotions/promo-codes/$id';
  static String promotionsPublic(String sellerId) =>
      '/promotions/public/$sellerId';

  // Login history
  static const String loginHistory = '/login-history';
  static const String loginHistoryActiveSeller =
      '/login-history/active-seller';
  static String loginHistoryBySession(String sessionId) =>
      '/login-history/$sessionId';

  // User profile (read-only)
  static const String userProfile = '/user/profile';

  // Jewellery category admin
  static String jewelleryCategoryById(String id) =>
      '/jewellery-categories/$id';
  static String jewelleryCategorySubcategories(String categoryId) =>
      '/jewellery-categories/$categoryId/subcategories';
  static String jewellerySubcategoryById(String id) =>
      '/jewellery-categories/subcategories/$id';
}
