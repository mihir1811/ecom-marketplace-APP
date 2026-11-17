import '../localized_message.dart';

/// Stable localization keys for account and commerce frontend messages.
abstract final class AccountCommerceL10n {
  static const forgotPassword = 'account.auth.forgotPassword';
  static const forgotInstructions = 'account.auth.forgotInstructions';
  static const emailRequired = 'account.validation.emailRequired';
  static const validEmail = 'account.validation.validEmail';
  static const sendResetLink = 'account.auth.sendResetLink';
  static const resetLinkSent = 'account.auth.resetLinkSent';
  static const backToLogin = 'account.auth.backToLogin';
  static const welcomeBack = 'account.auth.welcomeBack';
  static const signInToGemWorld = 'account.auth.signInToGemWorld';
  static const enterUsername = 'account.validation.enterUsername';
  static const validEmailOrUsername = 'account.validation.validEmailOrUsername';
  static const showPassword = 'account.auth.showPassword';
  static const hidePassword = 'account.auth.hidePassword';
  static const enterPassword = 'account.validation.enterPassword';
  static const passwordRequired = 'account.validation.passwordRequired';
  static const passwordMin6 = 'account.validation.passwordMin6';
  static const forgotPasswordAction = 'account.auth.forgotPasswordAction';
  static const recoverDeletedAccount = 'account.auth.recoverDeletedAccount';
  static const signIn = 'account.auth.signIn';
  static const createAccountPrompt = 'account.auth.createAccountPrompt';
  static const accountRecovered = 'account.auth.accountRecovered';
  static const recoverAccount = 'account.auth.recoverAccount';
  static const recoverInstructions = 'account.auth.recoverInstructions';
  static const emailToken = 'account.auth.emailToken';
  static const emailAndPassword = 'account.auth.emailAndPassword';
  static const recoveryToken = 'account.auth.recoveryToken';
  static const recoveryTokenRequired =
      'account.validation.recoveryTokenRequired';
  static const newAccount = 'account.auth.newAccount';
  static const sellerAccount = 'account.auth.sellerAccount';
  static const forBusinesses = 'account.auth.forBusinesses';
  static const joinGemWorld = 'account.auth.joinGemWorld';
  static const sellerRegistration = 'account.auth.sellerRegistration';
  static const register = 'account.auth.register';
  static const accountTypesSeparate = 'account.auth.accountTypesSeparate';
  static const agreeToTermsIntro = 'account.auth.agreeToTermsIntro';
  static const termsOfServiceLink = 'account.auth.termsOfServiceLink';
  static const agreeToTermsAnd = 'account.auth.agreeToTermsAnd';
  static const ethicalSourcingPolicyLink =
      'account.auth.ethicalSourcingPolicyLink';
  static const createAccount = 'account.auth.createAccount';
  static const alreadyRegistered = 'account.auth.alreadyRegistered';
  static const fullName = 'account.field.fullName';
  static const fullNameRequired = 'account.validation.fullNameRequired';
  static const dateOfBirth = 'account.field.dateOfBirth';
  static const dateOfBirthRequired = 'account.validation.dateOfBirthRequired';
  static const dateOfBirthInvalid = 'account.validation.dateOfBirthInvalid';
  static const dateOfBirthTooYoung = 'account.validation.dateOfBirthTooYoung';
  static const selectDateOfBirth = 'account.action.selectDateOfBirth';
  static const usernameRequired = 'account.validation.usernameRequired';
  static const emailAddress = 'account.field.emailAddress';
  static const referralEmail = 'account.field.referralEmail';
  static const validReferralEmail = 'account.validation.validReferralEmail';
  static const referralCode = 'account.field.referralCode';
  static const referralEmailOrCode = 'account.field.referralEmailOrCode';
  static const continueAction = 'account.action.continue';
  static const createSellerAccount = 'account.auth.createSellerAccount';
  static const individual = 'account.type.individual';
  static const individualDescription = 'account.type.individualDescription';
  static const businessDescription = 'account.type.businessDescription';
  static const resetPassword = 'account.auth.resetPassword';
  static const missingResetToken = 'account.auth.missingResetToken';
  static const chooseNewPassword = 'account.auth.chooseNewPassword';
  static const passwordResetSuccess = 'account.auth.passwordResetSuccess';
  static const goToLogin = 'account.auth.goToLogin';
  static const newPassword = 'account.field.newPassword';
  static const confirmPassword = 'account.field.confirmPassword';
  static const passwordsDoNotMatch = 'account.validation.passwordsDoNotMatch';
  static const resetPasswordAction = 'account.auth.resetPasswordAction';
  static const verifyEmail = 'account.auth.verifyEmail';
  static const enterCodeSent = 'account.auth.enterCodeSent';
  static const verifyOtp = 'account.auth.verifyOtp';
  static const enterSixDigitCode = 'account.auth.enterSixDigitCode';
  static const codeSentToEmail = 'account.auth.codeSentToEmail';
  static const enterOtp = 'account.validation.enterOtp';
  static const verifyAction = 'account.auth.verifyAction';
  static const otpSent = 'account.auth.otpSent';
  static const resendOtp = 'account.auth.resendOtp';
  static const basicDetails = 'account.registration.basicDetails';
  static const companyDetails = 'account.registration.companyDetails';
  static const contactsKyc = 'account.registration.contactsKyc';
  static const bankAccount = 'account.registration.bankAccount';
  static const companyName = 'account.field.companyName';
  static const companyNameRequired = 'account.validation.companyNameRequired';
  static const sellerType = 'account.field.sellerType';
  static const uploadCompanyLogo = 'account.field.uploadCompanyLogo';
  static const uploadBanner = 'account.field.uploadBanner';
  static const addressLine1 = 'account.field.addressLine1';
  static const addressLine2 = 'account.field.addressLine2';
  static const city = 'account.field.city';
  static const stateProvince = 'account.field.stateProvince';
  static const country = 'account.field.country';
  static const postalCode = 'account.field.postalCode';
  static const primaryPhone = 'account.field.primaryPhone';
  static const secondaryPhone = 'account.field.secondaryPhone';
  static const representative1 = 'account.field.representative1';
  static const representative2 = 'account.field.representative2';
  static const panNumber = 'account.field.panNumber';
  static const aadhaarNumber = 'account.field.aadhaarNumber';
  static const iecNumber = 'account.field.iecNumber';
  static const gstNumber = 'account.field.gstNumber';
  static const accountHolderName = 'account.field.accountHolderName';
  static const accountNumber = 'account.field.accountNumber';
  static const ifscCode = 'account.field.ifscCode';
  static const bankName = 'account.field.bankName';
  static const accountTypeOptional = 'account.field.accountTypeOptional';
  static const upiOptional = 'account.field.upiOptional';
  static const stepOf = 'account.registration.stepOf';
  static const notProvided = 'account.value.notProvided';
  static const onFile = 'account.value.onFile';
  static const required = 'account.validation.required';
  static const orders = 'commerce.orders.title';
  static const noOrders = 'commerce.orders.empty';
  static const retry = 'commerce.action.retry';
  static const itemsCount = 'commerce.items.count';
  static const itemCount = 'commerce.items.countOne';
  static const soldBy = 'commerce.seller.soldBy';
  static const orderDetails = 'commerce.order.details';
  static const orderNotFound = 'commerce.order.notFound';
  static const backToOrders = 'commerce.order.back';
  static const orderIdCopied = 'commerce.order.idCopied';
  static const copyOrderId = 'commerce.order.copyId';
  static const orderItem = 'commerce.order.item';
  static const placedOn = 'commerce.order.placed';
  static const invoiceNumber = 'commerce.order.invoice';
  static const downloadInvoice = 'commerce.order.downloadInvoice';
  static const invoiceOpenFailed = 'commerce.order.invoiceOpenFailed';
  static const quantity = 'commerce.item.quantity';
  static const orderSummary = 'commerce.order.summary';
  static const itemsSubtotal = 'commerce.price.itemsSubtotal';
  static const transactionFee = 'commerce.price.transactionFee';
  static const platformFee = 'commerce.price.platformFee';
  static const deliveryFee = 'commerce.price.deliveryFee';
  static const verificationFee = 'commerce.price.verification';
  static const myProfile = 'account.profile.myProfile';
  static const signInProfile = 'account.profile.signInRequired';
  static const personalDetails = 'account.profile.personalDetails';
  static const accountStatus = 'account.profile.accountStatus';
  static const accountType = 'account.profile.accountType';
  static const sellerBusiness = 'account.profile.sellerBusiness';
  static const individualBuyer = 'account.profile.individualBuyer';
  static const accountVerification = 'account.profile.verification';
  static const verificationPending = 'account.profile.verificationPending';
  static const noRefunds = 'commerce.refund.empty';
  static const sellerLabel = 'commerce.refund.seller';
  static const orderNumber = 'commerce.order.number';
  static const sellerNote = 'commerce.refund.sellerNote';
  static const requestedOn = 'commerce.refund.requested';
  static const refundCancelled = 'commerce.refund.cancelled';
  static const cancelRequest = 'commerce.refund.cancelRequest';
  static const requestRefund = 'commerce.refund.request';
  static const refundReasonHint = 'commerce.refund.reasonHint';
  static const refundReasonRequired = 'commerce.refund.reasonRequired';
  static const refundSubmitted = 'commerce.refund.submitted';
  static const viewRefunds = 'commerce.refund.viewMine';
  static const myReviews = 'commerce.reviews.title';
  static const reviewsLoadFailed = 'commerce.reviews.loadFailed';
  static const noReviews = 'commerce.reviews.empty';
  static const viewOrders = 'commerce.orders.view';
  static const sellerRatingReview = 'commerce.reviews.sellerRating';
  static const selectStar = 'commerce.reviews.selectStar';
  static const thanksReview = 'commerce.reviews.thanks';
  static const submitReviewFor = 'commerce.reviews.submitFor';
  static const submitReview = 'commerce.reviews.submit';
  static const helpCenter = 'account.helpCenter';
  static const aboutGemWorld = 'account.about';
  static const privacyPolicy = 'account.privacy';
  static const policiesLegal = 'account.policies';
  static const termsConditions = 'account.terms';
  static const signOut = 'account.signOut';
  static const deleteAccount = 'account.delete';
  static const deleteRecoveryWindow = 'account.delete.recoveryWindow';
  static const myWishlist = 'commerce.wishlist.title';
  static const wishlistEmpty = 'commerce.wishlist.empty';
  static const wishlistEmptyHint = 'commerce.wishlist.emptyHint';
  static const removedWishlist = 'commerce.wishlist.removed';
  static const addedWishlist = 'commerce.wishlist.added';
  static const removeWishlist = 'commerce.wishlist.remove';
  static const addWishlist = 'commerce.wishlist.add';
  static const productOpenFailed = 'commerce.product.openFailed';
  static const recentlyViewed = 'commerce.recent.title';
  static const clearRecentTitle = 'commerce.recent.clearTitle';
  static const clearRecentBody = 'commerce.recent.clearBody';
  static const clearAll = 'commerce.action.clearAll';
  static const recentCleared = 'commerce.recent.cleared';
  static const recentLoadFailed = 'commerce.recent.loadFailed';
  static const noRecent = 'commerce.recent.empty';
  static const noRecentHint = 'commerce.recent.emptyHint';
  static const loadingMore = 'commerce.list.loadingMore';
  static const untitledProduct = 'commerce.product.untitled';
  static const specsUnavailable = 'commerce.product.specsUnavailable';
  static const stockNumber = 'commerce.product.stock';
  static const viewedOn = 'commerce.product.viewed';
  static const onHold = 'commerce.availability.onHold';
  static const onMemo = 'commerce.availability.onMemo';
  static const sold = 'commerce.availability.sold';
  static const yourCart = 'commerce.cart.title';
  static const cartEmpty = 'commerce.cart.empty';
  static const continueShopping = 'commerce.action.continueShopping';
  static const deliverTo = 'commerce.address.deliverTo';
  static const noAddress = 'commerce.address.empty';
  static const savedAddresses = 'commerce.address.saved';
  static const editAddress = 'commerce.address.edit';
  static const deleteAddress = 'commerce.address.delete';
  static const addAddress = 'commerce.address.add';
  static const addressSaved = 'commerce.address.savedMessage';
  static const addressUpdated = 'commerce.address.updated';
  static const addressDeleted = 'commerce.address.deleted';
  static const deleteAddressTitle = 'commerce.address.deleteTitle';
  static const fullNameField = 'commerce.address.fullName';
  static const phone = 'commerce.address.phone';
  static const state = 'commerce.address.state';
  static const postalCodeCaps = 'commerce.address.postal';
  static const addressLabel = 'commerce.address.label';
  static const updateAddress = 'commerce.address.update';
  static const saveAddress = 'commerce.address.save';
  static const promoApplied = 'commerce.promo.applied';
  static const promoCode = 'commerce.promo.code';
  static const enterCode = 'commerce.promo.enter';
  static const automaticDiscount = 'commerce.price.automaticDiscount';
  static const promoDiscount = 'commerce.price.promoDiscount';
  static const loadingFees = 'commerce.price.loadingFees';
  static const amountToPay = 'commerce.price.amountToPay';
  static const payRazorpay = 'commerce.payment.razorpay';
  static const addDeliveryAddress = 'commerce.checkout.addAddress';
  static const removeUnavailable = 'commerce.checkout.removeUnavailable';
  static const continueCheckout = 'commerce.checkout.continue';
  static const payWallet = 'commerce.payment.wallet';
  static const paymentSuccessful = 'commerce.payment.success';
  static const orderConfirmation = 'commerce.payment.confirmation';
  static const couldNotLoadOrder = 'commerce.order.loadFailed';
  static const skipViewOrders = 'commerce.reviews.skip';
  static const compareInstruction = 'commerce.compare.instruction';
  static const goBack = 'commerce.action.goBack';
  static const compareTitle = 'commerce.compare.title';
  static const startNew = 'commerce.compare.startNew';
  static const addComparison = 'commerce.compare.add';
  static const removeComparison = 'commerce.compare.remove';
  static const addedComparison = 'commerce.compare.added';
  static const removedComparison = 'commerce.compare.removed';
  static const alreadySelected = 'commerce.compare.already';
  static const compareLimit = 'commerce.compare.limit';
  static const selectedCount = 'commerce.compare.selected';
  static const browseMore = 'commerce.compare.browseMore';
  static const newComparison = 'commerce.compare.new';
  static const reorderHint = 'commerce.compare.reorder';
  static const compareEyebrow = 'commerce.compare.eyebrow';
  static const comparePiecesOf = 'commerce.compare.piecesOf';
  static const compareAddPiece = 'commerce.compare.addPiece';
  static const compareAllSpecs = 'commerce.compare.allSpecs';
  static const compareDifferences = 'commerce.compare.differences';
  static const compareLeads = 'commerce.compare.leads';
  static const compareLegend = 'commerce.compare.legend';
  static const compareClear = 'commerce.compare.clear';
  static const compareClearTitle = 'commerce.compare.clearTitle';
  static const compareClearBody = 'commerce.compare.clearBody';
  static const compareKeep = 'commerce.compare.keep';
  static const compareViewDetails = 'commerce.compare.viewDetails';
  static const compareMoveLeft = 'commerce.compare.moveLeft';
  static const compareMoveRight = 'commerce.compare.moveRight';
  static const compareUndo = 'commerce.compare.undo';
  static const compareEmptyTitle = 'commerce.compare.emptyTitle';
  static const compareEmptyBody = 'commerce.compare.emptyBody';
  static const compareOneMore = 'commerce.compare.oneMore';
  static const compareAllIdentical = 'commerce.compare.allIdentical';
  static const compareFabEmpty = 'commerce.compare.fabEmpty';
  static const compareFabOver = 'commerce.compare.fabOver';
  static const compareFabOpen = 'commerce.compare.fabOpen';
  static const compareSwitched = 'commerce.compare.switched';
  static const compareOverLimit = 'commerce.compare.overLimit';
  static const compareSelect = 'commerce.compare.select';
  static const compareDeselect = 'commerce.compare.deselect';
  static const compareGroupEssentials = 'commerce.compare.group.essentials';
  static const compareGroupFourCs = 'commerce.compare.group.fourCs';
  static const compareGroupProportions = 'commerce.compare.group.proportions';
  static const compareGroupFinish = 'commerce.compare.group.finish';
  static const compareGroupProvenance = 'commerce.compare.group.provenance';
  static const compareGroupCharacter = 'commerce.compare.group.character';
  static const compareGroupCraft = 'commerce.compare.group.craft';
  static const compareGroupMetal = 'commerce.compare.group.metal';
  static const compareGroupStones = 'commerce.compare.group.stones';
  static const compareGroupDetails = 'commerce.compare.group.details';
  static const projectClear = 'commerce.project.clear';
  static const projectShown = 'commerce.project.shown';
  static const projectSelectedCount = 'commerce.project.selectedCount';
  static const projectSelectAll = 'commerce.project.selectAll';
  static const projectSelecting = 'commerce.project.selecting';
  static const projectLoadFailed = 'commerce.project.loadFailed';
  static const projectAnalytics = 'commerce.project.analytics';
  static const projectAnalyticsHint = 'commerce.project.analyticsHint';
  static const notAvailable = 'commerce.value.notAvailable';
  static const compareDiamond = 'commerce.category.diamond';
  static const compareDiamonds = 'commerce.category.diamonds';
  static const compareGemstone = 'commerce.category.gemstone';
  static const compareGemstones = 'commerce.category.gemstones';
  static const compareWatch = 'commerce.category.watch';
  static const compareWatches = 'commerce.category.watches';
  static const compareJewelry = 'commerce.category.jewelry';
  static const compareJewelryPieces = 'commerce.category.jewelryPieces';
  static const price = 'commerce.spec.price';
  static const caratWeight = 'commerce.spec.caratWeight';
  static const shape = 'commerce.spec.shape';
  static const measurements = 'commerce.spec.measurements';
  static const certificate = 'commerce.spec.certificate';
  static const cut = 'commerce.spec.cut';
  static const color = 'commerce.spec.color';
  static const clarity = 'commerce.spec.clarity';
  static const tablePercent = 'commerce.spec.table';
  static const depthPercent = 'commerce.spec.depth';
  static const ratio = 'commerce.spec.ratio';
  static const polish = 'commerce.spec.polish';
  static const symmetry = 'commerce.spec.symmetry';
  static const fluorescence = 'commerce.spec.fluorescence';
  static const lab = 'commerce.spec.lab';
  static const totalCarat = 'commerce.spec.totalCarat';
  static const type = 'commerce.spec.type';
  static const origin = 'commerce.spec.origin';
  static const treatment = 'commerce.spec.treatment';
  static const dimensions = 'commerce.spec.dimensions';
  static const hardness = 'commerce.spec.hardness';
  static const brand = 'commerce.spec.brand';
  static const model = 'commerce.spec.model';
  static const movement = 'commerce.spec.movement';
  static const caseMaterial = 'commerce.spec.caseMaterial';
  static const dialColor = 'commerce.spec.dialColor';
  static const gender = 'commerce.spec.gender';
  static const year = 'commerce.spec.year';
  static const uploadProfileImage = 'account.field.uploadProfileImage';
  static const termsAgreement = 'account.validation.termsAgreement';
  static const sellerIncomplete = 'account.validation.sellerIncomplete';
  static const companyLogoRequired = 'account.validation.companyLogoRequired';
  static const address1Required = 'account.validation.address1Required';
  static const address2Required = 'account.validation.address2Required';
  static const cityRequired = 'account.validation.cityRequired';
  static const stateRequired = 'account.validation.stateRequired';
  static const countryRequired = 'account.validation.countryRequired';
  static const postalRequired = 'account.validation.postalRequired';
  static const phone1Required = 'account.validation.phone1Required';
  static const phone2Required = 'account.validation.phone2Required';
  static const validPhone = 'account.validation.validPhone';
  static const rep1Required = 'account.validation.rep1Required';
  static const rep2Required = 'account.validation.rep2Required';
  static const panRequired = 'account.validation.panRequired';
  static const validPan = 'account.validation.validPan';
  static const aadhaarRequired = 'account.validation.aadhaarRequired';
  static const validAadhaar = 'account.validation.validAadhaar';
  static const iecRequired = 'account.validation.iecRequired';
  static const holderRequired = 'account.validation.holderRequired';
  static const accountNumberRequired =
      'account.validation.accountNumberRequired';
  static const accountNumberLength = 'account.validation.accountNumberLength';
  static const ifscRequired = 'account.validation.ifscRequired';
  static const validIfsc = 'account.validation.validIfsc';
  static const bankRequired = 'account.validation.bankRequired';
  static const passwordUse8 = 'account.password.use8';
  static const passwordStrong = 'account.password.strong';
  static const myProfileCaps = 'account.drawer.myProfile';
  static const helpCenterCaps = 'account.drawer.helpCenter';
  static const sellerDashboard = 'account.drawer.sellerDashboard';
  static const sellerAccountLabel = 'account.drawer.sellerAccount';
  static const accountLabel = 'account.drawer.account';
  static const backToShop = 'commerce.action.backToShop';
  static const shipmentTracking = 'commerce.tracking.title';
  static const trackingLoadFailed = 'commerce.tracking.loadFailed';
  static const noShipment = 'commerce.tracking.empty';
  static const trackingNumber = 'commerce.tracking.number';
  static const location = 'commerce.tracking.location';
  static const deleteAccountTitle = 'account.delete.title';
  static const deleteAccountBody = 'account.delete.body';
  static const currentPassword = 'account.field.currentPassword';
  static const signOutTitle = 'account.signOut.title';
  static const signOutBody = 'account.signOut.body';
  static const inquiries = 'commerce.inquiry.title';
  static const newInquiry = 'commerce.inquiry.new';
  static const inquiry = 'commerce.inquiry.single';
  static const chat = 'commerce.chat.title';
  static const compareCategoryMismatch = 'commerce.compare.categoryMismatch';
  static const available = 'commerce.availability.available';
  static const unavailable = 'commerce.availability.unavailable';
  static const naturalDiamond = 'commerce.sellerType.naturalDiamond';
  static const labGrownDiamond = 'commerce.sellerType.labGrownDiamond';
  static const jewellery = 'commerce.sellerType.jewellery';
  static const bullion = 'commerce.sellerType.bullion';
  static const savings = 'commerce.bankAccount.savings';
  static const current = 'commerce.bankAccount.current';
  static const company = 'account.profile.company';
  static const businessAddress = 'account.profile.businessAddress';
  static const businessContacts = 'account.profile.businessContacts';
  static const taxKyc = 'account.profile.taxKyc';
  static const username = 'account.field.username';
  static const password = 'account.field.password';
  static const email = 'account.field.email';
  static const otp = 'account.field.otp';
  static const reason = 'commerce.refund.reason';
  static const refunds = 'commerce.refund.title';
  static const refresh = 'commerce.action.refresh';
  static const remove = 'commerce.action.remove';
  static const viewMyOrders = 'commerce.orders.viewMine';
  static const compare = 'commerce.compare.heading';
  static const passwordAddRequirements = 'account.password.addRequirements';
  static const uppercaseLetter = 'account.password.uppercaseLetter';
  static const lowercaseLetter = 'account.password.lowercaseLetter';
  static const numberRequirement = 'account.password.number';
  static const symbolRequirement = 'account.password.symbol';

  static String english(String key) =>
      accountCommerceMessages[key]?.english ?? key;
}

const accountCommerceMessages = <String, LocalizedMessage>{
  AccountCommerceL10n.forgotPassword: LocalizedMessage(
    english: 'Forgot Password',
    hindi: 'पासवर्ड भूल गए',
    gujarati: 'પાસવર્ડ ભૂલી ગયા છો',
  ),
  AccountCommerceL10n.forgotInstructions: LocalizedMessage(
    english: 'Enter your registered email and we will send you a reset link.',
    hindi: 'अपना रजिस्टर्ड ईमेल डालें और हम आपको एक रीसेट लिंक भेजेंगे।',
    gujarati:
        'તમારું રજિસ્ટર્ડ ઇમેઇલ દાખલ કરો અને અમે તમને રીસેટ લિંક મોકલીશું.',
  ),
  AccountCommerceL10n.emailRequired: LocalizedMessage(
    english: 'Email is required',
    hindi: 'ईमेल ज़रूरी है',
    gujarati: 'ઇમેઇલ જરૂરી છે.',
  ),
  AccountCommerceL10n.validEmail: LocalizedMessage(
    english: 'Enter a valid email address',
    hindi: 'कृपया कोई मान्य ईमेल एड्रैस लिखें.',
    gujarati: 'kapda kevi rite dhovay',
  ),
  AccountCommerceL10n.sendResetLink: LocalizedMessage(
    english: 'Send Reset Link',
    hindi: 'रीसेट लिंक भेजें',
    gujarati: 'રીસેટ લિંક મોકલો',
  ),
  AccountCommerceL10n.resetLinkSent: LocalizedMessage(
    english: 'Reset link sent. Please check your email.',
    hindi: 'लिंक रीसेट कर दिया गया है। कृपया अपना ईमेल देखें।',
    gujarati: 'રીસેટ લિંક મોકલવામાં આવી છે. કૃપા કરીને તમારું ઇમેઇલ તપાસો.',
  ),
  AccountCommerceL10n.backToLogin: LocalizedMessage(
    english: 'Back to login',
    hindi: 'लॉग इन पर वापस जाएँ',
    gujarati: 'લૉગિન પર પાછા જાઓ',
  ),
  AccountCommerceL10n.welcomeBack: LocalizedMessage(
    english: 'WELCOME BACK',
    hindi: 'फिर से स्वागत है।',
    gujarati: 'સ્વાગત પાછા',
  ),
  AccountCommerceL10n.signInToGemWorld: LocalizedMessage(
    english: 'Sign in to GemWorld',
    hindi: 'GemWorld में साइन इन करें',
    gujarati: 'GemWorld માં સાઇન ઇન કરો',
  ),
  AccountCommerceL10n.enterUsername: LocalizedMessage(
    english: 'Enter username',
    hindi: 'प्रयोक्ता नाम दर्ज़ करें...',
    gujarati: 'વપરાશકર્તાનામ ને દાખલ કરો',
  ),
  AccountCommerceL10n.validEmailOrUsername: LocalizedMessage(
    english: 'Enter a valid email or username',
    hindi: 'कोई मान्य ईमेल या यूज़रनेम डालें',
    gujarati: 'માન્ય ઇમેઇલ અથવા વપરાશકર્તાનામ દાખલ કરો',
  ),
  AccountCommerceL10n.showPassword: LocalizedMessage(
    english: 'Show password',
    hindi: 'पासवर्ड दिखाएँ',
    gujarati: 'પાસવર્ડને બતાવો',
  ),
  AccountCommerceL10n.hidePassword: LocalizedMessage(
    english: 'Hide password',
    hindi: 'पासवर्ड छिपाएँ',
    gujarati: 'પાસવર્ડ છુપાવો',
  ),
  AccountCommerceL10n.enterPassword: LocalizedMessage(
    english: 'Enter password',
    hindi: 'पासवर्ड डालें',
    gujarati: 'પાસવર્ડ દાખલ કરો',
  ),
  AccountCommerceL10n.passwordRequired: LocalizedMessage(
    english: 'Password is required.',
    hindi: 'पासवर्ड की आवश्यकता है',
    gujarati: 'પાસવર્ડની જરૂરિયાત છે',
  ),
  AccountCommerceL10n.passwordMin6: LocalizedMessage(
    english: 'Password must be at least 6 characters.',
    hindi: 'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए',
    gujarati: 'પાસવર્ડ ઓછામાં ઓછો 6 અક્ષરોનો હોવો જોઈએ.',
  ),
  AccountCommerceL10n.forgotPasswordAction: LocalizedMessage(
    english: 'Forgot password?',
    hindi: 'पासवर्ड भूल गए?',
    gujarati: 'પાસવર્ડ ભૂલી ગયા છો?',
  ),
  AccountCommerceL10n.recoverDeletedAccount: LocalizedMessage(
    english: 'Recover deleted account',
    hindi: 'हटाए गए अकाउंट को पुनर्प्राप्त करें',
    gujarati: 'કાઢી નાખેલ એકાઉન્ટ પુનઃપ્રાપ્ત કરો',
  ),
  AccountCommerceL10n.signIn: LocalizedMessage(
    english: 'Sign in ?',
    hindi: 'साइन इन करें',
    gujarati: 'સાઇન ઇન કરો',
  ),
  AccountCommerceL10n.createAccountPrompt: LocalizedMessage(
    english: 'New to GemWorld? Create an account',
    hindi: 'GemWorld में नए हैं? एक अकाउंट बनाएँ',
    gujarati: 'GemWorld પર નવા છો? એક એકાઉન્ટ બનાવો',
  ),
  AccountCommerceL10n.accountRecovered: LocalizedMessage(
    english: 'Account recovered. Please sign in.',
    hindi: 'अकाउंट रिकवर हो गया है। कृपया साइन इन करें।',
    gujarati: 'એકાઉન્ટ પુનઃપ્રાપ્ત થયું. કૃપા કરીને સાઇન ઇન કરો.',
  ),
  AccountCommerceL10n.recoverAccount: LocalizedMessage(
    english: 'Recover account',
    hindi: 'रिकवर अकाउंट फ़ॉर्म',
    gujarati: 'એકાઉન્ટ પુનઃપ્રાપ્ત કરો',
  ),
  AccountCommerceL10n.recoverInstructions: LocalizedMessage(
    english:
        'If your account was scheduled for deletion, recover it within 7 days using the email token or your email and password.',
    hindi:
        'अगर आपका अकाउंट मिटाने के लिए शेड्यूल किया गया था, तो ईमेल टोकन या अपने ईमेल और पासवर्ड का इस्तेमाल करके 7 दिनों के अंदर उसे रिकवर करें।',
    gujarati:
        'જો તમારું એકાઉન્ટ કાઢી નાખવા માટે સુનિશ્ચિત થયેલ હતું, તો તેને ઇમેઇલ ટોકન અથવા તમારા ઇમેઇલ અને પાસવર્ડનો ઉપયોગ કરીને 7 દિવસની અંદર પુનઃપ્રાપ્ત કરો.',
  ),
  AccountCommerceL10n.emailToken: LocalizedMessage(
    english: 'Email token',
    hindi: 'ईमेल टोकन',
    gujarati: 'ઇમેઇલ ટોકન',
  ),
  AccountCommerceL10n.emailAndPassword: LocalizedMessage(
    english: 'Email & password',
    hindi: 'ईमेल और पासवर्ड',
    gujarati: 'ઇમેઇલ અને પાસવર્ડ',
  ),
  AccountCommerceL10n.recoveryToken: LocalizedMessage(
    english: 'Recovery token',
    hindi: 'रिकवरी टोकन',
    gujarati: 'પુનઃપ્રાપ્તિ ટોકન',
  ),
  AccountCommerceL10n.recoveryTokenRequired: LocalizedMessage(
    english: 'Recovery token is required',
    hindi: 'रिकवरी टोकन ज़रूरी है',
    gujarati: 'રિકવરી ટોકન જરૂરી છે',
  ),
  AccountCommerceL10n.newAccount: LocalizedMessage(
    english: 'NEW ACCOUNT',
    hindi: 'नया खाता',
    gujarati: 'નવું ખાતું',
  ),
  AccountCommerceL10n.sellerAccount: LocalizedMessage(
    english: 'SELLER ACCOUNT',
    hindi: 'विक्रेता खाता',
    gujarati: 'વિક્રેતા એકાઉન્ટ',
  ),
  AccountCommerceL10n.forBusinesses: LocalizedMessage(
    english: 'For Businesses',
    hindi: 'व्यवसायों के लिए',
    gujarati: 'વ્યવસાયો માટે',
  ),
  AccountCommerceL10n.joinGemWorld: LocalizedMessage(
    english: 'Join GemWorld',
    hindi: 'GemWorld में शामिल हों',
    gujarati: 'GemWorld માં જોડાઓ',
  ),
  AccountCommerceL10n.sellerRegistration: LocalizedMessage(
    english: 'Seller registration',
    hindi: 'विक्रेता पंजीकरण',
    gujarati: 'વિક્રેતા નોંધણી',
  ),
  AccountCommerceL10n.register: LocalizedMessage(
    english: 'Register',
    hindi: 'रजिस्टर करें',
    gujarati: 'રજીસ્ટર',
  ),
  AccountCommerceL10n.accountTypesSeparate: LocalizedMessage(
    english:
        'Account types are separate — individual buyers cannot sell on the same account.',
    hindi:
        'अकाउंट के प्रकार अलग-अलग होते हैं — व्यक्तिगत खरीदार एक ही अकाउंट पर नहीं बेच सकते।',
    gujarati:
        'એકાઉન્ટના પ્રકાર અલગ છે — વ્યક્તિગત ખરીદદારો એક જ એકાઉન્ટ પર વેચી શકતા નથી.',
  ),
  AccountCommerceL10n.agreeToTermsIntro: LocalizedMessage(
    english:
        'I agree to the Terms of Service (including chatbot data use for AI training) and ',
    hindi:
        'मैं सेवा की शर्तों (AI प्रशिक्षण के लिए चैटबॉट डेटा उपयोग सहित) से सहमत हूँ और ',
    gujarati:
        'હું સેવાની શરતો (AI તાલીમ માટે ચેટબોટ ડેટા ઉપયોગ સહિત) સાથે સંમત છું અને ',
  ),
  AccountCommerceL10n.termsOfServiceLink: LocalizedMessage(
    english: 'Terms of Service',
    hindi: 'सेवा की शर्तें',
    gujarati: 'સેવાની શરતો',
  ),
  AccountCommerceL10n.agreeToTermsAnd: LocalizedMessage(
    english: ' and ',
    hindi: ' और ',
    gujarati: ' અને ',
  ),
  AccountCommerceL10n.ethicalSourcingPolicyLink: LocalizedMessage(
    english: 'Ethical Sourcing Policy.',
    hindi: 'नैतिक सोर्सिंग नीति।',
    gujarati: 'નૈતિક સોર્સિંગ નીતિ.',
  ),
  AccountCommerceL10n.createAccount: LocalizedMessage(
    english: 'Create account ?',
    hindi: 'अकाउंट बनाएँ',
    gujarati: 'એકાઉન્ટ બનાવો?',
  ),
  AccountCommerceL10n.alreadyRegistered: LocalizedMessage(
    english: 'Already registered? Sign in',
    hindi: 'पहले से ही रजिस्टर है? साइन इन करें',
    gujarati: 'પહેલેથી રજીસ્ટર છે? સાઇન ઇન કરો',
  ),
  AccountCommerceL10n.fullName: LocalizedMessage(
    english: 'Full name',
    hindi: 'पूरा नाम',
    gujarati: 'પૂરું નામ',
  ),
  AccountCommerceL10n.fullNameRequired: LocalizedMessage(
    english: 'Full name is required',
    hindi: 'पूरा नाम ज़रूरी है',
    gujarati: 'નામ જરૂરી છે',
  ),
  AccountCommerceL10n.dateOfBirth: LocalizedMessage(
    english: 'Date of birth',
    hindi: 'जन्म तिथि',
    gujarati: 'જન્મ તારીખ',
  ),
  AccountCommerceL10n.dateOfBirthRequired: LocalizedMessage(
    english: 'Date of birth is required',
    hindi: 'जन्म तिथि ज़रूरी है',
    gujarati: 'જન્મ તારીખ જરૂરી છે',
  ),
  AccountCommerceL10n.dateOfBirthInvalid: LocalizedMessage(
    english: 'Enter a valid date of birth',
    hindi: 'मान्य जन्म तिथि दर्ज करें',
    gujarati: 'માન્ય જન્મ તારીખ દાખલ કરો',
  ),
  AccountCommerceL10n.dateOfBirthTooYoung: LocalizedMessage(
    english: 'You must be at least 18 years old to register',
    hindi: 'रजिस्टर करने के लिए आपकी आयु कम से कम 18 वर्ष होनी चाहिए',
    gujarati: 'રજીસ્ટર કરવા માટે તમારી ઉંમર ઓછામાં ઓછી 18 વર્ષ હોવી જોઈએ',
  ),
  AccountCommerceL10n.selectDateOfBirth: LocalizedMessage(
    english: 'Select date of birth',
    hindi: 'जन्म तिथि चुनें',
    gujarati: 'જન્મ તારીખ પસંદ કરો',
  ),
  AccountCommerceL10n.usernameRequired: LocalizedMessage(
    english: 'Username is required.',
    hindi: 'यूज़रनेम ज़रूरी है।',
    gujarati: 'USERNAME જરૂરી છે.',
  ),
  AccountCommerceL10n.emailAddress: LocalizedMessage(
    english: 'Email address',
    hindi: 'ईमेल पता',
    gujarati: 'ઇમેલ સરનામું',
  ),
  AccountCommerceL10n.referralEmail: LocalizedMessage(
    english: 'Referral email (optional)',
    hindi: 'रेफ़रल ईमेल (ज़रूरी नहीं)',
    gujarati: 'રેફરલ ઇમેઇલ (વૈકલ્પિક)',
  ),
  AccountCommerceL10n.validReferralEmail: LocalizedMessage(
    english: 'Enter a valid referral email',
    hindi: 'मान्य ईमेल डालें।',
    gujarati: 'માન્ય રેફરલ ઇમેઇલ દાખલ કરો',
  ),
  AccountCommerceL10n.referralCode: LocalizedMessage(
    english: 'Referral code (optional)',
    hindi: 'रेफरल कोड (वैकल्पिक)',
    gujarati: 'રેફરલ કોડ (વૈકલ્પિક)',
  ),
  AccountCommerceL10n.referralEmailOrCode: LocalizedMessage(
    english: 'Referral email or code',
    hindi: 'रेफ़रल ईमेल या कोड',
    gujarati: 'રેફરલ ઇમેઇલ અથવા કોડ',
  ),
  AccountCommerceL10n.continueAction: LocalizedMessage(
    english: 'Continue ?',
    hindi: 'जारी रखें',
    gujarati: 'ચાલુ રાખો',
  ),
  AccountCommerceL10n.createSellerAccount: LocalizedMessage(
    english: 'Create seller account ?',
    hindi: 'विक्रेता खाता बनाएँ?',
    gujarati: 'વિક્રેતા એકાઉન્ટ બનાવો?',
  ),
  AccountCommerceL10n.individual: LocalizedMessage(
    english: 'For Individual',
    hindi: 'व्यक्ति के लिए',
    gujarati: '(વ્યક્તિગત માટે) ',
  ),
  AccountCommerceL10n.individualDescription: LocalizedMessage(
    english:
        'Buy and browse only ? create a separate business account later to sell',
    hindi:
        'केवल खरीदें और ब्राउज़ करें? बेचने के लिए बाद में एक अलग व्यावसायिक खाता बनाएं',
    gujarati:
        'ફક્ત ખરીદો અને બ્રાઉઝ કરો? વેચવા માટે પછીથી એક અલગ વ્યવસાય એકાઉન્ટ બનાવો',
  ),
  AccountCommerceL10n.businessDescription: LocalizedMessage(
    english: 'Dedicated seller account ? cannot share an individual login',
    hindi: 'समर्पित विक्रेता खाता ? व्यक्तिगत लॉगिन साझा नहीं कर सकते',
    gujarati: 'સમર્પિત વિક્રેતા ખાતું ? વ્યક્તિગત લૉગિન શેર કરી શકતા નથી',
  ),
  AccountCommerceL10n.resetPassword: LocalizedMessage(
    english: 'Reset Password',
    hindi: 'पासवर्ड रीसेट करें',
    gujarati: 'પાસવર્ડ ફરીથી સ્થાપિત કરો',
  ),
  AccountCommerceL10n.missingResetToken: LocalizedMessage(
    english:
        'This reset link is missing a token. Open the link from your email again.',
    hindi:
        'इस रीसेट लिंक में एक टोकन मौजूद नहीं है। अपने ईमेल से लिंक फिर से खोलें।',
    gujarati:
        'આ રીસેટ લિંકમાં એક ટોકન ખૂટે છે. તમારા ઇમેઇલમાંથી લિંક ફરીથી ખોલો.',
  ),
  AccountCommerceL10n.chooseNewPassword: LocalizedMessage(
    english: 'Choose a new password for your account.',
    hindi: 'अपने अकाउंट के लिए एक नया पासवर्ड चुनें।',
    gujarati: 'તમારા એકાઉન્ટ માટે નવો પાસવર્ડ પસંદ કરો.',
  ),
  AccountCommerceL10n.passwordResetSuccess: LocalizedMessage(
    english: 'Password reset successfully. You can sign in now.',
    hindi: 'पासवर्ड सफलतापूर्वक रीसेट हो गया। आप अभी साइन इन कर सकते हैं।',
    gujarati: 'પાસવર્ડ સફળતાપૂર્વક રીસેટ થયો. તમે હમણાં સાઇન ઇન કરી શકો છો.',
  ),
  AccountCommerceL10n.goToLogin: LocalizedMessage(
    english: 'Go to login',
    hindi: '"लॉगिन पर जाएं"',
    gujarati: 'લૉગિન પર જાઓ',
  ),
  AccountCommerceL10n.newPassword: LocalizedMessage(
    english: 'New password',
    hindi: 'नया पासवर्ड',
    gujarati: 'નવો પાસવર્ડ',
  ),
  AccountCommerceL10n.confirmPassword: LocalizedMessage(
    english: 'Confirm password',
    hindi: 'पासवर्ड कन्फ़र्म करें',
    gujarati: 'પાસવર્ડની ખાતરી કરો',
  ),
  AccountCommerceL10n.passwordsDoNotMatch: LocalizedMessage(
    english: 'Passwords do not match.',
    hindi:
        'हाँ, मैं केडीई वॉलेट को मेरी निजी जानकारी भंडारित करने के लिए उपयोग करना चाहता हूँ.',
    gujarati: 'પાસવર્ડસ બંધબેસતાં નથી.',
  ),
  AccountCommerceL10n.resetPasswordAction: LocalizedMessage(
    english: 'Reset password',
    hindi: 'पासवर्ड रीसेट करें',
    gujarati: 'પાસવર્ડ ફરીથી સેટ કરો',
  ),
  AccountCommerceL10n.verifyEmail: LocalizedMessage(
    english: 'VERIFY EMAIL',
    hindi: 'ईमेल सत्यापित करें',
    gujarati: 'ઇમેઇલ ચકાસો',
  ),
  AccountCommerceL10n.enterCodeSent: LocalizedMessage(
    english: 'Enter the code we sent you',
    hindi: 'हमने आपको जो कोड भेजा है, उसे डालें',
    gujarati: 'અમે તમને મોકલ્યો છે તે કોડ દાખલ કરો',
  ),
  AccountCommerceL10n.verifyOtp: LocalizedMessage(
    english: 'Verify OTP',
    hindi: 'ओटीपी से वेरीफाई करें',
    gujarati: 'OTP ચકાસો',
  ),
  AccountCommerceL10n.enterSixDigitCode: LocalizedMessage(
    english: 'Enter the 6-digit code from your email.',
    hindi: 'अपने ईमेल से 6 अंकों का कोड डालें।',
    gujarati: 'તમારા ઇમેઇલમાંથી 6-અંકનો કોડ દાખલ કરો.',
  ),
  AccountCommerceL10n.codeSentToEmail: LocalizedMessage(
    english: 'We sent a 6-digit code to {email}.',
    hindi: 'हमने {email} को 6 अंकों का एक कोड भेजा है।',
    gujarati: 'અમે {email} પર 6-અંકનો કોડ મોકલ્યો છે.',
  ),
  AccountCommerceL10n.enterOtp: LocalizedMessage(
    english: 'Enter the 6-digit OTP.',
    hindi: ' <x id="2"/>6 अंकों का <g id="1">OTP</g> डालें',
    gujarati: '6 અંકનો ઓટીપી દાખલ કરો',
  ),
  AccountCommerceL10n.verifyAction: LocalizedMessage(
    english: 'Verify ?',
    hindi: 'सत्यापित करें',
    gujarati: 'ચકાસો (y)',
  ),
  AccountCommerceL10n.otpSent: LocalizedMessage(
    english: 'OTP sent. Check your email.',
    hindi: 'ओटीपी भेजा गया। अपना ईमेल देखें।',
    gujarati: 'ઓટીપી મોકલવામાં આવ્યો છે. તમારું ઇમેઇલ તપાસો.',
  ),
  AccountCommerceL10n.resendOtp: LocalizedMessage(
    english: 'Resend OTP',
    hindi: 'ओटीपी पुनः भेजें',
    gujarati: 'ફરીથી OTP મોકલો,',
  ),
  AccountCommerceL10n.basicDetails: LocalizedMessage(
    english: 'Basic details',
    hindi: 'बुनियादी जानकारी',
    gujarati: 'મૂળભૂત વિગતો',
  ),
  AccountCommerceL10n.companyDetails: LocalizedMessage(
    english: 'Company details',
    hindi: 'कंपनी का ब्यौरा',
    gujarati: 'કંપનીની વિગતો',
  ),
  AccountCommerceL10n.contactsKyc: LocalizedMessage(
    english: 'Contacts & KYC',
    hindi: 'संपर्क और KYC',
    gujarati: 'સંપર્કો અને KYC',
  ),
  AccountCommerceL10n.bankAccount: LocalizedMessage(
    english: 'Bank account',
    hindi: 'बैंक अकाउंट',
    gujarati: 'બેંક એકાઊન્ટ',
  ),
  AccountCommerceL10n.companyName: LocalizedMessage(
    english: 'Company name',
    hindi: 'कंपनी का नाम।',
    gujarati: 'કંપનીનું નામ',
  ),
  AccountCommerceL10n.companyNameRequired: LocalizedMessage(
    english: 'Company name is required',
    hindi: 'कंपनी का नाम आवश्यक है।',
    gujarati: 'કંપનીનું નામ જરૂરી છે',
  ),
  AccountCommerceL10n.sellerType: LocalizedMessage(
    english: 'Seller type',
    hindi: 'विक्रेता का प्रकार',
    gujarati: 'વિક્રેતા પ્રકાર',
  ),
  AccountCommerceL10n.uploadCompanyLogo: LocalizedMessage(
    english: 'Upload company logo *',
    hindi: 'कंपनी का लोगो अपलोड करें *',
    gujarati: 'કંપનીનો લોગો અપલોડ કરો *',
  ),
  AccountCommerceL10n.uploadBanner: LocalizedMessage(
    english: 'Upload banner image (optional)',
    hindi: 'बैनर की फ़ोटो अपलोड करें (ज़रूरी नहीं)',
    gujarati: 'બેનર છબી અપલોડ કરો (વૈકલ્પિક)',
  ),
  AccountCommerceL10n.addressLine1: LocalizedMessage(
    english: 'Address line 1',
    hindi: 'पता पंक्ति 1',
    gujarati: 'સરનામા પંક્તિ 1',
  ),
  AccountCommerceL10n.addressLine2: LocalizedMessage(
    english: 'Address line 2',
    hindi: 'पता पंक्ति 2',
    gujarati: 'સરનામા પંક્તિ 2',
  ),
  AccountCommerceL10n.city: LocalizedMessage(
    english: 'City',
    hindi: 'शहर',
    gujarati: 'શહેર',
  ),
  AccountCommerceL10n.stateProvince: LocalizedMessage(
    english: 'State / province',
    hindi: 'प्रदेश/ प्रांत',
    gujarati: 'રાજ્ય/સામ્રાજ્ય',
  ),
  AccountCommerceL10n.country: LocalizedMessage(
    english: 'Country',
    hindi: 'देश',
    gujarati: 'દેશ',
  ),
  AccountCommerceL10n.postalCode: LocalizedMessage(
    english: 'ZIP / postal code',
    hindi: 'ज़िप/पोस्टल कोड',
    gujarati: 'ઝિપ/પોસ્ટલ કોડ',
  ),
  AccountCommerceL10n.primaryPhone: LocalizedMessage(
    english: 'Primary phone',
    hindi: 'प्राथमिक फ़ोन',
    gujarati: 'પ્રાઇમરી ફોન',
  ),
  AccountCommerceL10n.secondaryPhone: LocalizedMessage(
    english: 'Secondary phone',
    hindi: 'सेकंडरी फ़ोन',
    gujarati: 'ગૌણ ફોન',
  ),
  AccountCommerceL10n.representative1: LocalizedMessage(
    english: 'Representative name 1',
    hindi: 'प्रतिनिधि का नाम 1',
    gujarati: 'પ્રતિનિધિ નામ 1',
  ),
  AccountCommerceL10n.representative2: LocalizedMessage(
    english: 'Representative name 2',
    hindi: 'प्रतिनिधि का नाम 2',
    gujarati: 'પ્રતિનિધિ નામ 2',
  ),
  AccountCommerceL10n.panNumber: LocalizedMessage(
    english: 'PAN number',
    hindi: 'पैन नंबर',
    gujarati: 'પાન નંબર ',
  ),
  AccountCommerceL10n.aadhaarNumber: LocalizedMessage(
    english: 'Aadhaar number',
    hindi: 'आधार नंबर',
    gujarati: 'આધાર નંબર.\'',
  ),
  AccountCommerceL10n.iecNumber: LocalizedMessage(
    english: 'IEC number',
    hindi: 'IEC नंबर',
    gujarati: 'IEC નંબર',
  ),
  AccountCommerceL10n.gstNumber: LocalizedMessage(
    english: 'GST number (optional)',
    hindi: 'GST नंबर (ज़रूरी नहीं)',
    gujarati: 'જીએસટી નંબર (વૈકલ્પિક)',
  ),
  AccountCommerceL10n.accountHolderName: LocalizedMessage(
    english: 'Account holder name',
    hindi: 'क्या छात्र के पास आधार नंब',
    gujarati: 'એકાઊન્ટ સાથે જોડાયેલ આધાર આઈડી',
  ),
  AccountCommerceL10n.accountNumber: LocalizedMessage(
    english: 'Account number',
    hindi: 'खाता संख्या',
    gujarati: 'એકાઉન્ટ નંબર',
  ),
  AccountCommerceL10n.ifscCode: LocalizedMessage(
    english: 'IFSC code',
    hindi: 'IFSC कोड',
    gujarati: 'આઇએફએસસી કોડ',
  ),
  AccountCommerceL10n.bankName: LocalizedMessage(
    english: 'Bank name',
    hindi: 'बैंक का नाम',
    gujarati: 'બેંકનું નામ',
  ),
  AccountCommerceL10n.accountTypeOptional: LocalizedMessage(
    english: 'Account type (optional)',
    hindi: 'अकाउंट का प्रकार (ज़रूरी नहीं)',
    gujarati: 'એકાઉન્ટનો પ્રકાર (વૈકલ્પિક)',
  ),
  AccountCommerceL10n.upiOptional: LocalizedMessage(
    english: 'UPI ID (optional)',
    hindi: 'यूपीआई आईडी (ज़रूरी नहीं)',
    gujarati: 'UPI ID (વૈકલ્પિક)',
  ),
  AccountCommerceL10n.stepOf: LocalizedMessage(
    english: 'Step {current} of {total}',
    hindi: '{total} का चरण {current}',
    gujarati: '{total} નું પગલું {current}',
  ),
  AccountCommerceL10n.notProvided: LocalizedMessage(
    english: 'Not provided',
    hindi: 'नहीं दिया गया',
    gujarati: '(પૂરું પાડવામાં આવેલ નથી)',
  ),
  AccountCommerceL10n.onFile: LocalizedMessage(
    english: 'On file',
    hindi: 'फ़ाइल पर',
    gujarati: 'ફાઈલ પર',
  ),
  AccountCommerceL10n.required: LocalizedMessage(
    english: 'Required',
    hindi: 'आवश्यक',
    gujarati: 'જરૂરી',
  ),
  AccountCommerceL10n.orders: LocalizedMessage(
    english: 'Orders',
    hindi: 'आदेश',
    gujarati: 'ઓર્ડર્સ',
  ),
  AccountCommerceL10n.noOrders: LocalizedMessage(
    english: 'No orders yet',
    hindi: 'अभी तक कोई ऑर्डर नहीं है',
    gujarati: 'હજી સુધી કોઈ ઓર્ડર નથી',
  ),
  AccountCommerceL10n.retry: LocalizedMessage(
    english: 'Retry',
    hindi: 'वरी कोशिश कयो',
    gujarati: 'રીટ્રાય',
  ),
  AccountCommerceL10n.itemsCount: LocalizedMessage(
    english: '{count} items',
    hindi: '{count} आइटम',
    gujarati: '{count} વસ્તુઓ',
  ),
  AccountCommerceL10n.itemCount: LocalizedMessage(
    english: '{count} item',
    hindi: '{count} आइटम',
    gujarati: '{count} આઇટમ',
  ),
  AccountCommerceL10n.soldBy: LocalizedMessage(
    english: 'Sold by {seller}',
    hindi: '{seller} द्वारा बेचा गया',
    gujarati: '{seller} દ્વારા વેચવામાં આવેલ',
  ),
  AccountCommerceL10n.orderDetails: LocalizedMessage(
    english: 'Order details',
    hindi: 'ऑर्डर का विवरण',
    gujarati: 'ઓર્ડરની વિગતો',
  ),
  AccountCommerceL10n.orderNotFound: LocalizedMessage(
    english: 'Order not found',
    hindi: 'ऑर्डर नहीं मिला',
    gujarati: 'ઓર્ડર મળ્યો નથી',
  ),
  AccountCommerceL10n.backToOrders: LocalizedMessage(
    english: 'Back to orders',
    hindi: 'ऑर्डर पर वापस जाएँ',
    gujarati: 'ઓર્ડર પર પાછા ફરો',
  ),
  AccountCommerceL10n.orderIdCopied: LocalizedMessage(
    english: 'Order ID copied',
    hindi: 'ऑर्डर आईडी कॉपी की गई',
    gujarati: 'ઓર્ડર ID કૉપિ કરી',
  ),
  AccountCommerceL10n.copyOrderId: LocalizedMessage(
    english: 'Copy order id',
    hindi: 'आर्डर आईडी ',
    gujarati: 'ઓર્ડર ID, ',
  ),
  AccountCommerceL10n.orderItem: LocalizedMessage(
    english: 'Order item',
    hindi: 'ऑर्डर का आइटम',
    gujarati: 'ઓર્ડર આઇટમ',
  ),
  AccountCommerceL10n.placedOn: LocalizedMessage(
    english: 'Placed {date}',
    hindi: 'रखा {date}',
    gujarati: 'મૂકવામાં આવેલ {date}',
  ),
  AccountCommerceL10n.invoiceNumber: LocalizedMessage(
    english: 'Invoice {number}',
    hindi: 'इनवॉइस {number}',
    gujarati: 'ઇન્વોઇસ {number}',
  ),
  AccountCommerceL10n.downloadInvoice: LocalizedMessage(
    english: 'Download invoice',
    hindi: 'इनवॉइस डाउनलोड करें',
    gujarati: 'ઇન્વૉઇસ ડાઉનલોડ કરો',
  ),
  AccountCommerceL10n.invoiceOpenFailed: LocalizedMessage(
    english: 'Could not open the invoice.',
    hindi: 'इनवॉइस नहीं खोला जा सका।',
    gujarati: 'ભરતિયું ખોલી શકાયું નહીં.',
  ),
  AccountCommerceL10n.quantity: LocalizedMessage(
    english: 'Qty {count}',
    hindi: 'मात्रा {count}',
    gujarati: 'Qty {count}',
  ),
  AccountCommerceL10n.orderSummary: LocalizedMessage(
    english: 'ORDER SUMMARY',
    hindi: 'आदेश का सारांश',
    gujarati: 'ઓર્ડર નો સારાંશ',
  ),
  AccountCommerceL10n.itemsSubtotal: LocalizedMessage(
    english: 'Items subtotal',
    hindi: 'आइटम का कुल योग',
    gujarati: 'વસ્તુઓનો પેટા સરવાળો',
  ),
  AccountCommerceL10n.transactionFee: LocalizedMessage(
    english: 'Transaction fee',
    hindi: 'लेन - देन शुल्क',
    gujarati: 'ટ્રાન્ઝેક્શન ફી',
  ),
  AccountCommerceL10n.platformFee: LocalizedMessage(
    english: 'Platform fee',
    hindi: 'प्लैटफ़ॉर्म शुल्क',
    gujarati: 'પ્લેટફોર્મ ફી',
  ),
  AccountCommerceL10n.deliveryFee: LocalizedMessage(
    english: 'Delivery fee',
    hindi: 'डिलीवरी शुल्क',
    gujarati: 'ડિલિવરી ફી,',
  ),
  AccountCommerceL10n.verificationFee: LocalizedMessage(
    english: 'GemWorld verification',
    hindi: 'GemWorld वेरिफ़िकेशन',
    gujarati: 'GemWorld ચકાસણી',
  ),
  AccountCommerceL10n.myProfile: LocalizedMessage(
    english: 'My profile',
    hindi: 'मेरी प्रोफ़ाइल',
    gujarati: 'મારો પ્રોફાઇલ',
  ),
  AccountCommerceL10n.signInProfile: LocalizedMessage(
    english: 'Sign in to view your profile.',
    hindi: 'अपनी प्रोफ़ाइल देखने के लिए साइन इन करें।',
    gujarati: 'તમારી પ્રોફાઇલ જોવા માટે સાઇન ઇન કરો.',
  ),
  AccountCommerceL10n.personalDetails: LocalizedMessage(
    english: 'Personal details',
    hindi: 'निजी विवरण',
    gujarati: 'વ્યક્તિગત વિગતો',
  ),
  AccountCommerceL10n.accountStatus: LocalizedMessage(
    english: 'Account status',
    hindi: 'अकाउंट की स्थिति',
    gujarati: 'એકાઉન્ટની સ્થિતિ',
  ),
  AccountCommerceL10n.accountType: LocalizedMessage(
    english: 'Account type',
    hindi: 'खाता प्रकार',
    gujarati: 'એકાઉન્ટનો પ્રકાર',
  ),
  AccountCommerceL10n.sellerBusiness: LocalizedMessage(
    english: 'Seller (business)',
    hindi: 'विक्रेता (व्यवसाय)',
    gujarati: 'વિક્રેતા (વ્યવસાય)',
  ),
  AccountCommerceL10n.individualBuyer: LocalizedMessage(
    english: 'Individual (buying only)',
    hindi: 'व्यक्तिगत (सिर्फ़ खरीदारी के लिए)',
    gujarati: 'વ્યક્તિગત (ફક્ત ખરીદી)',
  ),
  AccountCommerceL10n.accountVerification: LocalizedMessage(
    english: 'Account verification',
    hindi: 'अकाउंट वेरिफ़िकेशन',
    gujarati: 'એકાઉન્ટ ચકાસણી',
  ),
  AccountCommerceL10n.verificationPending: LocalizedMessage(
    english: 'Verification is pending',
    hindi: 'वेरिफ़िकेशन बाकी है',
    gujarati: 'ચકાસણી બાકી છે',
  ),
  AccountCommerceL10n.noRefunds: LocalizedMessage(
    english: 'No refund requests yet',
    hindi: 'अभी तक कोई रिफ़ंड अनुरोध नहीं है',
    gujarati: 'હજી સુધી કોઈ રિફંડ વિનંતીઓ નથી',
  ),
  AccountCommerceL10n.sellerLabel: LocalizedMessage(
    english: 'Seller ? {seller}',
    hindi: 'विक्रेता ? {seller}',
    gujarati: 'વેચનાર ? {seller}',
  ),
  AccountCommerceL10n.orderNumber: LocalizedMessage(
    english: 'Order {order}',
    hindi: 'ऑर्डर {order}',
    gujarati: 'ઓર્ડર {order}',
  ),
  AccountCommerceL10n.sellerNote: LocalizedMessage(
    english: 'Seller note: {note}',
    hindi: 'विक्रेता का नोट: {note}',
    gujarati: 'વિક્રેતા નોંધ: {note}',
  ),
  AccountCommerceL10n.requestedOn: LocalizedMessage(
    english: 'Requested {date}',
    hindi: 'अनुरोधित {date}',
    gujarati: 'વિનંતી કરેલ {date}',
  ),
  AccountCommerceL10n.refundCancelled: LocalizedMessage(
    english: 'Refund request cancelled',
    hindi: 'रिफ़ंड का अनुरोध कैंसिल कर दिया गया',
    gujarati: 'રિફંડની વિનંતી રદ થઈ',
  ),
  AccountCommerceL10n.cancelRequest: LocalizedMessage(
    english: 'Cancel request',
    hindi: 'निवेदन रद्द करें',
    gujarati: 'વિનંતી રદ કરો',
  ),
  AccountCommerceL10n.requestRefund: LocalizedMessage(
    english: 'Request refund ? {seller}',
    hindi: 'रिफ़ंड का अनुरोध करें? {seller}',
    gujarati: 'રિફંડની વિનંતી કરો? {seller}',
  ),
  AccountCommerceL10n.refundReasonHint: LocalizedMessage(
    english: 'Why are you requesting a refund?',
    hindi: 'आप रिफ़ंड का अनुरोध क्यों कर रहे हैं?',
    gujarati: 'તમે રિફંડની વિનંતી કેમ કરી રહ્યા છો?',
  ),
  AccountCommerceL10n.refundReasonRequired: LocalizedMessage(
    english: 'Please enter a refund reason',
    hindi: 'कृपया रिफ़ंड का कारण डालें',
    gujarati: 'કૃપા કરીને રિફંડનું કારણ દાખલ કરો',
  ),
  AccountCommerceL10n.refundSubmitted: LocalizedMessage(
    english: 'Refund request submitted',
    hindi: 'रिफ़ंड का अनुरोध सबमिट किया गया',
    gujarati: 'રિફંડની વિનંતી સબમિટ કરવામાં આવી',
  ),
  AccountCommerceL10n.viewRefunds: LocalizedMessage(
    english: 'View my refund requests',
    hindi: 'मेरे रिफ़ंड के अनुरोध देखें',
    gujarati: 'મારી રિફંડ વિનંતીઓ જુઓ',
  ),
  AccountCommerceL10n.myReviews: LocalizedMessage(
    english: 'My Reviews',
    hindi: 'मेरी समीक्षाएँ',
    gujarati: 'મારી સમીક્ષાઓ',
  ),
  AccountCommerceL10n.reviewsLoadFailed: LocalizedMessage(
    english: 'Could not load reviews.',
    hindi: 'समीक्षाएँ लोड नहीं की जा सकीं।',
    gujarati: 'સમીક્ષાઓ લોડ કરી શકાતી નથી.',
  ),
  AccountCommerceL10n.noReviews: LocalizedMessage(
    english: 'No reviews yet',
    hindi: 'अभी तक कोई समीक्षा नहीं',
    gujarati: 'હજી સુધી કોઈ સમીક્ષાઓ નથી',
  ),
  AccountCommerceL10n.viewOrders: LocalizedMessage(
    english: 'View orders',
    hindi: 'ऑर्डर देखें',
    gujarati: 'ઓર્ડર જુઓ',
  ),
  AccountCommerceL10n.sellerRatingReview: LocalizedMessage(
    english: 'Seller Rating & review',
    hindi: 'विक्रेता रेटिंग और समीक्षा',
    gujarati: 'વિક્રેતા રેટિંગ અને સમીક્ષા',
  ),
  AccountCommerceL10n.selectStar: LocalizedMessage(
    english: 'Please select a star rating.',
    hindi: 'कृपया कोई स्टार रेटिंग चुनें।',
    gujarati: 'કૃપા કરીને સ્ટાર રેટિંગ પસંદ કરો.',
  ),
  AccountCommerceL10n.thanksReview: LocalizedMessage(
    english: 'Thanks for reviewing {seller}!',
    hindi: '{seller} की समीक्षा करने के लिए धन्यवाद!',
    gujarati: '{seller} ની સમીક્ષા કરવા બદલ આભાર!',
  ),
  AccountCommerceL10n.submitReviewFor: LocalizedMessage(
    english: 'Submit review for {seller}',
    hindi: '{seller} के लिए समीक्षा सबमिट करें',
    gujarati: '{seller} માટે સમીક્ષા સબમિટ કરો',
  ),
  AccountCommerceL10n.submitReview: LocalizedMessage(
    english: 'Submit review',
    hindi: 'समीक्षा सबमिट करें',
    gujarati: 'સમીક્ષા સબમિટ કરો',
  ),
  AccountCommerceL10n.helpCenter: LocalizedMessage(
    english: 'Help center',
    hindi: 'सहायता केंद्र',
    gujarati: 'કેડીઇ મદદ કેન્દ્ર',
  ),
  AccountCommerceL10n.aboutGemWorld: LocalizedMessage(
    english: 'About GemWorld',
    hindi: 'GemWorld के बारे में',
    gujarati: 'GemWorld વિશે',
  ),
  AccountCommerceL10n.privacyPolicy: LocalizedMessage(
    english: 'Privacy Policy',
    hindi: 'गोपनीयता नीति',
    gujarati: 'ગોપનીયતા નીતિ',
  ),
  AccountCommerceL10n.policiesLegal: LocalizedMessage(
    english: 'Policies & Legal',
    hindi: 'नीतियाँ और कानूनी',
    gujarati: 'નીતિઓ અને કાનૂની',
  ),
  AccountCommerceL10n.termsConditions: LocalizedMessage(
    english: 'Terms & Conditions',
    hindi: 'नियम और  शर्तें',
    gujarati: 'નિયમો અને શરતો',
  ),
  AccountCommerceL10n.signOut: LocalizedMessage(
    english: 'Sign out',
    hindi: 'साइन आउट करें',
    gujarati: 'સાઇન આઉટ કરો',
  ),
  AccountCommerceL10n.deleteAccount: LocalizedMessage(
    english: 'Delete account',
    hindi: 'खाता डिलीट करें',
    gujarati: 'એકાઉન્ટ કાઢી નાખો',
  ),
  AccountCommerceL10n.deleteRecoveryWindow: LocalizedMessage(
    english: 'Schedules deletion with a 7-day recovery window.',
    hindi: '7 - दिन की रिकवरी विंडो के साथ मिटाने का समय तय करता है।',
    gujarati:
        '7-દિવસની પુન recoveryપ્રાપ્તિ વિંડો સાથે કાtionી નાખવાનું સુનિશ્ચિત કરે છે.',
  ),
  AccountCommerceL10n.myWishlist: LocalizedMessage(
    english: 'My Wishlist',
    hindi: 'मेरी विशलिस्ट',
    gujarati: 'મારી વિશલિસ્ટ',
  ),
  AccountCommerceL10n.wishlistEmpty: LocalizedMessage(
    english: 'Your wishlist is empty',
    hindi: 'आपकी विशलिस्ट खाली है',
    gujarati: 'તમારી વિશલિસ્ટ ખાલી છે',
  ),
  AccountCommerceL10n.wishlistEmptyHint: LocalizedMessage(
    english:
        'Tap the heart on diamonds, gemstones, jewelry, watches, or bullion to save them here.',
    hindi:
        'हीरे, रत्न, गहने, घड़ियाँ या बुलियन को यहाँ सेव करने के लिए दिल पर टैप करें।',
    gujarati:
        'હીરા, રત્નો, દાગીના, ઘડિયાળો અથવા બુલિયન પર હૃદયને ટેપ કરો તેમને અહીં સાચવવા માટે.',
  ),
  AccountCommerceL10n.removedWishlist: LocalizedMessage(
    english: 'Removed from wishlist',
    hindi: 'विशलिस्ट से हटाया गया',
    gujarati: 'ઇચ્છા સૂચિમાંથી દૂર કરવામાં આવ્યું',
  ),
  AccountCommerceL10n.addedWishlist: LocalizedMessage(
    english: 'Added to wishlist',
    hindi: 'विशलिस्ट में जोड़ा गया',
    gujarati: 'ઇચ્છા યાદીમાં ઉમેરાયેલ છે',
  ),
  AccountCommerceL10n.removeWishlist: LocalizedMessage(
    english: 'Remove from wishlist',
    hindi: 'विशलिस्ट से हटाएँ ',
    gujarati: 'ઇચ્છા સૂચિમાંથી દૂર કરો',
  ),
  AccountCommerceL10n.addWishlist: LocalizedMessage(
    english: 'Add to wishlist',
    hindi: 'विशलिस्ट में जोड़ें ',
    gujarati: 'ઇચ્છા યાદીમાં ઉમેરો',
  ),
  AccountCommerceL10n.productOpenFailed: LocalizedMessage(
    english: 'Could not open this product right now.',
    hindi: 'इस उत्पाद को अभी नहीं खोल सका।',
    gujarati: 'હમણાં આ ઉત્પાદન ખોલી શકાયું નથી.',
  ),
  AccountCommerceL10n.recentlyViewed: LocalizedMessage(
    english: 'Recently Viewed',
    hindi: 'हाल ही में देखे गए',
    gujarati: 'તાજેતરમાં જોવાયેલ',
  ),
  AccountCommerceL10n.clearRecentTitle: LocalizedMessage(
    english: 'Clear all recently viewed?',
    hindi: 'हाल ही में देखे गए सभी साफ़ करें?',
    gujarati: 'તાજેતરમાં જોયેલા બધા સાફ કરો?',
  ),
  AccountCommerceL10n.clearRecentBody: LocalizedMessage(
    english: 'This will remove all items from your recently viewed history.',
    hindi: 'यह आपके हाल ही में देखे गए इतिहास से सभी आइटम हटा देगा।',
    gujarati: 'આ તમારા તાજેતરમાં જોયેલા ઇતિહાસમાંથી બધી આઇટમ્સને દૂર કરશે.',
  ),
  AccountCommerceL10n.clearAll: LocalizedMessage(
    english: 'Clear all',
    hindi: 'सभी साफ करें',
    gujarati: 'બધું ક્લિયર કરો',
  ),
  AccountCommerceL10n.recentCleared: LocalizedMessage(
    english: 'Recently viewed items cleared',
    hindi: 'हाल ही में देखे गए आइटम साफ़ किए गए',
    gujarati: 'તાજેતરમાં જોયેલી આઇટમ્સ સાફ થઈ',
  ),
  AccountCommerceL10n.recentLoadFailed: LocalizedMessage(
    english: 'Failed to load recently viewed items.',
    hindi: 'हाल ही में देखे गए आइटम लोड नहीं किए जा सके।',
    gujarati: 'તાજેતરમાં જોયેલી આઇટમ્સ લોડ કરવામાં નિષ્ફળ.',
  ),
  AccountCommerceL10n.noRecent: LocalizedMessage(
    english: 'No recently viewed items',
    hindi: 'हाल ही में देखे गए कोई आइटम नहीं हैं',
    gujarati: 'તાજેતરમાં જોયેલી કોઈ આઇટમ્સ નથી',
  ),
  AccountCommerceL10n.noRecentHint: LocalizedMessage(
    english: 'Items you view will appear here so you can find them again.',
    hindi:
        'आपके द्वारा देखे जाने वाले आइटम यहाँ दिखाई देंगे, ताकि आप उन्हें फिर से ढूँढ़ सकें।',
    gujarati:
        'તમે જે વસ્તુઓ જુઓ છો તે અહીં દેખાશે જેથી તમે તેમને ફરીથી શોધી શકો.',
  ),
  AccountCommerceL10n.loadingMore: LocalizedMessage(
    english: 'Loading more...',
    hindi: 'और लोड हो रहा है...',
    gujarati: 'વધુ લોડ થઈ રહ્યું છે...',
  ),
  AccountCommerceL10n.untitledProduct: LocalizedMessage(
    english: 'Untitled product',
    hindi: 'बिना शीर्षक वाला उत्पाद',
    gujarati: 'શીર્ષક વિનાનું ઉત્પાદન',
  ),
  AccountCommerceL10n.specsUnavailable: LocalizedMessage(
    english: 'Specs unavailable',
    hindi: 'ऐनक उपलब्ध नहीं हैं',
    gujarati: 'સ્પેક્સ અનુપલબ્ધ છે',
  ),
  AccountCommerceL10n.stockNumber: LocalizedMessage(
    english: 'Stock {stock}',
    hindi: 'स्टॉक {stock}',
    gujarati: 'સ્ટોક {stock}',
  ),
  AccountCommerceL10n.viewedOn: LocalizedMessage(
    english: 'Viewed {date}',
    hindi: '{date} देखा गया',
    gujarati: '{date} જોયું',
  ),
  AccountCommerceL10n.onHold: LocalizedMessage(
    english: 'On Hold',
    hindi: 'होल्ड पर',
    gujarati: 'હોલ્ડ પર',
  ),
  AccountCommerceL10n.onMemo: LocalizedMessage(
    english: 'On Memo',
    hindi: 'ज्ञापन पर',
    gujarati: 'મેમો પર',
  ),
  AccountCommerceL10n.sold: LocalizedMessage(
    english: 'Sold',
    hindi: 'बिक गया',
    gujarati: 'વેચાય છે',
  ),
  AccountCommerceL10n.yourCart: LocalizedMessage(
    english: 'Your Cart',
    hindi: 'आपकी कार्ट',
    gujarati: 'તમારી કાર્ટ',
  ),
  AccountCommerceL10n.cartEmpty: LocalizedMessage(
    english: 'Your cart is empty',
    hindi: 'आपकी कार्ट रिक्त है ।',
    gujarati: 'તમારું કાર્ટ ખાલી છે',
  ),
  AccountCommerceL10n.continueShopping: LocalizedMessage(
    english: 'Continue shopping',
    hindi: 'खरीदारी जारी रखें',
    gujarati: 'ખરીદી ચાલુ રાખો',
  ),
  AccountCommerceL10n.deliverTo: LocalizedMessage(
    english: 'Deliver to',
    hindi: 'पर डिलीवर करें',
    gujarati: 'અહીં ડિલિવર કરો',
  ),
  AccountCommerceL10n.noAddress: LocalizedMessage(
    english: 'No delivery address yet. Add one to proceed to payment.',
    hindi:
        'अभी तक कोई डिलीवरी पता नहीं है। भुगतान करने के लिए आगे बढ़ने के लिए एक जोड़ें।',
    gujarati:
        'હજી સુધી કોઈ ડિલિવરી સરનામું નથી. ચુકવણી પર આગળ વધવા માટે એક ઉમેરો.',
  ),
  AccountCommerceL10n.savedAddresses: LocalizedMessage(
    english: 'Saved addresses',
    hindi: 'सेव किये गए पते',
    gujarati: 'સાચવેલા સરનામાંઓ',
  ),
  AccountCommerceL10n.editAddress: LocalizedMessage(
    english: 'Edit address',
    hindi: 'पता संपादित करें',
    gujarati: 'સરનામાંમાં ફેરફાર કરો',
  ),
  AccountCommerceL10n.deleteAddress: LocalizedMessage(
    english: 'Delete address',
    hindi: 'पता मिटाएँ',
    gujarati: 'સરનામું કાઢી નાખો',
  ),
  AccountCommerceL10n.addAddress: LocalizedMessage(
    english: 'Add new address',
    hindi: 'नया पता जोड़ें ',
    gujarati: 'નવું સરનામું ઉમેરો',
  ),
  AccountCommerceL10n.addressSaved: LocalizedMessage(
    english: 'Address saved',
    hindi: 'पता सेव किया गया',
    gujarati: 'સરનામું સાચવવામાં આવ્યું',
  ),
  AccountCommerceL10n.addressUpdated: LocalizedMessage(
    english: 'Address updated',
    hindi: 'पता अपडेट किया गया',
    gujarati: 'સરનામું અપડેટ થયું',
  ),
  AccountCommerceL10n.addressDeleted: LocalizedMessage(
    english: 'Address deleted',
    hindi: 'पता मिटा दिया गया',
    gujarati: 'સરનામું કાઢી નાખવામાં આવ્યું',
  ),
  AccountCommerceL10n.deleteAddressTitle: LocalizedMessage(
    english: 'Delete address?',
    hindi: 'पता मिटाएँ',
    gujarati: 'સરનામું કાઢી નાખો?',
  ),
  AccountCommerceL10n.fullNameField: LocalizedMessage(
    english: 'Full name',
    hindi: 'पूरा नाम',
    gujarati: 'પૂરું નામ',
  ),
  AccountCommerceL10n.phone: LocalizedMessage(
    english: 'Phone',
    hindi: 'फ़ोन',
    gujarati: 'ફોન',
  ),
  AccountCommerceL10n.state: LocalizedMessage(
    english: 'State',
    hindi: 'राज्य',
    gujarati: 'રાજ્ય',
  ),
  AccountCommerceL10n.postalCodeCaps: LocalizedMessage(
    english: 'ZIP / Postal code',
    hindi: 'ज़िप/पोस्टल कोड',
    gujarati: 'ઝિપ/પોસ્ટલ કોડ',
  ),
  AccountCommerceL10n.addressLabel: LocalizedMessage(
    english: 'Label (Home, Office)',
    hindi: 'लेबल (घर, ऑफ़िस)',
    gujarati: 'લેબલ (ઘર, કાર્યાલય)',
  ),
  AccountCommerceL10n.updateAddress: LocalizedMessage(
    english: 'Update address',
    hindi: 'पता अपडेट करें',
    gujarati: 'સરનામું અપડેટ કરો',
  ),
  AccountCommerceL10n.saveAddress: LocalizedMessage(
    english: 'Save address',
    hindi: 'पता सेव करें',
    gujarati: 'સરનામું સાચવો',
  ),
  AccountCommerceL10n.promoApplied: LocalizedMessage(
    english: 'Promo applied',
    hindi: 'प्रोमो लागू किया गया',
    gujarati: 'પ્રોમો લાગુ',
  ),
  AccountCommerceL10n.promoCode: LocalizedMessage(
    english: 'Promo code',
    hindi: 'प्रोमो कोड',
    gujarati: 'પ્રોમો કોડ',
  ),
  AccountCommerceL10n.enterCode: LocalizedMessage(
    english: 'Enter code',
    hindi: 'कोड दर्ज करें',
    gujarati: 'કોડ દાખલ કરો',
  ),
  AccountCommerceL10n.automaticDiscount: LocalizedMessage(
    english: 'Automatic discount',
    hindi: 'ऑटोमैटिक छूट',
    gujarati: 'આપમેળે ડિસ્કાઉન્ટ',
  ),
  AccountCommerceL10n.promoDiscount: LocalizedMessage(
    english: 'Promo discount',
    hindi: 'प्रोमो पर छूट',
    gujarati: 'પ્રોમો ડિસ્કાઉન્ટ',
  ),
  AccountCommerceL10n.loadingFees: LocalizedMessage(
    english: 'Loading fees?',
    hindi: 'शुल्क लोड हो रहा है?',
    gujarati: 'ફી લોડ થઈ રહી છે?',
  ),
  AccountCommerceL10n.amountToPay: LocalizedMessage(
    english: 'Amount to pay',
    hindi: 'भुगतान की राशि: ',
    gujarati: 'ચૂકવણી કરવાની રકમ',
  ),
  AccountCommerceL10n.payRazorpay: LocalizedMessage(
    english: 'Pay via Razorpay',
    hindi: 'Razorpay के ज़रिए भुगतान करें',
    gujarati: 'Razorpay દ્વારા ચૂકવણી કરો',
  ),
  AccountCommerceL10n.addDeliveryAddress: LocalizedMessage(
    english: 'Add delivery address',
    hindi: 'डिलिवरी का पता',
    gujarati: 'ડિલિવરીનું સરનામું ઉમેરો',
  ),
  AccountCommerceL10n.removeUnavailable: LocalizedMessage(
    english: 'Remove unavailable items',
    hindi: 'अनुपलब्ध आइटम हटाएँ',
    gujarati: 'અનુપલબ્ધ વસ્તુઓ દૂર કરો',
  ),
  AccountCommerceL10n.continueCheckout: LocalizedMessage(
    english: 'Continue to checkout',
    hindi: 'चेक आउट करना जारी रखें',
    gujarati: 'ચેકઆઉટ કરવાનું ચાલુ રાખો',
  ),
  AccountCommerceL10n.payWallet: LocalizedMessage(
    english: 'Pay with wallet',
    hindi: 'वॉलेट से भुगतान करें',
    gujarati: 'વૉલેટથી ચૂકવણી કરો',
  ),
  AccountCommerceL10n.paymentSuccessful: LocalizedMessage(
    english: 'Payment successful',
    hindi: 'भुगतान सफल हुआ।',
    gujarati: 'ચુકવણી સફળ થઈ',
  ),
  AccountCommerceL10n.orderConfirmation: LocalizedMessage(
    english: 'Order confirmation',
    hindi: 'ऑर्डर की पुष्टि',
    gujarati: 'ઓર્ડર પુષ્ટિ:',
  ),
  AccountCommerceL10n.couldNotLoadOrder: LocalizedMessage(
    english: 'Could not load order.',
    hindi: 'ऑर्डर लोड नहीं किया जा सका।',
    gujarati: 'ઓર્ડર લોડ કરી શકાયો નથી.',
  ),
  AccountCommerceL10n.skipViewOrders: LocalizedMessage(
    english: 'Skip & view orders',
    hindi: 'ऑर्डर छोड़ें और देखें',
    gujarati: 'ઑર્ડર્સ અવગણો અને જુઓ',
  ),
  AccountCommerceL10n.compareInstruction: LocalizedMessage(
    english: 'Select at least 2 items of the same type to compare.',
    hindi: 'तुलना करने के लिए एक ही प्रकार के कम से कम 2 आइटम चुनें।',
    gujarati: 'તુલના કરવા માટે સમાન પ્રકારની ઓછામાં ઓછી 2 વસ્તુઓ પસંદ કરો.',
  ),
  AccountCommerceL10n.goBack: LocalizedMessage(
    english: 'Go back',
    hindi: 'वापस जाएँ',
    gujarati: 'પાછા જાવ',
  ),
  AccountCommerceL10n.compareTitle: LocalizedMessage(
    english: 'Compare {category}',
    hindi: '{category} की तुलना करें',
    gujarati: '{category} ની સરખામણી કરો',
  ),
  AccountCommerceL10n.startNew: LocalizedMessage(
    english: 'Start New',
    hindi: 'नया खेल प्रारंभ करें',
    gujarati: 'નવી રમત પસંદ કરો',
  ),
  AccountCommerceL10n.addComparison: LocalizedMessage(
    english: 'Add to comparison',
    hindi: 'तुलना में जोड़ें',
    gujarati: 'સરખામણીમાં ઉમેરો',
  ),
  AccountCommerceL10n.removeComparison: LocalizedMessage(
    english: 'Remove from comparison',
    hindi: 'तुलना से हटाएँ',
    gujarati: 'સરખામણીમાંથી દૂર કરો',
  ),
  AccountCommerceL10n.addedComparison: LocalizedMessage(
    english: 'Added to comparison',
    hindi: 'तुलना में जोड़ा गया',
    gujarati: 'સરખામણીમાં ઉમેરવામાં આવ્યું',
  ),
  AccountCommerceL10n.removedComparison: LocalizedMessage(
    english: 'Removed from comparison',
    hindi: 'तुलना से हटाया गया',
    gujarati: 'તુલનામાંથી દૂર કરવામાં આવ્યું',
  ),
  AccountCommerceL10n.alreadySelected: LocalizedMessage(
    english: 'Already selected',
    hindi: 'पहले ही चुना जा चुका है',
    gujarati: 'પહેલેથી જ પસંદ કરેલ છે',
  ),
  AccountCommerceL10n.compareLimit: LocalizedMessage(
    english: 'You can compare up to 4 items',
    hindi: 'आप अधिकतम 4 आइटम की तुलना कर सकते हैं',
    gujarati: 'તમે 4 વસ્તુઓ સુધીની તુલના કરી શકો છો',
  ),
  AccountCommerceL10n.selectedCount: LocalizedMessage(
    english: '{count} {category} selected',
    hindi: '{count} {category} चुना गया',
    gujarati: '{count} {category} પસંદ કરેલ',
  ),
  AccountCommerceL10n.browseMore: LocalizedMessage(
    english: 'Browse More',
    hindi: 'और ब्राउज़ करें',
    gujarati: 'વધુ બ્રાઉઝ કરો',
  ),
  AccountCommerceL10n.newComparison: LocalizedMessage(
    english: 'Start New Comparison',
    hindi: 'नई तुलना शुरू करें',
    gujarati: 'નવી સરખામણી શરૂ કરો',
  ),
  AccountCommerceL10n.reorderHint: LocalizedMessage(
    english: 'Hold & drag cards to reorder',
    hindi: 'फिर से ऑर्डर करने के लिए कार्ड पकड़ें और खींचें',
    gujarati: 'ફરીથી ક્રમમાં રાખવા માટે કાર્ડને પકડી રાખો અને ખેંચો',
  ),
  AccountCommerceL10n.compareEyebrow: LocalizedMessage(
    english: 'Side by side',
    hindi: 'आमने-सामने',
    gujarati: 'સામસામે',
  ),
  AccountCommerceL10n.comparePiecesOf: LocalizedMessage(
    english: '{count} of {max} pieces',
    hindi: '{max} में से {count} आइटम',
    gujarati: '{max} માંથી {count} વસ્તુઓ',
  ),
  AccountCommerceL10n.compareAddPiece: LocalizedMessage(
    english: 'Add a piece',
    hindi: 'आइटम जोड़ें',
    gujarati: 'વસ્તુ ઉમેરો',
  ),
  AccountCommerceL10n.compareAllSpecs: LocalizedMessage(
    english: 'All specs',
    hindi: 'सभी विवरण',
    gujarati: 'બધી વિગતો',
  ),
  AccountCommerceL10n.compareDifferences: LocalizedMessage(
    english: 'Differences',
    hindi: 'अंतर',
    gujarati: 'તફાવત',
  ),
  AccountCommerceL10n.compareLeads: LocalizedMessage(
    english: 'Leads {wins} of {total}',
    hindi: '{total} में से {wins} में आगे',
    gujarati: '{total} માંથી {wins} માં આગળ',
  ),
  AccountCommerceL10n.compareLegend: LocalizedMessage(
    english: 'Gold marks the strongest value in each row',
    hindi: 'सुनहरा रंग हर पंक्ति का सबसे अच्छा मान दिखाता है',
    gujarati: 'સોનેરી રંગ દરેક પંક્તિનું શ્રેષ્ઠ મૂલ્ય બતાવે છે',
  ),
  AccountCommerceL10n.compareClear: LocalizedMessage(
    english: 'Clear',
    hindi: 'साफ़ करें',
    gujarati: 'સાફ કરો',
  ),
  AccountCommerceL10n.compareClearTitle: LocalizedMessage(
    english: 'Clear this comparison?',
    hindi: 'यह तुलना साफ़ करें?',
    gujarati: 'આ સરખામણી સાફ કરવી છે?',
  ),
  AccountCommerceL10n.compareClearBody: LocalizedMessage(
    english:
        'Every piece leaves the comparison and your selection. You can start a new one from any listing.',
    hindi:
        'सभी आइटम तुलना और आपके चयन से हट जाएँगे। आप किसी भी सूची से नई तुलना शुरू कर सकते हैं।',
    gujarati:
        'બધી વસ્તુઓ સરખામણી અને તમારી પસંદગીમાંથી દૂર થશે. તમે કોઈપણ સૂચિમાંથી નવી સરખામણી શરૂ કરી શકો છો.',
  ),
  AccountCommerceL10n.compareKeep: LocalizedMessage(
    english: 'Keep comparing',
    hindi: 'तुलना जारी रखें',
    gujarati: 'સરખામણી ચાલુ રાખો',
  ),
  AccountCommerceL10n.compareViewDetails: LocalizedMessage(
    english: 'View details',
    hindi: 'विवरण देखें',
    gujarati: 'વિગતો જુઓ',
  ),
  AccountCommerceL10n.compareMoveLeft: LocalizedMessage(
    english: 'Move left',
    hindi: 'बाईं ओर ले जाएँ',
    gujarati: 'ડાબે ખસેડો',
  ),
  AccountCommerceL10n.compareMoveRight: LocalizedMessage(
    english: 'Move right',
    hindi: 'दाईं ओर ले जाएँ',
    gujarati: 'જમણે ખસેડો',
  ),
  AccountCommerceL10n.compareUndo: LocalizedMessage(
    english: 'Undo',
    hindi: 'पूर्ववत करें',
    gujarati: 'પૂર્વવત્ કરો',
  ),
  AccountCommerceL10n.compareEmptyTitle: LocalizedMessage(
    english: 'Nothing to compare yet',
    hindi: 'अभी तुलना के लिए कुछ नहीं है',
    gujarati: 'હજી સરખામણી માટે કંઈ નથી',
  ),
  AccountCommerceL10n.compareEmptyBody: LocalizedMessage(
    english:
        'Select up to four pieces of the same kind from any listing and see them side by side.',
    hindi:
        'किसी भी सूची से एक ही प्रकार के चार तक आइटम चुनें और उन्हें आमने-सामने देखें।',
    gujarati:
        'કોઈપણ સૂચિમાંથી એક જ પ્રકારની ચાર સુધીની વસ્તુઓ પસંદ કરો અને તેમને સામસામે જુઓ.',
  ),
  AccountCommerceL10n.compareOneMore: LocalizedMessage(
    english: 'Add one more piece to see how they differ.',
    hindi: 'अंतर देखने के लिए एक और आइटम जोड़ें।',
    gujarati: 'તફાવત જોવા માટે વધુ એક વસ્તુ ઉમેરો.',
  ),
  AccountCommerceL10n.compareAllIdentical: LocalizedMessage(
    english: 'These pieces match on every listed spec.',
    hindi: 'ये आइटम हर सूचीबद्ध विवरण में एक जैसे हैं।',
    gujarati: 'આ વસ્તુઓ દરેક સૂચિબદ્ધ વિગતમાં સમાન છે.',
  ),
  AccountCommerceL10n.compareFabEmpty: LocalizedMessage(
    english: 'Select up to 4 pieces to compare',
    hindi: 'तुलना के लिए 4 तक आइटम चुनें',
    gujarati: 'સરખામણી માટે 4 સુધીની વસ્તુઓ પસંદ કરો',
  ),
  AccountCommerceL10n.compareFabOver: LocalizedMessage(
    english: 'Compare holds up to 4 · {count} selected',
    hindi: 'तुलना में 4 तक · {count} चुने गए',
    gujarati: 'સરખામણીમાં 4 સુધી · {count} પસંદ કર્યા',
  ),
  AccountCommerceL10n.compareFabOpen: LocalizedMessage(
    english: 'Compare {count} pieces',
    hindi: '{count} आइटम की तुलना करें',
    gujarati: '{count} વસ્તુઓની સરખામણી કરો',
  ),
  AccountCommerceL10n.compareSwitched: LocalizedMessage(
    english: 'Comparison now holds diamonds',
    hindi: 'तुलना में अब हीरे हैं',
    gujarati: 'સરખામણીમાં હવે હીરા છે',
  ),
  AccountCommerceL10n.compareOverLimit: LocalizedMessage(
    english:
        '{count} selected · compare pauses above 4, your project keeps them all',
    hindi:
        '{count} चुने गए · 4 से अधिक पर तुलना रुकती है, प्रोजेक्ट में सभी रहते हैं',
    gujarati:
        '{count} પસંદ · 4 થી વધુ પર સરખામણી અટકે છે, પ્રોજેક્ટમાં બધા રહે છે',
  ),
  AccountCommerceL10n.compareSelect: LocalizedMessage(
    english: 'Select for compare and project',
    hindi: 'तुलना और प्रोजेक्ट के लिए चुनें',
    gujarati: 'સરખામણી અને પ્રોજેક્ટ માટે પસંદ કરો',
  ),
  AccountCommerceL10n.compareDeselect: LocalizedMessage(
    english: 'Remove from selection',
    hindi: 'चयन से हटाएँ',
    gujarati: 'પસંદગીમાંથી દૂર કરો',
  ),
  AccountCommerceL10n.compareGroupEssentials: LocalizedMessage(
    english: 'Essentials',
    hindi: 'मुख्य बातें',
    gujarati: 'મુખ્ય બાબતો',
  ),
  AccountCommerceL10n.compareGroupFourCs: LocalizedMessage(
    english: 'The four Cs',
    hindi: 'चार C',
    gujarati: 'ચાર C',
  ),
  AccountCommerceL10n.compareGroupProportions: LocalizedMessage(
    english: 'Proportions',
    hindi: 'अनुपात',
    gujarati: 'પ્રમાણ',
  ),
  AccountCommerceL10n.compareGroupFinish: LocalizedMessage(
    english: 'Finish',
    hindi: 'फ़िनिश',
    gujarati: 'ફિનિશ',
  ),
  AccountCommerceL10n.compareGroupProvenance: LocalizedMessage(
    english: 'Provenance',
    hindi: 'प्रमाणन',
    gujarati: 'પ્રમાણન',
  ),
  AccountCommerceL10n.compareGroupCharacter: LocalizedMessage(
    english: 'Character',
    hindi: 'गुण',
    gujarati: 'ગુણ',
  ),
  AccountCommerceL10n.compareGroupCraft: LocalizedMessage(
    english: 'Craft',
    hindi: 'कारीगरी',
    gujarati: 'કારીગરી',
  ),
  AccountCommerceL10n.compareGroupMetal: LocalizedMessage(
    english: 'Metal',
    hindi: 'धातु',
    gujarati: 'ધાતુ',
  ),
  AccountCommerceL10n.compareGroupStones: LocalizedMessage(
    english: 'Stones',
    hindi: 'रत्न',
    gujarati: 'રત્નો',
  ),
  AccountCommerceL10n.compareGroupDetails: LocalizedMessage(
    english: 'Details',
    hindi: 'विवरण',
    gujarati: 'વિગતો',
  ),
  AccountCommerceL10n.projectClear: LocalizedMessage(
    english: 'Clear selection',
    hindi: 'चयन साफ़ करें',
    gujarati: 'પસંદગી સાફ કરો',
  ),
  AccountCommerceL10n.projectShown: LocalizedMessage(
    english: '{shown} of {total}',
    hindi: '{total} में से {shown}',
    gujarati: '{total} માંથી {shown}',
  ),
  AccountCommerceL10n.projectSelectedCount: LocalizedMessage(
    english: '{count} selected',
    hindi: '{count} चुने गए',
    gujarati: '{count} પસંદ કર્યા',
  ),
  AccountCommerceL10n.projectSelectAll: LocalizedMessage(
    english: 'Select all',
    hindi: 'सभी चुनें',
    gujarati: 'બધા પસંદ કરો',
  ),
  AccountCommerceL10n.projectSelecting: LocalizedMessage(
    english: 'Selecting every matching stone',
    hindi: 'सभी मेल खाते पत्थर चुने जा रहे हैं',
    gujarati: 'બધા મેળ ખાતા પથ્થરો પસંદ થઈ રહ્યા છે',
  ),
  AccountCommerceL10n.projectLoadFailed: LocalizedMessage(
    english: "Couldn't load every stone. Try again.",
    hindi: 'सभी पत्थर लोड नहीं हो सके। फिर से प्रयास करें।',
    gujarati: 'બધા પથ્થરો લોડ થઈ શક્યા નહીં. ફરી પ્રયાસ કરો.',
  ),
  AccountCommerceL10n.projectAnalytics: LocalizedMessage(
    english: 'Analytics',
    hindi: 'विश्लेषण',
    gujarati: 'વિશ્લેષણ',
  ),
  AccountCommerceL10n.projectAnalyticsHint: LocalizedMessage(
    english: 'View detailed analytics',
    hindi: 'विस्तृत विश्लेषण देखें',
    gujarati: 'વિગતવાર વિશ્લેષણ જુઓ',
  ),
  AccountCommerceL10n.notAvailable: LocalizedMessage(
    english: 'N/A',
    hindi: 'N/A',
    gujarati: 'લાગુ પડતું નથી',
  ),
  AccountCommerceL10n.compareDiamond: LocalizedMessage(
    english: 'diamond',
    hindi: 'हीरा',
    gujarati: 'હિરો',
  ),
  AccountCommerceL10n.compareDiamonds: LocalizedMessage(
    english: 'diamonds',
    hindi: 'ईंट',
    gujarati: 'ચરકટ',
  ),
  AccountCommerceL10n.compareGemstone: LocalizedMessage(
    english: 'gemstone',
    hindi: 'रत्न',
    gujarati: 'રત્ન',
  ),
  AccountCommerceL10n.compareGemstones: LocalizedMessage(
    english: 'gemstones',
    hindi: 'रत्न',
    gujarati: 'રત્નો',
  ),
  AccountCommerceL10n.compareWatch: LocalizedMessage(
    english: 'watch',
    hindi: 'तक के लिए देखो',
    gujarati: 'કાંડા ઘડિયાળ',
  ),
  AccountCommerceL10n.compareWatches: LocalizedMessage(
    english: 'watches',
    hindi: 'निगरानी',
    gujarati: 'ઘડિયાળો',
  ),
  AccountCommerceL10n.compareJewelry: LocalizedMessage(
    english: 'jewelry piece',
    hindi: 'ज्वेलरी पीस',
    gujarati: 'જ્વેલરી પીસ',
  ),
  AccountCommerceL10n.compareJewelryPieces: LocalizedMessage(
    english: 'jewelry pieces',
    hindi: 'ज्वेलरी पीस',
    gujarati: 'જ્વેલરી પીસ',
  ),
  AccountCommerceL10n.price: LocalizedMessage(
    english: 'Price',
    hindi: 'मूल्य',
    gujarati: 'કિંમત ',
  ),
  AccountCommerceL10n.caratWeight: LocalizedMessage(
    english: 'Carat Weight',
    hindi: 'कैरेट वजन',
    gujarati: 'કેરેટ વજન',
  ),
  AccountCommerceL10n.shape: LocalizedMessage(
    english: 'Shape',
    hindi: 'आकृति',
    gujarati: 'આકાર',
  ),
  AccountCommerceL10n.measurements: LocalizedMessage(
    english: 'Measurements',
    hindi: 'मापन',
    gujarati: 'માપનો',
  ),
  AccountCommerceL10n.certificate: LocalizedMessage(
    english: 'Certificate #',
    hindi: 'सर्टिफ़िकेट ',
    gujarati: 'પ્રમાણપત્ર',
  ),
  AccountCommerceL10n.cut: LocalizedMessage(
    english: 'Cut',
    hindi: 'कट करें',
    gujarati: 'કાપો',
  ),
  AccountCommerceL10n.color: LocalizedMessage(
    english: 'Color',
    hindi: 'रंग',
    gujarati: 'રંગ',
  ),
  AccountCommerceL10n.clarity: LocalizedMessage(
    english: 'Clarity',
    hindi: 'सवाल पूछें',
    gujarati: 'સ્પષ્ટતા',
  ),
  AccountCommerceL10n.tablePercent: LocalizedMessage(
    english: 'Table %',
    hindi: 'मेज़',
    gujarati: 'ટેબલ',
  ),
  AccountCommerceL10n.depthPercent: LocalizedMessage(
    english: 'Depth %',
    hindi: 'गहराई',
    gujarati: 'ડેપ્થ',
  ),
  AccountCommerceL10n.ratio: LocalizedMessage(
    english: 'Ratio',
    hindi: 'अनुपात',
    gujarati: 'રેશિયો ',
  ),
  AccountCommerceL10n.polish: LocalizedMessage(
    english: 'Polish',
    hindi: 'पोलिश',
    gujarati: 'પોલિશ',
  ),
  AccountCommerceL10n.symmetry: LocalizedMessage(
    english: 'Symmetry',
    hindi: 'सममिती',
    gujarati: 'સમપ્રમાણ ',
  ),
  AccountCommerceL10n.fluorescence: LocalizedMessage(
    english: 'Fluorescence',
    hindi: 'प्रतिदीप्ति',
    gujarati: 'ફ્લોરોસેન્સ',
  ),
  AccountCommerceL10n.lab: LocalizedMessage(
    english: 'Lab',
    hindi: 'लैब',
    gujarati: 'LAB',
  ),
  AccountCommerceL10n.totalCarat: LocalizedMessage(
    english: 'Total Carat',
    hindi: 'कुल कैरेट',
    gujarati: 'કુલ કેરેટ',
  ),
  AccountCommerceL10n.type: LocalizedMessage(
    english: 'Type',
    hindi: 'प्रकार',
    gujarati: 'ખોટો પાસવર્ડ.',
  ),
  AccountCommerceL10n.origin: LocalizedMessage(
    english: 'Origin',
    hindi: 'मूल स्रोत',
    gujarati: 'શરૂઆત',
  ),
  AccountCommerceL10n.treatment: LocalizedMessage(
    english: 'Treatment',
    hindi: 'उपचार',
    gujarati: 'સારવાર',
  ),
  AccountCommerceL10n.dimensions: LocalizedMessage(
    english: 'Dimensions',
    hindi: 'आयाम',
    gujarati: 'પરિણામો',
  ),
  AccountCommerceL10n.hardness: LocalizedMessage(
    english: 'Hardness',
    hindi: 'कठोरता',
    gujarati: 'કઠણ',
  ),
  AccountCommerceL10n.brand: LocalizedMessage(
    english: 'Brand',
    hindi: 'ब्रांड',
    gujarati: 'બ્રાન્ડ',
  ),
  AccountCommerceL10n.model: LocalizedMessage(
    english: 'Model',
    hindi: 'मॉडल',
    gujarati: 'મોડેલ',
  ),
  AccountCommerceL10n.movement: LocalizedMessage(
    english: 'Movement',
    hindi: 'गति',
    gujarati: 'હલન-ચલન',
  ),
  AccountCommerceL10n.caseMaterial: LocalizedMessage(
    english: 'Case Material',
    hindi: 'केस सामग्री',
    gujarati: 'કેસ મટિરિયલ',
  ),
  AccountCommerceL10n.dialColor: LocalizedMessage(
    english: 'Dial Color',
    hindi: 'डायल का रंग',
    gujarati: 'ડાયલ રંગ',
  ),
  AccountCommerceL10n.gender: LocalizedMessage(
    english: 'Gender',
    hindi: 'लिंग',
    gujarati: 'લિંગ',
  ),
  AccountCommerceL10n.year: LocalizedMessage(
    english: 'Year',
    hindi: 'वर्ष',
    gujarati: 'વર્ષ',
  ),
  AccountCommerceL10n.uploadProfileImage: LocalizedMessage(
    english: 'Upload profile image',
    hindi: 'प्रोफ़ाइल चित्र अपलोड करें',
    gujarati: 'પ્રોફાઇલ છબી અપલોડ કરો',
  ),
  AccountCommerceL10n.termsAgreement: LocalizedMessage(
    english:
        'Please agree to the Terms of Service (including chatbot data use) and Ethical Sourcing Policy.',
    hindi:
        'कृपया सेवा की शर्तों (चैटबॉट डेटा उपयोग सहित) और नैतिक सोर्सिंग नीति से सहमत हों।',
    gujarati:
        'કૃપા કરીને સેવાની શરતો (ચેટબોટ ડેટા ઉપયોગ સહિત) અને નૈતિક સોર્સિંગ નીતિ સાથે સંમત થાઓ.',
  ),
  AccountCommerceL10n.sellerIncomplete: LocalizedMessage(
    english: 'Seller registration details are incomplete.',
    hindi: 'विक्रेता के रजिस्ट्रेशन का ब्यौरा अधूरा है।',
    gujarati: 'વિક્રેતાની નોંધણી વિગતો અધૂરી છે.',
  ),
  AccountCommerceL10n.companyLogoRequired: LocalizedMessage(
    english: 'Company logo is required.',
    hindi: 'कंपनी का लोगो ज़रूरी है।',
    gujarati: 'કંપનીનો લોગો જરૂરી છે.',
  ),
  AccountCommerceL10n.address1Required: LocalizedMessage(
    english: 'Address line 1 is required',
    hindi: 'पते में लाइन 1 आवश्यक है',
    gujarati: 'સરનામાંની લાઇન 1 જરૂરી છે',
  ),
  AccountCommerceL10n.address2Required: LocalizedMessage(
    english: 'Address line 2 is required',
    hindi: 'पते में लाइन 2 आवश्यक है',
    gujarati: 'સરનામાંની લાઇન 2 જરૂરી છે',
  ),
  AccountCommerceL10n.cityRequired: LocalizedMessage(
    english: 'City is required',
    hindi: 'शहर आवश्यक है',
    gujarati: 'જરૂરી છે',
  ),
  AccountCommerceL10n.stateRequired: LocalizedMessage(
    english: 'State is required',
    hindi: 'राज्य आवश्यक है',
    gujarati: 'રાજ્ય જરૂરી છે',
  ),
  AccountCommerceL10n.countryRequired: LocalizedMessage(
    english: 'Country is required',
    hindi: 'देश दर्ज करने की आवश्यकता है',
    gujarati: 'દેશ જરૂરી છે',
  ),
  AccountCommerceL10n.postalRequired: LocalizedMessage(
    english: 'ZIP / postal code is required',
    hindi: 'पिन कोड आवश्यक है',
    gujarati: 'ઝીપ / પોસ્ટલ કોડ આવશ્યક છે',
  ),
  AccountCommerceL10n.phone1Required: LocalizedMessage(
    english: 'Primary phone is required',
    hindi: 'प्राथमिक फ़ोन ज़रूरी है',
    gujarati: 'પ્રાથમિક ફોન જરૂરી છે',
  ),
  AccountCommerceL10n.phone2Required: LocalizedMessage(
    english: 'Secondary phone is required',
    hindi: 'सेकंडरी फ़ोन ज़रूरी है',
    gujarati: 'ગૌણ ફોન જરૂરી છે',
  ),
  AccountCommerceL10n.validPhone: LocalizedMessage(
    english: 'Enter a valid 10-digit phone number',
    hindi: 'मान्य 10 अंकों का फ़ोन नंबर डालें',
    gujarati: 'માન્ય 10-અંકનો ફોન નંબર દાખલ કરો',
  ),
  AccountCommerceL10n.rep1Required: LocalizedMessage(
    english: 'Representative name 1 is required',
    hindi: 'प्रतिनिधि का नाम 1 ज़रूरी है',
    gujarati: 'પ્રતિનિધિ નામ 1 જરૂરી છે',
  ),
  AccountCommerceL10n.rep2Required: LocalizedMessage(
    english: 'Representative name 2 is required',
    hindi: 'प्रतिनिधि का नाम 2 ज़रूरी है',
    gujarati: 'પ્રતિનિધિ નામ 2 જરૂરી છે',
  ),
  AccountCommerceL10n.panRequired: LocalizedMessage(
    english: 'PAN number is required',
    hindi: 'पैन नंबर ज़रूरी है',
    gujarati: 'પાન નંબર જરૂરી છે',
  ),
  AccountCommerceL10n.validPan: LocalizedMessage(
    english: 'Enter a valid PAN (e.g. ABCDE1234F)',
    hindi: 'मान्य पैन नंबर डालें (जैसे, ABCDE1234F)',
    gujarati: 'માન્ય PAN દાખલ કરો (દા .ત. ABCDE1234F)',
  ),
  AccountCommerceL10n.aadhaarRequired: LocalizedMessage(
    english: 'Aadhaar number is required',
    hindi: 'आधार नंबर ज़रूरी है',
    gujarati: 'આધાર નંબર જરૂરી છે',
  ),
  AccountCommerceL10n.validAadhaar: LocalizedMessage(
    english: 'Enter a valid 12-digit Aadhaar',
    hindi: '12 अंकों का मान्य आधार नंबर डालें',
    gujarati: 'માન્ય 12-અંકનો આધાર દાખલ કરો',
  ),
  AccountCommerceL10n.iecRequired: LocalizedMessage(
    english: 'IEC number is required',
    hindi: 'IEC नंबर ज़रूरी है',
    gujarati: 'IEC નંબર જરૂરી છે',
  ),
  AccountCommerceL10n.holderRequired: LocalizedMessage(
    english: 'Account holder name is required',
    hindi: 'खाताधारक का नाम ज़रूरी है।',
    gujarati: 'એકાઉન્ટ ધારકનું નામ જરૂરી છે',
  ),
  AccountCommerceL10n.accountNumberRequired: LocalizedMessage(
    english: 'Account number is required',
    hindi: 'खाता संख्या आवश्यक है',
    gujarati: 'એકાઉન્ટ નંબર જરૂરી છે',
  ),
  AccountCommerceL10n.accountNumberLength: LocalizedMessage(
    english: 'Account number must be 8?20 digits',
    hindi: 'अकाउंट नंबर 8?20 अंकों का होना चाहिए',
    gujarati: 'એકાઉન્ટ નંબર 8?20 અંકોનો હોવો જોઈએ',
  ),
  AccountCommerceL10n.ifscRequired: LocalizedMessage(
    english: 'IFSC code is required',
    hindi: 'आईएफएससी कोड आवश्यक है।',
    gujarati: 'IFSC કોડ જરૂરી છે',
  ),
  AccountCommerceL10n.validIfsc: LocalizedMessage(
    english: 'Enter a valid IFSC (e.g. HDFC0001234)',
    hindi: 'एक मान्य IFSC दर्ज करें (जैसे HDFC0001234)',
    gujarati: 'માન્ય IFSC દાખલ કરો (દા .ત. HDFC0001234)',
  ),
  AccountCommerceL10n.bankRequired: LocalizedMessage(
    english: 'Bank name is required',
    hindi: 'बैंक का नाम ज़रूरी है।',
    gujarati: 'નામ જરૂરી છે',
  ),
  AccountCommerceL10n.passwordUse8: LocalizedMessage(
    english: 'Use at least 8 characters.',
    hindi: 'कम - से - कम 8 कैरेक्टर का इस्तेमाल करें।',
    gujarati: 'ઓછામાં ઓછા 8 અક્ષરોનો ઉપયોગ કરો.',
  ),
  AccountCommerceL10n.passwordStrong: LocalizedMessage(
    english: 'Strong password.',
    hindi: 'मजबूत पासवर्ड।',
    gujarati: 'મજબૂત પાસવર્ડ.',
  ),
  AccountCommerceL10n.myProfileCaps: LocalizedMessage(
    english: 'My Profile',
    hindi: 'मेरी प्रोफ़ाइल',
    gujarati: 'મારી પ્રોફાઈલ',
  ),
  AccountCommerceL10n.helpCenterCaps: LocalizedMessage(
    english: 'Help Center',
    hindi: 'सहायता केंद्र',
    gujarati: 'કેડીઇ મદદ કેન્દ્ર',
  ),
  AccountCommerceL10n.sellerDashboard: LocalizedMessage(
    english: 'Seller dashboard',
    hindi: 'विक्रेता डैशबोर्ड',
    gujarati: 'વિક્રેતા ડેશબોર્ડ',
  ),
  AccountCommerceL10n.sellerAccountLabel: LocalizedMessage(
    english: 'Seller account',
    hindi: 'विक्रेता खाता',
    gujarati: 'વિક્રેતા એકાઉન્ટ',
  ),
  AccountCommerceL10n.accountLabel: LocalizedMessage(
    english: 'Account',
    hindi: 'खाता',
    gujarati: 'એકાઉન્ટ',
  ),
  AccountCommerceL10n.backToShop: LocalizedMessage(
    english: 'Back to shop',
    hindi: 'खरीदारी पर वापस जाएँ',
    gujarati: 'શોપ પર પાછા જાઓ',
  ),
  AccountCommerceL10n.shipmentTracking: LocalizedMessage(
    english: 'Shipment tracking',
    hindi: 'शिपमेंट ट्रैकिंग',
    gujarati: 'શિપમેન્ટ ટ્રેકિંગ',
  ),
  AccountCommerceL10n.trackingLoadFailed: LocalizedMessage(
    english: 'Could not load tracking.',
    hindi: 'ट्रैकिंग लोड नहीं की जा सकी।',
    gujarati: 'ટ્રેકિંગ લોડ કરી શકાયું નથી.',
  ),
  AccountCommerceL10n.noShipment: LocalizedMessage(
    english: 'No shipment yet. Tracking appears once the seller ships.',
    hindi:
        'अभी तक कोई शिपमेंट नहीं है। विक्रेता के जहाज आने के बाद ट्रैकिंग दिखाई देती है।',
    gujarati: 'હજુ સુધી કોઈ શિપમેન્ટ નથી. વેચનાર જહાજો પછી ટ્રેકિંગ દેખાય છે.',
  ),
  AccountCommerceL10n.trackingNumber: LocalizedMessage(
    english: 'Tracking # {number}',
    hindi: 'ट्रैकिंग # {number}',
    gujarati: 'ટ્રેકિંગ # {number}',
  ),
  AccountCommerceL10n.location: LocalizedMessage(
    english: 'Location: {location}',
    hindi: 'स्थान: {location}',
    gujarati: 'સ્થાન: {location}',
  ),
  AccountCommerceL10n.deleteAccountTitle: LocalizedMessage(
    english: 'Delete account?',
    hindi: 'खाता डिलीट करें',
    gujarati: 'ખાતું કાઢી નાંખવું છે?',
  ),
  AccountCommerceL10n.deleteAccountBody: LocalizedMessage(
    english:
        'Your account will be scheduled for deletion. You have 7 days to recover it from the email link or the recover account screen.',
    hindi:
        'आपका अकाउंट मिटाने के लिए शेड्यूल किया जाएगा। ईमेल लिंक या रिकवर अकाउंट स्क्रीन से इसे पुनर्प्राप्त करने के लिए आपके पास 7 दिन हैं।',
    gujarati:
        'તમારું એકાઉન્ટ કાઢી નાખવા માટે સુનિશ્ચિત કરવામાં આવશે. તમારી પાસે તેને ઇમેઇલ લિંક અથવા રિકવર એકાઉન્ટ સ્ક્રીન પરથી પુનઃપ્રાપ્ત કરવા માટે 7 દિવસ છે.',
  ),
  AccountCommerceL10n.currentPassword: LocalizedMessage(
    english: 'Current password',
    hindi: 'वर्तमान पासवर्ड',
    gujarati: 'વર્તમાન પાસવર્ડ',
  ),
  AccountCommerceL10n.signOutTitle: LocalizedMessage(
    english: 'Sign out?',
    hindi: 'साइन आउट करें',
    gujarati: 'સાઇન આઉટ કરો',
  ),
  AccountCommerceL10n.signOutBody: LocalizedMessage(
    english: 'Are you sure you want to sign out from this account?',
    hindi: 'क्या आप वाकई इस अकाउंट से साइन आउट करना चाहते हैं?',
    gujarati: 'શું તમે ખરેખર આ એકાઉન્ટમાંથી સાઇન આઉટ કરવા માંગો છો?',
  ),
  AccountCommerceL10n.inquiries: LocalizedMessage(
    english: 'Inquiries',
    hindi: 'पूछताछ',
    gujarati: 'પૂછપરછ',
  ),
  AccountCommerceL10n.newInquiry: LocalizedMessage(
    english: 'New inquiry',
    hindi: 'नई पूछताछ',
    gujarati: 'નવી પૂછપરછ',
  ),
  AccountCommerceL10n.inquiry: LocalizedMessage(
    english: 'Inquiry',
    hindi: 'पूछताछ',
    gujarati: 'પૂછપરછ',
  ),
  AccountCommerceL10n.chat: LocalizedMessage(
    english: 'Chat',
    hindi: 'चैट',
    gujarati: 'ચેટ',
  ),
  AccountCommerceL10n.compareCategoryMismatch: LocalizedMessage(
    english:
        'You can only compare {existing} with {existing}. Clear the tray to compare {attempted}.',
    hindi:
        'आप केवल {existing} की तुलना {existing} से कर सकते हैं। {attempted} की तुलना के लिए ट्रे साफ़ करें।',
    gujarati:
        'તમે ફક્ત {existing} ની સરખામણી {existing} સાથે કરી શકો છો. {attempted} ની સરખામણી કરવા ટ્રે સાફ કરો.',
  ),
  AccountCommerceL10n.available: LocalizedMessage(
    english: 'Available',
    hindi: 'उपलब्ध',
    gujarati: 'ઉપલબ્ધ',
  ),
  AccountCommerceL10n.unavailable: LocalizedMessage(
    english: 'Unavailable',
    hindi: 'अनुपलब्ध',
    gujarati: 'અનુપલબ્ધ',
  ),
  AccountCommerceL10n.naturalDiamond: LocalizedMessage(
    english: 'Natural diamond',
    hindi: 'प्राकृतिक हीरा',
    gujarati: 'કુદરતી હીરો',
  ),
  AccountCommerceL10n.labGrownDiamond: LocalizedMessage(
    english: 'Lab-grown diamond',
    hindi: 'Lab-grown diamond',
    gujarati: 'Lab-grown diamond',
  ),
  AccountCommerceL10n.jewellery: LocalizedMessage(
    english: 'Jewellery',
    hindi: 'आभूषण',
    gujarati: 'જ્વેલરી',
  ),
  AccountCommerceL10n.bullion: LocalizedMessage(
    english: 'Bullion',
    hindi: 'बुलियन',
    gujarati: 'બુલિયન',
  ),
  AccountCommerceL10n.savings: LocalizedMessage(
    english: 'Savings',
    hindi: 'बचत',
    gujarati: 'બચત',
  ),
  AccountCommerceL10n.current: LocalizedMessage(
    english: 'Current',
    hindi: 'चालू',
    gujarati: 'ચાલુ',
  ),
  AccountCommerceL10n.company: LocalizedMessage(
    english: 'Company',
    hindi: 'कंपनी',
    gujarati: 'કંપની',
  ),
  AccountCommerceL10n.businessAddress: LocalizedMessage(
    english: 'Business address',
    hindi: 'व्यवसाय का पता',
    gujarati: 'વ્યવસાયનું સરનામું',
  ),
  AccountCommerceL10n.businessContacts: LocalizedMessage(
    english: 'Business contacts',
    hindi: 'व्यवसाय संपर्क',
    gujarati: 'વ્યવસાય સંપર્કો',
  ),
  AccountCommerceL10n.taxKyc: LocalizedMessage(
    english: 'Tax & KYC',
    hindi: 'कर और KYC',
    gujarati: 'કર અને KYC',
  ),
  AccountCommerceL10n.username: LocalizedMessage(
    english: 'Username',
    hindi: 'यूज़रनेम',
    gujarati: 'યુઝરનેમ',
  ),
  AccountCommerceL10n.password: LocalizedMessage(
    english: 'Password',
    hindi: 'पासवर्ड',
    gujarati: 'પાસવર્ડ',
  ),
  AccountCommerceL10n.email: LocalizedMessage(
    english: 'Email',
    hindi: 'ईमेल',
    gujarati: 'ઇમેઇલ',
  ),
  AccountCommerceL10n.otp: LocalizedMessage(
    english: 'OTP',
    hindi: 'OTP',
    gujarati: 'OTP',
  ),
  AccountCommerceL10n.reason: LocalizedMessage(
    english: 'Reason',
    hindi: 'कारण',
    gujarati: 'કારણ',
  ),
  AccountCommerceL10n.refunds: LocalizedMessage(
    english: 'Refunds',
    hindi: 'रिफ़ंड',
    gujarati: 'રિફંડ',
  ),
  AccountCommerceL10n.refresh: LocalizedMessage(
    english: 'Refresh',
    hindi: 'रीफ़्रेश करें',
    gujarati: 'રિફ્રેશ કરો',
  ),
  AccountCommerceL10n.remove: LocalizedMessage(
    english: 'Remove',
    hindi: 'हटाएँ',
    gujarati: 'દૂર કરો',
  ),
  AccountCommerceL10n.viewMyOrders: LocalizedMessage(
    english: 'View my orders',
    hindi: 'मेरे ऑर्डर देखें',
    gujarati: 'મારા ઓર્ડર જુઓ',
  ),
  AccountCommerceL10n.compare: LocalizedMessage(
    english: 'Compare',
    hindi: 'तुलना करें',
    gujarati: 'સરખામણી કરો',
  ),
  AccountCommerceL10n.passwordAddRequirements: LocalizedMessage(
    english: 'Password is weak. Add {requirements}.',
    hindi: 'पासवर्ड कमज़ोर है। {requirements} जोड़ें।',
    gujarati: 'પાસવર્ડ નબળો છે. {requirements} ઉમેરો.',
  ),
  AccountCommerceL10n.uppercaseLetter: LocalizedMessage(
    english: 'an uppercase letter',
    hindi: 'एक बड़ा अक्षर',
    gujarati: 'એક મોટો અક્ષર',
  ),
  AccountCommerceL10n.lowercaseLetter: LocalizedMessage(
    english: 'a lowercase letter',
    hindi: 'एक छोटा अक्षर',
    gujarati: 'એક નાનો અક્ષર',
  ),
  AccountCommerceL10n.numberRequirement: LocalizedMessage(
    english: 'a number',
    hindi: 'एक संख्या',
    gujarati: 'એક નંબર',
  ),
  AccountCommerceL10n.symbolRequirement: LocalizedMessage(
    english: 'a symbol',
    hindi: 'एक प्रतीक',
    gujarati: 'એક ચિહ્ન',
  ),
};
