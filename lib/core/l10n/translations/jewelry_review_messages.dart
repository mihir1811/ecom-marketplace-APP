import '../localized_message.dart';

/// Copy for jewellery piece reviews: the order screen prompt, the review
/// form, the product / shop review lists and the shop's own review list.
abstract final class JewelryReviewL10n {
  // Order screen
  static const howIsIt = 'jewelryReview.howIsIt';
  static const writeReview = 'jewelryReview.writeReview';
  static const yourReview = 'jewelryReview.yourReview';
  static const edit = 'jewelryReview.edit';
  static const canChangeUntil = 'jewelryReview.canChangeUntil';
  static const hiddenNotice = 'jewelryReview.hiddenNotice';
  static const hiddenNoticeBare = 'jewelryReview.hiddenNoticeBare';
  static const replyFrom = 'jewelryReview.replyFrom';
  static const edited = 'jewelryReview.edited';

  // Form
  static const formTitle = 'jewelryReview.formTitle';
  static const formEditTitle = 'jewelryReview.formEditTitle';
  static const yourRating = 'jewelryReview.yourRating';
  static const chooseStars = 'jewelryReview.chooseStars';
  static const headline = 'jewelryReview.headline';
  static const body = 'jewelryReview.body';
  static const bodyHint = 'jewelryReview.bodyHint';
  static const photos = 'jewelryReview.photos';
  static const addPhoto = 'jewelryReview.addPhoto';
  static const takePhoto = 'jewelryReview.takePhoto';
  static const choosePhoto = 'jewelryReview.choosePhoto';
  static const photoTooBig = 'jewelryReview.photoTooBig';
  static const photoType = 'jewelryReview.photoType';
  static const photosMax = 'jewelryReview.photosMax';
  static const photosUnavailable = 'jewelryReview.photosUnavailable';
  static const post = 'jewelryReview.post';
  static const save = 'jewelryReview.save';
  static const posted = 'jewelryReview.posted';
  static const updated = 'jewelryReview.updated';
  static const star1 = 'jewelryReview.star1';
  static const star2 = 'jewelryReview.star2';
  static const star3 = 'jewelryReview.star3';
  static const star4 = 'jewelryReview.star4';
  static const star5 = 'jewelryReview.star5';

  // Public lists
  static const title = 'jewelryReview.title';
  static const countOne = 'jewelryReview.countOne';
  static const countMany = 'jewelryReview.countMany';
  static const received = 'jewelryReview.received';
  static const sortNewest = 'jewelryReview.sortNewest';
  static const sortHighest = 'jewelryReview.sortHighest';
  static const sortLowest = 'jewelryReview.sortLowest';
  static const showMore = 'jewelryReview.showMore';
  static const filtered = 'jewelryReview.filtered';
  static const clearFilter = 'jewelryReview.clearFilter';
  static const noneForFilter = 'jewelryReview.noneForFilter';
  static const loadError = 'jewelryReview.loadError';

  // Shop's list
  static const showAll = 'jewelryReview.showAll';
  static const showUnanswered = 'jewelryReview.showUnanswered';
  static const showHidden = 'jewelryReview.showHidden';
  static const reply = 'jewelryReview.reply';
  static const editReply = 'jewelryReview.editReply';
  static const removeReply = 'jewelryReview.removeReply';
  static const removeReplyBody = 'jewelryReview.removeReplyBody';
  static const replyHint = 'jewelryReview.replyHint';
  static const replyPosted = 'jewelryReview.replyPosted';
  static const replyRemoved = 'jewelryReview.replyRemoved';
  static const yourReply = 'jewelryReview.yourReply';
  static const order = 'jewelryReview.order';
  static const sellerEmpty = 'jewelryReview.sellerEmpty';
  static const sellerEmptyBody = 'jewelryReview.sellerEmptyBody';
  static const sellerUnavailable = 'jewelryReview.sellerUnavailable';
  static const hiddenBy = 'jewelryReview.hiddenBy';
  static const cancel = 'jewelryReview.cancel';
  static const remove = 'jewelryReview.remove';
}

const Map<String, LocalizedMessage> jewelryReviewMessages = {
  JewelryReviewL10n.howIsIt: LocalizedMessage(
    english: 'How is it?',
    hindi: 'यह कैसा है?',
    gujarati: 'આ કેવું છે?',
  ),
  JewelryReviewL10n.writeReview: LocalizedMessage(
    english: 'Write a review',
    hindi: 'रिव्यू लिखें',
    gujarati: 'રિવ્યૂ લખો',
  ),
  JewelryReviewL10n.yourReview: LocalizedMessage(
    english: 'Your review',
    hindi: 'आपका रिव्यू',
    gujarati: 'તમારો રિવ્યૂ',
  ),
  JewelryReviewL10n.edit: LocalizedMessage(
    english: 'Edit',
    hindi: 'बदलें',
    gujarati: 'બદલો',
  ),
  JewelryReviewL10n.canChangeUntil: LocalizedMessage(
    english: 'You can change it until {date}',
    hindi: 'आप इसे {date} तक बदल सकते हैं',
    gujarati: 'તમે તેને {date} સુધી બદલી શકો છો',
  ),
  JewelryReviewL10n.hiddenNotice: LocalizedMessage(
    english: 'GemWorld hid this review: {reason}',
    hindi: 'GemWorld ने यह रिव्यू छिपाया: {reason}',
    gujarati: 'GemWorld એ આ રિવ્યૂ છુપાવ્યો: {reason}',
  ),
  JewelryReviewL10n.hiddenNoticeBare: LocalizedMessage(
    english: 'GemWorld hid this review.',
    hindi: 'GemWorld ने यह रिव्यू छिपाया।',
    gujarati: 'GemWorld એ આ રિવ્યૂ છુપાવ્યો.',
  ),
  JewelryReviewL10n.replyFrom: LocalizedMessage(
    english: 'Reply from {shop}',
    hindi: '{shop} का जवाब',
    gujarati: '{shop} નો જવાબ',
  ),
  JewelryReviewL10n.edited: LocalizedMessage(
    english: 'Edited',
    hindi: 'बदला गया',
    gujarati: 'બદલાયેલ',
  ),
  JewelryReviewL10n.formTitle: LocalizedMessage(
    english: 'Review this piece',
    hindi: 'इस पीस का रिव्यू करें',
    gujarati: 'આ પીસનો રિવ્યૂ કરો',
  ),
  JewelryReviewL10n.formEditTitle: LocalizedMessage(
    english: 'Edit your review',
    hindi: 'अपना रिव्यू बदलें',
    gujarati: 'તમારો રિવ્યૂ બદલો',
  ),
  JewelryReviewL10n.yourRating: LocalizedMessage(
    english: 'Your rating',
    hindi: 'आपकी रेटिंग',
    gujarati: 'તમારું રેટિંગ',
  ),
  JewelryReviewL10n.chooseStars: LocalizedMessage(
    english: 'Choose 1 to 5 stars.',
    hindi: '1 से 5 स्टार चुनें।',
    gujarati: '1 થી 5 સ્ટાર પસંદ કરો.',
  ),
  JewelryReviewL10n.headline: LocalizedMessage(
    english: 'Headline (optional)',
    hindi: 'शीर्षक (वैकल्पिक)',
    gujarati: 'શીર્ષક (વૈકલ્પિક)',
  ),
  JewelryReviewL10n.body: LocalizedMessage(
    english: 'Your review (optional)',
    hindi: 'आपका रिव्यू (वैकल्पिक)',
    gujarati: 'તમારો રિવ્યૂ (વૈકલ્પિક)',
  ),
  JewelryReviewL10n.bodyHint: LocalizedMessage(
    english: 'What do you love about it? How does it fit?',
    hindi: 'इसमें आपको क्या पसंद है? यह कैसा फ़िट होता है?',
    gujarati: 'તમને તેમાં શું ગમે છે? તે કેવું ફિટ થાય છે?',
  ),
  JewelryReviewL10n.photos: LocalizedMessage(
    english: 'Photos ({count}/4)',
    hindi: 'फ़ोटो ({count}/4)',
    gujarati: 'ફોટા ({count}/4)',
  ),
  JewelryReviewL10n.addPhoto: LocalizedMessage(
    english: 'Add photo',
    hindi: 'फ़ोटो जोड़ें',
    gujarati: 'ફોટો ઉમેરો',
  ),
  JewelryReviewL10n.takePhoto: LocalizedMessage(
    english: 'Take a photo',
    hindi: 'फ़ोटो खींचें',
    gujarati: 'ફોટો પાડો',
  ),
  JewelryReviewL10n.choosePhoto: LocalizedMessage(
    english: 'Choose from gallery',
    hindi: 'गैलरी से चुनें',
    gujarati: 'ગેલેરીમાંથી પસંદ કરો',
  ),
  JewelryReviewL10n.photoTooBig: LocalizedMessage(
    english: 'Each photo must be 10 MB or smaller.',
    hindi: 'हर फ़ोटो 10 MB या उससे छोटी होनी चाहिए।',
    gujarati: 'દરેક ફોટો 10 MB કે તેથી નાનો હોવો જોઈએ.',
  ),
  JewelryReviewL10n.photoType: LocalizedMessage(
    english: 'Photos must be JPG, PNG or WebP images.',
    hindi: 'फ़ोटो JPG, PNG या WebP होनी चाहिए।',
    gujarati: 'ફોટા JPG, PNG અથવા WebP હોવા જોઈએ.',
  ),
  JewelryReviewL10n.photosMax: LocalizedMessage(
    english: 'A review can have up to 4 photos.',
    hindi: 'एक रिव्यू में 4 फ़ोटो तक हो सकती हैं।',
    gujarati: 'એક રિવ્યૂમાં 4 ફોટા સુધી હોઈ શકે.',
  ),
  JewelryReviewL10n.photosUnavailable: LocalizedMessage(
    english: "Couldn't open your photos.",
    hindi: 'आपकी फ़ोटो नहीं खुल सकीं।',
    gujarati: 'તમારા ફોટા ખોલી શકાયા નથી.',
  ),
  JewelryReviewL10n.post: LocalizedMessage(
    english: 'Post review',
    hindi: 'रिव्यू पोस्ट करें',
    gujarati: 'રિવ્યૂ પોસ્ટ કરો',
  ),
  JewelryReviewL10n.save: LocalizedMessage(
    english: 'Save changes',
    hindi: 'बदलाव सेव करें',
    gujarati: 'ફેરફાર સેવ કરો',
  ),
  JewelryReviewL10n.posted: LocalizedMessage(
    english: 'Thank you! Your review is live.',
    hindi: 'धन्यवाद! आपका रिव्यू लाइव है।',
    gujarati: 'આભાર! તમારો રિવ્યૂ લાઇવ છે.',
  ),
  JewelryReviewL10n.updated: LocalizedMessage(
    english: 'Your review is updated.',
    hindi: 'आपका रिव्यू अपडेट हो गया।',
    gujarati: 'તમારો રિવ્યૂ અપડેટ થયો.',
  ),
  JewelryReviewL10n.star1: LocalizedMessage(
    english: 'Poor',
    hindi: 'खराब',
    gujarati: 'ખરાબ',
  ),
  JewelryReviewL10n.star2: LocalizedMessage(
    english: 'Fair',
    hindi: 'ठीक-ठाक',
    gujarati: 'ઠીકઠાક',
  ),
  JewelryReviewL10n.star3: LocalizedMessage(
    english: 'Good',
    hindi: 'अच्छा',
    gujarati: 'સારું',
  ),
  JewelryReviewL10n.star4: LocalizedMessage(
    english: 'Very good',
    hindi: 'बहुत अच्छा',
    gujarati: 'ખૂબ સારું',
  ),
  JewelryReviewL10n.star5: LocalizedMessage(
    english: 'Excellent',
    hindi: 'शानदार',
    gujarati: 'ઉત્તમ',
  ),
  JewelryReviewL10n.title: LocalizedMessage(
    english: 'Reviews',
    hindi: 'रिव्यू',
    gujarati: 'રિવ્યૂ',
  ),
  JewelryReviewL10n.countOne: LocalizedMessage(
    english: '1 review',
    hindi: '1 रिव्यू',
    gujarati: '1 રિવ્યૂ',
  ),
  JewelryReviewL10n.countMany: LocalizedMessage(
    english: '{count} reviews',
    hindi: '{count} रिव्यू',
    gujarati: '{count} રિવ્યૂ',
  ),
  JewelryReviewL10n.received: LocalizedMessage(
    english: 'Bought and received it',
    hindi: 'खरीदा और प्राप्त किया',
    gujarati: 'ખરીદ્યું અને મળ્યું',
  ),
  JewelryReviewL10n.sortNewest: LocalizedMessage(
    english: 'Newest',
    hindi: 'नए पहले',
    gujarati: 'નવા પહેલા',
  ),
  JewelryReviewL10n.sortHighest: LocalizedMessage(
    english: 'Highest rated',
    hindi: 'सबसे ऊँची रेटिंग',
    gujarati: 'સૌથી ઊંચું રેટિંગ',
  ),
  JewelryReviewL10n.sortLowest: LocalizedMessage(
    english: 'Lowest rated',
    hindi: 'सबसे कम रेटिंग',
    gujarati: 'સૌથી ઓછું રેટિંગ',
  ),
  JewelryReviewL10n.showMore: LocalizedMessage(
    english: 'Show more',
    hindi: 'और दिखाएँ',
    gujarati: 'વધુ બતાવો',
  ),
  JewelryReviewL10n.filtered: LocalizedMessage(
    english: '{stars}-star reviews',
    hindi: '{stars}-स्टार रिव्यू',
    gujarati: '{stars}-સ્ટાર રિવ્યૂ',
  ),
  JewelryReviewL10n.clearFilter: LocalizedMessage(
    english: 'Show all',
    hindi: 'सभी दिखाएँ',
    gujarati: 'બધા બતાવો',
  ),
  JewelryReviewL10n.noneForFilter: LocalizedMessage(
    english: 'No reviews here yet.',
    hindi: 'यहाँ अभी कोई रिव्यू नहीं।',
    gujarati: 'અહીં હજી કોઈ રિવ્યૂ નથી.',
  ),
  JewelryReviewL10n.loadError: LocalizedMessage(
    english: "Couldn't load reviews",
    hindi: 'रिव्यू लोड नहीं हो सके',
    gujarati: 'રિવ્યૂ લોડ થઈ શક્યા નથી',
  ),
  JewelryReviewL10n.showAll: LocalizedMessage(
    english: 'All',
    hindi: 'सभी',
    gujarati: 'બધા',
  ),
  JewelryReviewL10n.showUnanswered: LocalizedMessage(
    english: 'To answer',
    hindi: 'जवाब बाकी',
    gujarati: 'જવાબ બાકી',
  ),
  JewelryReviewL10n.showHidden: LocalizedMessage(
    english: 'Hidden',
    hindi: 'छिपे हुए',
    gujarati: 'છુપાયેલા',
  ),
  JewelryReviewL10n.reply: LocalizedMessage(
    english: 'Reply',
    hindi: 'जवाब दें',
    gujarati: 'જવાબ આપો',
  ),
  JewelryReviewL10n.editReply: LocalizedMessage(
    english: 'Edit reply',
    hindi: 'जवाब बदलें',
    gujarati: 'જવાબ બદલો',
  ),
  JewelryReviewL10n.removeReply: LocalizedMessage(
    english: 'Remove reply',
    hindi: 'जवाब हटाएँ',
    gujarati: 'જવાબ દૂર કરો',
  ),
  JewelryReviewL10n.removeReplyBody: LocalizedMessage(
    english: 'Buyers will no longer see your reply.',
    hindi: 'खरीदार अब आपका जवाब नहीं देख पाएँगे।',
    gujarati: 'ખરીદનાર હવે તમારો જવાબ જોઈ શકશે નહીં.',
  ),
  JewelryReviewL10n.replyHint: LocalizedMessage(
    english: 'Write a public reply',
    hindi: 'सार्वजनिक जवाब लिखें',
    gujarati: 'જાહેર જવાબ લખો',
  ),
  JewelryReviewL10n.replyPosted: LocalizedMessage(
    english: 'Your reply is posted.',
    hindi: 'आपका जवाब पोस्ट हो गया।',
    gujarati: 'તમારો જવાબ પોસ્ટ થયો.',
  ),
  JewelryReviewL10n.replyRemoved: LocalizedMessage(
    english: 'Your reply is removed.',
    hindi: 'आपका जवाब हटा दिया गया।',
    gujarati: 'તમારો જવાબ દૂર થયો.',
  ),
  JewelryReviewL10n.yourReply: LocalizedMessage(
    english: 'Your reply',
    hindi: 'आपका जवाब',
    gujarati: 'તમારો જવાબ',
  ),
  JewelryReviewL10n.order: LocalizedMessage(
    english: 'Order {number}',
    hindi: 'ऑर्डर {number}',
    gujarati: 'ઓર્ડર {number}',
  ),
  JewelryReviewL10n.sellerEmpty: LocalizedMessage(
    english: 'No reviews yet',
    hindi: 'अभी कोई रिव्यू नहीं',
    gujarati: 'હજી કોઈ રિવ્યૂ નથી',
  ),
  JewelryReviewL10n.sellerEmptyBody: LocalizedMessage(
    english: 'Reviews of your pieces show here.',
    hindi: 'आपके पीस के रिव्यू यहाँ दिखते हैं।',
    gujarati: 'તમારા પીસના રિવ્યૂ અહીં દેખાય છે.',
  ),
  JewelryReviewL10n.sellerUnavailable: LocalizedMessage(
    english: "Can't open reviews",
    hindi: 'रिव्यू नहीं खुल सके',
    gujarati: 'રિવ્યૂ ખોલી શકાયા નથી',
  ),
  JewelryReviewL10n.hiddenBy: LocalizedMessage(
    english: 'Hidden by GemWorld',
    hindi: 'GemWorld द्वारा छिपाया गया',
    gujarati: 'GemWorld દ્વારા છુપાવેલ',
  ),
  JewelryReviewL10n.cancel: LocalizedMessage(
    english: 'Cancel',
    hindi: 'रद्द करें',
    gujarati: 'રદ કરો',
  ),
  JewelryReviewL10n.remove: LocalizedMessage(
    english: 'Remove',
    hindi: 'हटाएँ',
    gujarati: 'દૂર કરો',
  ),
};
