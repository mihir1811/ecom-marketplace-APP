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
}
