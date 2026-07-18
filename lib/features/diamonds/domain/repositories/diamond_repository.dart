import '../../../../core/error/result.dart';
import '../../../../core/error/failure.dart';
import '../models/diamond.dart';
import '../models/diamond_filter_state.dart';
import '../models/sorting_criteria.dart';

abstract class DiamondRepository {
  Future<Result<DiamondListResponse, Failure>> getDiamonds({
    required DiamondFilterState filters,
    required int page,
    int pageSize = 20,
    List<SortingCriteria> sorting = const [],
    bool isLabGrown = false,
  });
}
