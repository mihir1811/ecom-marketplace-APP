import '../domain/agent_session.dart';

/// A request the agent answers itself, without the model.
class GuardVerdict {
  const GuardVerdict(this.reply, {this.options = const []});

  final String reply;
  final List<String> options;
}

/// Deterministic checks on what the user typed, run before anything reaches
/// the model. Blocks prompt injection, secret probing, other people's data
/// and clearly off-topic requests, so those never cost a model call and can
/// never be talked past the policy.
///
/// The system prompt carries the same rules for anything phrased in a way
/// these patterns miss; this layer is the cheap, unbypassable first line.
class InputGuard {
  const InputGuard();

  /// Longest request accepted. Real requests are a sentence or two; long
  /// pastes are where injected instructions hide.
  static const maxChars = 500;

  /// Marketplace words that keep a request in scope even when it also
  /// matches an off-topic pattern ("write a poem about my ring" goes on to
  /// the model, which declines or helps within policy).
  static final _domain = RegExp(
    r'diamond|gem|stone|jewel|ring|earring|necklace|bracelet|pendant|bangle|'
    r'gold|silver|platinum|bullion|coin|watch|rolex|carat|ruby|sapphire|'
    r'emerald|pearl|order|cart|bag|wishlist|wallet|reward|offer|auction|bid|'
    r'seller|buyer|sale|sales|inventory|listing|refund|payment|invoice|'
    r'gemworld|हीरा|हीरे|सोना|ગોલ્ડ|હીરા|સોનું',
    caseSensitive: false,
  );

  static final _injection = RegExp(
    r'ignore (all |any |the )?(previous|prior|above|earlier|your) (instructions|rules|prompt|messages)|'
    r'disregard (all |the |your )?(previous |prior )?(instructions|rules)|'
    r'forget (all |your |the )?(previous |prior )?(instructions|rules)|'
    r'(new|override|updated) (system )?(instructions|rules|prompt)\s*:|'
    r'you are (now|no longer)|from now on,? you|act as (a|an|my) |pretend (to be|you are)|'
    r'role-?play|jail ?break|\bdan\b|developer mode|dev mode|god mode|sudo mode|'
    r'do anything now|without (any )?restrictions|bypass (your |the )?(rules|filters|guard)|'
    r'<\s*/?\s*(system|assistant|im_start|im_end)\s*>|\[\s*system\s*\]|###\s*system',
    caseSensitive: false,
  );

  static final _secrets = RegExp(
    r'system prompt|your (instructions|prompt|rules|guidelines|configuration|config)|'
    r'(show|print|reveal|repeat|display|tell me|give me|leak|dump|output) .{0,30}'
    r'(your prompt|instructions|your rules|your tools|tool list|schema|api ?keys?|tokens?|secrets?|passwords?)|'
    r'api[\s_-]?key|openai|access token|bearer|(which|what) (ai|llm|language model)|(which|what) model are you|are you (gpt|chatgpt|claude|gemini)|'
    r'\b(chatgpt|gpt-?\d|llama)\b|\.env\b',
    caseSensitive: false,
  );

  /// Personal data of anyone other than the signed-in user.
  static final _othersData = RegExp(
    r'(other|another|all|every|some) (users?|buyers?|sellers?|customers?|members?|people)'
    r"('s|s')? .{0,20}(emails?|phones?|numbers?|address(es)?|passwords?|details|data|contacts?|kyc|pan|aadhaa?r|bank)|"
    r'(emails?|phones?|numbers?|address(es)?|passwords?|contacts?|kyc|bank details) of (other|another|all|every) ',
    caseSensitive: false,
  );

  static final _offTopic = RegExp(
    r'\b(write|generate|create|give|fix|debug|explain)\b.{0,30}\b(code|program|script|function|class|sql|query|regex|html|css|api)\b|'
    r'\b(python|javascript|typescript|java|kotlin|swift|c\+\+|c#|golang|rust|php|flutter|dart|react|node\.?js)\b|'
    r'\b(president|prime minister|chief minister|governor|capital|population|currency) of\b|'
    r'\bweather\b|\bforecast\b|\bnews\b|\bheadlines\b|\bcricket\b|\bfootball\b|\bmatch score\b|\bmovies?\b|\bsongs?\b|\blyrics\b|'
    r'\b(tell|say) (me )?(a )?joke\b|\bpoem\b|\bpoetry\b|\bessay\b|\bstory\b|\bhomework\b|\bassignment\b|'
    r'\btranslate\b|\brecipe\b|\bhoroscope\b|\bstock market\b|\bcrypto\b|\bbitcoin\b|\bshare price\b|'
    r'\bwho (is|was) (the )?(founder|ceo|inventor|president|pm)\b|\bwho invented\b|\bmeaning of life\b',
    caseSensitive: false,
  );

  /// Bare arithmetic ("2+2", "what is 12*7").
  static final _math = RegExp(
    r'^(?=.*\d\s*[-+*/x×÷^]\s*\d)\s*(what\s*is|whats|calculate|solve|compute)?\s*[-+*/x×÷^().\d\s]+\s*\??\s*$',
    caseSensitive: false,
  );

  static final _abuse = RegExp(
    r'\b(fuck|f\*ck|shit|bitch|bastard|asshole|madarchod|bhenchod|chutiya|gaand|randi)\b',
    caseSensitive: false,
  );

  /// Null when the request may continue.
  GuardVerdict? check(String utterance, AgentSession session) {
    final text = utterance.trim();
    if (text.isEmpty) return null;
    final scope = scopeLine(session);
    final options = starterOptions(session);
    if (text.length > maxChars) {
      return GuardVerdict(
        'That is a bit long for me. Please ask in a sentence or two. $scope',
        options: options,
      );
    }
    if (_injection.hasMatch(text) || _secrets.hasMatch(text)) {
      return GuardVerdict(
        'I can\'t share or change how I work. $scope',
        options: options,
      );
    }
    if (_othersData.hasMatch(text)) {
      return GuardVerdict(
        'I can only show your own account information. $scope',
        options: options,
      );
    }
    if (_abuse.hasMatch(text)) {
      return GuardVerdict('Let\'s keep it friendly. $scope', options: options);
    }
    final inDomain = _domain.hasMatch(text);
    final hasDigits = RegExp(r'\d').hasMatch(text);
    if (!inDomain &&
        (_offTopic.hasMatch(text) || (hasDigits && _math.hasMatch(text)))) {
      return GuardVerdict('I can\'t help with that. $scope', options: options);
    }
    return null;
  }

  /// One sentence on what Gem Agent does, for refusals and help.
  static String scopeLine(AgentSession session) => session.isSeller
      ? 'I can help you find diamonds, gemstones, jewelry, watches and '
            'bullion, and check your orders, sales, listings, offers and '
            'auctions.'
      : 'I can help you find diamonds, gemstones, jewelry, watches and '
            'bullion, and check your cart, orders, wishlist, offers, wallet '
            'and auctions.';

  /// Quick replies that steer back to things the agent does.
  static List<String> starterOptions(AgentSession session) {
    if (session.isSeller && session.onSellerSide) {
      return const [
        'Any orders today?',
        'Sales this month',
        'My active auctions',
        'Pending offers',
      ];
    }
    if (session.signedIn) {
      return const [
        'What\'s in my cart?',
        'My recent orders',
        '2 carat round diamond',
        'Gold rings',
      ];
    }
    return const [
      '2 carat round diamond',
      'Gold rings',
      'Blue sapphire',
      'Luxury watches',
    ];
  }
}

/// Cleans the model's free-text reply before it is shown: no markdown, no
/// code, no leaked instructions or credentials, bounded length.
class OutputGuard {
  const OutputGuard();

  static const maxChars = 600;

  /// Fragments that only appear in the system prompt / tool schemas.
  static final _leak = RegExp(
    r'how to handle every request|## tool:|# tools|promptGuidance|'
    r'additionalProperties|"type"\s*:\s*"object"|system prompt|'
    r'OPENAI|sk-[A-Za-z0-9_-]{12,}|Bearer\s+[A-Za-z0-9._-]{12,}|'
    r'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}',
    caseSensitive: false,
  );

  static final _codeFence = RegExp(r'```');

  String sanitize(String text, AgentSession session) {
    var out = text.trim();
    if (out.isEmpty) return out;
    if (_leak.hasMatch(out) || _codeFence.hasMatch(out)) {
      return 'I can\'t help with that. ${InputGuard.scopeLine(session)}';
    }
    out = out
        .replaceAll(RegExp(r'\*\*|__|`'), '')
        .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*[-*•]\s+', multiLine: true), '• ')
        .replaceAll(RegExp(r'\[([^\]]+)\]\((https?://[^)]+)\)'), r'$1')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    if (out.length > maxChars) {
      final cut = out.lastIndexOf(RegExp(r'[.!?।]\s'), maxChars);
      out = '${out.substring(0, cut > 200 ? cut + 1 : maxChars).trim()}…';
    }
    return out;
  }
}
