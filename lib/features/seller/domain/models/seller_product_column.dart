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
  const SellerProductColumnDef(
    id: 'selection',
    label: 'Checkbox selection',
    defaultVisible: true,
  ),
  const SellerProductColumnDef(id: 'id', label: 'Id'),
  const SellerProductColumnDef(id: 'seller_id', label: 'Seller Id'),
  const SellerProductColumnDef(
    id: 'stock_number',
    label: 'Stock Number',
    defaultVisible: true,
  ),
  const SellerProductColumnDef(
    id: 'available',
    label: 'Available',
    defaultVisible: true,
  ),
  const SellerProductColumnDef(
    id: 'shape',
    label: 'Shape',
    defaultVisible: true,
  ),
  const SellerProductColumnDef(
    id: 'color',
    label: 'Color',
    defaultVisible: true,
  ),
  const SellerProductColumnDef(
    id: 'clarity',
    label: 'Clarity',
    defaultVisible: true,
  ),
  const SellerProductColumnDef(
    id: 'carat_weight',
    label: 'Carat Weight',
    defaultVisible: true,
  ),
  const SellerProductColumnDef(id: 'measurement', label: 'Measurement'),
  const SellerProductColumnDef(id: 'ratio', label: 'Ratio'),
  const SellerProductColumnDef(id: 'rap', label: 'Rap'),
  const SellerProductColumnDef(id: 'discount', label: 'Discount'),
  const SellerProductColumnDef(id: 'price_per_carat', label: 'Price Per Carat'),
  const SellerProductColumnDef(id: 'total_price', label: 'Total Price'),
  const SellerProductColumnDef(id: 'cut', label: 'Cut'),
  const SellerProductColumnDef(id: 'symmetry', label: 'Symmetry'),
  const SellerProductColumnDef(id: 'polish', label: 'Polish'),
  const SellerProductColumnDef(
    id: 'fluorescence_intensity',
    label: 'Fluorescence Intensity',
  ),
  const SellerProductColumnDef(
    id: 'fluorescence_color',
    label: 'Fluorescence Color',
  ),
  const SellerProductColumnDef(
    id: 'certificate_company_name',
    label: 'Certificate Company Name',
  ),
  const SellerProductColumnDef(
    id: 'certificate_number',
    label: 'Certificate Number',
  ),
  const SellerProductColumnDef(id: 'certification', label: 'Certification'),
  const SellerProductColumnDef(id: 'video_url', label: 'Video U R L'),
  const SellerProductColumnDef(id: 'shade', label: 'Shade'),
  const SellerProductColumnDef(id: 'fancy_color', label: 'Fancy Color'),
  const SellerProductColumnDef(id: 'fancy_intensity', label: 'Fancy Intencity'),
  const SellerProductColumnDef(id: 'fancy_overtone', label: 'Fancy Overtone'),
  const SellerProductColumnDef(id: 'origin', label: 'Origin'),
  const SellerProductColumnDef(id: 'comment', label: 'Comment'),
  const SellerProductColumnDef(id: 'table', label: 'Table'),
  const SellerProductColumnDef(id: 'depth', label: 'Depth'),
  const SellerProductColumnDef(id: 'gridle_min', label: 'Gridle Min'),
  const SellerProductColumnDef(id: 'gridle_max', label: 'Gridle Max'),
  const SellerProductColumnDef(
    id: 'gridle_percentage',
    label: 'Gridle Percentage',
  ),
  const SellerProductColumnDef(id: 'crown_height', label: 'Crown Height'),
  const SellerProductColumnDef(id: 'crown_angle', label: 'Crown Angle'),
  const SellerProductColumnDef(id: 'pavilion_angle', label: 'Pavilion Angle'),
  const SellerProductColumnDef(id: 'pavilion_depth', label: 'Pavilion Depth'),
  const SellerProductColumnDef(id: 'culet_size', label: 'Culet Size'),
  const SellerProductColumnDef(id: 'enhancement', label: 'Enhancement'),
  const SellerProductColumnDef(id: 'growth_type', label: 'Growth Type'),
  const SellerProductColumnDef(
    id: 'laser_inscription',
    label: 'Laser Inscription',
  ),
  const SellerProductColumnDef(
    id: 'gridle_condition',
    label: 'Gridle Condition',
  ),
  const SellerProductColumnDef(id: 'star_length', label: 'Star Length'),
  const SellerProductColumnDef(id: 'culet_condition', label: 'Culet Condition'),
  const SellerProductColumnDef(id: 'inclusions_type', label: 'Inclusions Type'),
  const SellerProductColumnDef(id: 'eye_clean', label: 'Eye Clean'),
  const SellerProductColumnDef(id: 'bgm', label: 'B G M'),
  const SellerProductColumnDef(id: 'milky', label: 'Milky'),
  const SellerProductColumnDef(id: 'ha', label: 'H A'),
  const SellerProductColumnDef(
    id: 'matching_pair_number',
    label: 'Matching Pair Number',
  ),
  const SellerProductColumnDef(id: 'rough_source', label: 'Rough Source'),
  const SellerProductColumnDef(id: 'key_to_symbols', label: 'Key To Symbols'),
  const SellerProductColumnDef(id: 'cert_comment', label: 'Cert Comment'),
  const SellerProductColumnDef(id: 'tinge', label: 'Tinge'),
  const SellerProductColumnDef(id: 'luster', label: 'Luster'),
  const SellerProductColumnDef(id: 'tags', label: 'Tags'),
  const SellerProductColumnDef(id: 'image1', label: 'Image1'),
  const SellerProductColumnDef(id: 'image2', label: 'Image2'),
  const SellerProductColumnDef(id: 'image3', label: 'Image3'),
  const SellerProductColumnDef(id: 'image4', label: 'Image4'),
  const SellerProductColumnDef(id: 'image5', label: 'Image5'),
  const SellerProductColumnDef(id: 'image6', label: 'Image6'),
  const SellerProductColumnDef(id: 'is_on_auction', label: 'Is On Auction'),
  const SellerProductColumnDef(id: 'is_sold', label: 'Is Sold'),
  const SellerProductColumnDef(id: 'is_expired', label: 'Is Expired'),
  const SellerProductColumnDef(id: 'is_deleted', label: 'Is Deleted'),
  const SellerProductColumnDef(id: 'created_at', label: 'Created At'),
  const SellerProductColumnDef(id: 'updated_at', label: 'Updated At'),
  const SellerProductColumnDef(
    id: 'auction_start_time',
    label: 'Auction Start Time',
  ),
  const SellerProductColumnDef(
    id: 'auction_end_time',
    label: 'Auction End Time',
  ),
  const SellerProductColumnDef(id: 'actions', label: 'Actions'),
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
