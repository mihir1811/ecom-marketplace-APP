import '../localized_message.dart';

/// Stable localization keys shared across the application.
abstract final class CoreL10n {
  static const appTitle = 'core.appTitle';
  static const language = 'core.language';
  static const english = 'core.language.english';
  static const hindi = 'core.language.hindi';
  static const gujarati = 'core.language.gujarati';
  static const selectLanguage = 'core.language.select';
  static const changeLanguage = 'core.language.change';
  static const cancel = 'core.action.cancel';
  static const close = 'core.action.close';
  static const retry = 'core.action.retry';
  static const delete = 'core.action.delete';
  static const submit = 'core.action.submit';
  static const save = 'core.action.save';
  static const copy = 'core.action.copy';
  static const cart = 'core.nav.cart';
  static const wallet = 'core.nav.wallet';
  static const messages = 'core.nav.messages';
  static const menu = 'core.nav.menu';
  static const appearance = 'core.settings.appearance';
  static const account = 'core.settings.account';
  static const settings = 'core.settings.title';
  static const darkTheme = 'core.settings.darkTheme';
  static const darkThemeDescription = 'core.settings.darkThemeDescription';
  static const paletteDescription = 'core.settings.paletteDescription';
  static const switchToLightMode = 'core.theme.switchToLight';
  static const switchToDarkMode = 'core.theme.switchToDark';
  static const somethingWentWrong = 'core.error.somethingWentWrong';
  static const unexpectedError = 'core.error.unexpectedError';
  static const exitAppTitle = 'core.exit.title';
  static const exitAppBody = 'core.exit.body';
  static const exitAppConfirm = 'core.exit.confirm';
}

const coreMessages = <String, LocalizedMessage>{
  CoreL10n.appTitle: LocalizedMessage(
    english: 'GemWorld Diamond Marketplace',
    hindi: 'जेमवर्ल्ड डायमंड मार्केटप्लेस',
    gujarati: 'જેમવર્લ્ડ ડાયમંડ માર્કેટપ્લેસ',
  ),
  CoreL10n.language: LocalizedMessage(
    english: 'Language',
    hindi: 'भाषा',
    gujarati: 'ભાષા',
  ),
  CoreL10n.english: LocalizedMessage(
    english: 'English',
    hindi: 'English',
    gujarati: 'English',
  ),
  CoreL10n.hindi: LocalizedMessage(
    english: 'हिन्दी',
    hindi: 'हिन्दी',
    gujarati: 'हिन्दी',
  ),
  CoreL10n.gujarati: LocalizedMessage(
    english: 'ગુજરાતી',
    hindi: 'ગુજરાતી',
    gujarati: 'ગુજરાતી',
  ),
  CoreL10n.selectLanguage: LocalizedMessage(
    english: 'Select language',
    hindi: 'भाषा चुनें',
    gujarati: 'ભાષા પસંદ કરો',
  ),
  CoreL10n.changeLanguage: LocalizedMessage(
    english: 'Change language',
    hindi: 'भाषा बदलें',
    gujarati: 'ભાષા બદલો',
  ),
  CoreL10n.cancel: LocalizedMessage(
    english: 'Cancel',
    hindi: 'रद्द करें',
    gujarati: 'રદ કરો',
  ),
  CoreL10n.close: LocalizedMessage(
    english: 'Close',
    hindi: 'बंद करें',
    gujarati: 'બંધ કરો',
  ),
  CoreL10n.retry: LocalizedMessage(
    english: 'Retry',
    hindi: 'फिर कोशिश करें',
    gujarati: 'ફરી પ્રયાસ કરો',
  ),
  CoreL10n.delete: LocalizedMessage(
    english: 'Delete',
    hindi: 'हटाएँ',
    gujarati: 'કાઢી નાખો',
  ),
  CoreL10n.submit: LocalizedMessage(
    english: 'Submit',
    hindi: 'जमा करें',
    gujarati: 'સબમિટ કરો',
  ),
  CoreL10n.save: LocalizedMessage(
    english: 'Save',
    hindi: 'सहेजें',
    gujarati: 'સાચવો',
  ),
  CoreL10n.copy: LocalizedMessage(
    english: 'Copy',
    hindi: 'कॉपी करें',
    gujarati: 'કૉપિ કરો',
  ),
  CoreL10n.cart: LocalizedMessage(
    english: 'Cart',
    hindi: 'कार्ट',
    gujarati: 'કાર્ટ',
  ),
  CoreL10n.wallet: LocalizedMessage(
    english: 'Wallet',
    hindi: 'वॉलेट',
    gujarati: 'વૉલેટ',
  ),
  CoreL10n.messages: LocalizedMessage(
    english: 'Messages',
    hindi: 'संदेश',
    gujarati: 'સંદેશા',
  ),
  CoreL10n.menu: LocalizedMessage(
    english: 'Menu',
    hindi: 'मेन्यू',
    gujarati: 'મેનૂ',
  ),
  CoreL10n.appearance: LocalizedMessage(
    english: 'Appearance',
    hindi: 'दिखावट',
    gujarati: 'દેખાવ',
  ),
  CoreL10n.account: LocalizedMessage(
    english: 'Account',
    hindi: 'खाता',
    gujarati: 'ખાતું',
  ),
  CoreL10n.settings: LocalizedMessage(
    english: 'Settings',
    hindi: 'सेटिंग्स',
    gujarati: 'સેટિંગ્સ',
  ),
  CoreL10n.darkTheme: LocalizedMessage(
    english: 'Dark theme',
    hindi: 'डार्क थीम',
    gujarati: 'ડાર્ક થીમ',
  ),
  CoreL10n.darkThemeDescription: LocalizedMessage(
    english: 'Enables dark mode across the app.',
    hindi: 'पूरे ऐप में डार्क मोड चालू करता है।',
    gujarati: 'સમગ્ર ઍપમાં ડાર્ક મોડ ચાલુ કરે છે.',
  ),
  CoreL10n.paletteDescription: LocalizedMessage(
    english: 'Your palette colours every screen and is remembered next time.',
    hindi: 'आपका पैलेट हर स्क्रीन पर लागू होता है और अगली बार भी याद रहता है।',
    gujarati:
        'તમારી પેલેટ દરેક સ્ક્રીન પર લાગુ થાય છે અને આગલી વખતે પણ યાદ રહે છે.',
  ),
  CoreL10n.switchToLightMode: LocalizedMessage(
    english: 'Switch to light mode',
    hindi: 'लाइट मोड पर जाएँ',
    gujarati: 'લાઇટ મોડ પર જાઓ',
  ),
  CoreL10n.switchToDarkMode: LocalizedMessage(
    english: 'Switch to dark mode',
    hindi: 'डार्क मोड पर जाएँ',
    gujarati: 'ડાર્ક મોડ પર જાઓ',
  ),
  CoreL10n.somethingWentWrong: LocalizedMessage(
    english: 'Something went wrong.',
    hindi: 'कुछ गलत हो गया।',
    gujarati: 'કંઈક ખોટું થયું.',
  ),
  CoreL10n.unexpectedError: LocalizedMessage(
    english:
        'An unexpected error occurred. Please reload or restart the application.',
    hindi: 'एक अनपेक्षित त्रुटि हुई। कृपया ऐप को फिर से लोड या पुनः शुरू करें।',
    gujarati: 'અણધારી ભૂલ આવી. કૃપા કરીને ઍપ ફરી લોડ કરો અથવા ફરી શરૂ કરો.',
  ),
  CoreL10n.exitAppTitle: LocalizedMessage(
    english: 'Exit app?',
    hindi: 'ऐप बंद करें?',
    gujarati: 'ઍપ બંધ કરો?',
  ),
  CoreL10n.exitAppBody: LocalizedMessage(
    english: 'Are you sure you want to exit the app?',
    hindi: 'क्या आप वाकई ऐप से बाहर निकलना चाहते हैं?',
    gujarati: 'શું તમે ખરેખર ઍપમાંથી બહાર નીકળવા માંગો છો?',
  ),
  CoreL10n.exitAppConfirm: LocalizedMessage(
    english: 'Exit',
    hindi: 'बाहर निकलें',
    gujarati: 'બહાર નીકળો',
  ),
};
