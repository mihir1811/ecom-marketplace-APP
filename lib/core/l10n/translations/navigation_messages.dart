import '../localized_message.dart';

/// Stable keys for app-wide navigation chrome (drawers, mode switch, bars).
abstract final class NavL10n {
  static const buyer = 'nav.mode.buyer';
  static const seller = 'nav.mode.seller';
  static const switchToBuyer = 'nav.mode.switchToBuyer';
  static const switchToSeller = 'nav.mode.switchToSeller';
  static const modeHint = 'nav.mode.hint';
  static const buyerAccount = 'nav.mode.buyerAccount';
  static const sellerWorkspace = 'nav.mode.sellerWorkspace';
  static const startSelling = 'nav.mode.startSelling';
  static const startSellingBody = 'nav.mode.startSellingBody';
  static const pendingLocked = 'nav.mode.pendingLocked';
  static const home = 'nav.home';
  static const categories = 'nav.categories';
  static const agent = 'nav.agent';
  static const closeCategories = 'nav.categories.close';
  static const groupShopping = 'nav.group.shopping';
  static const groupAuctions = 'nav.group.auctions';
  static const groupConversations = 'nav.group.conversations';
  static const groupAccount = 'nav.group.account';
  static const groupWorkspace = 'nav.group.workspace';
  static const groupGrow = 'nav.group.grow';
  static const liveAuctions = 'nav.item.liveAuctions';
  static const myWins = 'nav.item.myWins';
  static const notifications = 'nav.item.notifications';
}

const navigationMessages = <String, LocalizedMessage>{
  NavL10n.buyer: LocalizedMessage(
    english: 'Buyer',
    hindi: 'खरीदार',
    gujarati: 'ખરીદનાર',
  ),
  NavL10n.seller: LocalizedMessage(
    english: 'Seller',
    hindi: 'विक्रेता',
    gujarati: 'વિક્રેતા',
  ),
  NavL10n.switchToBuyer: LocalizedMessage(
    english: 'Switch to Buyer',
    hindi: 'खरीदार मोड पर जाएँ',
    gujarati: 'ખરીદનાર મોડ પર જાઓ',
  ),
  NavL10n.switchToSeller: LocalizedMessage(
    english: 'Switch to Seller',
    hindi: 'विक्रेता मोड पर जाएँ',
    gujarati: 'વિક્રેતા મોડ પર જાઓ',
  ),
  NavL10n.modeHint: LocalizedMessage(
    english: 'Switch between buying and selling anytime',
    hindi: 'कभी भी खरीदने और बेचने के बीच बदलें',
    gujarati: 'ગમે ત્યારે ખરીદી અને વેચાણ વચ્ચે બદલો',
  ),
  NavL10n.buyerAccount: LocalizedMessage(
    english: 'Buyer account',
    hindi: 'खरीदार खाता',
    gujarati: 'ખરીદનાર એકાઉન્ટ',
  ),
  NavL10n.sellerWorkspace: LocalizedMessage(
    english: 'Seller workspace',
    hindi: 'विक्रेता कार्यक्षेत्र',
    gujarati: 'વિક્રેતા કાર્યક્ષેત્ર',
  ),
  NavL10n.startSelling: LocalizedMessage(
    english: 'Start selling',
    hindi: 'बेचना शुरू करें',
    gujarati: 'વેચાણ શરૂ કરો',
  ),
  NavL10n.startSellingBody: LocalizedMessage(
    english: 'List your gems on GemWorld with a business account',
    hindi: 'बिज़नेस खाते से जेमवर्ल्ड पर अपने रत्न सूचीबद्ध करें',
    gujarati: 'બિઝનેસ એકાઉન્ટ સાથે જેમવર્લ્ડ પર તમારા રત્નો મૂકો',
  ),
  NavL10n.pendingLocked: LocalizedMessage(
    english: 'Verification pending — some tools are locked',
    hindi: 'सत्यापन लंबित — कुछ टूल लॉक हैं',
    gujarati: 'ચકાસણી બાકી — કેટલાક ટૂલ્સ લૉક છે',
  ),
  NavL10n.home: LocalizedMessage(
    english: 'Home',
    hindi: 'होम',
    gujarati: 'હોમ',
  ),
  NavL10n.categories: LocalizedMessage(
    english: 'Categories',
    hindi: 'श्रेणियाँ',
    gujarati: 'શ્રેણીઓ',
  ),
  NavL10n.agent: LocalizedMessage(
    english: 'Agent',
    hindi: 'एजेंट',
    gujarati: 'એજન્ટ',
  ),
  NavL10n.closeCategories: LocalizedMessage(
    english: 'Close categories',
    hindi: 'श्रेणियाँ बंद करें',
    gujarati: 'શ્રેણીઓ બંધ કરો',
  ),
  NavL10n.groupShopping: LocalizedMessage(
    english: 'Shopping',
    hindi: 'खरीदारी',
    gujarati: 'ખરીદી',
  ),
  NavL10n.groupAuctions: LocalizedMessage(
    english: 'Auctions',
    hindi: 'नीलामी',
    gujarati: 'હરાજી',
  ),
  NavL10n.groupConversations: LocalizedMessage(
    english: 'Messages & support',
    hindi: 'संदेश और सहायता',
    gujarati: 'સંદેશા અને સહાય',
  ),
  NavL10n.groupAccount: LocalizedMessage(
    english: 'Account',
    hindi: 'खाता',
    gujarati: 'એકાઉન્ટ',
  ),
  NavL10n.groupWorkspace: LocalizedMessage(
    english: 'Workspace',
    hindi: 'कार्यक्षेत्र',
    gujarati: 'કાર્યક્ષેત્ર',
  ),
  NavL10n.groupGrow: LocalizedMessage(
    english: 'Grow your business',
    hindi: 'अपना व्यवसाय बढ़ाएँ',
    gujarati: 'તમારો વ્યવસાય વધારો',
  ),
  NavL10n.liveAuctions: LocalizedMessage(
    english: 'Live auctions',
    hindi: 'लाइव नीलामी',
    gujarati: 'લાઇવ હરાજી',
  ),
  NavL10n.myWins: LocalizedMessage(
    english: 'My wins',
    hindi: 'मेरी जीत',
    gujarati: 'મારી જીત',
  ),
  NavL10n.notifications: LocalizedMessage(
    english: 'Notifications',
    hindi: 'सूचनाएँ',
    gujarati: 'સૂચનાઓ',
  ),
};
