import '../../../diamonds/domain/models/diamond.dart';
import '../../domain/models/diamond_project.dart';
import '../../domain/models/diamond_project_item.dart';
import '../models/diamond_project_dto.dart';

/// Maps diamond-project API DTOs and listing diamonds into domain models.
abstract final class DiamondProjectMapper {
  static DiamondProject toDomain(DiamondProjectDto dto) {
    return DiamondProject(
      id: dto.id ?? '',
      name: dto.name ?? 'Untitled project',
      userId: dto.userId,
      sellerId: dto.sellerId,
      diamondType: dto.diamondType,
      filters: dto.filters,
      analytics: dto.analytics,
      itemCount: dto.itemCount,
      totalCarat: dto.totalCarat?.toDouble() ?? 0,
      totalPrice: dto.totalPrice?.toDouble() ?? 0,
      avgPrice: dto.avgPrice?.toDouble() ?? 0,
      avgPpc: dto.avgPpc?.toDouble() ?? 0,
      items: [for (final item in dto.items) itemFromJson(item)],
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      ownerName: dto.ownerName,
      companyName: dto.companyName,
    );
  }

  static DiamondProjectItem itemFromJson(Map<String, dynamic> json) {
    return DiamondProjectItem(
      diamondId: _str(json['diamondId']) ?? '',
      rowId: _str(json['id']),
      productKind: _str(json['productKind']) ?? 'SINGLE',
      stockNumber: _str(json['stockNumber']),
      shape: _str(json['shape']),
      color: _str(json['color']),
      clarity: _str(json['clarity']),
      cut: _str(json['cut']),
      carat: _num(json['carat']),
      price: _num(json['price']),
      pricePerCarat: _numOrNull(json['pricePerCarat']),
    );
  }

  static DiamondProjectItem fromDiamond(
    Diamond diamond, {
    required String productKind,
  }) {
    final carat = diamond.carat;
    final price = diamond.price;
    final storedPpc = diamond.pricePerCarat;
    final ppc = (storedPpc != null && storedPpc > 0)
        ? storedPpc
        : (carat > 0 ? price / carat : null);
    return DiamondProjectItem(
      diamondId: diamond.id,
      productKind: productKind,
      stockNumber: diamond.stockNumber,
      shape: diamond.shape,
      color: diamond.color,
      clarity: diamond.clarity,
      cut: diamond.cut,
      carat: carat,
      price: price,
      pricePerCarat: ppc,
    );
  }

  static Map<String, dynamic> itemToJson(DiamondProjectItem item) {
    return {
      'diamondId': item.diamondId,
      'productKind': item.productKind,
      if (item.stockNumber != null && item.stockNumber!.isNotEmpty)
        'stockNumber': item.stockNumber,
      if (item.shape != null && item.shape!.isNotEmpty) 'shape': item.shape,
      if (item.color != null && item.color!.isNotEmpty) 'color': item.color,
      if (item.clarity != null && item.clarity!.isNotEmpty)
        'clarity': item.clarity,
      if (item.cut != null && item.cut!.isNotEmpty) 'cut': item.cut,
      'carat': item.carat,
      'price': item.price,
      'pricePerCarat': item.ppc,
    };
  }

  static String? _str(Object? value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static double _num(Object? value) => _numOrNull(value) ?? 0;

  static double? _numOrNull(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
