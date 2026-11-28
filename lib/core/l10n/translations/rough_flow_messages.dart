import '../localized_message.dart';

/// Copy for the rough diamond listing → filters → detail flow. Generic
/// flow copy (filters, sort, grid / list, reset, …) is shared via
/// `DiamondFlowL10n` and `CatalogL10n`.
abstract final class RoughFlowL10n {
  static const title = 'roughFlow.title';
  static const homeNote = 'roughFlow.homeNote';
  static const natural = 'roughFlow.natural';
  static const lab = 'roughFlow.lab';
  static const resultsCount = 'roughFlow.resultsCount';
  static const searchHint = 'roughFlow.searchHint';
  static const emptyTitle = 'roughFlow.emptyTitle';
  static const emptyBody = 'roughFlow.emptyBody';
  static const errorTitle = 'roughFlow.errorTitle';
  static const sortTitle = 'roughFlow.sortTitle';
  static const sortArrivals = 'roughFlow.sortArrivals';
  static const sortPrice = 'roughFlow.sortPrice';
  static const sortPpc = 'roughFlow.sortPpc';
  static const sortCarat = 'roughFlow.sortCarat';
  static const newest = 'roughFlow.newest';
  static const oldest = 'roughFlow.oldest';
  static const lowToHigh = 'roughFlow.lowToHigh';
  static const highToLow = 'roughFlow.highToLow';

  // Filter sections.
  static const sectionCrystal = 'roughFlow.section.crystal';
  static const sectionSizePrice = 'roughFlow.section.sizePrice';
  static const sectionColorClarity = 'roughFlow.section.colorClarity';
  static const sectionQuality = 'roughFlow.section.quality';
  static const sectionParcel = 'roughFlow.section.parcel';
  static const sectionOrigin = 'roughFlow.section.origin';
  static const sectionListing = 'roughFlow.section.listing';

  // Filter groups (list keys of the search body).
  static const crystalShape = 'roughFlow.f.crystalShape';
  static const crystalCondition = 'roughFlow.f.crystalCondition';
  static const transparency = 'roughFlow.f.transparency';
  static const surfaceCondition = 'roughFlow.f.surfaceCondition';
  static const growthType = 'roughFlow.f.growthType';
  static const colorGrades = 'roughFlow.f.colorGrades';
  static const colorWords = 'roughFlow.f.colorWords';
  static const clarityGrades = 'roughFlow.f.clarityGrades';
  static const clarityWords = 'roughFlow.f.clarityWords';
  static const colorDistribution = 'roughFlow.f.colorDistribution';
  static const fluorescence = 'roughFlow.f.fluorescence';
  static const roughQuality = 'roughFlow.f.roughQuality';
  static const manufacturingPotential = 'roughFlow.f.manufacturingPotential';
  static const compositionType = 'roughFlow.f.compositionType';
  static const parcelType = 'roughFlow.f.parcelType';
  static const sieveSizes = 'roughFlow.f.sieveSizes';
  static const countryOfOrigin = 'roughFlow.f.countryOfOrigin';
  static const kpStatus = 'roughFlow.f.kpStatus';
  static const deliveryTerms = 'roughFlow.f.deliveryTerms';

  // Ranges.
  static const totalCarat = 'roughFlow.r.totalCarat';
  static const avgCarat = 'roughFlow.r.avgCarat';
  static const pieces = 'roughFlow.r.pieces';
  static const totalPrice = 'roughFlow.r.totalPrice';
  static const pricePerCarat = 'roughFlow.r.pricePerCarat';
  static const yieldMin = 'roughFlow.r.yieldMin';
  static const rangeHint = 'roughFlow.r.hint';

  // Flags.
  static const separableOnly = 'roughFlow.b.separableOnly';
  static const inspectionAllowed = 'roughFlow.b.inspectionAllowed';
  static const labReportOnly = 'roughFlow.b.labReportOnly';
  static const withImages = 'roughFlow.b.withImages';
  static const withVideo = 'roughFlow.b.withVideo';
  static const makeAnOfferOnly = 'roughFlow.b.makeAnOfferOnly';
  static const onAuctionOnly = 'roughFlow.b.onAuctionOnly';
  static const noValues = 'roughFlow.noValues';

  // Detail.
  static const lotsTitle = 'roughFlow.lots.title';
  static const lotsCount = 'roughFlow.lots.count';
  static const separableNote = 'roughFlow.lots.separable';
  static const wholeOnlyNote = 'roughFlow.lots.wholeOnly';
  static const auctionLotsNote = 'roughFlow.lots.auction';
  static const leftLine = 'roughFlow.lots.left';
  static const lotSold = 'roughFlow.lots.sold';
  static const lotHeld = 'roughFlow.lots.held';
  static const selectedLine = 'roughFlow.lots.selected';
  static const clearSelection = 'roughFlow.lots.clear';
  static const selectLot = 'roughFlow.lots.selectLot';
  static const addLots = 'roughFlow.buy.addLots';
  static const addOneLot = 'roughFlow.buy.addOneLot';
  static const addParcel = 'roughFlow.buy.addParcel';
  static const pickLots = 'roughFlow.buy.pickLots';
  static const goToAuction = 'roughFlow.buy.goToAuction';
  static const auctionLive = 'roughFlow.auction.live';
  static const auctionEnds = 'roughFlow.auction.ends';
  static const notAvailable = 'roughFlow.notAvailable';
  static const goneTitle = 'roughFlow.gone';
  static const documents = 'roughFlow.documents';
  static const kpCertificate = 'roughFlow.kpCertificate';
  static const viewDocument = 'roughFlow.viewDocument';

  // Comparison.
  static const compareParcel = 'roughFlow.compare.parcel';
  static const compareParcels = 'roughFlow.compare.parcels';
  static const compareGroupParcel = 'roughFlow.compare.groupParcel';
  static const estimatedYield = 'roughFlow.compare.estimatedYield';
}

const roughFlowMessages = <String, LocalizedMessage>{
  RoughFlowL10n.title: LocalizedMessage(
    english: 'Rough Diamonds',
    hindi: 'रफ़ हीरे',
    gujarati: 'રફ હીરા',
  ),
  RoughFlowL10n.homeNote: LocalizedMessage(
    english: 'Natural and lab-grown rough, whole parcels or single lots.',
    hindi: 'प्राकृतिक और लैब-ग्रोन रफ़, पूरे पार्सल या एकल लॉट।',
    gujarati: 'કુદરતી અને લેબ-ગ્રોન રફ, આખા પાર્સલ અથવા એક લોટ.',
  ),
  RoughFlowL10n.natural: LocalizedMessage(
    english: 'Natural',
    hindi: 'प्राकृतिक',
    gujarati: 'કુદરતી',
  ),
  RoughFlowL10n.lab: LocalizedMessage(
    english: 'Lab-grown',
    hindi: 'लैब-ग्रोन',
    gujarati: 'લેબ-ગ્રોન',
  ),
  RoughFlowL10n.resultsCount: LocalizedMessage(
    english: '{count} rough parcels',
    hindi: '{count} रफ़ पार्सल',
    gujarati: '{count} રફ પાર્સલ',
  ),
  RoughFlowL10n.searchHint: LocalizedMessage(
    english: 'Search stock no., mine, shape or seller',
    hindi: 'स्टॉक नं., खदान, आकार या विक्रेता खोजें',
    gujarati: 'સ્ટોક નં., ખાણ, આકાર અથવા વિક્રેતા શોધો',
  ),
  RoughFlowL10n.emptyTitle: LocalizedMessage(
    english: 'No rough parcels match.',
    hindi: 'कोई रफ़ पार्सल मेल नहीं खाता।',
    gujarati: 'કોઈ રફ પાર્સલ મેળ ખાતું નથી.',
  ),
  RoughFlowL10n.emptyBody: LocalizedMessage(
    english: 'Try the other tab, or loosen a filter.',
    hindi: 'दूसरा टैब आज़माएँ, या कोई फ़िल्टर ढीला करें।',
    gujarati: 'બીજું ટેબ અજમાવો, અથવા કોઈ ફિલ્ટર ઓછું કરો.',
  ),
  RoughFlowL10n.errorTitle: LocalizedMessage(
    english: 'We couldn’t load rough parcels.',
    hindi: 'रफ़ पार्सल लोड नहीं हो सके।',
    gujarati: 'રફ પાર્સલ લોડ થઈ શક્યા નહીં.',
  ),
  RoughFlowL10n.sortTitle: LocalizedMessage(
    english: 'Sort rough parcels',
    hindi: 'रफ़ पार्सल क्रमबद्ध करें',
    gujarati: 'રફ પાર્સલ ગોઠવો',
  ),
  RoughFlowL10n.sortArrivals: LocalizedMessage(
    english: 'Arrivals',
    hindi: 'नए आगमन',
    gujarati: 'નવા આગમન',
  ),
  RoughFlowL10n.sortPrice: LocalizedMessage(
    english: 'Total price',
    hindi: 'कुल कीमत',
    gujarati: 'કુલ કિંમત',
  ),
  RoughFlowL10n.sortPpc: LocalizedMessage(
    english: 'Price per carat',
    hindi: 'प्रति कैरेट कीमत',
    gujarati: 'પ્રતિ કેરેટ કિંમત',
  ),
  RoughFlowL10n.sortCarat: LocalizedMessage(
    english: 'Carat weight',
    hindi: 'कैरेट वज़न',
    gujarati: 'કેરેટ વજન',
  ),
  RoughFlowL10n.newest: LocalizedMessage(
    english: 'Newest',
    hindi: 'नवीनतम',
    gujarati: 'નવીનતમ',
  ),
  RoughFlowL10n.oldest: LocalizedMessage(
    english: 'Oldest',
    hindi: 'सबसे पुराने',
    gujarati: 'સૌથી જૂના',
  ),
  RoughFlowL10n.lowToHigh: LocalizedMessage(
    english: 'Low to High',
    hindi: 'कम से ज़्यादा',
    gujarati: 'ઓછાથી વધુ',
  ),
  RoughFlowL10n.highToLow: LocalizedMessage(
    english: 'High to Low',
    hindi: 'ज़्यादा से कम',
    gujarati: 'વધુથી ઓછા',
  ),
  RoughFlowL10n.sectionCrystal: LocalizedMessage(
    english: 'Crystal',
    hindi: 'क्रिस्टल',
    gujarati: 'ક્રિસ્ટલ',
  ),
  RoughFlowL10n.sectionSizePrice: LocalizedMessage(
    english: 'Size & price',
    hindi: 'आकार और कीमत',
    gujarati: 'કદ અને કિંમત',
  ),
  RoughFlowL10n.sectionColorClarity: LocalizedMessage(
    english: 'Colour & clarity',
    hindi: 'रंग और स्पष्टता',
    gujarati: 'રંગ અને સ્પષ્ટતા',
  ),
  RoughFlowL10n.sectionQuality: LocalizedMessage(
    english: 'Quality',
    hindi: 'गुणवत्ता',
    gujarati: 'ગુણવત્તા',
  ),
  RoughFlowL10n.sectionParcel: LocalizedMessage(
    english: 'Parcel & lots',
    hindi: 'पार्सल और लॉट',
    gujarati: 'પાર્સલ અને લોટ',
  ),
  RoughFlowL10n.sectionOrigin: LocalizedMessage(
    english: 'Origin & terms',
    hindi: 'मूल और शर्तें',
    gujarati: 'મૂળ અને શરતો',
  ),
  RoughFlowL10n.sectionListing: LocalizedMessage(
    english: 'Listing',
    hindi: 'लिस्टिंग',
    gujarati: 'લિસ્ટિંગ',
  ),
  RoughFlowL10n.crystalShape: LocalizedMessage(
    english: 'Crystal shape',
    hindi: 'क्रिस्टल आकार',
    gujarati: 'ક્રિસ્ટલ આકાર',
  ),
  RoughFlowL10n.crystalCondition: LocalizedMessage(
    english: 'Crystal condition',
    hindi: 'क्रिस्टल स्थिति',
    gujarati: 'ક્રિસ્ટલ સ્થિતિ',
  ),
  RoughFlowL10n.transparency: LocalizedMessage(
    english: 'Transparency',
    hindi: 'पारदर्शिता',
    gujarati: 'પારદર્શિતા',
  ),
  RoughFlowL10n.surfaceCondition: LocalizedMessage(
    english: 'Surface',
    hindi: 'सतह',
    gujarati: 'સપાટી',
  ),
  RoughFlowL10n.growthType: LocalizedMessage(
    english: 'Growth type',
    hindi: 'ग्रोथ प्रकार',
    gujarati: 'ગ્રોથ પ્રકાર',
  ),
  RoughFlowL10n.colorGrades: LocalizedMessage(
    english: 'Colour grade (D–Z)',
    hindi: 'रंग ग्रेड (D–Z)',
    gujarati: 'રંગ ગ્રેડ (D–Z)',
  ),
  RoughFlowL10n.colorWords: LocalizedMessage(
    english: 'Colour',
    hindi: 'रंग',
    gujarati: 'રંગ',
  ),
  RoughFlowL10n.clarityGrades: LocalizedMessage(
    english: 'Clarity grade (FL–I3)',
    hindi: 'स्पष्टता ग्रेड (FL–I3)',
    gujarati: 'સ્પષ્ટતા ગ્રેડ (FL–I3)',
  ),
  RoughFlowL10n.clarityWords: LocalizedMessage(
    english: 'Clarity',
    hindi: 'स्पष्टता',
    gujarati: 'સ્પષ્ટતા',
  ),
  RoughFlowL10n.colorDistribution: LocalizedMessage(
    english: 'Colour distribution',
    hindi: 'रंग वितरण',
    gujarati: 'રંગ વિતરણ',
  ),
  RoughFlowL10n.fluorescence: LocalizedMessage(
    english: 'Fluorescence',
    hindi: 'फ़्लोरेसेंस',
    gujarati: 'ફ્લોરોસન્સ',
  ),
  RoughFlowL10n.roughQuality: LocalizedMessage(
    english: 'Rough quality',
    hindi: 'रफ़ गुणवत्ता',
    gujarati: 'રફ ગુણવત્તા',
  ),
  RoughFlowL10n.manufacturingPotential: LocalizedMessage(
    english: 'Manufacturing potential',
    hindi: 'निर्माण क्षमता',
    gujarati: 'ઉત્પાદન ક્ષમતા',
  ),
  RoughFlowL10n.compositionType: LocalizedMessage(
    english: 'Diamond type',
    hindi: 'हीरे का प्रकार',
    gujarati: 'હીરાનો પ્રકાર',
  ),
  RoughFlowL10n.parcelType: LocalizedMessage(
    english: 'Parcel type',
    hindi: 'पार्सल प्रकार',
    gujarati: 'પાર્સલ પ્રકાર',
  ),
  RoughFlowL10n.sieveSizes: LocalizedMessage(
    english: 'Sieve size',
    hindi: 'छलनी आकार',
    gujarati: 'ચાળણી કદ',
  ),
  RoughFlowL10n.countryOfOrigin: LocalizedMessage(
    english: 'Country of origin',
    hindi: 'मूल देश',
    gujarati: 'મૂળ દેશ',
  ),
  RoughFlowL10n.kpStatus: LocalizedMessage(
    english: 'Kimberley Process',
    hindi: 'किम्बरली प्रक्रिया',
    gujarati: 'કિમ્બર્લી પ્રક્રિયા',
  ),
  RoughFlowL10n.deliveryTerms: LocalizedMessage(
    english: 'Delivery terms',
    hindi: 'डिलीवरी शर्तें',
    gujarati: 'ડિલિવરી શરતો',
  ),
  RoughFlowL10n.totalCarat: LocalizedMessage(
    english: 'Total carat',
    hindi: 'कुल कैरेट',
    gujarati: 'કુલ કેરેટ',
  ),
  RoughFlowL10n.avgCarat: LocalizedMessage(
    english: 'Carat per piece',
    hindi: 'प्रति पीस कैरेट',
    gujarati: 'પ્રતિ પીસ કેરેટ',
  ),
  RoughFlowL10n.pieces: LocalizedMessage(
    english: 'Pieces',
    hindi: 'पीस',
    gujarati: 'પીસ',
  ),
  RoughFlowL10n.totalPrice: LocalizedMessage(
    english: 'Total price',
    hindi: 'कुल कीमत',
    gujarati: 'કુલ કિંમત',
  ),
  RoughFlowL10n.pricePerCarat: LocalizedMessage(
    english: 'Price per carat',
    hindi: 'प्रति कैरेट कीमत',
    gujarati: 'પ્રતિ કેરેટ કિંમત',
  ),
  RoughFlowL10n.yieldMin: LocalizedMessage(
    english: 'Minimum estimated yield',
    hindi: 'न्यूनतम अनुमानित यील्ड',
    gujarati: 'ન્યૂનતમ અંદાજિત યીલ્ડ',
  ),
  RoughFlowL10n.rangeHint: LocalizedMessage(
    english: 'On sale now: {min} – {max}',
    hindi: 'अभी बिक्री पर: {min} – {max}',
    gujarati: 'હાલ વેચાણમાં: {min} – {max}',
  ),
  RoughFlowL10n.separableOnly: LocalizedMessage(
    english: 'Sold by lot only',
    hindi: 'केवल लॉट में बिकने वाले',
    gujarati: 'ફક્ત લોટમાં વેચાતા',
  ),
  RoughFlowL10n.inspectionAllowed: LocalizedMessage(
    english: 'Inspection allowed',
    hindi: 'निरीक्षण की अनुमति',
    gujarati: 'નિરીક્ષણની મંજૂરી',
  ),
  RoughFlowL10n.labReportOnly: LocalizedMessage(
    english: 'With lab report',
    hindi: 'लैब रिपोर्ट सहित',
    gujarati: 'લેબ રિપોર્ટ સાથે',
  ),
  RoughFlowL10n.withImages: LocalizedMessage(
    english: 'With photos',
    hindi: 'फ़ोटो सहित',
    gujarati: 'ફોટા સાથે',
  ),
  RoughFlowL10n.withVideo: LocalizedMessage(
    english: 'With video',
    hindi: 'वीडियो सहित',
    gujarati: 'વિડિયો સાથે',
  ),
  RoughFlowL10n.makeAnOfferOnly: LocalizedMessage(
    english: 'Open to offers',
    hindi: 'ऑफ़र के लिए खुले',
    gujarati: 'ઑફર માટે ખુલ્લા',
  ),
  RoughFlowL10n.onAuctionOnly: LocalizedMessage(
    english: 'On auction',
    hindi: 'नीलामी में',
    gujarati: 'હરાજીમાં',
  ),
  RoughFlowL10n.noValues: LocalizedMessage(
    english: 'Nothing listed for this tab yet.',
    hindi: 'इस टैब में अभी कुछ सूचीबद्ध नहीं है।',
    gujarati: 'આ ટેબમાં હજી કંઈ સૂચિબદ્ધ નથી.',
  ),
  RoughFlowL10n.lotsTitle: LocalizedMessage(
    english: 'Lots',
    hindi: 'लॉट',
    gujarati: 'લોટ',
  ),
  RoughFlowL10n.lotsCount: LocalizedMessage(
    english: '{count} sieve lots',
    hindi: '{count} छलनी लॉट',
    gujarati: '{count} ચાળણી લોટ',
  ),
  RoughFlowL10n.separableNote: LocalizedMessage(
    english: 'Buy single lots or the whole parcel.',
    hindi: 'एकल लॉट या पूरा पार्सल खरीदें।',
    gujarati: 'એક લોટ અથવા આખું પાર્સલ ખરીદો.',
  ),
  RoughFlowL10n.wholeOnlyNote: LocalizedMessage(
    english: 'Sold as one parcel.',
    hindi: 'एक पार्सल के रूप में बिकता है।',
    gujarati: 'એક પાર્સલ તરીકે વેચાય છે.',
  ),
  RoughFlowL10n.auctionLotsNote: LocalizedMessage(
    english: 'Bids buy the whole parcel.',
    hindi: 'बोली पूरा पार्सल खरीदती है।',
    gujarati: 'બોલી આખું પાર્સલ ખરીદે છે.',
  ),
  RoughFlowL10n.leftLine: LocalizedMessage(
    english: 'Left: {carat}, {price}',
    hindi: 'शेष: {carat}, {price}',
    gujarati: 'બાકી: {carat}, {price}',
  ),
  RoughFlowL10n.lotSold: LocalizedMessage(
    english: 'Sold',
    hindi: 'बिक गया',
    gujarati: 'વેચાયું',
  ),
  RoughFlowL10n.lotHeld: LocalizedMessage(
    english: 'Held',
    hindi: 'होल्ड पर',
    gujarati: 'હોલ્ડ પર',
  ),
  RoughFlowL10n.selectedLine: LocalizedMessage(
    english: '{count} selected · {carat} · {pieces}',
    hindi: '{count} चुने गए · {carat} · {pieces}',
    gujarati: '{count} પસંદ · {carat} · {pieces}',
  ),
  RoughFlowL10n.clearSelection: LocalizedMessage(
    english: 'Clear',
    hindi: 'हटाएँ',
    gujarati: 'સાફ કરો',
  ),
  RoughFlowL10n.selectLot: LocalizedMessage(
    english: 'Select lot {size}',
    hindi: 'लॉट {size} चुनें',
    gujarati: 'લોટ {size} પસંદ કરો',
  ),
  RoughFlowL10n.addLots: LocalizedMessage(
    english: 'Add {count} lots',
    hindi: '{count} लॉट जोड़ें',
    gujarati: '{count} લોટ ઉમેરો',
  ),
  RoughFlowL10n.addOneLot: LocalizedMessage(
    english: 'Add 1 lot',
    hindi: '1 लॉट जोड़ें',
    gujarati: '1 લોટ ઉમેરો',
  ),
  RoughFlowL10n.addParcel: LocalizedMessage(
    english: 'Add whole parcel',
    hindi: 'पूरा पार्सल जोड़ें',
    gujarati: 'આખું પાર્સલ ઉમેરો',
  ),
  RoughFlowL10n.pickLots: LocalizedMessage(
    english: 'Pick lots to buy',
    hindi: 'खरीदने के लिए लॉट चुनें',
    gujarati: 'ખરીદવા માટે લોટ પસંદ કરો',
  ),
  RoughFlowL10n.goToAuction: LocalizedMessage(
    english: 'Go to auction',
    hindi: 'नीलामी पर जाएँ',
    gujarati: 'હરાજી પર જાઓ',
  ),
  RoughFlowL10n.auctionLive: LocalizedMessage(
    english: 'In a live timed auction',
    hindi: 'लाइव समयबद्ध नीलामी में',
    gujarati: 'લાઇવ સમયબદ્ધ હરાજીમાં',
  ),
  RoughFlowL10n.auctionEnds: LocalizedMessage(
    english: 'Ends {time}',
    hindi: '{time} को समाप्त',
    gujarati: '{time} એ પૂરી થશે',
  ),
  RoughFlowL10n.notAvailable: LocalizedMessage(
    english: 'Not available',
    hindi: 'उपलब्ध नहीं',
    gujarati: 'ઉપલબ્ધ નથી',
  ),
  RoughFlowL10n.goneTitle: LocalizedMessage(
    english: 'This parcel is no longer available.',
    hindi: 'यह पार्सल अब उपलब्ध नहीं है।',
    gujarati: 'આ પાર્સલ હવે ઉપલબ્ધ નથી.',
  ),
  RoughFlowL10n.documents: LocalizedMessage(
    english: 'Documents',
    hindi: 'दस्तावेज़',
    gujarati: 'દસ્તાવેજો',
  ),
  RoughFlowL10n.kpCertificate: LocalizedMessage(
    english: 'Kimberley Process certificate',
    hindi: 'किम्बरली प्रक्रिया प्रमाणपत्र',
    gujarati: 'કિમ્બર્લી પ્રક્રિયા પ્રમાણપત્ર',
  ),
  RoughFlowL10n.viewDocument: LocalizedMessage(
    english: 'View',
    hindi: 'देखें',
    gujarati: 'જુઓ',
  ),
  RoughFlowL10n.compareParcel: LocalizedMessage(
    english: 'rough parcel',
    hindi: 'रफ़ पार्सल',
    gujarati: 'રફ પાર્સલ',
  ),
  RoughFlowL10n.compareParcels: LocalizedMessage(
    english: 'rough parcels',
    hindi: 'रफ़ पार्सल',
    gujarati: 'રફ પાર્સલ',
  ),
  RoughFlowL10n.compareGroupParcel: LocalizedMessage(
    english: 'Parcel',
    hindi: 'पार्सल',
    gujarati: 'પાર્સલ',
  ),
  RoughFlowL10n.estimatedYield: LocalizedMessage(
    english: 'Estimated yield',
    hindi: 'अनुमानित यील्ड',
    gujarati: 'અંદાજિત યીલ્ડ',
  ),
};
