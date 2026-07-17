import '../../domain/models/diamond.dart';
import '../models/diamond_dto.dart';

extension DiamondDtoMapper on DiamondDto {
  Diamond toDomain() {
    return Diamond(
      id: id,
      shape: shape,
      carat: carat,
      price: price,
      cut: cut,
      color: color,
      clarity: clarity,
      certificate: certificate,
      imageUrl: imageUrl,
      pricePerCarat: pricePerCarat,
      polish: polish,
      symmetry: symmetry,
      fluorescence: fluorescence,
      lab: lab,
      hasVideo: hasVideo,
      hasImage: hasImage,
      discount: discount,
    );
  }
}
