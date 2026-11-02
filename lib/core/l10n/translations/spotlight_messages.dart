import '../localized_message.dart';

/// Copy for paid placements (banners, featured sellers, sponsored rows),
/// the seller shop page and the seller's Advertising studio.
abstract final class SpotlightL10n {
  static const sponsored = 'spotlight.sponsored';
  static const view = 'spotlight.view';
  static const visitShop = 'spotlight.visitShop';
  static const featuredSellers = 'spotlight.featuredSellers';
  static const featuredPicks = 'spotlight.featuredPicks';
  static const youMayAlsoLike = 'spotlight.youMayAlsoLike';
  static const onAuction = 'spotlight.onAuction';
  static const priceOnRequest = 'spotlight.priceOnRequest';
  static const reviews = 'spotlight.reviews';
  static const shopTitle = 'spotlight.shopTitle';
  static const shopEmpty = 'spotlight.shopEmpty';
  static const shopEmptyBody = 'spotlight.shopEmptyBody';
  static const jewelleryHouse = 'spotlight.jewelleryHouse';
  static const openJewelleryHouse = 'spotlight.openJewelleryHouse';
  static const naturalDiamonds = 'spotlight.naturalDiamonds';
  static const labGrownDiamonds = 'spotlight.labGrownDiamonds';
  static const gemstones = 'spotlight.gemstones';
  static const watches = 'spotlight.watches';
  static const bullion = 'spotlight.bullion';
  static const advertising = 'spotlight.advertising';
  static const seeAll = 'spotlight.seeAll';
}

const spotlightMessages = <String, LocalizedMessage>{
  SpotlightL10n.sponsored: LocalizedMessage(
    english: 'Sponsored',
    hindi: 'प्रायोजित',
    gujarati: 'પ્રાયોજિત',
  ),
  SpotlightL10n.view: LocalizedMessage(
    english: 'View',
    hindi: 'देखें',
    gujarati: 'જુઓ',
  ),
  SpotlightL10n.visitShop: LocalizedMessage(
    english: 'Visit shop',
    hindi: 'दुकान देखें',
    gujarati: 'દુકાન જુઓ',
  ),
  SpotlightL10n.featuredSellers: LocalizedMessage(
    english: 'Featured sellers',
    hindi: 'चुनिंदा विक्रेता',
    gujarati: 'પસંદગીના વિક્રેતાઓ',
  ),
  SpotlightL10n.featuredPicks: LocalizedMessage(
    english: 'Featured picks',
    hindi: 'चुनिंदा पेशकश',
    gujarati: 'પસંદગીની રજૂઆત',
  ),
  SpotlightL10n.youMayAlsoLike: LocalizedMessage(
    english: 'You may also like',
    hindi: 'आपको यह भी पसंद आ सकता है',
    gujarati: 'તમને આ પણ ગમી શકે',
  ),
  SpotlightL10n.onAuction: LocalizedMessage(
    english: 'On auction',
    hindi: 'नीलामी में',
    gujarati: 'હરાજીમાં',
  ),
  SpotlightL10n.priceOnRequest: LocalizedMessage(
    english: 'Price on request',
    hindi: 'अनुरोध पर मूल्य',
    gujarati: 'વિનંતી પર કિંમત',
  ),
  SpotlightL10n.reviews: LocalizedMessage(
    english: '{count} reviews',
    hindi: '{count} समीक्षाएँ',
    gujarati: '{count} સમીક્ષાઓ',
  ),
  SpotlightL10n.shopTitle: LocalizedMessage(
    english: 'Shop',
    hindi: 'दुकान',
    gujarati: 'દુકાન',
  ),
  SpotlightL10n.shopEmpty: LocalizedMessage(
    english: 'Nothing listed right now',
    hindi: 'अभी कुछ सूचीबद्ध नहीं है',
    gujarati: 'હમણાં કંઈ સૂચિબદ્ધ નથી',
  ),
  SpotlightL10n.shopEmptyBody: LocalizedMessage(
    english: 'This seller has no pieces for sale at the moment.',
    hindi: 'इस विक्रेता के पास अभी बिक्री के लिए कुछ नहीं है।',
    gujarati: 'આ વિક્રેતા પાસે હમણાં વેચાણ માટે કંઈ નથી.',
  ),
  SpotlightL10n.jewelleryHouse: LocalizedMessage(
    english: 'Jewellery house',
    hindi: 'आभूषण घराना',
    gujarati: 'આભૂષણ ગૃહ',
  ),
  SpotlightL10n.openJewelleryHouse: LocalizedMessage(
    english: 'Open jewellery house',
    hindi: 'आभूषण घराना खोलें',
    gujarati: 'આભૂષણ ગૃહ ખોલો',
  ),
  SpotlightL10n.naturalDiamonds: LocalizedMessage(
    english: 'Natural diamonds',
    hindi: 'प्राकृतिक हीरे',
    gujarati: 'કુદરતી હીરા',
  ),
  SpotlightL10n.labGrownDiamonds: LocalizedMessage(
    english: 'Lab-grown diamonds',
    hindi: 'लैब-ग्रोन हीरे',
    gujarati: 'લેબ-ગ્રોન હીરા',
  ),
  SpotlightL10n.gemstones: LocalizedMessage(
    english: 'Gemstones',
    hindi: 'रत्न',
    gujarati: 'રત્નો',
  ),
  SpotlightL10n.watches: LocalizedMessage(
    english: 'Watches',
    hindi: 'घड़ियाँ',
    gujarati: 'ઘડિયાળો',
  ),
  SpotlightL10n.bullion: LocalizedMessage(
    english: 'Bullion',
    hindi: 'बुलियन',
    gujarati: 'બુલિયન',
  ),
  SpotlightL10n.advertising: LocalizedMessage(
    english: 'Advertising',
    hindi: 'विज्ञापन',
    gujarati: 'જાહેરાત',
  ),
  SpotlightL10n.seeAll: LocalizedMessage(
    english: 'See all',
    hindi: 'सभी देखें',
    gujarati: 'બધું જુઓ',
  ),
};
