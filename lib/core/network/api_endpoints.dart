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
}
