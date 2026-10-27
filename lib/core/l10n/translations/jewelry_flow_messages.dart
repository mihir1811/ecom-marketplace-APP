import '../localized_message.dart';

/// Copy for the luxe jewelry flow (house landing → results → filters →
/// detail). Generic flow copy (reset, filters, sort, grid, …) is shared via
/// `DiamondFlowL10n` and `CatalogFlowL10n`.
abstract final class JewelryFlowL10n {
  // House landing
  static const houseEyebrow = 'jewelryFlow.houseEyebrow';
  static const housesHeadline = 'jewelryFlow.housesHeadline';
  static const housesIntro = 'jewelryFlow.housesIntro';
  static const featuredHouses = 'jewelryFlow.featuredHouses';
  static const allHouses = 'jewelryFlow.allHouses';
  static const housesCount = 'jewelryFlow.housesCount';
  static const showAllHouses = 'jewelryFlow.showAllHouses';
  static const sortBy = 'jewelryFlow.sortBy';
  static const filterBy = 'jewelryFlow.filterBy';
  static const sortMostPieces = 'jewelryFlow.sortMostPieces';
  static const sortName = 'jewelryFlow.sortName';
  static const housesNoMatch = 'jewelryFlow.housesNoMatch';
  static const housesEmpty = 'jewelryFlow.housesEmpty';
  static const housesEmptyBody = 'jewelryFlow.housesEmptyBody';
  static const housesError = 'jewelryFlow.housesError';
  static const shopAll = 'jewelryFlow.shopAll';
  static const dragToTurn = 'jewelryFlow.dragToTurn';
  static const collectionsTitle = 'jewelryFlow.collectionsTitle';
  static const collectionsSubtitle = 'jewelryFlow.collectionsSubtitle';
  static const styleCount = 'jewelryFlow.styleCount';
  static const styleOne = 'jewelryFlow.styleOne';
  static const stylesTitle = 'jewelryFlow.stylesTitle';
  static const stylesSubtitle = 'jewelryFlow.stylesSubtitle';
  static const metalsTitle = 'jewelryFlow.metalsTitle';
  static const metalsSubtitle = 'jewelryFlow.metalsSubtitle';
  static const rings = 'jewelryFlow.rings';
  static const earrings = 'jewelryFlow.earrings';
  static const necklaces = 'jewelryFlow.necklaces';
  static const bracelets = 'jewelryFlow.bracelets';

  // Results
  static const results = 'jewelryFlow.results';
  static const sortTitle = 'jewelryFlow.sortTitle';
  static const sortFeatured = 'jewelryFlow.sortFeatured';
  static const sortNewest = 'jewelryFlow.sortNewest';
  static const allStyles = 'jewelryFlow.allStyles';

  // Filters
  static const sectionStyle = 'jewelryFlow.sectionStyle';
  static const sectionPrice = 'jewelryFlow.sectionPrice';
  static const sectionMetal = 'jewelryFlow.sectionMetal';
  static const sectionStone = 'jewelryFlow.sectionStone';
  static const sectionSize = 'jewelryFlow.sectionSize';
  static const sectionQuality = 'jewelryFlow.sectionQuality';

  // Detail
  static const configureTitle = 'jewelryFlow.configureTitle';
  static const configureIntro = 'jewelryFlow.configureIntro';
  static const size = 'jewelryFlow.size';
  static const inclTaxes = 'jewelryFlow.inclTaxes';
  static const priceOnRequest = 'jewelryFlow.priceOnRequest';
  static const sku = 'jewelryFlow.sku';
  static const lineTotal = 'jewelryFlow.lineTotal';
  static const tabCare = 'jewelryFlow.tabCare';
  static const aboutPiece = 'jewelryFlow.aboutPiece';
  static const readMore = 'jewelryFlow.readMore';
  static const readLess = 'jewelryFlow.readLess';
  static const productInfo = 'jewelryFlow.productInfo';
  static const productSummary = 'jewelryFlow.productSummary';
  static const priceBreakup = 'jewelryFlow.priceBreakup';
  static const metalDetails = 'jewelryFlow.metalDetails';
  static const diamondDetails = 'jewelryFlow.diamondDetails';
  static const stoneNumber = 'jewelryFlow.stoneNumber';
  static const material = 'jewelryFlow.material';
  static const category = 'jewelryFlow.category';
  static const style = 'jewelryFlow.style';
  static const styleNo = 'jewelryFlow.styleNo';
  static const totalWeight = 'jewelryFlow.totalWeight';
  static const diamond = 'jewelryFlow.diamond';
  static const makingCharges = 'jewelryFlow.makingCharges';
  static const discount = 'jewelryFlow.discount';
  static const grandTotal = 'jewelryFlow.grandTotal';
  static const mrp = 'jewelryFlow.mrp';
  static const centerType = 'jewelryFlow.centerType';
  static const setting = 'jewelryFlow.setting';
  static const careTitle = 'jewelryFlow.careTitle';
  static const careStore = 'jewelryFlow.careStore';
  static const careClean = 'jewelryFlow.careClean';
  static const careAvoid = 'jewelryFlow.careAvoid';
  static const careRemove = 'jewelryFlow.careRemove';
  static const serviceTitle = 'jewelryFlow.serviceTitle';
  static const serviceBody = 'jewelryFlow.serviceBody';
}

const jewelryFlowMessages = <String, LocalizedMessage>{
  JewelryFlowL10n.houseEyebrow: LocalizedMessage(
    english: 'Jewelry houses',
    hindi: 'ज्वेलरी हाउस',
    gujarati: 'જ્વેલરી હાઉસ',
  ),
  JewelryFlowL10n.housesHeadline: LocalizedMessage(
    english: 'The houses\nbehind the pieces.',
    hindi: 'हर पीस के पीछे\nके हाउस।',
    gujarati: 'દરેક પીસ પાછળના\nહાઉસ.',
  ),
  JewelryFlowL10n.housesIntro: LocalizedMessage(
    english: '{count} independent jewellers — tap a house to see its pieces.',
    hindi: '{count} स्वतंत्र जौहरी — किसी हाउस के पीस देखने के लिए टैप करें।',
    gujarati: '{count} સ્વતંત્ર ઝવેરીઓ — હાઉસના પીસ જોવા ટેપ કરો.',
  ),
  JewelryFlowL10n.featuredHouses: LocalizedMessage(
    english: 'Featured houses',
    hindi: 'विशेष हाउस',
    gujarati: 'વિશેષ હાઉસ',
  ),
  JewelryFlowL10n.allHouses: LocalizedMessage(
    english: 'All houses',
    hindi: 'सभी हाउस',
    gujarati: 'બધા હાઉસ',
  ),
  JewelryFlowL10n.housesCount: LocalizedMessage(
    english: '{count} houses',
    hindi: '{count} हाउस',
    gujarati: '{count} હાઉસ',
  ),
  JewelryFlowL10n.showAllHouses: LocalizedMessage(
    english: 'Show all houses',
    hindi: 'सभी हाउस देखें',
    gujarati: 'બધા હાઉસ જુઓ',
  ),
  JewelryFlowL10n.sortBy: LocalizedMessage(
    english: 'Sort by',
    hindi: 'क्रमबद्ध करें',
    gujarati: 'ક્રમ',
  ),
  JewelryFlowL10n.filterBy: LocalizedMessage(
    english: 'Filter by',
    hindi: 'फ़िल्टर करें',
    gujarati: 'ફિલ્ટર',
  ),
  JewelryFlowL10n.sortMostPieces: LocalizedMessage(
    english: 'Most pieces',
    hindi: 'सबसे ज़्यादा पीस',
    gujarati: 'સૌથી વધુ પીસ',
  ),
  JewelryFlowL10n.sortName: LocalizedMessage(
    english: 'Name A–Z',
    hindi: 'नाम A–Z',
    gujarati: 'નામ A–Z',
  ),
  JewelryFlowL10n.housesNoMatch: LocalizedMessage(
    english: 'No houses match these filters',
    hindi: 'इन फ़िल्टर से कोई हाउस मेल नहीं खाता',
    gujarati: 'આ ફિલ્ટર સાથે કોઈ હાઉસ મેળ ખાતું નથી',
  ),
  JewelryFlowL10n.housesEmpty: LocalizedMessage(
    english: 'No houses yet',
    hindi: 'अभी कोई हाउस नहीं',
    gujarati: 'હજી કોઈ હાઉસ નથી',
  ),
  JewelryFlowL10n.housesEmptyBody: LocalizedMessage(
    english: 'New jewellers are joining soon.',
    hindi: 'नए जौहरी जल्द जुड़ रहे हैं।',
    gujarati: 'નવા ઝવેરીઓ જલ્દી જોડાઈ રહ્યા છે.',
  ),
  JewelryFlowL10n.housesError: LocalizedMessage(
    english: 'Jewelry houses could not load.',
    hindi: 'ज्वेलरी हाउस लोड नहीं हो सके।',
    gujarati: 'જ્વેલરી હાઉસ લોડ ન થયા.',
  ),
  JewelryFlowL10n.shopAll: LocalizedMessage(
    english: 'Shop all jewelry',
    hindi: 'सभी ज्वेलरी देखें',
    gujarati: 'બધી જ્વેલરી જુઓ',
  ),
  JewelryFlowL10n.dragToTurn: LocalizedMessage(
    english: 'Drag to turn',
    hindi: 'घुमाने के लिए खींचें',
    gujarati: 'ફેરવવા માટે ખેંચો',
  ),
  JewelryFlowL10n.collectionsTitle: LocalizedMessage(
    english: 'Collections',
    hindi: 'कलेक्शन',
    gujarati: 'કલેક્શન',
  ),
  JewelryFlowL10n.collectionsSubtitle: LocalizedMessage(
    english: 'Every category, one tap away',
    hindi: 'हर श्रेणी, बस एक टैप पर',
    gujarati: 'દરેક શ્રેણી, માત્ર એક ટેપ પર',
  ),
  JewelryFlowL10n.styleCount: LocalizedMessage(
    english: '{count} styles',
    hindi: '{count} स्टाइल',
    gujarati: '{count} સ્ટાઇલ',
  ),
  JewelryFlowL10n.styleOne: LocalizedMessage(
    english: '1 style',
    hindi: '1 स्टाइल',
    gujarati: '1 સ્ટાઇલ',
  ),
  JewelryFlowL10n.stylesTitle: LocalizedMessage(
    english: 'Popular styles',
    hindi: 'लोकप्रिय स्टाइल',
    gujarati: 'લોકપ્રિય સ્ટાઇલ',
  ),
  JewelryFlowL10n.stylesSubtitle: LocalizedMessage(
    english: 'Jump straight to a silhouette',
    hindi: 'सीधे अपनी पसंद की डिज़ाइन पर जाएँ',
    gujarati: 'સીધા તમારી પસંદની ડિઝાઇન પર જાઓ',
  ),
  JewelryFlowL10n.metalsTitle: LocalizedMessage(
    english: 'Shop by metal',
    hindi: 'धातु से खरीदें',
    gujarati: 'ધાતુ પ્રમાણે ખરીદો',
  ),
  JewelryFlowL10n.metalsSubtitle: LocalizedMessage(
    english: 'Find the tone that suits you',
    hindi: 'अपने लिए सही रंगत चुनें',
    gujarati: 'તમને શોભે તેવો રંગ પસંદ કરો',
  ),
  JewelryFlowL10n.rings: LocalizedMessage(
    english: 'Rings',
    hindi: 'अंगूठियाँ',
    gujarati: 'વીંટીઓ',
  ),
  JewelryFlowL10n.earrings: LocalizedMessage(
    english: 'Earrings',
    hindi: 'झुमके',
    gujarati: 'કાનની બુટ્ટીઓ',
  ),
  JewelryFlowL10n.necklaces: LocalizedMessage(
    english: 'Necklaces',
    hindi: 'हार',
    gujarati: 'હાર',
  ),
  JewelryFlowL10n.bracelets: LocalizedMessage(
    english: 'Bracelets',
    hindi: 'ब्रेसलेट',
    gujarati: 'બ્રેસલેટ',
  ),
  JewelryFlowL10n.results: LocalizedMessage(
    english: '{count} pieces',
    hindi: '{count} पीस',
    gujarati: '{count} પીસ',
  ),
  JewelryFlowL10n.sortTitle: LocalizedMessage(
    english: 'Sort jewelry',
    hindi: 'ज्वेलरी क्रमबद्ध करें',
    gujarati: 'જ્વેલરી ક્રમમાં ગોઠવો',
  ),
  JewelryFlowL10n.sortFeatured: LocalizedMessage(
    english: 'Featured',
    hindi: 'विशेष',
    gujarati: 'વિશેષ',
  ),
  JewelryFlowL10n.sortNewest: LocalizedMessage(
    english: 'Newest',
    hindi: 'नवीनतम',
    gujarati: 'નવીનતમ',
  ),
  JewelryFlowL10n.allStyles: LocalizedMessage(
    english: 'All styles',
    hindi: 'सभी स्टाइल',
    gujarati: 'બધી સ્ટાઇલ',
  ),
  JewelryFlowL10n.sectionStyle: LocalizedMessage(
    english: 'Style & occasion',
    hindi: 'स्टाइल और अवसर',
    gujarati: 'સ્ટાઇલ અને પ્રસંગ',
  ),
  JewelryFlowL10n.sectionPrice: LocalizedMessage(
    english: 'Budget',
    hindi: 'बजट',
    gujarati: 'બજેટ',
  ),
  JewelryFlowL10n.sectionMetal: LocalizedMessage(
    english: 'Metal',
    hindi: 'धातु',
    gujarati: 'ધાતુ',
  ),
  JewelryFlowL10n.sectionStone: LocalizedMessage(
    english: 'Stones',
    hindi: 'पत्थर',
    gujarati: 'પથ્થર',
  ),
  JewelryFlowL10n.sectionSize: LocalizedMessage(
    english: 'Size & fit',
    hindi: 'साइज़ और फिट',
    gujarati: 'સાઇઝ અને ફિટ',
  ),
  JewelryFlowL10n.sectionQuality: LocalizedMessage(
    english: 'Quality',
    hindi: 'गुणवत्ता',
    gujarati: 'ગુણવત્તા',
  ),
  JewelryFlowL10n.configureTitle: LocalizedMessage(
    english: 'Make it yours',
    hindi: 'इसे अपना बनाएँ',
    gujarati: 'તેને તમારું બનાવો',
  ),
  JewelryFlowL10n.configureIntro: LocalizedMessage(
    english:
        'Choose purity, size and stone weight — the price updates '
        'instantly.',
    hindi: 'शुद्धता, साइज़ और स्टोन वज़न चुनें — कीमत तुरंत बदलती है।',
    gujarati: 'શુદ્ધતા, સાઇઝ અને સ્ટોન વજન પસંદ કરો — કિંમત તરત બદલાય છે.',
  ),
  JewelryFlowL10n.size: LocalizedMessage(
    english: 'Size',
    hindi: 'साइज़',
    gujarati: 'સાઇઝ',
  ),
  JewelryFlowL10n.inclTaxes: LocalizedMessage(
    english: 'Inclusive of all taxes and charges',
    hindi: 'सभी करों और शुल्कों सहित',
    gujarati: 'તમામ કર અને શુલ્ક સહિત',
  ),
  JewelryFlowL10n.priceOnRequest: LocalizedMessage(
    english: 'Price on request',
    hindi: 'अनुरोध पर मूल्य',
    gujarati: 'વિનંતી પર કિંમત',
  ),
  JewelryFlowL10n.sku: LocalizedMessage(
    english: 'SKU {sku}',
    hindi: 'SKU {sku}',
    gujarati: 'SKU {sku}',
  ),
  JewelryFlowL10n.lineTotal: LocalizedMessage(
    english: '{count} × {price}',
    hindi: '{count} × {price}',
    gujarati: '{count} × {price}',
  ),
  JewelryFlowL10n.tabCare: LocalizedMessage(
    english: 'Care',
    hindi: 'देखभाल',
    gujarati: 'સંભાળ',
  ),
  JewelryFlowL10n.aboutPiece: LocalizedMessage(
    english: 'About this piece',
    hindi: 'इस पीस के बारे में',
    gujarati: 'આ પીસ વિશે',
  ),
  JewelryFlowL10n.readMore: LocalizedMessage(
    english: 'Read more',
    hindi: 'और पढ़ें',
    gujarati: 'વધુ વાંચો',
  ),
  JewelryFlowL10n.readLess: LocalizedMessage(
    english: 'Read less',
    hindi: 'कम पढ़ें',
    gujarati: 'ઓછું વાંચો',
  ),
  JewelryFlowL10n.productInfo: LocalizedMessage(
    english: 'Product info',
    hindi: 'उत्पाद जानकारी',
    gujarati: 'પ્રોડક્ટ માહિતી',
  ),
  JewelryFlowL10n.productSummary: LocalizedMessage(
    english: 'Product summary',
    hindi: 'उत्पाद सारांश',
    gujarati: 'પ્રોડક્ટ સારાંશ',
  ),
  JewelryFlowL10n.priceBreakup: LocalizedMessage(
    english: 'Price breakup',
    hindi: 'मूल्य विवरण',
    gujarati: 'કિંમત વિગત',
  ),
  JewelryFlowL10n.metalDetails: LocalizedMessage(
    english: 'Metal details',
    hindi: 'धातु विवरण',
    gujarati: 'ધાતુ વિગતો',
  ),
  JewelryFlowL10n.diamondDetails: LocalizedMessage(
    english: 'Diamond details',
    hindi: 'हीरे का विवरण',
    gujarati: 'હીરાની વિગતો',
  ),
  JewelryFlowL10n.stoneNumber: LocalizedMessage(
    english: 'Stone {n}',
    hindi: 'पत्थर {n}',
    gujarati: 'પથ્થર {n}',
  ),
  JewelryFlowL10n.material: LocalizedMessage(
    english: 'Material',
    hindi: 'सामग्री',
    gujarati: 'સામગ્રી',
  ),
  JewelryFlowL10n.category: LocalizedMessage(
    english: 'Category',
    hindi: 'श्रेणी',
    gujarati: 'શ્રેણી',
  ),
  JewelryFlowL10n.style: LocalizedMessage(
    english: 'Style',
    hindi: 'स्टाइल',
    gujarati: 'સ્ટાઇલ',
  ),
  JewelryFlowL10n.styleNo: LocalizedMessage(
    english: 'Style no.',
    hindi: 'स्टाइल नं.',
    gujarati: 'સ્ટાઇલ નં.',
  ),
  JewelryFlowL10n.totalWeight: LocalizedMessage(
    english: 'Total weight',
    hindi: 'कुल वज़न',
    gujarati: 'કુલ વજન',
  ),
  JewelryFlowL10n.diamond: LocalizedMessage(
    english: 'Diamond',
    hindi: 'हीरा',
    gujarati: 'હીરો',
  ),
  JewelryFlowL10n.makingCharges: LocalizedMessage(
    english: 'Making charges',
    hindi: 'मेकिंग चार्ज',
    gujarati: 'મેકિંગ ચાર્જ',
  ),
  JewelryFlowL10n.discount: LocalizedMessage(
    english: 'Discount',
    hindi: 'छूट',
    gujarati: 'ડિસ્કાઉન્ટ',
  ),
  JewelryFlowL10n.grandTotal: LocalizedMessage(
    english: 'Grand total',
    hindi: 'कुल योग',
    gujarati: 'કુલ રકમ',
  ),
  JewelryFlowL10n.mrp: LocalizedMessage(
    english: 'MRP',
    hindi: 'एमआरपी',
    gujarati: 'એમઆરપી',
  ),
  JewelryFlowL10n.centerType: LocalizedMessage(
    english: 'Center type',
    hindi: 'सेंटर प्रकार',
    gujarati: 'સેન્ટર પ્રકાર',
  ),
  JewelryFlowL10n.setting: LocalizedMessage(
    english: 'Setting',
    hindi: 'सेटिंग',
    gujarati: 'સેટિંગ',
  ),
  JewelryFlowL10n.careTitle: LocalizedMessage(
    english: 'Care instructions',
    hindi: 'देखभाल निर्देश',
    gujarati: 'સંભાળની સૂચનાઓ',
  ),
  JewelryFlowL10n.careStore: LocalizedMessage(
    english:
        'Store in a soft cloth pouch or jewelry box to prevent '
        'scratches',
    hindi:
        'खरोंच से बचाने के लिए मुलायम कपड़े की थैली या ज्वेलरी बॉक्स '
        'में रखें',
    gujarati: 'ઘસરકાથી બચાવવા નરમ કાપડની થેલી કે જ્વેલરી બોક્સમાં રાખો',
  ),
  JewelryFlowL10n.careClean: LocalizedMessage(
    english: 'Clean with a soft, dry cloth after each wear',
    hindi: 'हर बार पहनने के बाद मुलायम, सूखे कपड़े से साफ़ करें',
    gujarati: 'દરેક વખત પહેર્યા પછી નરમ, સૂકા કપડાથી સાફ કરો',
  ),
  JewelryFlowL10n.careAvoid: LocalizedMessage(
    english: 'Avoid contact with perfumes, lotions and cleaning agents',
    hindi: 'परफ़्यूम, लोशन और सफ़ाई के रसायनों के संपर्क से बचें',
    gujarati: 'પરફ્યુમ, લોશન અને સફાઈના રસાયણોના સંપર્કથી બચો',
  ),
  JewelryFlowL10n.careRemove: LocalizedMessage(
    english: 'Remove before swimming, exercising or showering',
    hindi: 'तैराकी, व्यायाम या नहाने से पहले उतार दें',
    gujarati: 'તરવા, કસરત કે નહાતા પહેલાં ઉતારી દો',
  ),
  JewelryFlowL10n.serviceTitle: LocalizedMessage(
    english: 'Professional service',
    hindi: 'पेशेवर सेवा',
    gujarati: 'વ્યાવસાયિક સેવા',
  ),
  JewelryFlowL10n.serviceBody: LocalizedMessage(
    english:
        'For deep cleaning and maintenance, visit our store or contact '
        'customer service to schedule professional jewelry cleaning and '
        'inspection.',
    hindi:
        'गहरी सफ़ाई और रखरखाव के लिए हमारे स्टोर पर आएँ या पेशेवर '
        'ज्वेलरी सफ़ाई और जाँच के लिए ग्राहक सेवा से संपर्क करें।',
    gujarati:
        'ઊંડી સફાઈ અને જાળવણી માટે અમારા સ્ટોરની મુલાકાત લો અથવા '
        'વ્યાવસાયિક જ્વેલરી સફાઈ અને તપાસ માટે ગ્રાહક સેવાનો સંપર્ક કરો.',
  ),
};
