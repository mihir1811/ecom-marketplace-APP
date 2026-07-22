import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/gemstone.dart';
import '../models/gemstone_filter_state.dart';

abstract class GemstoneRepository {
  Future<Result<GemstoneListResponse, Failure>> getGemstones({
    required GemstoneFilterState filters,
    required int page,
    int pageSize = 20,
  });
}
