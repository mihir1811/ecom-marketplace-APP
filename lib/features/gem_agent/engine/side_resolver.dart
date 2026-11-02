import '../domain/agent_session.dart';
import '../domain/tool_result.dart';

/// What a buyer/seller look-up should read.
sealed class SideDecision {
  const SideDecision();
}

/// Read this side.
final class UseSide extends SideDecision {
  const UseSide(this.side);
  final AgentWorkspace side;
}

/// Run the call as made: the user named both sides ("what I bought and
/// what I sold").
final class KeepAsCalled extends SideDecision {
  const KeepAsCalled();
}

/// The side can't be known: ask before reading anything.
final class AskSide extends SideDecision {
  const AskSide();
}

/// Orders, offers and auctions exist on both sides of the app and work
/// differently on each (a buyer's purchases vs a seller's incoming orders).
/// This decides which side a seller account means, so the agent never mixes
/// them up or guesses:
///
/// 1. A side the user named in this request wins ("as a buyer", "I bought",
///    "seller side", "orders from customers").
/// 2. A short follow-up ("and yesterday?", "Seller side") keeps the side
///    named earlier in the conversation.
/// 3. Otherwise the side on screen: buyer screens (home, listings, cart…)
///    read buyer data, seller workspace screens read seller data.
/// 4. On a shared page (about, policies…) the agent asks.
///
/// Buyer-only accounts always read buyer data.
class AgentSideResolver {
  const AgentSideResolver();

  /// Buyer tool → its seller twin.
  static const pairs = {
    'my_orders': 'seller_orders',
    'my_offers': 'seller_offers',
    'my_auctions': 'seller_auctions',
  };

  /// Side a paired tool reads; null for every other tool.
  static AgentWorkspace? sideOf(String tool) => pairs.containsKey(tool)
      ? AgentWorkspace.buyer
      : (pairs.containsValue(tool) ? AgentWorkspace.seller : null);

  /// The same look-up on the other side.
  static String? twinOf(String tool) =>
      pairs[tool] ??
      pairs.entries.where((e) => e.value == tool).firstOrNull?.key;

  static RegExp _words(String alternatives) => RegExp(
    r'(?<![\p{L}\p{M}\p{N}])(?:' + alternatives + r')(?![\p{L}\p{M}\p{N}])',
    unicode: true,
    caseSensitive: false,
  );

  /// The user means their own purchases.
  static final _buyer = _words(
    r'buyer side|buying side|shopping side|as an? buyer|buyer account|'
    r'my purchases?|purchases?|purchased|i bought|bought|i ordered|ordered by me|'
    r'i placed|placed by me|i paid|my bids?|i bid|offers? i (?:made|sent)|'
    r'kharid\w*|khareed\w*|liya|lidhu|lidha|खरीद\w*|ખરીદ\w*|लिया|લીધ\w*',
  );

  /// The user means what customers did with their shop.
  static final _seller = _words(
    r'seller side|selling side|seller workspace|as an? seller|seller account|'
    r'my shop|my store|my sales|sales|sold|vechyu|vechi|becha|बेचा|વેચ\w*|'
    r'customers?|grahak|ग्राहक|ગ્રાહક|from (?:a |my )?buyers?|buyers? (?:placed|ordered|sent|made)|'
    r'orders? received|received orders?|incoming|orders? i got|'
    r'my listings?|offers? (?:i )?received|received offers?|bids? on my',
  );

  /// Words that make an utterance a request of its own (not a follow-up).
  static final _topic = _words(
    r'orders?|offers?|auctions?|bids?|purchases?|sales|ऑर्डर|ઓર્ડર',
  );

  /// Which side to read for a request; [utterances] oldest first, the
  /// current request last.
  SideDecision resolve(AgentSession session, List<String> utterances) {
    if (!session.signedIn || !session.isSeller) {
      return const UseSide(AgentWorkspace.buyer);
    }
    for (final text in utterances.reversed) {
      final buyer = _buyer.hasMatch(text);
      final seller = _seller.hasMatch(text);
      if (buyer && seller) return const KeepAsCalled();
      if (buyer) return const UseSide(AgentWorkspace.buyer);
      if (seller) return const UseSide(AgentWorkspace.seller);
      // A request of its own with no side named: the screen decides.
      if (_topic.hasMatch(text)) break;
    }
    return switch (session.workspace) {
      AgentWorkspace.shared => const AskSide(),
      final side => UseSide(side),
    };
  }

  /// The question asked when the side can't be known.
  static ToolNeedsInput question(String tool) {
    final noun = switch (pairs[tool] ?? tool) {
      'seller_offers' => 'offers',
      'seller_auctions' => 'auctions',
      _ => 'orders',
    };
    final (buyerText, sellerText) = switch (noun) {
      'offers' => ('offers you made as a buyer', 'offers customers sent you'),
      'auctions' => ('auctions you bid on as a buyer', 'auctions you listed'),
      _ => ('orders you placed as a buyer', 'orders customers placed with you'),
    };
    return ToolNeedsInput(
      question:
          'Do you mean $buyerText (buyer side), or $sellerText '
          '(seller side)?',
      missing: const ['side'],
      options: const ['Buyer side', 'Seller side'],
    );
  }
}
