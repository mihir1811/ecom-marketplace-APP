import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/metal_spot_price.dart';

/// Fetches live precious-metal spot prices for the bullions ticker.
abstract class MetalPricesRepository {
  Future<Result<List<MetalSpotPrice>, Failure>> fetchSpotPrices();
}
