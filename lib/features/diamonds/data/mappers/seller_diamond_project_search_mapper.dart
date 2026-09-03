import 'diamond_search_request_mapper.dart';
import '../../domain/models/diamond_catalog_type.dart';
import '../../domain/models/diamond_filter_state.dart';

/// Builds seller-scoped `POST /diamond/search` bodies for dashboard projects.
abstract final class SellerDiamondProjectSearchMapper {
  static Map<String, dynamic> toBody({
    required String sellerId,
    required DiamondFilterState filters,
    required int page,
    int pageSize = 100,
  }) {
    final body = DiamondSearchRequestMapper.toBody(
      filters: filters,
      catalog: DiamondCatalogType.natural,
      page: page,
      pageSize: pageSize,
    );
    body['seller_id'] = sellerId;
    body['is_sold'] = false;
    body['is_expired'] = false;
    body['is_deleted'] = false;
    return body;
  }
}
