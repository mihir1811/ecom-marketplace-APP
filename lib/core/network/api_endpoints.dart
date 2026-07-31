/// Path constants relative to [ApiConfig.baseUrl].
abstract final class ApiEndpoints {
  static const String diamondSearch = '/diamond/search';
  static const String diamondFilters = '/diamond/filters';
  static String diamondById(String id) => '/diamond/$id';
  static String meleeDiamondById(String id) => '/melee-diamond/$id';

  static const String gemStoneSearch = '/gem-stone/search';
  static const String gemStoneFilters = '/gem-stone/filters';
  static String gemStoneById(String id) => '/gem-stone/$id';
}
