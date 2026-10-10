import '../localized_message.dart';

/// Copy for the redesigned experience surfaces: the interactive gem stage,
/// Gem AI advisor, cart and diamond project dashboard.
abstract final class ExperienceL10n {
  // Gem stage (home footer)
  static const stageEyebrow = 'experience.stageEyebrow';
  static const stageHeadline = 'experience.stageHeadline';
  static const stageBody = 'experience.stageBody';

  // Gem AI
  static const aiAdvisor = 'experience.aiAdvisor';
  static const aiGreeting = 'experience.aiGreeting';
  static const aiTryAsking = 'experience.aiTryAsking';
  static const aiPrompt1 = 'experience.aiPrompt1';
  static const aiPrompt2 = 'experience.aiPrompt2';
  static const aiPrompt3 = 'experience.aiPrompt3';
  static const aiPrompt4 = 'experience.aiPrompt4';
  static const aiHistory = 'experience.aiHistory';
  static const aiNewChat = 'experience.aiNewChat';
  static const aiLanguage = 'experience.aiLanguage';
  static const aiAttach = 'experience.aiAttach';
  static const aiSend = 'experience.aiSend';
  static const aiClose = 'experience.aiClose';

  // Cart
  static const cartEyebrow = 'experience.cartEyebrow';
  static const cartPieces = 'experience.cartPieces';
  static const cartPieceOne = 'experience.cartPieceOne';
  static const cartEmptyBody = 'experience.cartEmptyBody';
  static const cartChange = 'experience.cartChange';
  static const cartAddresses = 'experience.cartAddresses';
  static const cartHavePromo = 'experience.cartHavePromo';
  static const cartApply = 'experience.cartApply';
  static const cartPromoApplied = 'experience.cartPromoApplied';
  static const cartPaymentOptions = 'experience.cartPaymentOptions';
  static const cartTotal = 'experience.cartTotal';
  static const cartSecure = 'experience.cartSecure';
  static const cartLoadError = 'experience.cartLoadError';

  // Diamond project
  static const projectEyebrow = 'experience.projectEyebrow';
  static const projectValue = 'experience.projectValue';
  static const projectAverages = 'experience.projectAverages';
  static const tabOverview = 'experience.tabOverview';
  static const tabMix = 'experience.tabMix';
  static const tabDistribution = 'experience.tabDistribution';
  static const tabStones = 'experience.tabStones';
  static const projectArchive = 'experience.projectArchive';
  static const projectUpdated = 'experience.projectUpdated';
  static const projectOpen = 'experience.projectOpen';
  static const projectTapHint = 'experience.projectTapHint';
}

const experienceMessages = <String, LocalizedMessage>{
  ExperienceL10n.stageEyebrow: LocalizedMessage(
    english: 'Ten cuts · rendered live',
    hindi: 'दस कट · लाइव रेंडर',
    gujarati: 'દસ કટ · લાઇવ રેન્ડર',
  ),
  ExperienceL10n.stageHeadline: LocalizedMessage(
    english: 'Every facet,\nin your hands.',
    hindi: 'हर पहलू,\nआपके हाथों में।',
    gujarati: 'દરેક પાસું,\nતમારા હાથમાં.',
  ),
  ExperienceL10n.stageBody: LocalizedMessage(
    english:
        'Round to heart, princess to pear — touch the stones and '
        'watch them catch the light.',
    hindi:
        'राउंड से हार्ट, प्रिंसेस से पियर तक — पत्थरों को छुएँ और उन्हें '
        'रोशनी में चमकते देखें।',
    gujarati:
        'રાઉન્ડથી હાર્ટ, પ્રિન્સેસથી પિયર સુધી — પથ્થરોને સ્પર્શો અને '
        'તેમને પ્રકાશમાં ઝળહળતા જુઓ.',
  ),
  ExperienceL10n.aiAdvisor: LocalizedMessage(
    english: 'Your gem advisor',
    hindi: 'आपका रत्न सलाहकार',
    gujarati: 'તમારા રત્ન સલાહકાર',
  ),
  ExperienceL10n.aiGreeting: LocalizedMessage(
    english: 'What are you\nlooking for today?',
    hindi: 'आज आप क्या\nढूँढ रहे हैं?',
    gujarati: 'આજે તમે શું\nશોધી રહ્યા છો?',
  ),
  ExperienceL10n.aiTryAsking: LocalizedMessage(
    english: 'Try asking',
    hindi: 'ऐसे पूछें',
    gujarati: 'આવું પૂછો',
  ),
  ExperienceL10n.aiPrompt1: LocalizedMessage(
    english: 'Round diamonds, 1 carat, VS1 or better',
    hindi: 'राउंड डायमंड, 1 कैरेट, VS1 या बेहतर',
    gujarati: 'રાઉન્ડ ડાયમંડ, 1 કેરેટ, VS1 કે વધુ સારા',
  ),
  ExperienceL10n.aiPrompt2: LocalizedMessage(
    english: 'Natural emeralds around 2 carats',
    hindi: 'लगभग 2 कैरेट के प्राकृतिक पन्ने',
    gujarati: 'લગભગ 2 કેરેટના કુદરતી પન્ના',
  ),
  ExperienceL10n.aiPrompt3: LocalizedMessage(
    english: 'Lab-grown oval diamonds under \$3,000',
    hindi: '\$3,000 से कम के लैब-ग्रोन ओवल डायमंड',
    gujarati: '\$3,000થી ઓછી કિંમતના લેબ-ગ્રોન ઓવલ ડાયમંડ',
  ),
  ExperienceL10n.aiPrompt4: LocalizedMessage(
    english: 'Gold earrings for a gift',
    hindi: 'उपहार के लिए सोने के झुमके',
    gujarati: 'ભેટ માટે સોનાની બુટ્ટી',
  ),
  ExperienceL10n.aiHistory: LocalizedMessage(
    english: 'Chat history',
    hindi: 'चैट इतिहास',
    gujarati: 'ચેટ ઇતિહાસ',
  ),
  ExperienceL10n.aiNewChat: LocalizedMessage(
    english: 'New chat',
    hindi: 'नई चैट',
    gujarati: 'નવી ચેટ',
  ),
  ExperienceL10n.aiLanguage: LocalizedMessage(
    english: 'Reply language',
    hindi: 'जवाब की भाषा',
    gujarati: 'જવાબની ભાષા',
  ),
  ExperienceL10n.aiAttach: LocalizedMessage(
    english: 'Attach a photo',
    hindi: 'फ़ोटो जोड़ें',
    gujarati: 'ફોટો ઉમેરો',
  ),
  ExperienceL10n.aiSend: LocalizedMessage(
    english: 'Send',
    hindi: 'भेजें',
    gujarati: 'મોકલો',
  ),
  ExperienceL10n.aiClose: LocalizedMessage(
    english: 'Close',
    hindi: 'बंद करें',
    gujarati: 'બંધ કરો',
  ),
  ExperienceL10n.cartEyebrow: LocalizedMessage(
    english: 'Your selection',
    hindi: 'आपका चयन',
    gujarati: 'તમારી પસંદગી',
  ),
  ExperienceL10n.cartPieces: LocalizedMessage(
    english: '{count} pieces',
    hindi: '{count} आइटम',
    gujarati: '{count} વસ્તુઓ',
  ),
  ExperienceL10n.cartPieceOne: LocalizedMessage(
    english: '1 piece',
    hindi: '1 आइटम',
    gujarati: '1 વસ્તુ',
  ),
  ExperienceL10n.cartEmptyBody: LocalizedMessage(
    english: 'Pieces you add will wait for you here.',
    hindi: 'आप जो आइटम जोड़ेंगे, वे यहाँ आपका इंतज़ार करेंगे।',
    gujarati: 'તમે ઉમેરેલી વસ્તુઓ અહીં તમારી રાહ જોશે.',
  ),
  ExperienceL10n.cartChange: LocalizedMessage(
    english: 'Change',
    hindi: 'बदलें',
    gujarati: 'બદલો',
  ),
  ExperienceL10n.cartAddresses: LocalizedMessage(
    english: 'Delivery addresses',
    hindi: 'डिलीवरी पते',
    gujarati: 'ડિલિવરી સરનામાં',
  ),
  ExperienceL10n.cartHavePromo: LocalizedMessage(
    english: 'Have a promo code?',
    hindi: 'प्रोमो कोड है?',
    gujarati: 'પ્રોમો કોડ છે?',
  ),
  ExperienceL10n.cartApply: LocalizedMessage(
    english: 'Apply',
    hindi: 'लागू करें',
    gujarati: 'લાગુ કરો',
  ),
  ExperienceL10n.cartPromoApplied: LocalizedMessage(
    english: 'Code {code} applied',
    hindi: 'कोड {code} लागू हुआ',
    gujarati: 'કોડ {code} લાગુ થયો',
  ),
  ExperienceL10n.cartPaymentOptions: LocalizedMessage(
    english: 'Payment options',
    hindi: 'भुगतान विकल्प',
    gujarati: 'ચુકવણી વિકલ્પો',
  ),
  ExperienceL10n.cartTotal: LocalizedMessage(
    english: 'Total',
    hindi: 'कुल',
    gujarati: 'કુલ',
  ),
  ExperienceL10n.cartSecure: LocalizedMessage(
    english: 'Secure checkout',
    hindi: 'सुरक्षित चेकआउट',
    gujarati: 'સુરક્ષિત ચેકઆઉટ',
  ),
  ExperienceL10n.cartLoadError: LocalizedMessage(
    english: 'Your cart could not be loaded',
    hindi: 'आपका कार्ट लोड नहीं हो सका',
    gujarati: 'તમારું કાર્ટ લોડ થઈ શક્યું નહીં',
  ),
  ExperienceL10n.projectEyebrow: LocalizedMessage(
    english: 'Diamond project',
    hindi: 'डायमंड प्रोजेक्ट',
    gujarati: 'ડાયમંડ પ્રોજેક્ટ',
  ),
  ExperienceL10n.projectValue: LocalizedMessage(
    english: 'Total value',
    hindi: 'कुल मूल्य',
    gujarati: 'કુલ મૂલ્ય',
  ),
  ExperienceL10n.projectAverages: LocalizedMessage(
    english: 'Averages',
    hindi: 'औसत',
    gujarati: 'સરેરાશ',
  ),
  ExperienceL10n.tabOverview: LocalizedMessage(
    english: 'Overview',
    hindi: 'सारांश',
    gujarati: 'સારાંશ',
  ),
  ExperienceL10n.tabMix: LocalizedMessage(
    english: 'Mix',
    hindi: 'मिश्रण',
    gujarati: 'મિશ્રણ',
  ),
  ExperienceL10n.tabDistribution: LocalizedMessage(
    english: 'Spread',
    hindi: 'वितरण',
    gujarati: 'વિતરણ',
  ),
  ExperienceL10n.tabStones: LocalizedMessage(
    english: 'Stones',
    hindi: 'पत्थर',
    gujarati: 'પથ્થર',
  ),
  ExperienceL10n.projectArchive: LocalizedMessage(
    english: 'Your archive',
    hindi: 'आपका संग्रह',
    gujarati: 'તમારો સંગ્રહ',
  ),
  ExperienceL10n.projectUpdated: LocalizedMessage(
    english: 'Updated {date}',
    hindi: '{date} को अपडेट',
    gujarati: '{date}એ અપડેટ',
  ),
  ExperienceL10n.projectOpen: LocalizedMessage(
    english: 'Open',
    hindi: 'खोलें',
    gujarati: 'ખોલો',
  ),
  ExperienceL10n.projectTapHint: LocalizedMessage(
    english: 'Tap a bar or point for its value',
    hindi: 'मान देखने के लिए बार या बिंदु पर टैप करें',
    gujarati: 'મૂલ્ય જોવા માટે બાર કે બિંદુ પર ટેપ કરો',
  ),
};
