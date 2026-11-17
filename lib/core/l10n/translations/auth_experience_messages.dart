import '../localized_message.dart';

/// Stable localization keys for the authentication experience.
abstract final class AuthL10n {
  static const welcomeTitle = 'auth.x.welcomeTitle';
  static const usernameOrEmail = 'auth.x.usernameOrEmail';
  static const signIn = 'auth.x.signIn';
  static const newHere = 'auth.x.newHere';
  static const createAccount = 'auth.x.createAccount';
  static const haveAccount = 'auth.x.haveAccount';
  static const registerTitle = 'auth.x.registerTitle';
  static const registerSubtitle = 'auth.x.registerSubtitle';
  static const sellerTitle = 'auth.x.sellerTitle';
  static const sellerSubtitle = 'auth.x.sellerSubtitle';
  static const individual = 'auth.x.individual';
  static const business = 'auth.x.business';
  static const individualHint = 'auth.x.individualHint';
  static const businessHint = 'auth.x.businessHint';
  static const sectionDetails = 'auth.x.sectionDetails';
  static const sectionSecurity = 'auth.x.sectionSecurity';
  static const referralToggle = 'auth.x.referralToggle';
  static const optional = 'auth.x.optional';
  static const required = 'auth.x.required';
  static const addPhoto = 'auth.x.addPhoto';
  static const replace = 'auth.x.replace';
  static const remove = 'auth.x.remove';
  static const tapToUpload = 'auth.x.tapToUpload';
  static const profilePhoto = 'auth.x.profilePhoto';
  static const back = 'auth.x.back';
  static const continueAction = 'auth.x.continue';
  static const createSellerAccount = 'auth.x.createSellerAccount';
  static const pwRule8 = 'auth.x.pwRule8';
  static const pwRuleUpper = 'auth.x.pwRuleUpper';
  static const pwRuleLower = 'auth.x.pwRuleLower';
  static const pwRuleNumber = 'auth.x.pwRuleNumber';
  static const pwRuleSymbol = 'auth.x.pwRuleSymbol';
  static const pwWeak = 'auth.x.pwWeak';
  static const pwFair = 'auth.x.pwFair';
  static const pwGood = 'auth.x.pwGood';
  static const pwStrong = 'auth.x.pwStrong';
  static const passwordsMatch = 'auth.x.passwordsMatch';
  static const otpTitle = 'auth.x.otpTitle';
  static const verify = 'auth.x.verify';
  static const resendIn = 'auth.x.resendIn';
  static const noCode = 'auth.x.noCode';
  static const resendCode = 'auth.x.resendCode';
  static const otpFieldLabel = 'auth.x.otpFieldLabel';
  static const forgotTitle = 'auth.x.forgotTitle';
  static const sendLink = 'auth.x.sendLink';
  static const inboxTitle = 'auth.x.inboxTitle';
  static const inboxBody = 'auth.x.inboxBody';
  static const useDifferentEmail = 'auth.x.useDifferentEmail';
  static const resendLink = 'auth.x.resendLink';
  static const resetTitle = 'auth.x.resetTitle';
  static const updatePassword = 'auth.x.updatePassword';
  static const linkInvalidTitle = 'auth.x.linkInvalidTitle';
  static const requestNewLink = 'auth.x.requestNewLink';
  static const passwordUpdated = 'auth.x.passwordUpdated';
  static const recoverTitle = 'auth.x.recoverTitle';
  static const recoverAction = 'auth.x.recoverAction';
  static const recoverWindow = 'auth.x.recoverWindow';
  static const recoverWindowBody = 'auth.x.recoverWindowBody';
  static const useToken = 'auth.x.useToken';
  static const useCredentials = 'auth.x.useCredentials';
  static const paste = 'auth.x.paste';
  static const showcaseTitle = 'auth.x.showcaseTitle';
  static const showcaseBody = 'auth.x.showcaseBody';
  static const trustVerified = 'auth.x.trustVerified';
  static const trustCertified = 'auth.x.trustCertified';
  static const trustSecure = 'auth.x.trustSecure';
  static const dismiss = 'auth.x.dismiss';
  static const gemLabel = 'auth.x.gemLabel';
  static const pleaseWait = 'auth.x.pleaseWait';
  static const stepAddress = 'auth.x.stepAddress';
  static const stepHintBasic = 'auth.x.stepHintBasic';
  static const stepHintCompany = 'auth.x.stepHintCompany';
  static const stepHintAddress = 'auth.x.stepHintAddress';
  static const stepHintKyc = 'auth.x.stepHintKyc';
  static const stepHintBank = 'auth.x.stepHintBank';
  static const companyLogo = 'auth.x.companyLogo';
  static const companyLogoHint = 'auth.x.companyLogoHint';
  static const bannerImage = 'auth.x.bannerImage';
  static const bannerImageHint = 'auth.x.bannerImageHint';
  static const panCardImage = 'auth.x.panCardImage';
  static const panCardImageHint = 'auth.x.panCardImageHint';
  static const sectionContacts = 'auth.x.sectionContacts';
  static const sectionIdentity = 'auth.x.sectionIdentity';
  static const sectionPayouts = 'auth.x.sectionPayouts';
  static const accountNumberDigits = 'auth.x.accountNumberDigits';
  static const fixHighlighted = 'auth.x.fixHighlighted';
  static const signedIn = 'auth.x.signedIn';
}

const authExperienceMessages = <String, LocalizedMessage>{
  AuthL10n.welcomeTitle: LocalizedMessage(
    english: 'Welcome back',
    hindi: 'फिर से स्वागत है',
    gujarati: 'ફરી સ્વાગત છે',
  ),
  AuthL10n.usernameOrEmail: LocalizedMessage(
    english: 'Username or email',
    hindi: 'यूज़रनेम या ईमेल',
    gujarati: 'યુઝરનેમ અથવા ઇમેઇલ',
  ),
  AuthL10n.signIn: LocalizedMessage(
    english: 'Sign in',
    hindi: 'साइन इन करें',
    gujarati: 'સાઇન ઇન કરો',
  ),
  AuthL10n.newHere: LocalizedMessage(
    english: 'New to GemWorld?',
    hindi: 'GemWorld पर नए हैं?',
    gujarati: 'GemWorld પર નવા છો?',
  ),
  AuthL10n.createAccount: LocalizedMessage(
    english: 'Create an account',
    hindi: 'खाता बनाएँ',
    gujarati: 'એકાઉન્ટ બનાવો',
  ),
  AuthL10n.haveAccount: LocalizedMessage(
    english: 'Already have an account?',
    hindi: 'क्या पहले से खाता है?',
    gujarati: 'પહેલેથી એકાઉન્ટ છે?',
  ),
  AuthL10n.registerTitle: LocalizedMessage(
    english: 'Create your account',
    hindi: 'अपना खाता बनाएँ',
    gujarati: 'તમારું એકાઉન્ટ બનાવો',
  ),
  AuthL10n.registerSubtitle: LocalizedMessage(
    english: 'Diamonds, gemstones and fine jewellery from verified sellers.',
    hindi: 'सत्यापित विक्रेताओं से हीरे, रत्न और बेहतरीन ज्वेलरी।',
    gujarati: 'ચકાસાયેલ વિક્રેતાઓ પાસેથી હીરા, રત્નો અને ઉત્તમ જ્વેલરી.',
  ),
  AuthL10n.sellerTitle: LocalizedMessage(
    english: 'Sell on GemWorld',
    hindi: 'GemWorld पर बेचें',
    gujarati: 'GemWorld પર વેચો',
  ),
  AuthL10n.sellerSubtitle: LocalizedMessage(
    english: 'Set up a verified business account in five short steps.',
    hindi: 'पाँच आसान चरणों में सत्यापित बिज़नेस खाता बनाएँ।',
    gujarati: 'પાંચ સરળ પગલાંમાં ચકાસાયેલ બિઝનેસ એકાઉન્ટ બનાવો.',
  ),
  AuthL10n.individual: LocalizedMessage(
    english: 'Buyer',
    hindi: 'खरीदार',
    gujarati: 'ખરીદનાર',
  ),
  AuthL10n.business: LocalizedMessage(
    english: 'Seller',
    hindi: 'विक्रेता',
    gujarati: 'વિક્રેતા',
  ),
  AuthL10n.individualHint: LocalizedMessage(
    english:
        'Individual buyer account to browse and shop. Individuals cannot sell — sellers must register a business account.',
    hindi:
        'ब्राउज़ और खरीदारी के लिए व्यक्तिगत खरीदार खाता। व्यक्तिगत खाते से बेचा नहीं जा सकता — विक्रेताओं को बिज़नेस खाता बनाना होगा।',
    gujarati:
        'બ્રાઉઝ અને ખરીદી માટે વ્યક્તિગત ખરીદનાર એકાઉન્ટ. વ્યક્તિગત એકાઉન્ટથી વેચાણ થઈ શકતું નથી — વિક્રેતાઓએ બિઝનેસ એકાઉન્ટ બનાવવું પડશે.',
  ),
  AuthL10n.businessHint: LocalizedMessage(
    english:
        'Sellers register as a business only. Company, KYC and bank details are required.',
    hindi:
        'विक्रेता केवल बिज़नेस के रूप में रजिस्टर करते हैं। कंपनी, KYC और बैंक विवरण ज़रूरी हैं।',
    gujarati:
        'વિક્રેતાઓ ફક્ત બિઝનેસ તરીકે નોંધણી કરે છે. કંપની, KYC અને બેંક વિગતો જરૂરી છે.',
  ),
  AuthL10n.sectionDetails: LocalizedMessage(
    english: 'Your details',
    hindi: 'आपकी जानकारी',
    gujarati: 'તમારી વિગતો',
  ),
  AuthL10n.sectionSecurity: LocalizedMessage(
    english: 'Security',
    hindi: 'सुरक्षा',
    gujarati: 'સુરક્ષા',
  ),
  AuthL10n.referralToggle: LocalizedMessage(
    english: 'Have a referral?',
    hindi: 'क्या आपके पास रेफ़रल है?',
    gujarati: 'શું તમારી પાસે રેફરલ છે?',
  ),
  AuthL10n.optional: LocalizedMessage(
    english: 'Optional',
    hindi: 'वैकल्पिक',
    gujarati: 'વૈકલ્પિક',
  ),
  AuthL10n.required: LocalizedMessage(
    english: 'Required',
    hindi: 'ज़रूरी',
    gujarati: 'જરૂરી',
  ),
  AuthL10n.addPhoto: LocalizedMessage(
    english: 'Add photo',
    hindi: 'फ़ोटो जोड़ें',
    gujarati: 'ફોટો ઉમેરો',
  ),
  AuthL10n.replace: LocalizedMessage(
    english: 'Replace',
    hindi: 'बदलें',
    gujarati: 'બદલો',
  ),
  AuthL10n.remove: LocalizedMessage(
    english: 'Remove',
    hindi: 'हटाएँ',
    gujarati: 'દૂર કરો',
  ),
  AuthL10n.tapToUpload: LocalizedMessage(
    english: 'Tap to upload',
    hindi: 'अपलोड करने के लिए टैप करें',
    gujarati: 'અપલોડ કરવા ટેપ કરો',
  ),
  AuthL10n.profilePhoto: LocalizedMessage(
    english: 'Profile photo',
    hindi: 'प्रोफ़ाइल फ़ोटो',
    gujarati: 'પ્રોફાઇલ ફોટો',
  ),
  AuthL10n.back: LocalizedMessage(
    english: 'Back',
    hindi: 'वापस',
    gujarati: 'પાછા',
  ),
  AuthL10n.continueAction: LocalizedMessage(
    english: 'Continue',
    hindi: 'जारी रखें',
    gujarati: 'ચાલુ રાખો',
  ),
  AuthL10n.createSellerAccount: LocalizedMessage(
    english: 'Create seller account',
    hindi: 'विक्रेता खाता बनाएँ',
    gujarati: 'વિક્રેતા એકાઉન્ટ બનાવો',
  ),
  AuthL10n.pwRule8: LocalizedMessage(
    english: '8+ characters',
    hindi: '8+ अक्षर',
    gujarati: '8+ અક્ષરો',
  ),
  AuthL10n.pwRuleUpper: LocalizedMessage(
    english: 'Uppercase',
    hindi: 'बड़ा अक्षर',
    gujarati: 'મોટો અક્ષર',
  ),
  AuthL10n.pwRuleLower: LocalizedMessage(
    english: 'Lowercase',
    hindi: 'छोटा अक्षर',
    gujarati: 'નાનો અક્ષર',
  ),
  AuthL10n.pwRuleNumber: LocalizedMessage(
    english: 'Number',
    hindi: 'अंक',
    gujarati: 'અંક',
  ),
  AuthL10n.pwRuleSymbol: LocalizedMessage(
    english: 'Symbol',
    hindi: 'चिह्न',
    gujarati: 'ચિહ્ન',
  ),
  AuthL10n.pwWeak: LocalizedMessage(
    english: 'Weak',
    hindi: 'कमज़ोर',
    gujarati: 'નબળો',
  ),
  AuthL10n.pwFair: LocalizedMessage(
    english: 'Fair',
    hindi: 'ठीक-ठाक',
    gujarati: 'ઠીક',
  ),
  AuthL10n.pwGood: LocalizedMessage(
    english: 'Good',
    hindi: 'अच्छा',
    gujarati: 'સારો',
  ),
  AuthL10n.pwStrong: LocalizedMessage(
    english: 'Strong',
    hindi: 'मज़बूत',
    gujarati: 'મજબૂત',
  ),
  AuthL10n.passwordsMatch: LocalizedMessage(
    english: 'Passwords match',
    hindi: 'पासवर्ड मेल खाते हैं',
    gujarati: 'પાસવર્ડ મેળ ખાય છે',
  ),
  AuthL10n.otpTitle: LocalizedMessage(
    english: 'Check your email',
    hindi: 'अपना ईमेल देखें',
    gujarati: 'તમારું ઇમેઇલ તપાસો',
  ),
  AuthL10n.verify: LocalizedMessage(
    english: 'Verify',
    hindi: 'सत्यापित करें',
    gujarati: 'ચકાસો',
  ),
  AuthL10n.resendIn: LocalizedMessage(
    english: 'Resend code in {time}',
    hindi: '{time} में कोड फिर से भेजें',
    gujarati: '{time} માં કોડ ફરી મોકલો',
  ),
  AuthL10n.noCode: LocalizedMessage(
    english: "Didn't get the code?",
    hindi: 'कोड नहीं मिला?',
    gujarati: 'કોડ મળ્યો નથી?',
  ),
  AuthL10n.resendCode: LocalizedMessage(
    english: 'Resend code',
    hindi: 'कोड फिर से भेजें',
    gujarati: 'કોડ ફરી મોકલો',
  ),
  AuthL10n.otpFieldLabel: LocalizedMessage(
    english: '6-digit verification code',
    hindi: '6 अंकों का सत्यापन कोड',
    gujarati: '6 અંકનો ચકાસણી કોડ',
  ),
  AuthL10n.forgotTitle: LocalizedMessage(
    english: 'Forgot your password?',
    hindi: 'पासवर्ड भूल गए?',
    gujarati: 'પાસવર્ડ ભૂલી ગયા?',
  ),
  AuthL10n.sendLink: LocalizedMessage(
    english: 'Send reset link',
    hindi: 'रीसेट लिंक भेजें',
    gujarati: 'રીસેટ લિંક મોકલો',
  ),
  AuthL10n.inboxTitle: LocalizedMessage(
    english: 'Check your inbox',
    hindi: 'अपना इनबॉक्स देखें',
    gujarati: 'તમારું ઇનબોક્સ તપાસો',
  ),
  AuthL10n.inboxBody: LocalizedMessage(
    english: 'We sent a password reset link to {email}.',
    hindi: 'हमने {email} पर पासवर्ड रीसेट लिंक भेजा है।',
    gujarati: 'અમે {email} પર પાસવર્ડ રીસેટ લિંક મોકલી છે.',
  ),
  AuthL10n.useDifferentEmail: LocalizedMessage(
    english: 'Use a different email',
    hindi: 'दूसरा ईमेल इस्तेमाल करें',
    gujarati: 'બીજો ઇમેઇલ વાપરો',
  ),
  AuthL10n.resendLink: LocalizedMessage(
    english: 'Resend link',
    hindi: 'लिंक फिर से भेजें',
    gujarati: 'લિંક ફરી મોકલો',
  ),
  AuthL10n.resetTitle: LocalizedMessage(
    english: 'Set a new password',
    hindi: 'नया पासवर्ड सेट करें',
    gujarati: 'નવો પાસવર્ડ સેટ કરો',
  ),
  AuthL10n.updatePassword: LocalizedMessage(
    english: 'Update password',
    hindi: 'पासवर्ड अपडेट करें',
    gujarati: 'પાસવર્ડ અપડેટ કરો',
  ),
  AuthL10n.linkInvalidTitle: LocalizedMessage(
    english: "This link isn't valid",
    hindi: 'यह लिंक मान्य नहीं है',
    gujarati: 'આ લિંક માન્ય નથી',
  ),
  AuthL10n.requestNewLink: LocalizedMessage(
    english: 'Request a new link',
    hindi: 'नया लिंक मँगाएँ',
    gujarati: 'નવી લિંક મંગાવો',
  ),
  AuthL10n.passwordUpdated: LocalizedMessage(
    english: 'Password updated',
    hindi: 'पासवर्ड अपडेट हो गया',
    gujarati: 'પાસવર્ડ અપડેટ થયો',
  ),
  AuthL10n.recoverTitle: LocalizedMessage(
    english: 'Restore your account',
    hindi: 'अपना खाता वापस पाएँ',
    gujarati: 'તમારું એકાઉન્ટ પાછું મેળવો',
  ),
  AuthL10n.recoverAction: LocalizedMessage(
    english: 'Restore account',
    hindi: 'खाता वापस पाएँ',
    gujarati: 'એકાઉન્ટ પાછું મેળવો',
  ),
  AuthL10n.recoverWindow: LocalizedMessage(
    english: '7-day recovery window',
    hindi: '7 दिन की रिकवरी अवधि',
    gujarati: '7 દિવસની રિકવરી અવધિ',
  ),
  AuthL10n.recoverWindowBody: LocalizedMessage(
    english:
        'Accounts scheduled for deletion can be restored for 7 days. '
        'Use the token from your email, or your email and password.',
    hindi:
        'हटाने के लिए शेड्यूल किए गए खाते 7 दिनों तक वापस पाए जा सकते हैं। '
        'अपने ईमेल का टोकन या ईमेल और पासवर्ड इस्तेमाल करें।',
    gujarati:
        'ડિલીટ માટે શેડ્યૂલ થયેલા એકાઉન્ટ 7 દિવસ સુધી પાછા મેળવી શકાય છે. '
        'તમારા ઇમેઇલનો ટોકન અથવા ઇમેઇલ અને પાસવર્ડ વાપરો.',
  ),
  AuthL10n.useToken: LocalizedMessage(
    english: 'Email token',
    hindi: 'ईमेल टोकन',
    gujarati: 'ઇમેઇલ ટોકન',
  ),
  AuthL10n.useCredentials: LocalizedMessage(
    english: 'Email & password',
    hindi: 'ईमेल और पासवर्ड',
    gujarati: 'ઇમેઇલ અને પાસવર્ડ',
  ),
  AuthL10n.paste: LocalizedMessage(
    english: 'Paste',
    hindi: 'पेस्ट करें',
    gujarati: 'પેસ્ટ કરો',
  ),
  AuthL10n.showcaseTitle: LocalizedMessage(
    english: 'The finest stones,\nin one place.',
    hindi: 'बेहतरीन रत्न,\nएक ही जगह।',
    gujarati: 'શ્રેષ્ઠ રત્નો,\nએક જ જગ્યાએ.',
  ),
  AuthL10n.showcaseBody: LocalizedMessage(
    english:
        'Diamonds, gemstones, jewellery and watches from verified sellers.',
    hindi: 'सत्यापित विक्रेताओं से हीरे, रत्न, ज्वेलरी और घड़ियाँ।',
    gujarati: 'ચકાસાયેલ વિક્રેતાઓ પાસેથી હીરા, રત્નો, જ્વેલરી અને ઘડિયાળો.',
  ),
  AuthL10n.trustVerified: LocalizedMessage(
    english: 'Verified sellers',
    hindi: 'सत्यापित विक्रेता',
    gujarati: 'ચકાસાયેલ વિક્રેતાઓ',
  ),
  AuthL10n.trustCertified: LocalizedMessage(
    english: 'Certified stones',
    hindi: 'प्रमाणित रत्न',
    gujarati: 'પ્રમાણિત રત્નો',
  ),
  AuthL10n.trustSecure: LocalizedMessage(
    english: 'Secure checkout',
    hindi: 'सुरक्षित चेकआउट',
    gujarati: 'સુરક્ષિત ચેકઆઉટ',
  ),
  AuthL10n.dismiss: LocalizedMessage(
    english: 'Dismiss',
    hindi: 'बंद करें',
    gujarati: 'બંધ કરો',
  ),
  AuthL10n.gemLabel: LocalizedMessage(
    english: 'Rotating diamond. Drag to turn it.',
    hindi: 'घूमता हुआ हीरा। घुमाने के लिए खींचें।',
    gujarati: 'ફરતો હીરો. ફેરવવા માટે ખેંચો.',
  ),
  AuthL10n.pleaseWait: LocalizedMessage(
    english: 'Please wait',
    hindi: 'कृपया प्रतीक्षा करें',
    gujarati: 'કૃપા કરીને રાહ જુઓ',
  ),
  AuthL10n.stepAddress: LocalizedMessage(
    english: 'Business address',
    hindi: 'बिज़नेस का पता',
    gujarati: 'બિઝનેસનું સરનામું',
  ),
  AuthL10n.stepHintBasic: LocalizedMessage(
    english: 'The person who will manage this account.',
    hindi: 'वह व्यक्ति जो इस खाते को संभालेगा।',
    gujarati: 'આ એકાઉન્ટ સંભાળનાર વ્યક્તિ.',
  ),
  AuthL10n.stepHintCompany: LocalizedMessage(
    english: 'How buyers will recognise your storefront.',
    hindi: 'खरीदार आपके स्टोरफ़्रंट को कैसे पहचानेंगे।',
    gujarati: 'ખરીદદારો તમારા સ્ટોરફ્રન્ટને કેવી રીતે ઓળખશે.',
  ),
  AuthL10n.stepHintAddress: LocalizedMessage(
    english: 'Where your business is registered.',
    hindi: 'आपका बिज़नेस कहाँ रजिस्टर्ड है।',
    gujarati: 'તમારો બિઝનેસ ક્યાં રજિસ્ટર્ડ છે.',
  ),
  AuthL10n.stepHintKyc: LocalizedMessage(
    english: 'Contacts and identity documents for verification.',
    hindi: 'सत्यापन के लिए संपर्क और पहचान दस्तावेज़।',
    gujarati: 'ચકાસણી માટે સંપર્કો અને ઓળખ દસ્તાવેજો.',
  ),
  AuthL10n.stepHintBank: LocalizedMessage(
    english: 'Where your payouts will be sent.',
    hindi: 'आपके भुगतान कहाँ भेजे जाएँगे।',
    gujarati: 'તમારી ચુકવણી ક્યાં મોકલાશે.',
  ),
  AuthL10n.companyLogo: LocalizedMessage(
    english: 'Company logo',
    hindi: 'कंपनी का लोगो',
    gujarati: 'કંપનીનો લોગો',
  ),
  AuthL10n.companyLogoHint: LocalizedMessage(
    english: 'Square image shown on your storefront',
    hindi: 'आपके स्टोरफ़्रंट पर दिखने वाली चौकोर इमेज',
    gujarati: 'તમારા સ્ટોરફ્રન્ટ પર દેખાતી ચોરસ છબી',
  ),
  AuthL10n.bannerImage: LocalizedMessage(
    english: 'Banner image',
    hindi: 'बैनर इमेज',
    gujarati: 'બેનર છબી',
  ),
  AuthL10n.bannerImageHint: LocalizedMessage(
    english: 'Wide image across the top of your storefront',
    hindi: 'आपके स्टोरफ़्रंट के ऊपर चौड़ी इमेज',
    gujarati: 'તમારા સ્ટોરફ્રન્ટની ટોચ પર પહોળી છબી',
  ),
  AuthL10n.panCardImage: LocalizedMessage(
    english: 'PAN card image',
    hindi: 'पैन कार्ड की इमेज',
    gujarati: 'પાન કાર્ડની છબી',
  ),
  AuthL10n.panCardImageHint: LocalizedMessage(
    english: 'A clear photo of the front of the card',
    hindi: 'कार्ड के सामने वाले हिस्से की साफ़ फ़ोटो',
    gujarati: 'કાર્ડની આગળની બાજુનો સ્પષ્ટ ફોટો',
  ),
  AuthL10n.sectionContacts: LocalizedMessage(
    english: 'Contacts',
    hindi: 'संपर्क',
    gujarati: 'સંપર્કો',
  ),
  AuthL10n.sectionIdentity: LocalizedMessage(
    english: 'Identity & tax',
    hindi: 'पहचान और टैक्स',
    gujarati: 'ઓળખ અને ટેક્સ',
  ),
  AuthL10n.sectionPayouts: LocalizedMessage(
    english: 'Payout account',
    hindi: 'भुगतान खाता',
    gujarati: 'ચુકવણી એકાઉન્ટ',
  ),
  AuthL10n.accountNumberDigits: LocalizedMessage(
    english: 'Account number must be 8–20 digits',
    hindi: 'खाता संख्या 8–20 अंकों की होनी चाहिए',
    gujarati: 'એકાઉન્ટ નંબર 8–20 અંકનો હોવો જોઈએ',
  ),
  AuthL10n.fixHighlighted: LocalizedMessage(
    english: 'Please check the highlighted fields.',
    hindi: 'कृपया हाइलाइट किए गए फ़ील्ड जाँचें।',
    gujarati: 'કૃપા કરીને હાઇલાઇટ કરેલા ફીલ્ડ તપાસો.',
  ),
  AuthL10n.signedIn: LocalizedMessage(
    english: 'Signed in',
    hindi: 'साइन इन हो गया',
    gujarati: 'સાઇન ઇન થયું',
  ),
};
