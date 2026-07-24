import '../domain/models/seller_inquiry.dart';

final List<SellerInquiry> kSellerInquiriesMock = [
  SellerInquiry(
    id: '1',
    category: InquiryCategory.diamond,
    buyerName: 'John Buyer',
    buyerEmail: 'john.buyer@example.com',
    userId: 'a0000000-0000-0000-0000-000000000000',
    summary: 'ROUND · 1–2 ct',
    createdAtLabel: '5 Jun 2026, 17:41',
    updatedAtLabel: '06/06/2024, 11:43:08',
    createdAtLong: 'Friday, 5 June 2026 at 17:41',
    sellerReply:
        'Thanks for your inquiry.\n\n**We have matching stones** in stock:\n'
        '- 1.12ct Round D VS1 GIA\n'
        '- 1.51ct Round E VS2 GIA\n\n'
        'Please confirm preferred carat and budget and we will send certificates.',
    sellerReplyAt: '06/06/2026, 09:15:00',
    fields: const {
      'Sub-category (PARCEL / SINGLE)': 'SINGLE',
      'Diamond type (LAB / NATURAL)': 'NATURAL',
      'Growth process (LAB only)': '—',
      'Certified': 'Yes',
      'Certificate company': 'GIA',
      'Minimum sieve size (PARCEL)': '—',
      'Maximum sieve size (PARCEL)': '—',
      'Shape': 'ROUND',
      'Minimum carat weight': '1',
      'Maximum carat weight': '2',
      'Minimum color grade': 'D',
      'Maximum color grade': 'G',
      'Minimum clarity grade': 'VS1',
      'Maximum clarity grade': 'SI1',
      'Cut quality': 'Excellent',
      'BGM (brown/green/milky)': 'No',
      'Inclusion type': '—',
      'Minimum fluorescence intensity': 'None',
      'Maximum fluorescence intensity': 'Faint',
      'Quantity': '1',
      'Minimum total price': '10000',
      'Maximum total price': '25000',
      'Minimum price per carat': '—',
      'Maximum price per carat': '—',
      'Payment terms': 'Bank transfer / 7 days',
      'Remarks': 'Looking for engagement ring diamond',
      'Minimum length (SINGLE)': '—',
      'Maximum length': '—',
      'Minimum width': '—',
      'Maximum width': '—',
      'Minimum height': '—',
      'Maximum height': '—',
      'Expiry date': '05/03/2024, 11:43:08',
      'Reference image URL': '—',
      'Delivery location': 'New York, USA',
    },
  ),
  SellerInquiry(
    id: '2',
    category: InquiryCategory.gemstone,
    buyerName: 'Sara Cole',
    buyerEmail: 'sara@example.com',
    userId: 'b1111111-1111-1111-1111-111111111111',
    summary: 'Ruby · 1–2 ct',
    createdAtLabel: '8 Jun 2026, 11:20',
    updatedAtLabel: '08/06/2026, 11:20:00',
    createdAtLong: 'Monday, 8 June 2026 at 11:20',
    fields: const {
      'Is Certified': 'Yes',
      'Gemstone type': 'Ruby',
      'Shape': 'Round',
      'Carat weight min': '1',
      'Carat weight max': '2',
      'Primary color min': 'Red',
      'Primary color max': 'Deep red',
      'Clarity': 'VS',
      'Origin': 'Mozambique',
      'Treatments': 'None',
      'Quantity': '2',
      'Total budget min': '5000',
      'Total budget max': '12000',
      'Delivery location': 'London, UK',
    },
  ),
  SellerInquiry(
    id: '3',
    category: InquiryCategory.watch,
    buyerName: 'Alex Kim',
    buyerEmail: 'alex@example.com',
    userId: 'c2222222-2222-2222-2222-222222222222',
    summary: 'Rolex · Submariner',
    createdAtLabel: '10 Jun 2026, 09:05',
    updatedAtLabel: '10/06/2026, 09:05:00',
    createdAtLong: 'Wednesday, 10 June 2026 at 09:05',
    fields: const {
      'Brand': 'Rolex',
      'Model': 'Submariner',
      'Reference number': '126610LN',
      'Year min': '2020',
      'Year max': '2024',
      'Total price min': '10000',
      'Total price max': '15000',
      'Condition': 'Used',
      'Delivery location': 'Dubai, UAE',
    },
  ),
];

SellerInquiry? findSellerInquiry(String id) {
  for (final i in kSellerInquiriesMock) {
    if (i.id == id) return i;
  }
  return null;
}

List<SellerInquiry> inquiriesForCategory(InquiryCategory category) {
  return kSellerInquiriesMock.where((i) => i.category == category).toList();
}
