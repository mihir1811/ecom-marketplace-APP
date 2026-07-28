import '../../../core/utils/app_currency.dart';
class SellerChatThread {
  const SellerChatThread({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productSubtitle,
    required this.priceLabel,
    required this.buyerName,
    required this.buyerId,
    required this.lastMessage,
    required this.timeLabel,
    required this.isOnline,
    required this.messages,
    this.avatarColor = 0xFF2563EB,
  });

  final String id;
  final String productId;
  final String productName;
  final String productSubtitle;
  final String priceLabel;
  final String buyerName;
  final String buyerId;
  final String lastMessage;
  final String timeLabel;
  final bool isOnline;
  final int avatarColor;
  final List<SellerChatMessage> messages;
}

class SellerChatMessage {
  const SellerChatMessage({
    required this.text,
    required this.time,
    required this.isMine,
    this.dateLabel,
  });

  final String text;
  final String time;
  final bool isMine;
  final String? dateLabel;
}

final kSellerChatsMock = <SellerChatThread>[
  SellerChatThread(
    id: 'c1',
    productId: '3759',
    productName: 'tttt',
    productSubtitle: 'adsfdsa',
    priceLabel: '${AppCurrency.symbol}23.58',
    buyerName: 'Tttt',
    buyerId: '10d4073e-c437-4650-99de-6aab8c7bae61',
    lastMessage: 'fbvgcgb',
    timeLabel: '16h ago',
    isOnline: true,
    avatarColor: 0xFF2563EB,
    messages: const [
      SellerChatMessage(
        text: 'hello',
        time: '15:05',
        isMine: false,
        dateLabel: 'Thursday 9 Jul',
      ),
      SellerChatMessage(text: 'asdf', time: '15:06', isMine: false),
      SellerChatMessage(
        text: 'fbvgcgb',
        time: '17:12',
        isMine: true,
        dateLabel: 'Yesterday',
      ),
    ],
  ),
  SellerChatThread(
    id: 'c2',
    productId: '3812',
    productName: 'round diamond',
    productSubtitle: 'GIA certified',
    priceLabel: '${AppCurrency.symbol}1,240',
    buyerName: 'Testd',
    buyerId: 'a1b2c3d4-1111-2222-3333-444455556666',
    lastMessage: 'Photo',
    timeLabel: '1 Jul',
    isOnline: false,
    avatarColor: 0xFF6B7280,
    messages: const [
      SellerChatMessage(
        text: 'Is this still available?',
        time: '10:20',
        isMine: false,
        dateLabel: '1 Jul',
      ),
      SellerChatMessage(text: 'Yes, it is.', time: '10:22', isMine: true),
      SellerChatMessage(text: 'Photo', time: '10:25', isMine: false),
    ],
  ),
  SellerChatThread(
    id: 'c3',
    productId: '3901',
    productName: 'cushion',
    productSubtitle: 'VVS1',
    priceLabel: '${AppCurrency.symbol}890',
    buyerName: 'Prem',
    buyerId: 'bbbbbbbb-cccc-dddd-eeee-ffffffffffff',
    lastMessage: 'hyy',
    timeLabel: '30 Jun',
    isOnline: false,
    avatarColor: 0xFFEA580C,
    messages: const [
      SellerChatMessage(
        text: 'hyy',
        time: '09:01',
        isMine: false,
        dateLabel: '30 Jun',
      ),
    ],
  ),
];

SellerChatThread? findSellerChatById(String id) {
  for (final c in kSellerChatsMock) {
    if (c.id == id) return c;
  }
  return null;
}
