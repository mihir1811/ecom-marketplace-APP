/// Column definitions for the seller products table and column picker.
class SellerProductColumnDef {
  const SellerProductColumnDef({
    required this.id,
    required this.label,
    this.defaultVisible = false,
  });

  final String id;
  final String label;
  final bool defaultVisible;
}

/// All product table columns (picker + dynamic table).
const kSellerProductColumns = <SellerProductColumnDef>[
  SellerProductColumnDef(
    id: 'selection',
    label: 'Checkbox selection',
    defaultVisible: true,
  ),
  SellerProductColumnDef(id: 'id', label: 'Id'),
  SellerProductColumnDef(id: 'seller_id', label: 'Seller Id'),
  SellerProductColumnDef(
    id: 'stock_number',
    label: 'Stock Number',
    defaultVisible: true,
  ),
  SellerProductColumnDef(
    id: 'available',
    label: 'Available',
    defaultVisible: true,
  ),
  SellerProductColumnDef(id: 'shape', label: 'Shape', defaultVisible: true),
  SellerProductColumnDef(id: 'color', label: 'Color', defaultVisible: true),
  SellerProductColumnDef(id: 'clarity', label: 'Clarity', defaultVisible: true),
  SellerProductColumnDef(
    id: 'carat_weight',
    label: 'Carat Weight',
    defaultVisible: true,
  ),
  SellerProductColumnDef(id: 'measurement', label: 'Measurement'),
  SellerProductColumnDef(id: 'ratio', label: 'Ratio'),
  SellerProductColumnDef(id: 'rap', label: 'Rap'),
  SellerProductColumnDef(id: 'discount', label: 'Discount'),
  SellerProductColumnDef(id: 'price_per_carat', label: 'Price Per Carat'),
  SellerProductColumnDef(id: 'total_price', label: 'Total Price'),
  SellerProductColumnDef(id: 'cut', label: 'Cut'),
  SellerProductColumnDef(id: 'symmetry', label: 'Symmetry'),
  SellerProductColumnDef(id: 'polish', label: 'Polish'),
  SellerProductColumnDef(
    id: 'fluorescence_intensity',
    label: 'Fluorescence Intensity',
  ),
  SellerProductColumnDef(id: 'fluorescence_color', label: 'Fluorescence Color'),
  SellerProductColumnDef(
    id: 'certificate_company_name',
    label: 'Certificate Company Name',
  ),
  SellerProductColumnDef(id: 'certificate_number', label: 'Certificate Number'),
  SellerProductColumnDef(id: 'certification', label: 'Certification'),
  SellerProductColumnDef(id: 'video_url', label: 'Video U R L'),
  SellerProductColumnDef(id: 'shade', label: 'Shade'),
  SellerProductColumnDef(id: 'fancy_color', label: 'Fancy Color'),
  SellerProductColumnDef(id: 'fancy_intensity', label: 'Fancy Intencity'),
  SellerProductColumnDef(id: 'fancy_overtone', label: 'Fancy Overtone'),
  SellerProductColumnDef(id: 'origin', label: 'Origin'),
  SellerProductColumnDef(id: 'comment', label: 'Comment'),
  SellerProductColumnDef(id: 'table', label: 'Table'),
  SellerProductColumnDef(id: 'depth', label: 'Depth'),
  SellerProductColumnDef(id: 'gridle_min', label: 'Gridle Min'),
  SellerProductColumnDef(id: 'gridle_max', label: 'Gridle Max'),
  SellerProductColumnDef(id: 'gridle_percentage', label: 'Gridle Percentage'),
  SellerProductColumnDef(id: 'crown_height', label: 'Crown Height'),
  SellerProductColumnDef(id: 'crown_angle', label: 'Crown Angle'),
  SellerProductColumnDef(id: 'pavilion_angle', label: 'Pavilion Angle'),
  SellerProductColumnDef(id: 'pavilion_depth', label: 'Pavilion Depth'),
  SellerProductColumnDef(id: 'culet_size', label: 'Culet Size'),
  SellerProductColumnDef(id: 'enhancement', label: 'Enhancement'),
  SellerProductColumnDef(id: 'growth_type', label: 'Growth Type'),
  SellerProductColumnDef(id: 'laser_inscription', label: 'Laser Inscription'),
  SellerProductColumnDef(id: 'gridle_condition', label: 'Gridle Condition'),
  SellerProductColumnDef(id: 'star_length', label: 'Star Length'),
  SellerProductColumnDef(id: 'culet_condition', label: 'Culet Condition'),
  SellerProductColumnDef(id: 'inclusions_type', label: 'Inclusions Type'),
  SellerProductColumnDef(id: 'eye_clean', label: 'Eye Clean'),
  SellerProductColumnDef(id: 'bgm', label: 'B G M'),
  SellerProductColumnDef(id: 'milky', label: 'Milky'),
  SellerProductColumnDef(id: 'ha', label: 'H A'),
  SellerProductColumnDef(
    id: 'matching_pair_number',
    label: 'Matching Pair Number',
  ),
  SellerProductColumnDef(id: 'rough_source', label: 'Rough Source'),
  SellerProductColumnDef(id: 'key_to_symbols', label: 'Key To Symbols'),
  SellerProductColumnDef(id: 'cert_comment', label: 'Cert Comment'),
  SellerProductColumnDef(id: 'tinge', label: 'Tinge'),
  SellerProductColumnDef(id: 'luster', label: 'Luster'),
  SellerProductColumnDef(id: 'tags', label: 'Tags'),
  SellerProductColumnDef(id: 'image1', label: 'Image1'),
  SellerProductColumnDef(id: 'image2', label: 'Image2'),
  SellerProductColumnDef(id: 'image3', label: 'Image3'),
  SellerProductColumnDef(id: 'image4', label: 'Image4'),
  SellerProductColumnDef(id: 'image5', label: 'Image5'),
  SellerProductColumnDef(id: 'image6', label: 'Image6'),
  SellerProductColumnDef(id: 'is_on_auction', label: 'Is On Auction'),
  SellerProductColumnDef(id: 'is_sold', label: 'Is Sold'),
  SellerProductColumnDef(id: 'is_expired', label: 'Is Expired'),
  SellerProductColumnDef(id: 'is_deleted', label: 'Is Deleted'),
  SellerProductColumnDef(id: 'created_at', label: 'Created At'),
  SellerProductColumnDef(id: 'updated_at', label: 'Updated At'),
  SellerProductColumnDef(id: 'auction_start_time', label: 'Auction Start Time'),
  SellerProductColumnDef(id: 'auction_end_time', label: 'Auction End Time'),
  SellerProductColumnDef(id: 'actions', label: 'Actions'),
];

Set<String> defaultVisibleSellerProductColumnIds() {
  return kSellerProductColumns
      .where((c) => c.defaultVisible)
      .map((c) => c.id)
      .toSet();
}

SellerProductColumnDef? sellerProductColumnById(String id) {
  for (final col in kSellerProductColumns) {
    if (col.id == id) return col;
  }
  return null;
}
