import 'models/home_search_result.dart';

/// Query mode for header-style autocomplete fan-out.
enum HomeSearchMode { freeText, stockNumber, certificateNumber }

/// Classifies stock / cert / free-text the way the web header does.
abstract final class HomeSearchQueryClassifier {
  /// Alphanumeric stock/SKU tokens (e.g. `GY93727`).
  static final _stockLike = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z0-9\-_./]{4,}$',
  );

  /// Long mostly-numeric certificate ids (e.g. `2141439997`).
  static final _certLike = RegExp(r'^\d{8,}$');

  static HomeSearchMode classify(String raw) {
    final q = raw.trim();
    if (q.isEmpty) return HomeSearchMode.freeText;
    if (_certLike.hasMatch(q)) return HomeSearchMode.certificateNumber;
    if (_stockLike.hasMatch(q)) return HomeSearchMode.stockNumber;
    return HomeSearchMode.freeText;
  }

  /// Category `searchBy` values from the web autocomplete curls.
  static String searchBy({
    required HomeSearchMode mode,
    required HomeSearchKind kind,
  }) {
    if (mode == HomeSearchMode.certificateNumber) {
      return 'certificateNumber';
    }
    if (mode == HomeSearchMode.stockNumber) {
      return switch (kind) {
        HomeSearchKind.gemstone => 'stockNumber,certificateNumber,tags',
        HomeSearchKind.jewelry =>
          'productTitle,stockNumber,variants.stockNumber',
        HomeSearchKind.watch => 'stockNumber',
        HomeSearchKind.bullion => 'stockNumber',
        // Rough search matches its own fields; `searchBy` is not sent.
        HomeSearchKind.rough => 'stockNumber',
        HomeSearchKind.diamond ||
        HomeSearchKind.lab ||
        HomeSearchKind.melee => 'stockNumber',
      };
    }

    // Free-text — match useLiveSearchResults / gemstoneService.searchGemstones.
    return switch (kind) {
      HomeSearchKind.diamond || HomeSearchKind.lab =>
        'stockNumber,certificateNumber,shape,color,clarity,cut,origin',
      HomeSearchKind.melee =>
        'stockNumber,certificateNumber,shape,colorFrom,clarityMin,origin',
      HomeSearchKind.gemstone =>
        'stockNumber,gemsType,subType,origin,shape,primaryColor,description,tags',
      HomeSearchKind.watch =>
        'brand,model,referenceNumber,stockNumber,collection,description',
      HomeSearchKind.jewelry => 'productTitle,stockNumber,variants.stockNumber',
      HomeSearchKind.bullion => 'mintMark,stockNumber,design,certification',
      HomeSearchKind.rough =>
        'stockNumber,title,mineSource,countryOfOrigin,crystalShape,description',
    };
  }
}
