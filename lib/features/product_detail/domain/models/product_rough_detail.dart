import '../../../rough_diamonds/domain/models/rough_parcel.dart';

/// Rough parcel extras on the shared product page: its lots, the server's
/// `buy` verdict and its documents.
class ProductRoughDetail {
  const ProductRoughDetail({required this.parcel, this.isGone = false});

  final RoughParcel parcel;

  /// The parcel was deleted after the list was loaded (detail 404).
  final bool isGone;

  RoughBuy get buy => parcel.buy;

  /// Nothing can be bought: gone, sold, expired, held or not `yes`.
  bool get onSale => !isGone && buy.onSale;
}
