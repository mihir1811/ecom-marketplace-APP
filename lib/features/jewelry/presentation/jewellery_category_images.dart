/// Bundled art for jewellery category tiles when API `imageUrl` is relative or 404.
///
/// Live relative paths like `/images/jewelryCategoryImages/ring.png` currently
/// 404 on the API host; shopper tiles use these assets instead.
abstract final class JewelleryCategoryImages {
  static const _dir = 'public/images/jewelryCategoryImages';

  static String assetFor(String name) {
    return switch (name.trim().toLowerCase()) {
      'ring' || 'rings' => '$_dir/ring.webp',
      'bracelet' || 'bracelets' => '$_dir/bracelet.webp',
      'earring' || 'earrings' => '$_dir/earrings.webp',
      'necklace' || 'necklaces' || 'chain' || 'chains' => '$_dir/necklace.webp',
      _ => '$_dir/set.webp',
    };
  }

  static String? absoluteUrl(String? imageUrl) {
    final raw = imageUrl?.trim() ?? '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return null;
  }
}
