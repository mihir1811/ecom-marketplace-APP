import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/jewelry.dart';
import '../models/jewelry_filter_state.dart';

abstract class JewelryRepository {
  Future<Result<JewelryListResponse, Failure>> getJewelry({
    required JewelryFilterState filters,
    required int page,
    int pageSize = 20,
    JewelrySortOption sort = JewelrySortOption.featured,
  });
}
