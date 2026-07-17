import '../../../../core/error/result.dart';
import '../../../../core/error/failure.dart';
import '../../application/diamond_list_provider.dart';
import '../models/diamond.dart';
import '../models/diamond_filter_state.dart';

abstract class DiamondRepository {
  Future<Result<DiamondListResponse, Failure>> getDiamonds({
    required DiamondFilterState filters,
    required int page,
    int pageSize = 20,
    required DiamondSortField primarySort,
    DiamondSortField? secondarySort,
  });
}
