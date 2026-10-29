import '../domain/agent_session.dart';
import 'guardrails.dart';

/// What the router decided for a request it can handle without the model.
sealed class LocalDecision {
  const LocalDecision();
}

/// Answer directly (greeting, thanks, help).
final class LocalReply extends LocalDecision {
  const LocalReply(this.text, {this.options = const []});
  final String text;
  final List<String> options;
}

/// Ask for a missing required detail before the model is involved. The
/// user's answer then goes to the model with this exchange in memory.
final class LocalClarify extends LocalDecision {
  const LocalClarify(this.question, this.options, {required this.slot});
  final String question;
  final List<String> options;
  final String slot;
}

/// Run one read-only tool with fixed arguments.
final class LocalToolCall extends LocalDecision {
  const LocalToolCall(this.tool, [this.args = const {}]);
  final String tool;
  final Map<String, Object?> args;
}

/// Deterministic fast path in front of the model.
///
/// Handles only what it can recognise with certainty — short account
/// look-ups ("what's in my cart", "any orders today"), small talk, and
/// catalog requests missing a required detail (natural vs lab-grown, jewelry
/// type, bullion metal). Everything else, and anything with extra
/// constraints, goes to the model. Saves a model round trip (cost, ~1–2 s)
/// on the most common requests and keeps follow-up questions identical
/// every time.
class LocalRouter {
  const LocalRouter();

  /// Whole-word match that also works for Hindi / Gujarati script (Dart's
  /// `\b` only knows ASCII word characters).
  static RegExp _words(String alternatives) => RegExp(
    r'(?<![\p{L}\p{M}\p{N}])(?:' + alternatives + r')(?![\p{L}\p{M}\p{N}])',
    unicode: true,
  );

  /// Look-ups longer than this carry constraints the model must read.
  static const _maxLookupWords = 9;

  static final _greeting = RegExp(
    r'^(hi+|hello+|hey+|namaste|namaskar|kem cho|good (morning|afternoon|evening)|yo)\b',
  );
  static final _thanks = RegExp(
    r'^(thanks?|thank you|thx|ty|dhanyavaa?d|shukriya|aabhar|great|ok(ay)?|cool|nice|perfect)\b',
  );
  static final _help = RegExp(
    r'^(help|what can you do|what do you do|how (do|can) you help|who are you|what are you)\b',
  );

  /// Words that add filters or conditions a fixed look-up cannot honour.
  static final _constraint = RegExp(
    r'\d|\b(from|above|below|under|over|more than|less than|between|except|'
    r'without|not|sort|cheapest|highest|lowest|biggest|largest|by|for|named|called|'
    r'customer|buyer|stock|id|compare|vs|versus|why)\b',
  );

  static final _mutation = RegExp(
    r'\b(add|remove|delete|clear|empty|cancel|buy|checkout|pay|place|accept|'
    r'reject|decline|counter|bid|update|edit|change|move|apply)\b',
  );

  /// Spoken windows → `period` values the account tools accept.
  static final _periods = <(RegExp, String)>[
    (_words(r'today|todays|aaj|aaje|आज|આજે'), 'today'),
    (_words(r'yesterday|kal|कल|ગઈકાલે'), 'yesterday'),
    (_words(r'this week|is hafte|aa athvadiye'), 'this_week'),
    (_words(r'last week|past week|last 7 days|past 7 days'), 'last_7_days'),
    (_words(r'this month|is mahine|aa mahine'), 'this_month'),
    (_words(r'last month|previous month|pichle mahine'), 'last_month'),
    (_words(r'last 30 days|past 30 days'), 'last_30_days'),
    (_words(r'this year|is saal|aa varshe'), 'this_year'),
  ];

  static final _cart = _words(r'cart|carts|basket|कार्ट|કાર્ટ');
  static final _bag = _words(r'bag|jewel(?:le)?ry bag');
  static final _wishlist = _words(
    r'wishlist|wish list|favou?rites?|saved items?|liked items?',
  );
  static final _wallet = _words(r'wallet|balance');
  static final _rewards = _words(r'rewards?|reward points|points');
  static final _orders = _words(r'orders?|ऑर्डर|ઓર્ડર');
  static final _received = _words(
    r'received|arrived|came|come|incoming|new|got|aaya|aaye|aavya|mila|mile',
  );
  static final _sales = _words(r'sales|revenue|earnings|sold|turnover');
  static final _auctions = _words(r'auctions?|bids?|lots?');
  static final _offers = _words(r'offers?|negotiations?');
  static final _inventory = _words(
    r'inventory|listings?|my (?:products|stones|diamonds|stock)',
  );

  static final _diamond = _words(r'diamonds?|heera|heere|hira|हीरा|हीरे|હીરા');
  static final _origin = RegExp(
    r'natural|nature|mined|earth|real|lab|grown|cvd|hpht|synthetic|man[\s-]?made|created|'
    r'नेचुरल|नैचुरल|प्राकृतिक|असली|लैब|लेब|નેચરલ|કુદરતી|અસલી|લેબ',
  );
  static final _jewelryWord = _words(
    r'jewel(?:le)?ry|jewels?|gehna|gehne|zevar|ornaments?|ghareno|ઘરેણાં|गहने',
  );
  static final _jewelryType = _words(
    r'rings?|earrings?|studs?|jhumkas?|necklaces?|chains?|pendants?|bracelets?|'
    r'bangles?|kada|mangalsutra|anklets?|nose ?pins?',
  );
  static final _watch = _words(
    r'watch(?:es)?|rolex|omega|cartier|patek|ghadi|ghadiyal',
  );
  static final _anyKind = _words(r'any|all|every|sab|badha');
  static final _gemType = _words(
    r'ruby|rubies|sapphires?|emeralds?|spinels?|tanzanites?|alexandrites?|'
    r'tourmalines?|garnets?|aquamarines?|morganites?|opals?|topaz|amethysts?|'
    r'citrines?|peridots?|pearls?|neelam|panna|manik|pukhraj',
  );
  static final _bullion = _words(r'bullion|biscuits?|coins?');
  static final _metal = _words(
    r'gold|silver|platinum|palladium|sona|sonu|chandi|सोना|चांदी|સોનું|ચાંદી',
  );

  /// Questions about a topic, not a search ("what is a lab diamond").
  static final _knowledge = RegExp(
    r'^(what|why|how|which is better|difference|explain|tell me about|is it|are)\b',
  );

  static final _ownership = _words(
    r'my|mine|i have|i listed|our|me|mera|mari|maru|मेरा|મારું',
  );

  LocalDecision? route(
    String utterance,
    AgentSession session, {
    List<String> history = const [],
  }) {
    final text = _normalize(utterance);
    if (text.isEmpty) return null;
    final words = text.split(' ').length;

    if (words <= 4 && _greeting.hasMatch(text) && !_hasTask(text)) {
      return LocalReply(
        'Hi! ${InputGuard.scopeLine(session)} What would you like?',
        options: InputGuard.starterOptions(session),
      );
    }
    if (words <= 5 && _thanks.hasMatch(text) && !_hasTask(text)) {
      return LocalReply(
        'Happy to help. Anything else?',
        options: InputGuard.starterOptions(session),
      );
    }
    if (words <= 7 && _help.hasMatch(text)) {
      return LocalReply(
        InputGuard.scopeLine(session),
        options: InputGuard.starterOptions(session),
      );
    }

    final lookup = _lookup(text, words, session);
    if (lookup != null) return lookup;
    return _clarify(text, session, history);
  }

  bool _hasTask(String text) =>
      _cart.hasMatch(text) ||
      _orders.hasMatch(text) ||
      _diamond.hasMatch(text) ||
      _jewelryWord.hasMatch(text) ||
      _wishlist.hasMatch(text);

  LocalDecision? _lookup(String text, int words, AgentSession session) {
    if (words > _maxLookupWords || _mutation.hasMatch(text)) return null;
    String? period;
    var stripped = text;
    for (final (pattern, value) in _periods) {
      if (!pattern.hasMatch(stripped)) continue;
      // Two windows ("today vs yesterday") is a comparison for the model.
      if (period != null) return null;
      period = value;
      stripped = stripped.replaceAll(pattern, ' ');
    }
    // A time window is the only constraint a fixed look-up honours.
    if (_constraint.hasMatch(stripped)) return null;

    final seller = session.signedIn && session.isSeller;
    final sellerSide = seller && session.onSellerSide;

    if (_orders.hasMatch(text)) {
      // A seller asking what "arrived" means sales, from either side.
      if (seller && (sellerSide || _received.hasMatch(text))) {
        return LocalToolCall('seller_orders', {'period': ?period});
      }
      return LocalToolCall('my_orders', {'period': ?period});
    }
    if (sellerSide && _sales.hasMatch(text)) {
      return LocalToolCall('seller_sales_report', {
        'period': period ?? 'today',
      });
    }
    if (sellerSide && _auctions.hasMatch(text) && period == null) {
      return const LocalToolCall('seller_auctions');
    }
    if (sellerSide && _offers.hasMatch(text) && period == null) {
      return const LocalToolCall('seller_offers');
    }
    if (sellerSide && _inventory.hasMatch(text) && period == null) {
      return const LocalToolCall('seller_inventory');
    }
    if (period != null) return null;
    if (_cart.hasMatch(text) ||
        (_bag.hasMatch(text) && _ownership.hasMatch(text))) {
      return const LocalToolCall('my_cart');
    }
    if (_wishlist.hasMatch(text)) return const LocalToolCall('my_wishlist');
    if (_wallet.hasMatch(text) || _rewards.hasMatch(text)) {
      return const LocalToolCall('my_wallet');
    }
    if (!sellerSide && _ownership.hasMatch(text)) {
      if (_offers.hasMatch(text)) return const LocalToolCall('my_offers');
      if (_auctions.hasMatch(text)) return const LocalToolCall('my_auctions');
    }
    return null;
  }

  LocalDecision? _clarify(
    String text,
    AgentSession session,
    List<String> history,
  ) {
    if (_knowledge.hasMatch(text)) return null;
    // Sellers talking about their own stock are not shopping.
    if (_ownership.hasMatch(text) &&
        (session.onSellerSide || _inventory.hasMatch(text))) {
      return null;
    }
    if (_orders.hasMatch(text) ||
        _cart.hasMatch(text) ||
        _wishlist.hasMatch(text) ||
        _auctions.hasMatch(text) ||
        _offers.hasMatch(text)) {
      return null;
    }
    final said = [...history.map(_normalize), text];
    bool everSaid(RegExp pattern) => said.any(pattern.hasMatch);

    // Diamonds set in jewelry or watches are not loose-stone searches.
    final jewelry =
        _jewelryWord.hasMatch(text) ||
        _jewelryType.hasMatch(text) ||
        _watch.hasMatch(text);
    if (_diamond.hasMatch(text) && !jewelry && !everSaid(_origin)) {
      return const LocalClarify(
        'Do you want a natural diamond or a lab-grown diamond?',
        ['Natural', 'Lab-grown'],
        slot: 'origin',
      );
    }
    final gem = _gemType.firstMatch(text)?.group(0);
    if (gem != null && !jewelry && !everSaid(_origin)) {
      return LocalClarify(
        'Do you want a natural $gem or a lab-grown $gem?',
        const ['Natural', 'Lab-grown'],
        slot: 'origin',
      );
    }
    if (_jewelryWord.hasMatch(text) &&
        !_jewelryType.hasMatch(text) &&
        !_anyKind.hasMatch(text)) {
      return const LocalClarify('What type of jewelry are you looking for?', [
        'Rings',
        'Earrings',
        'Necklaces',
        'Bracelets',
      ], slot: 'category');
    }
    if (_bullion.hasMatch(text) &&
        !_metal.hasMatch(text) &&
        !jewelry &&
        RegExp(r'\b(bullion|biscuits?|coins?)\b').hasMatch(text)) {
      return const LocalClarify('Which metal would you like?', [
        'Gold',
        'Silver',
        'Platinum',
        'Any',
      ], slot: 'metal');
    }
    return null;
  }

  static String _normalize(String text) => text
      .toLowerCase()
      .replaceAll('’', "'")
      .replaceAll("what's", 'what is')
      .replaceAll(RegExp(r"[^\p{L}\p{M}\p{N}\s'-]", unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
