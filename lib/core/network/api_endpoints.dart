/// Path constants relative to [ApiConfig.baseUrl].
abstract final class ApiEndpoints {
  static const String diamondSearch = '/diamond/search';
  static const String diamondFilters = '/diamond/filters';
  static String diamondById(String id) => '/diamond/$id';
  static String meleeDiamondById(String id) => '/melee-diamond/$id';

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
}
