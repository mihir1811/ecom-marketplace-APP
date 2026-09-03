import '../localized_message.dart';

/// Stable localization keys for catalog, product, and filter frontends.
abstract final class CatalogL10n {
  static const basic = 'catalog.section.basic';
  static const preferences = 'catalog.section.preferences';
  static const measurements = 'catalog.section.measurements';
  static const advanced = 'catalog.section.advanced';
  static const prefShort = 'catalog.section.preferences.short';
  static const measurementsShort = 'catalog.section.measurements.short';
  static const advancedShort = 'catalog.section.advanced.short';
  static const filters = 'catalog.filters.title';
  static const editFilters = 'catalog.filters.edit';
  static const resetFilters = 'catalog.filters.reset';
  static const clearAll = 'catalog.filters.clearAll';
  static const apply = 'catalog.action.apply';
  static const reset = 'catalog.action.reset';
  static const clear = 'catalog.action.clear';
  static const add = 'catalog.action.add';
  static const view = 'catalog.action.view';
  static const compare = 'catalog.action.compare';
  static const wishlist = 'catalog.action.wishlist';
  static const retry = 'catalog.action.retry';
  static const search = 'catalog.action.search';
  static const showResults = 'catalog.action.showResults';
  static const viewAdvancedFilters = 'catalog.filters.advanced.view';
  static const hideAdvancedFilters = 'catalog.filters.advanced.hide';
  static const minimum = 'catalog.range.minimum';
  static const maximum = 'catalog.range.maximum';
  static const rangeValue = 'catalog.range.value';
  static const rangeFilters = 'catalog.range.filters';
  static const currentRange = 'catalog.range.current';
  static const any = 'catalog.value.any';
  static const pieces = 'catalog.unit.pieces';
  static const carat = 'catalog.unit.carat';
  static const totalCarat = 'catalog.range.totalCarat';
  static const totalPrice = 'catalog.range.totalPrice';
  static const pricePerCarat = 'catalog.range.pricePerCarat';
  static const pricePerPiece = 'catalog.range.pricePerPiece';
  static const totalPieces = 'catalog.range.totalPieces';
  static const caratPerPiece = 'catalog.range.caratPerPiece';
  static const length = 'catalog.measurement.length';
  static const width = 'catalog.measurement.width';
  static const height = 'catalog.measurement.height';
  static const lengthRange = 'catalog.measurement.lengthRange';
  static const widthRange = 'catalog.measurement.widthRange';
  static const heightRange = 'catalog.measurement.heightRange';
  static const ratioRange = 'catalog.measurement.ratioRange';
  static const ratioHelp = 'catalog.measurement.ratioHelp';
  static const lengthHelp = 'catalog.measurement.lengthHelp';
  static const widthHelp = 'catalog.measurement.widthHelp';
  static const heightHelp = 'catalog.measurement.heightHelp';
  static const roughSource = 'catalog.preferences.roughSource';
  static const roughSourceHelp = 'catalog.preferences.roughSourceHelp';
  static const selectRoughSource = 'catalog.preferences.selectRoughSource';
  static const minimumSellerRating = 'catalog.preferences.minimumSellerRating';
  static const sellerRatingHelp = 'catalog.preferences.sellerRatingHelp';
  static const ratingAndUp = 'catalog.preferences.ratingAndUp';
  static const selectDiamondShapes = 'catalog.diamond.selectShapes';
  static const diamondCategory = 'catalog.diamond.category';
  static const growthMethod = 'catalog.diamond.growthMethod';
  static const selectShape = 'catalog.filter.selectShape';
  static const shape = 'catalog.filter.shape';
  static const separable = 'catalog.filter.separable';
  static const filterByMedia = 'catalog.filter.media';
  static const cutGrade = 'catalog.filter.cutGrade';
  static const polish = 'catalog.filter.polish';
  static const symmetry = 'catalog.filter.symmetry';
  static const vendorLocation = 'catalog.filter.vendorLocation';
  static const searchLocation = 'catalog.filter.searchLocation';
  static const companyName = 'catalog.filter.companyName';
  static const searchCompany = 'catalog.filter.searchCompany';
  static const searchCountries = 'catalog.filter.searchCountries';
  static const diamondCompanyHelp = 'catalog.diamond.companyHelp';
  static const gemstoneCompanyHelp = 'catalog.gemstone.companyHelp';
  static const tablePercentage = 'catalog.diamond.tablePercentage';
  static const depthPercentage = 'catalog.diamond.depthPercentage';
  static const crownAngleRange = 'catalog.diamond.crownAngleRange';
  static const crownAngleHelp = 'catalog.diamond.crownAngleHelp';
  static const crownHeightRange = 'catalog.diamond.crownHeightRange';
  static const crownHeightHelp = 'catalog.diamond.crownHeightHelp';
  static const pavilionAngleRange = 'catalog.diamond.pavilionAngleRange';
  static const pavilionAngleHelp = 'catalog.diamond.pavilionAngleHelp';
  static const pavilionDepthRange = 'catalog.diamond.pavilionDepthRange';
  static const pavilionDepthHelp = 'catalog.diamond.pavilionDepthHelp';
  static const girdle = 'catalog.diamond.girdle';
  static const girdleHelp = 'catalog.diamond.girdleHelp';
  static const culetSize = 'catalog.diamond.culetSize';
  static const culetHelp = 'catalog.diamond.culetHelp';
  static const noDiamonds = 'catalog.diamond.empty';
  static const labGrownResults = 'catalog.diamond.labResults';
  static const labGrownFinder = 'catalog.diamond.labFinder';
  static const pcsShort = 'catalog.stats.pieces';
  static const totalCtShort = 'catalog.stats.totalCarat';
  static const pricePerCtShort = 'catalog.stats.pricePerCarat';
  static const total = 'catalog.stats.total';
  static const averageTotal = 'catalog.stats.averageTotal';
  static const noBgm = 'catalog.diamond.noBgm';
  static const eyeClean = 'catalog.diamond.eyeClean';
  static const gemstoneFinder = 'catalog.gemstone.finder';
  static const exploreGemstoneTypes = 'catalog.gemstone.exploreTypes';
  static const gemstoneResults = 'catalog.gemstone.results';
  static const stoneType = 'catalog.gemstone.stoneType';
  static const natural = 'catalog.value.natural';
  static const labGrown = 'catalog.value.labGrown';
  static const lotType = 'catalog.gemstone.lotType';
  static const single = 'catalog.value.single';
  static const melee = 'catalog.value.melee';
  static const gemstoneType = 'catalog.gemstone.type';
  static const searchGemstoneTypes = 'catalog.gemstone.searchTypes';
  static const othersCount = 'catalog.value.othersCount';
  static const birthstones = 'catalog.gemstone.birthstones';
  static const birthstonesHelp = 'catalog.gemstone.birthstonesHelp';
  static const certification = 'catalog.filter.certification';
  static const treatments = 'catalog.gemstone.treatments';
  static const originCountry = 'catalog.gemstone.originCountry';
  static const originCountryHelp = 'catalog.gemstone.originCountryHelp';
  static const selectOriginCountry = 'catalog.filter.selectOriginCountry';
  static const diamondOriginCountryHelp = 'catalog.diamond.originCountryHelp';
  static const color = 'catalog.filter.color';
  static const colorIntensity = 'catalog.filter.colorIntensity';
  static const modifier = 'catalog.filter.modifier';
  static const modifierHelp = 'catalog.gemstone.modifierHelp';
  static const fluorescenceIntensity = 'catalog.filter.fluorescenceIntensity';
  static const fluorescenceHelp = 'catalog.gemstone.fluorescenceHelp';
  static const fluorescenceColor = 'catalog.filter.fluorescenceColor';
  static const clarity = 'catalog.filter.clarity';
  static const qualityGrade = 'catalog.filter.qualityGrade';
  static const noGemstones = 'catalog.gemstone.empty';
  static const adjustSearchCriteria = 'catalog.empty.adjustCriteria';
  static const fineJewelry = 'catalog.jewelry.fine';
  static const noCategories = 'catalog.jewelry.noCategories';
  static const categoriesComing = 'catalog.jewelry.categoriesComing';
  static const mediaOnly = 'catalog.filter.mediaOnly';
  static const price = 'catalog.filter.price';
  static const metalType = 'catalog.jewelry.metalType';
  static const metalColor = 'catalog.jewelry.metalColor';
  static const metalPurity = 'catalog.jewelry.metalPurity';
  static const metalWeight = 'catalog.jewelry.metalWeight';
  static const metalFinish = 'catalog.jewelry.metalFinish';
  static const plating = 'catalog.jewelry.plating';
  static const stoneCategory = 'catalog.jewelry.stoneCategory';
  static const stoneShape = 'catalog.jewelry.stoneShape';
  static const stoneWeight = 'catalog.jewelry.stoneWeight';
  static const stoneColor = 'catalog.jewelry.stoneColor';
  static const stoneClarity = 'catalog.jewelry.stoneClarity';
  static const stoneSetting = 'catalog.jewelry.stoneSetting';
  static const searchJewelry = 'catalog.jewelry.search';
  static const noProducts = 'catalog.empty.noProducts';
  static const adjustOrClear = 'catalog.empty.adjustOrClear';
  static const luxuryWatches = 'catalog.watch.title';
  static const searchWatches = 'catalog.watch.search';
  static const noWatches = 'catalog.watch.empty';
  static const adjustWatchFilters = 'catalog.watch.adjustFilters';
  static const boxIncluded = 'catalog.watch.boxIncluded';
  static const papersIncluded = 'catalog.watch.papersIncluded';
  static const warrantyCard = 'catalog.watch.warrantyCard';
  static const fullSetOnly = 'catalog.watch.fullSetOnly';
  static const showAllCount = 'catalog.action.showAllCount';
  static const searchBrands = 'catalog.watch.searchBrands';
  static const applyBrandCount = 'catalog.watch.applyBrandCount';
  static const bullions = 'catalog.bullion.title';
  static const searchBullions = 'catalog.bullion.search';
  static const noBullions = 'catalog.bullion.empty';
  static const adjustBullionFilters = 'catalog.bullion.adjustFilters';
  static const retryLivePrices = 'catalog.bullion.retryLivePrices';
  static const close = 'catalog.action.close';
  static const share = 'catalog.action.share';
  static const copyLink = 'catalog.share.copyLink';
  static const email = 'catalog.share.email';
  static const recipientEmail = 'catalog.share.recipientEmail';
  static const recipientNameOptional = 'catalog.share.recipientNameOptional';
  static const sendEmail = 'catalog.share.sendEmail';
  static const sharedProduct = 'catalog.share.sharedProduct';
  static const shareUnavailable = 'catalog.share.unavailable';
  static const makeOffer = 'catalog.product.makeOffer';
  static const yourOffer = 'catalog.product.yourOffer';
  static const messageOptional = 'catalog.product.messageOptional';
  static const submitOffer = 'catalog.product.submitOffer';
  static const chatWithSeller = 'catalog.product.chatSeller';
  static const copyValue = 'catalog.product.copyValue';
  static const valueCopied = 'catalog.product.valueCopied';
  static const viewerTitle = 'catalog.viewer.title';
  static const viewerMissingUrl = 'catalog.viewer.missingUrl';
  static const viewerInvalidUrl = 'catalog.viewer.invalidUrl';
  static const viewerTimeout = 'catalog.viewer.timeout';
  static const viewerHttpError = 'catalog.viewer.httpError';
  static const viewerBrowserError = 'catalog.viewer.browserError';
  static const tryAgain = 'catalog.action.tryAgain';
  static const viewerGestureHint = 'catalog.viewer.gestureHint';
  static const diamondProject = 'catalog.project.title';
  static const savedStatistics = 'catalog.project.savedStatistics';
  static const saveNow = 'catalog.project.saveNow';
  static const clearSelection = 'catalog.project.clearSelection';
  static const projectActions = 'catalog.project.actions';
  static const noDiamondsSelected = 'catalog.project.noSelection';
  static const shapeMix = 'catalog.project.shapeMix';
  static const colorMix = 'catalog.project.colorMix';
  static const clarityMix = 'catalog.project.clarityMix';
  static const priceDistribution = 'catalog.project.priceDistribution';
  static const pricePerCaratDistribution =
      'catalog.project.pricePerCaratDistribution';
  static const caratDistribution = 'catalog.project.caratDistribution';
  static const savedProject = 'catalog.project.saved';
  static const savedProjects = 'catalog.project.savedProjects';
  static const noSavedProjects = 'catalog.project.empty';
  static const loadProjectsError = 'catalog.project.loadError';
  static const deleteProject = 'catalog.project.delete';
  static const deleteProjectConfirm = 'catalog.project.deleteConfirm';
  static const deleteProjectError = 'catalog.project.deleteError';
  static const removeSelection = 'catalog.project.removeSelection';
  static const stock = 'catalog.table.stock';
  static const meanAverage = 'catalog.stats.meanAverage';
  static const median = 'catalog.stats.median';
  static const mode = 'catalog.stats.mode';
  static const stockId = 'catalog.product.stockId';
  static const report = 'catalog.product.report';
  static const summary = 'catalog.product.summary';
  static const details = 'catalog.product.details';
  static const comment = 'catalog.product.comment';
  static const overview = 'catalog.product.overview';
  static const specifications = 'catalog.product.specifications';
  static const availability = 'catalog.product.availability';
  static const sold = 'catalog.product.sold';
  static const onHold = 'catalog.product.onHold';
  static const onMemo = 'catalog.product.onMemo';
  static const available = 'catalog.product.available';
  static const availabilityUnknown = 'catalog.product.availabilityUnknown';
  static const certified = 'catalog.product.certified';
  static const perCarat = 'catalog.product.perCarat';
  static const perGram = 'catalog.product.perGram';
  static const seller = 'catalog.product.seller';
  static const phone = 'catalog.product.phone';
  static const location = 'catalog.product.location';
  static const type = 'catalog.product.type';
  static const cut = 'catalog.product.cut';
  static const origin = 'catalog.product.origin';
  static const treatment = 'catalog.product.treatment';
  static const purity = 'catalog.product.purity';
  static const metal = 'catalog.product.metal';
  static const stones = 'catalog.product.stones';
  static const year = 'catalog.product.year';
  static const movement = 'catalog.product.movement';
  static const fullSet = 'catalog.product.fullSet';
  static const caseSize = 'catalog.product.caseSize';
  static const basicInfo = 'catalog.product.basicInfo';
  static const caliber = 'catalog.product.caliber';
  static const watchCase = 'catalog.product.case';
  static const braceletStrap = 'catalog.product.braceletStrap';
  static const security = 'catalog.product.security';
  static const product = 'catalog.product.title';
  static const productUnavailable = 'catalog.product.unavailable';
  static const openFromCatalog = 'catalog.product.openFromCatalog';
  static const reopenFromCatalog = 'catalog.product.reopenFromCatalog';
  static const accessories = 'catalog.jewelry.accessories';
  static const adjustStyleOrPrice = 'catalog.watch.adjustStyleOrPrice';
  static const backToListings = 'catalog.project.backToListings';
  static const brand = 'catalog.watch.brand';
  static const brands = 'catalog.watch.brands';
  static const browseCatalog = 'catalog.action.browseCatalog';
  static const cancel = 'catalog.action.cancel';
  static const condition = 'catalog.filter.condition';
  static const delete = 'catalog.action.delete';
  static const dimensions = 'catalog.filter.dimensions';
  static const done = 'catalog.action.done';
  static const enhancement = 'catalog.diamond.enhancement';
  static const gemstoneCutHelp = 'catalog.gemstone.cutHelp';
  static const heartsAndArrows = 'catalog.diamond.heartsAndArrows';
  static const jewelry = 'catalog.jewelry.title';
  static const loadJewelryCategoriesError =
      'catalog.jewelry.loadCategoriesError';
  static const loading = 'catalog.state.loading';
  static const lotTypePresets = 'catalog.diamond.lotTypePresets';
  static const milky = 'catalog.diamond.milky';
  static const mintMark = 'catalog.bullion.mintMark';
  static const noBgmLong = 'catalog.diamond.noBgmLong';
  static const priceRange = 'catalog.filter.priceRange';
  static const projectSummary = 'catalog.project.summary';
  static const quantity = 'catalog.filter.quantity';
  static const savedProjectsHelp = 'catalog.project.savedProjectsHelp';
  static const searchGemstones = 'catalog.action.searchGemstones';
  static const selectEnhancement = 'catalog.diamond.selectEnhancement';
  static const selectPageHelp = 'catalog.project.selectPageHelp';
  static const shareInvalidOrExpired = 'catalog.share.invalidOrExpired';
  static const shopByCategory = 'catalog.jewelry.shopByCategory';
  static const showDiamonds = 'catalog.action.showDiamonds';
  static const showingProducts = 'catalog.state.showingProducts';
  static const showingDiamonds = 'catalog.listing.showingDiamonds';
  static const showingGemstones = 'catalog.listing.showingGemstones';
  static const sortByLabel = 'catalog.listing.sortByLabel';
  static const defaultSorting = 'catalog.listing.defaultSorting';
  static const sieve = 'catalog.diamond.sieve';
  static const sieveSize = 'catalog.diamond.sieveSize';
  static const somethingWentWrong = 'catalog.state.somethingWentWrong';
  static const weight = 'catalog.filter.weight';
  static const whatsAppUnavailableCopied =
      'catalog.share.whatsAppUnavailableCopied';
  static const enterValidEmail = 'catalog.share.enterValidEmail';
  static const shareEmailSent = 'catalog.share.emailSent';
  static const shareLinkCopied = 'catalog.share.linkCopied';
  static const shareProduct = 'catalog.share.product';
  static const images = 'catalog.share.images';
  static const videos360 = 'catalog.share.videos360';
  static const shareVia = 'catalog.share.via';
  static const emailRecipient = 'catalog.share.emailRecipient';
  static const selectFluorescenceColor =
      'catalog.diamond.selectFluorescenceColor';
  static const colorIntensityHelp = 'catalog.gemstone.colorIntensityHelp';
  static const clarityHelp = 'catalog.gemstone.clarityHelp';
  static const qualityGradeHelp = 'catalog.gemstone.qualityGradeHelp';
  static const advance = 'catalog.product.advance';
  static const measurement = 'catalog.product.measurement';
  static const measurementMin = 'catalog.product.measurementMin';
  static const measurementMax = 'catalog.product.measurementMax';
  static const ratio = 'catalog.product.ratio';
  static const shade = 'catalog.product.shade';
  static const growth = 'catalog.product.growth';
  static const growthType = 'catalog.product.growthType';
  static const totalPiecesLabel = 'catalog.product.totalPieces';
  static const weightPerPieceLabel = 'catalog.product.weightPerPiece';
  static const totalWeightLabel = 'catalog.product.totalWeight';
  static const tablePercent = 'catalog.product.tablePercent';
  static const depthPercent = 'catalog.product.depthPercent';
  static const crown = 'catalog.product.crown';
  static const pavilion = 'catalog.product.pavilion';
  static const culetCondition = 'catalog.product.culetCondition';
  static const listingCode = 'catalog.product.listingCode';
  static const brandLabel = 'catalog.product.brand';
  static const model = 'catalog.product.model';
  static const referenceNumber = 'catalog.product.referenceNumber';
  static const caseMaterial = 'catalog.product.caseMaterial';
  static const braceletMaterial = 'catalog.product.braceletMaterial';
  static const yearProduction = 'catalog.product.yearProduction';
  static const scopeDelivery = 'catalog.product.scopeDelivery';
  static const gender = 'catalog.product.gender';
  static const powerReserve = 'catalog.product.powerReserve';
  static const display = 'catalog.product.display';
  static const caseShape = 'catalog.product.caseShape';
  static const glass = 'catalog.product.glass';
  static const dialColor = 'catalog.product.dialColor';
  static const waterResistance = 'catalog.product.waterResistance';
  static const braceletColor = 'catalog.product.braceletColor';
  static const caratWeight = 'catalog.product.caratWeight';
  static const certificationStatus = 'catalog.product.certificationStatus';
  static const metalWeightLabel = 'catalog.product.metalWeight';
  static const stoneWeightLabel = 'catalog.product.stoneWeight';
  static const watchStyle = 'catalog.watch.style';
  static const withMedia = 'catalog.filter.withMedia';
  static const bezel = 'catalog.watch.bezel';
  static const dial = 'catalog.watch.dial';
  static const strap = 'catalog.watch.strap';
  static const clasp = 'catalog.watch.clasp';
  static const features = 'catalog.watch.features';
  static const modelYear = 'catalog.watch.modelYear';
  static const authentication = 'catalog.watch.authentication';
  static const occasion = 'catalog.jewelry.occasion';
  static const stone = 'catalog.jewelry.stone';
  static const deliveryTime = 'catalog.jewelry.deliveryTime';
  static const braceletSize = 'catalog.jewelry.braceletSize';
  static const braceletLength = 'catalog.jewelry.braceletLength';
  static const chainLength = 'catalog.jewelry.chainLength';
  static const necklaceLength = 'catalog.jewelry.necklaceLength';
  static const ringSize = 'catalog.jewelry.ringSize';
  static const sorting = 'catalog.sorting.title';
  static const selectedSortingFilters = 'catalog.sorting.selected';
  static const noSortingCriteria = 'catalog.sorting.empty';
  static const addSortingFields = 'catalog.sorting.addFields';
  static const availableSortingFields = 'catalog.sorting.available';
  static const allSortingFieldsSelected = 'catalog.sorting.allSelected';
  static const standard = 'catalog.color.standard';
  static const fancy = 'catalog.color.fancy';
  static const fancyColors = 'catalog.color.fancyColors';
  static const overtone = 'catalog.color.overtone';
  static const intensity = 'catalog.color.intensity';
  static const eyeCleanLong = 'catalog.diamond.eyeCleanLong';
  static const viewMoreFilters = 'catalog.filters.viewMore';
  static const finishQuickSelect = 'catalog.diamond.finishQuickSelect';
  static const gemstoneSearch = 'catalog.gemstone.searchTitle';
  static const viewMore = 'catalog.action.viewMore';
  static const viewLess = 'catalog.action.viewLess';
  static const certificateHash = 'catalog.product.certificateHash';
  static const sellerInformation = 'catalog.product.sellerInformation';
  static const cutSymPol = 'catalog.product.cutSymPol';
  static const bgmLabel = 'catalog.product.bgmLabel';
  static const floro = 'catalog.product.floro';
  static const selectedDiamonds = 'catalog.project.selectedDiamonds';
  static const projectNoData = 'catalog.project.noData';
  static const projectUnsaved = 'catalog.project.unsaved';
  static const projectStonesKpi = 'catalog.project.kpi.stones';
  static const projectTotalCaratKpi = 'catalog.project.kpi.totalCarat';
  static const projectAvgCaratKpi = 'catalog.project.kpi.avgCarat';
  static const projectTotalPriceKpi = 'catalog.project.kpi.totalPrice';
  static const projectAvgPriceKpi = 'catalog.project.kpi.avgPrice';
  static const projectAvgPpcKpi = 'catalog.project.kpi.avgPpc';
  static const hideAnalytics = 'catalog.project.hideAnalytics';
  static const showAnalytics = 'catalog.project.showAnalytics';
  static const caratVsPpc = 'catalog.project.caratVsPpc';
  static const priceStats = 'catalog.project.priceStats';
  static const outliers = 'catalog.project.outliers';
  static const outliersSummary = 'catalog.project.outliersSummary';
  static const ppcOutliers = 'catalog.project.ppcOutliers';
  static const outlierHigh = 'catalog.project.outlierHigh';
  static const outlierLow = 'catalog.project.outlierLow';
  static const diamondsSelectedSummary =
      'catalog.project.diamondsSelectedSummary';
  static const sellerDiamondProjectsTitle =
      'catalog.sellerDashboard.diamondProjectsTitle';
  static const sellerDiamondProjectsSubtitle =
      'catalog.sellerDashboard.diamondProjectsSubtitle';
  static const filtersToOpenDiamondProject =
      'catalog.sellerDashboard.filtersToOpenDiamondProject';
  static const clearFilters = 'catalog.sellerDashboard.clearFilters';
  static const applyFilters = 'catalog.sellerDashboard.applyFilters';
  static const openProjectAllMatching =
      'catalog.sellerDashboard.openProjectAllMatching';
  static const matchingStonesCount =
      'catalog.sellerDashboard.matchingStonesCount';
  static const allShapes = 'catalog.sellerDashboard.allShapes';
  static const allFancyColors = 'catalog.sellerDashboard.allFancyColors';
  static const cutGradePoor = 'catalog.sellerDashboard.cutGradePoor';
  static const certOther = 'catalog.sellerDashboard.certOther';
}

class _M extends LocalizedMessage {
  const _M(String english, String hindi, String gujarati)
    : super(english: english, hindi: hindi, gujarati: gujarati);
}

const catalogMessages = <String, LocalizedMessage>{
  CatalogL10n.basic: _M('Basic', 'मूल', 'મૂળભૂત'),
  CatalogL10n.preferences: _M('Preferences', 'प्राथमिकताएँ', 'પસંદગીઓ'),
  CatalogL10n.measurements: _M('Measurements', 'माप', 'માપ'),
  CatalogL10n.advanced: _M('Advanced', 'उन्नत', 'અદ્યતન'),
  CatalogL10n.prefShort: _M('PREF', 'पसंद', 'પસંદ'),
  CatalogL10n.measurementsShort: _M('MEAS', 'माप', 'માપ'),
  CatalogL10n.advancedShort: _M('ADV', 'उन्नत', 'અદ્યતન'),
  CatalogL10n.filters: _M('Filters', 'फ़िल्टर', 'ફિલ્ટર'),
  CatalogL10n.editFilters: _M('Edit Filters', 'फ़िल्टर बदलें', 'ફિલ્ટર બદલો'),
  CatalogL10n.resetFilters: _M(
    'Reset Filters',
    'फ़िल्टर रीसेट करें',
    'ફિલ્ટર રીસેટ કરો',
  ),
  CatalogL10n.clearAll: _M('Clear All', 'सभी हटाएँ', 'બધું સાફ કરો'),
  CatalogL10n.apply: _M('Apply', 'लागू करें', 'લાગુ કરો'),
  CatalogL10n.reset: _M('Reset', 'रीसेट करें', 'રીસેટ કરો'),
  CatalogL10n.clear: _M('Clear', 'साफ़ करें', 'સાફ કરો'),
  CatalogL10n.add: _M('Add', 'जोड़ें', 'ઉમેરો'),
  CatalogL10n.view: _M('View', 'देखें', 'જુઓ'),
  CatalogL10n.compare: _M('Compare', 'तुलना करें', 'સરખામણી કરો'),
  CatalogL10n.wishlist: _M('Wishlist', 'इच्छा-सूची', 'ઇચ્છાસૂચિ'),
  CatalogL10n.retry: _M('Retry', 'फिर कोशिश करें', 'ફરી પ્રયાસ કરો'),
  CatalogL10n.search: _M('Search', 'खोजें', 'શોધો'),
  CatalogL10n.showResults: _M('SHOW RESULTS', 'परिणाम दिखाएँ', 'પરિણામ બતાવો'),
  CatalogL10n.viewAdvancedFilters: _M(
    'View Advanced Filters',
    'उन्नत फ़िल्टर देखें',
    'અદ્યતન ફિલ્ટર જુઓ',
  ),
  CatalogL10n.hideAdvancedFilters: _M(
    'Hide Advanced Filters',
    'उन्नत फ़िल्टर छिपाएँ',
    'અદ્યતન ફિલ્ટર છુપાવો',
  ),
  CatalogL10n.minimum: _M('Minimum', 'न्यूनतम', 'ન્યૂનતમ'),
  CatalogL10n.maximum: _M('Maximum', 'अधिकतम', 'મહત્તમ'),
  CatalogL10n.rangeValue: _M('value', 'मान', 'મૂલ્ય'),
  CatalogL10n.rangeFilters: _M(
    'Range Filters',
    'सीमा फ़िल्टर',
    'શ્રેણી ફિલ્ટર',
  ),
  CatalogL10n.currentRange: _M(
    'Current Range',
    'वर्तमान सीमा',
    'વર્તમાન શ્રેણી',
  ),
  CatalogL10n.any: _M('Any', 'कोई भी', 'કોઈપણ'),
  CatalogL10n.pieces: _M('Pieces', 'नग', 'નંગ'),
  CatalogL10n.carat: _M('Carat', 'कैरेट', 'કેરેટ'),
  CatalogL10n.totalCarat: _M('Total Carat', 'कुल कैरेट', 'કુલ કેરેટ'),
  CatalogL10n.totalPrice: _M('Total Price', 'कुल कीमत', 'કુલ કિંમત'),
  CatalogL10n.pricePerCarat: _M(
    'Price / Carat',
    'कीमत / कैरेट',
    'કિંમત / કેરેટ',
  ),
  CatalogL10n.pricePerPiece: _M('Price / Pcs', 'कीमत / नग', 'કિંમત / નંગ'),
  CatalogL10n.totalPieces: _M('Total Pcs', 'कुल नग', 'કુલ નંગ'),
  CatalogL10n.caratPerPiece: _M('Carat / Pcs', 'कैरेट / नग', 'કેરેટ / નંગ'),
  CatalogL10n.length: _M('Length', 'लंबाई', 'લંબાઈ'),
  CatalogL10n.width: _M('Width', 'चौड़ाई', 'પહોળાઈ'),
  CatalogL10n.height: _M('Height', 'ऊँचाई', 'ઊંચાઈ'),
  CatalogL10n.lengthRange: _M('Length Range', 'लंबाई सीमा', 'લંબાઈની શ્રેણી'),
  CatalogL10n.widthRange: _M('Width Range', 'चौड़ाई सीमा', 'પહોળાઈની શ્રેણી'),
  CatalogL10n.heightRange: _M('Height Range', 'ऊँचाई सीमा', 'ઊંચાઈની શ્રેણી'),
  CatalogL10n.ratioRange: _M(
    'Length to Width Ratio Range',
    'लंबाई-चौड़ाई अनुपात सीमा',
    'લંબાઈ-પહોળાઈ ગુણોત્તર શ્રેણી',
  ),
  CatalogL10n.ratioHelp: _M(
    'Filter by the ratio of length divided by width.',
    'लंबाई को चौड़ाई से भाग देने वाले अनुपात से फ़िल्टर करें।',
    'લંબાઈને પહોળાઈથી ભાગ્યાના ગુણોત્તરથી ફિલ્ટર કરો.',
  ),
  CatalogL10n.lengthHelp: _M(
    'Filter by the physical length of the stone in millimeters.',
    'पत्थर की लंबाई मिलीमीटर में फ़िल्टर करें।',
    'પથ્થરની લંબાઈ મિલીમીટરમાં ફિલ્ટર કરો.',
  ),
  CatalogL10n.widthHelp: _M(
    'Filter by the physical width of the stone in millimeters.',
    'पत्थर की चौड़ाई मिलीमीटर में फ़िल्टर करें।',
    'પથ્થરની પહોળાઈ મિલીમીટરમાં ફિલ્ટર કરો.',
  ),
  CatalogL10n.heightHelp: _M(
    'Filter by the physical height of the stone in millimeters.',
    'पत्थर की ऊँचाई मिलीमीटर में फ़िल्टर करें।',
    'પથ્થરની ઊંચાઈ મિલીમીટરમાં ફિલ્ટર કરો.',
  ),
  CatalogL10n.roughSource: _M('Rough Source', 'रफ़ स्रोत', 'રફ સ્ત્રોત'),
  CatalogL10n.roughSourceHelp: _M(
    'Filter by the mine source or rough diamond holder.',
    'खदान स्रोत या रफ़ डायमंड धारक से फ़िल्टर करें।',
    'ખાણના સ્ત્રોત અથવા રફ ડાયમંડ ધારકથી ફિલ્ટર કરો.',
  ),
  CatalogL10n.selectRoughSource: _M(
    'Select rough source',
    'रफ़ स्रोत चुनें',
    'રફ સ્ત્રોત પસંદ કરો',
  ),
  CatalogL10n.minimumSellerRating: _M(
    'Minimum Seller Rating',
    'न्यूनतम विक्रेता रेटिंग',
    'ન્યૂનતમ વિક્રેતા રેટિંગ',
  ),
  CatalogL10n.sellerRatingHelp: _M(
    'Filter based on vendor rating stars.',
    'विक्रेता की स्टार रेटिंग से फ़िल्टर करें।',
    'વિક્રેતાના સ્ટાર રેટિંગથી ફિલ્ટર કરો.',
  ),
  CatalogL10n.ratingAndUp: _M(
    '{rating}★ & up',
    '{rating}★ और अधिक',
    '{rating}★ અને વધુ',
  ),
  CatalogL10n.selectDiamondShapes: _M(
    'Select Diamond\nShapes',
    'डायमंड के आकार\nचुनें',
    'ડાયમંડના આકાર\nપસંદ કરો',
  ),
  CatalogL10n.diamondCategory: _M(
    'Diamond Category',
    'डायमंड श्रेणी',
    'ડાયમંડ શ્રેણી',
  ),
  CatalogL10n.growthMethod: _M(
    'Growth Method (CVD / HPHT)',
    'विकास विधि (CVD / HPHT)',
    'વિકાસ પદ્ધતિ (CVD / HPHT)',
  ),
  CatalogL10n.selectShape: _M('Select Shape', 'आकार चुनें', 'આકાર પસંદ કરો'),
  CatalogL10n.shape: _M('Shape', 'आकार', 'આકાર'),
  CatalogL10n.separable: _M(
    'Separable',
    'अलग करने योग्य',
    'અલગ કરી શકાય તેવું',
  ),
  CatalogL10n.filterByMedia: _M(
    'Filter by Media',
    'मीडिया से फ़िल्टर करें',
    'મીડિયા દ્વારા ફિલ્ટર કરો',
  ),
  CatalogL10n.cutGrade: _M('Cut Grade', 'कट ग्रेड', 'કટ ગ્રેડ'),
  CatalogL10n.polish: _M('Polish', 'पॉलिश', 'પોલિશ'),
  CatalogL10n.symmetry: _M('Symmetry', 'समरूपता', 'સમમિતિ'),
  CatalogL10n.vendorLocation: _M(
    "Vendor's Location",
    'विक्रेता का स्थान',
    'વિક્રેતાનું સ્થાન',
  ),
  CatalogL10n.searchLocation: _M(
    'Search by location (City, State, Country)',
    'स्थान खोजें (शहर, राज्य, देश)',
    'સ્થાન શોધો (શહેર, રાજ્ય, દેશ)',
  ),
  CatalogL10n.companyName: _M('Company Name', 'कंपनी का नाम', 'કંપનીનું નામ'),
  CatalogL10n.searchCompany: _M(
    'Search by company name',
    'कंपनी के नाम से खोजें',
    'કંપનીના નામથી શોધો',
  ),
  CatalogL10n.searchCountries: _M(
    'Search countries...',
    'देश खोजें...',
    'દેશ શોધો...',
  ),
  CatalogL10n.diamondCompanyHelp: _M(
    'Search for diamonds supplied by a specific company name.',
    'किसी खास कंपनी द्वारा दिए गए डायमंड खोजें।',
    'ચોક્કસ કંપની દ્વારા અપાયેલા ડાયમંડ શોધો.',
  ),
  CatalogL10n.gemstoneCompanyHelp: _M(
    'Search for gemstones supplied by a specific company name.',
    'किसी खास कंपनी द्वारा दिए गए रत्न खोजें।',
    'ચોક્કસ કંપની દ્વારા અપાયેલા રત્ન શોધો.',
  ),
  CatalogL10n.tablePercentage: _M(
    'Table Percentage',
    'टेबल प्रतिशत',
    'ટેબલ ટકાવારી',
  ),
  CatalogL10n.depthPercentage: _M(
    'Depth Percentage',
    'गहराई प्रतिशत',
    'ઊંડાઈ ટકાવારી',
  ),
  CatalogL10n.crownAngleRange: _M(
    'Crown Angle Range',
    'क्राउन कोण सीमा',
    'ક્રાઉન કોણ શ્રેણી',
  ),
  CatalogL10n.crownAngleHelp: _M(
    'Filter by average crown facet angle.',
    'औसत क्राउन फ़ैसेट कोण से फ़िल्टर करें।',
    'સરેરાશ ક્રાઉન ફેસેટ કોણથી ફિલ્ટર કરો.',
  ),
  CatalogL10n.crownHeightRange: _M(
    'Crown Height Range',
    'क्राउन ऊँचाई सीमा',
    'ક્રાઉન ઊંચાઈ શ્રેણી',
  ),
  CatalogL10n.crownHeightHelp: _M(
    'Filter by crown height relative to total depth.',
    'कुल गहराई के सापेक्ष क्राउन ऊँचाई से फ़िल्टर करें।',
    'કુલ ઊંડાઈની સરખામણીએ ક્રાઉન ઊંચાઈથી ફિલ્ટર કરો.',
  ),
  CatalogL10n.pavilionAngleRange: _M(
    'Pavilion Angle Range',
    'पैविलियन कोण सीमा',
    'પેવિલિયન કોણ શ્રેણી',
  ),
  CatalogL10n.pavilionAngleHelp: _M(
    'Filter by average pavilion facet angle.',
    'औसत पैविलियन फ़ैसेट कोण से फ़िल्टर करें।',
    'સરેરાશ પેવિલિયન ફેસેટ કોણથી ફિલ્ટર કરો.',
  ),
  CatalogL10n.pavilionDepthRange: _M(
    'Pavilion Depth Range',
    'पैविलियन गहराई सीमा',
    'પેવિલિયન ઊંડાઈ શ્રેણી',
  ),
  CatalogL10n.pavilionDepthHelp: _M(
    'Filter by pavilion depth relative to total depth.',
    'कुल गहराई के सापेक्ष पैविलियन गहराई से फ़िल्टर करें।',
    'કુલ ઊંડાઈની સરખામણીએ પેવિલિયન ઊંડાઈથી ફિલ્ટર કરો.',
  ),
  CatalogL10n.girdle: _M('Girdle', 'गर्डल', 'ગર્ડલ'),
  CatalogL10n.girdleHelp: _M(
    'Filter by thickness of the girdle rim.',
    'गर्डल रिम की मोटाई से फ़िल्टर करें।',
    'ગર્ડલ રિમની જાડાઈથી ફિલ્ટર કરો.',
  ),
  CatalogL10n.culetSize: _M('Culet Size', 'क्यूलेट आकार', 'ક્યુલેટ કદ'),
  CatalogL10n.culetHelp: _M(
    'Filter by size of the culet facet.',
    'क्यूलेट फ़ैसेट के आकार से फ़िल्टर करें।',
    'ક્યુલેટ ફેસેટના કદથી ફિલ્ટર કરો.',
  ),
  CatalogL10n.noDiamonds: _M(
    'No Diamonds Found',
    'कोई डायमंड नहीं मिला',
    'કોઈ ડાયમંડ મળ્યો નથી',
  ),
  CatalogL10n.labGrownResults: _M(
    'Lab Grown Results',
    'लैब ग्रोन परिणाम',
    'લેબ ગ્રોન પરિણામો',
  ),
  CatalogL10n.labGrownFinder: _M(
    'LAB GROWN FINDER',
    'लैब ग्रोन खोज',
    'લેબ ગ્રોન શોધ',
  ),
  CatalogL10n.pcsShort: _M('PCS', 'नग', 'નંગ'),
  CatalogL10n.totalCtShort: _M('TOTAL CT', 'कुल कैरेट', 'કુલ કેરેટ'),
  CatalogL10n.pricePerCtShort: _M('P/CT', 'कीमत/कैरेट', 'કિંમત/કેરેટ'),
  CatalogL10n.total: _M('TOTAL', 'कुल', 'કુલ'),
  CatalogL10n.averageTotal: _M('AVG TOTAL', 'औसत कुल', 'સરેરાશ કુલ'),
  CatalogL10n.noBgm: _M('No BGM', 'कोई BGM नहीं', 'કોઈ BGM નહીં'),
  CatalogL10n.eyeClean: _M('Eye Clean', 'आँखों से साफ़', 'આંખે સ્વચ્છ'),
  CatalogL10n.gemstoneFinder: _M('GEMSTONE FINDER', 'रत्न खोज', 'રત્ન શોધ'),
  CatalogL10n.exploreGemstoneTypes: _M(
    'Explore Gemstone\nTypes',
    'रत्न के प्रकार\nदेखें',
    'રત્નના પ્રકાર\nજુઓ',
  ),
  CatalogL10n.gemstoneResults: _M(
    'Gemstone Results',
    'रत्न परिणाम',
    'રત્ન પરિણામો',
  ),
  CatalogL10n.stoneType: _M('Stone Type', 'पत्थर का प्रकार', 'પથ્થરનો પ્રકાર'),
  CatalogL10n.natural: _M('Natural', 'प्राकृतिक', 'કુદરતી'),
  CatalogL10n.labGrown: _M('Lab Grown', 'लैब ग्रोन', 'લેબ ગ્રોન'),
  CatalogL10n.lotType: _M('Lot Type', 'लॉट प्रकार', 'લોટ પ્રકાર'),
  CatalogL10n.single: _M('Single', 'एकल', 'એકલ'),
  CatalogL10n.melee: _M('Melee', 'मेली', 'મેલી'),
  CatalogL10n.gemstoneType: _M('Gemstone Type', 'रत्न प्रकार', 'રત્ન પ્રકાર'),
  CatalogL10n.searchGemstoneTypes: _M(
    'Search gemstone types...',
    'रत्न प्रकार खोजें...',
    'રત્ન પ્રકાર શોધો...',
  ),
  CatalogL10n.othersCount: _M(
    'Others ({count})',
    'अन्य ({count})',
    'અન્ય ({count})',
  ),
  CatalogL10n.birthstones: _M('Birthstones', 'जन्मरत्न', 'જન્મરત્ન'),
  CatalogL10n.birthstonesHelp: _M(
    'Filter gemstones by their associated birth month.',
    'रत्नों को उनके जन्म महीने से फ़िल्टर करें।',
    'રત્નોને તેમના જન્મ મહિના પ્રમાણે ફિલ્ટર કરો.',
  ),
  CatalogL10n.certification: _M('Certification', 'प्रमाणन', 'પ્રમાણપત્ર'),
  CatalogL10n.treatments: _M('Treatments', 'उपचार', 'ઉપચાર'),
  CatalogL10n.originCountry: _M('Origin Country', 'मूल देश', 'મૂળ દેશ'),
  CatalogL10n.originCountryHelp: _M(
    "Filter by the gemstone's origin country.",
    'रत्न के मूल देश से फ़िल्टर करें।',
    'રત્નના મૂળ દેશથી ફિલ્ટર કરો.',
  ),
  CatalogL10n.selectOriginCountry: _M(
    'Select origin country',
    'मूल देश चुनें',
    'મૂળ દેશ પસંદ કરો',
  ),
  CatalogL10n.diamondOriginCountryHelp: _M(
    "Filter by the diamond's mined origin country.",
    'हीरे के खनन मूल देश से फ़िल्टर करें।',
    'હીરાના ખનન મૂળ દેશથી ફિલ્ટર કરો.',
  ),
  CatalogL10n.color: _M('Color', 'रंग', 'રંગ'),
  CatalogL10n.colorIntensity: _M(
    'Color Intensity',
    'रंग की तीव्रता',
    'રંગની તીવ્રતા',
  ),
  CatalogL10n.modifier: _M('Modifier', 'द्वितीयक रंग', 'ગૌણ રંગ'),
  CatalogL10n.modifierHelp: _M(
    'Filter by secondary color tints in the gemstone.',
    'रत्न के द्वितीयक रंगों से फ़िल्टर करें।',
    'રત્નના ગૌણ રંગછટાથી ફિલ્ટર કરો.',
  ),
  CatalogL10n.fluorescenceIntensity: _M(
    'Fluorescence Intensity',
    'फ्लोरोसेंस तीव्रता',
    'ફ્લોરોસન્સ તીવ્રતા',
  ),
  CatalogL10n.fluorescenceHelp: _M(
    'Filter by the strength of fluorescence under UV light.',
    'UV प्रकाश में फ्लोरोसेंस की तीव्रता से फ़िल्टर करें।',
    'UV પ્રકાશમાં ફ્લોરોસન્સની તીવ્રતાથી ફિલ્ટર કરો.',
  ),
  CatalogL10n.fluorescenceColor: _M(
    'Fluorescence Color',
    'फ्लोरोसेंस रंग',
    'ફ્લોરોસન્સ રંગ',
  ),
  CatalogL10n.clarity: _M('Clarity', 'शुद्धता', 'શુદ્ધતા'),
  CatalogL10n.qualityGrade: _M(
    'Quality Grade',
    'गुणवत्ता ग्रेड',
    'ગુણવત્તા ગ્રેડ',
  ),
  CatalogL10n.noGemstones: _M(
    'No gemstones match your filters.',
    'आपके फ़िल्टर से कोई रत्न नहीं मिला।',
    'તમારા ફિલ્ટર સાથે કોઈ રત્ન મેળ ખાતું નથી.',
  ),
  CatalogL10n.adjustSearchCriteria: _M(
    'Try adjusting your search criteria.',
    'खोज मानदंड बदलकर देखें।',
    'શોધ માપદંડ બદલીને જુઓ.',
  ),
  CatalogL10n.fineJewelry: _M('Fine Jewelry', 'उत्तम आभूषण', 'ઉત્તમ આભૂષણ'),
  CatalogL10n.noCategories: _M(
    'No categories yet',
    'अभी कोई श्रेणी नहीं',
    'હજુ કોઈ શ્રેણી નથી',
  ),
  CatalogL10n.categoriesComing: _M(
    'Jewelry categories will appear here when available.',
    'उपलब्ध होने पर आभूषण श्रेणियाँ यहाँ दिखेंगी।',
    'ઉપલબ્ધ થતાં આભૂષણ શ્રેણીઓ અહીં દેખાશે.',
  ),
  CatalogL10n.mediaOnly: _M(
    'Show items with images/media only',
    'केवल चित्र/मीडिया वाले आइटम दिखाएँ',
    'ફક્ત ચિત્ર/મીડિયા ધરાવતી વસ્તુઓ બતાવો',
  ),
  CatalogL10n.price: _M('Price', 'कीमत', 'કિંમત'),
  CatalogL10n.metalType: _M('Metal Type', 'धातु प्रकार', 'ધાતુ પ્રકાર'),
  CatalogL10n.metalColor: _M('Metal Color', 'धातु रंग', 'ધાતુ રંગ'),
  CatalogL10n.metalPurity: _M('Metal Purity', 'धातु शुद्धता', 'ધાતુ શુદ્ધતા'),
  CatalogL10n.metalWeight: _M('Metal Weight', 'धातु वजन', 'ધાતુ વજન'),
  CatalogL10n.metalFinish: _M('Metal Finish', 'धातु फ़िनिश', 'ધાતુ ફિનિશ'),
  CatalogL10n.plating: _M('Plating', 'प्लेटिंग', 'પ્લેટિંગ'),
  CatalogL10n.stoneCategory: _M(
    'Stone Category',
    'पत्थर श्रेणी',
    'પથ્થર શ્રેણી',
  ),
  CatalogL10n.stoneShape: _M('Stone Shape', 'पत्थर आकार', 'પથ્થર આકાર'),
  CatalogL10n.stoneWeight: _M('Stone Weight', 'पत्थर वजन', 'પથ્થર વજન'),
  CatalogL10n.stoneColor: _M('Stone Color', 'पत्थर रंग', 'પથ્થર રંગ'),
  CatalogL10n.stoneClarity: _M(
    'Stone Clarity',
    'पत्थर शुद्धता',
    'પથ્થર શુદ્ધતા',
  ),
  CatalogL10n.stoneSetting: _M('Stone Setting', 'पत्थर जड़ाई', 'પથ્થર જડતર'),
  CatalogL10n.searchJewelry: _M(
    'Search by name, SKU, metal, stone...',
    'नाम, SKU, धातु या पत्थर से खोजें...',
    'નામ, SKU, ધાતુ અથવા પથ્થરથી શોધો...',
  ),
  CatalogL10n.noProducts: _M(
    'No products found',
    'कोई उत्पाद नहीं मिला',
    'કોઈ ઉત્પાદન મળ્યું નથી',
  ),
  CatalogL10n.adjustOrClear: _M(
    'Try clearing filters or adjusting search.',
    'फ़िल्टर हटाएँ या खोज बदलें।',
    'ફિલ્ટર સાફ કરો અથવા શોધ બદલો.',
  ),
  CatalogL10n.luxuryWatches: _M(
    'Luxury Watches',
    'लक्ज़री घड़ियाँ',
    'લક્ઝરી ઘડિયાળો',
  ),
  CatalogL10n.searchWatches: _M(
    'Search for luxury watches...',
    'लक्ज़री घड़ियाँ खोजें...',
    'લક્ઝરી ઘડિયાળો શોધો...',
  ),
  CatalogL10n.noWatches: _M(
    'No watches match your filters',
    'आपके फ़िल्टर से कोई घड़ी नहीं मिली',
    'તમારા ફિલ્ટર સાથે કોઈ ઘડિયાળ મેળ ખાતી નથી',
  ),
  CatalogL10n.adjustWatchFilters: _M(
    'Try adjusting brand, price, or style filters.',
    'ब्रांड, कीमत या शैली फ़िल्टर बदलें।',
    'બ્રાન્ડ, કિંમત અથવા શૈલી ફિલ્ટર બદલો.',
  ),
  CatalogL10n.boxIncluded: _M('Box Included', 'बॉक्स शामिल', 'બોક્સ સામેલ'),
  CatalogL10n.papersIncluded: _M(
    'Papers Included',
    'दस्तावेज़ शामिल',
    'દસ્તાવેજો સામેલ',
  ),
  CatalogL10n.warrantyCard: _M('Warranty Card', 'वारंटी कार्ड', 'વોરંટી કાર્ડ'),
  CatalogL10n.fullSetOnly: _M(
    'Full Set Only',
    'केवल पूरा सेट',
    'ફક્ત સંપૂર્ણ સેટ',
  ),
  CatalogL10n.showAllCount: _M(
    'Show all ({count})',
    'सभी दिखाएँ ({count})',
    'બધું બતાવો ({count})',
  ),
  CatalogL10n.searchBrands: _M(
    'Search brands...',
    'ब्रांड खोजें...',
    'બ્રાન્ડ શોધો...',
  ),
  CatalogL10n.applyBrandCount: _M(
    'Apply {count} {brandLabel}',
    '{count} {brandLabel} लागू करें',
    '{count} {brandLabel} લાગુ કરો',
  ),
  CatalogL10n.bullions: _M('Bullions', 'बुलियन', 'બુલિયન'),
  CatalogL10n.searchBullions: _M(
    'Search bullions...',
    'बुलियन खोजें...',
    'બુલિયન શોધો...',
  ),
  CatalogL10n.noBullions: _M(
    'No bullions match your filters',
    'आपके फ़िल्टर से कोई बुलियन नहीं मिला',
    'તમારા ફિલ્ટર સાથે કોઈ બુલિયન મેળ ખાતું નથી',
  ),
  CatalogL10n.adjustBullionFilters: _M(
    'Try adjusting metal type or search keywords.',
    'धातु प्रकार या खोज शब्द बदलें।',
    'ધાતુ પ્રકાર અથવા શોધ શબ્દો બદલો.',
  ),
  CatalogL10n.retryLivePrices: _M(
    'Retry live prices',
    'लाइव कीमतें फिर लाएँ',
    'લાઇવ કિંમતો ફરી મેળવો',
  ),
  CatalogL10n.close: _M('Close', 'बंद करें', 'બંધ કરો'),
  CatalogL10n.share: _M('Share', 'साझा करें', 'શેર કરો'),
  CatalogL10n.copyLink: _M('Copy link', 'लिंक कॉपी करें', 'લિંક કૉપિ કરો'),
  CatalogL10n.email: _M('Email', 'ईमेल', 'ઈમેલ'),
  CatalogL10n.recipientEmail: _M(
    'Recipient email',
    'प्राप्तकर्ता का ईमेल',
    'પ્રાપ્તકર્તાનું ઈમેલ',
  ),
  CatalogL10n.recipientNameOptional: _M(
    'Recipient name (optional)',
    'प्राप्तकर्ता का नाम (वैकल्पिक)',
    'પ્રાપ્તકર્તાનું નામ (વૈકલ્પિક)',
  ),
  CatalogL10n.sendEmail: _M('Send email', 'ईमेल भेजें', 'ઈમેલ મોકલો'),
  CatalogL10n.sharedProduct: _M(
    'Shared product',
    'साझा उत्पाद',
    'શેર કરેલું ઉત્પાદન',
  ),
  CatalogL10n.shareUnavailable: _M(
    'Share link unavailable',
    'शेयर लिंक उपलब्ध नहीं',
    'શેર લિંક ઉપલબ્ધ નથી',
  ),
  CatalogL10n.makeOffer: _M('Make an offer', 'प्रस्ताव दें', 'ઓફર કરો'),
  CatalogL10n.yourOffer: _M(
    'Your offer ({currency})',
    'आपका प्रस्ताव ({currency})',
    'તમારી ઓફર ({currency})',
  ),
  CatalogL10n.messageOptional: _M(
    'Message (optional)',
    'संदेश (वैकल्पिक)',
    'સંદેશ (વૈકલ્પિક)',
  ),
  CatalogL10n.submitOffer: _M('Submit offer', 'प्रस्ताव भेजें', 'ઓફર મોકલો'),
  CatalogL10n.chatWithSeller: _M(
    'Chat with seller',
    'विक्रेता से चैट करें',
    'વિક્રેતા સાથે ચેટ કરો',
  ),
  CatalogL10n.copyValue: _M(
    'Copy {label}',
    '{label} कॉपी करें',
    '{label} કૉપિ કરો',
  ),
  CatalogL10n.valueCopied: _M(
    '{label} copied',
    '{label} कॉपी किया गया',
    '{label} કૉપિ થયું',
  ),
  CatalogL10n.viewerTitle: _M('360° View', '360° दृश्य', '360° દૃશ્ય'),
  CatalogL10n.viewerMissingUrl: _M(
    'Missing 360° viewer URL',
    '360° व्यूअर URL उपलब्ध नहीं',
    '360° વ્યૂઅર URL ઉપલબ્ધ નથી',
  ),
  CatalogL10n.viewerInvalidUrl: _M(
    'This product does not have a valid 360° viewer link.',
    'इस उत्पाद में मान्य 360° व्यूअर लिंक नहीं है।',
    'આ ઉત્પાદનમાં માન્ય 360° વ્યૂઅર લિંક નથી.',
  ),
  CatalogL10n.viewerTimeout: _M(
    'The viewer took too long to load. Check your connection and try again.',
    'व्यूअर लोड होने में बहुत समय लगा। कनेक्शन जाँचकर फिर कोशिश करें।',
    'વ્યૂઅર લોડ થવામાં ઘણો સમય લાગ્યો. કનેક્શન તપાસીને ફરી પ્રયાસ કરો.',
  ),
  CatalogL10n.viewerHttpError: _M(
    'Viewer unavailable (HTTP {code}).',
    'व्यूअर उपलब्ध नहीं (HTTP {code})।',
    'વ્યૂઅર ઉપલબ્ધ નથી (HTTP {code}).',
  ),
  CatalogL10n.viewerBrowserError: _M(
    'The 360° viewer could not be loaded in this browser.',
    'इस ब्राउज़र में 360° व्यूअर लोड नहीं हो सका।',
    'આ બ્રાઉઝરમાં 360° વ્યૂઅર લોડ થઈ શક્યું નહીં.',
  ),
  CatalogL10n.tryAgain: _M('Try again', 'फिर कोशिश करें', 'ફરી પ્રયાસ કરો'),
  CatalogL10n.viewerGestureHint: _M(
    'Drag to rotate · Pinch to zoom',
    'घुमाने के लिए खींचें · ज़ूम के लिए पिंच करें',
    'ફેરવવા ખેંચો · ઝૂમ કરવા પિંચ કરો',
  ),
  CatalogL10n.diamondProject: _M(
    'Diamond project',
    'डायमंड प्रोजेक्ट',
    'ડાયમંડ પ્રોજેક્ટ',
  ),
  CatalogL10n.savedStatistics: _M(
    'Saved Statistics',
    'सहेजे गए आँकड़े',
    'સાચવેલા આંકડા',
  ),
  CatalogL10n.saveNow: _M('Save now', 'अभी सहेजें', 'હમણાં સાચવો'),
  CatalogL10n.clearSelection: _M(
    'Clear selection',
    'चयन हटाएँ',
    'પસંદગી સાફ કરો',
  ),
  CatalogL10n.projectActions: _M(
    'Project actions',
    'प्रोजेक्ट कार्रवाइयाँ',
    'પ્રોજેક્ટ ક્રિયાઓ',
  ),
  CatalogL10n.noDiamondsSelected: _M(
    'No diamonds selected',
    'कोई डायमंड चुना नहीं गया',
    'કોઈ ડાયમંડ પસંદ કર્યો નથી',
  ),
  CatalogL10n.shapeMix: _M('Shape mix', 'आकार मिश्रण', 'આકાર મિશ્રણ'),
  CatalogL10n.colorMix: _M('Color mix', 'रंग मिश्रण', 'રંગ મિશ્રણ'),
  CatalogL10n.clarityMix: _M('Clarity mix', 'शुद्धता मिश्रण', 'શુદ્ધતા મિશ્રણ'),
  CatalogL10n.priceDistribution: _M(
    'Price distribution',
    'कीमत वितरण',
    'કિંમત વિતરણ',
  ),
  CatalogL10n.pricePerCaratDistribution: _M(
    'Price per carat distribution',
    'प्रति कैरेट कीमत वितरण',
    'પ્રતિ કેરેટ કિંમત વિતરણ',
  ),
  CatalogL10n.caratDistribution: _M(
    'Carat distribution',
    'कैरेट वितरण',
    'કેરેટ વિતરણ',
  ),
  CatalogL10n.savedProject: _M(
    'Saved {name}',
    '{name} सहेजा गया',
    '{name} સાચવ્યું',
  ),
  CatalogL10n.savedProjects: _M(
    'Saved projects',
    'सहेजे गए प्रोजेक्ट',
    'સાચવેલા પ્રોજેક્ટ',
  ),
  CatalogL10n.noSavedProjects: _M(
    'No saved projects',
    'कोई सहेजा प्रोजेक्ट नहीं',
    'કોઈ સાચવેલો પ્રોજેક્ટ નથી',
  ),
  CatalogL10n.loadProjectsError: _M(
    'Could not load projects.',
    'प्रोजेक्ट लोड नहीं हो सके।',
    'પ્રોજેક્ટ લોડ થઈ શક્યા નહીં.',
  ),
  CatalogL10n.deleteProject: _M(
    'Delete project',
    'प्रोजेक्ट हटाएँ',
    'પ્રોજેક્ટ કાઢી નાખો',
  ),
  CatalogL10n.deleteProjectConfirm: _M(
    'Delete {name}? This cannot be undone.',
    '{name} हटाएँ? इसे वापस नहीं किया जा सकता।',
    '{name} કાઢી નાખવું? આ પાછું ફેરવી શકાશે નહીં.',
  ),
  CatalogL10n.deleteProjectError: _M(
    'Could not delete.',
    'हटाया नहीं जा सका।',
    'કાઢી શકાયું નહીં.',
  ),
  CatalogL10n.removeSelection: _M(
    'Remove from selection',
    'चयन से हटाएँ',
    'પસંદગીમાંથી દૂર કરો',
  ),
  CatalogL10n.stock: _M('STOCK', 'स्टॉक', 'સ્ટોક'),
  CatalogL10n.meanAverage: _M('MEAN (AVG)', 'माध्य (औसत)', 'મધ્યક (સરેરાશ)'),
  CatalogL10n.median: _M('MEDIAN', 'मध्यिका', 'મધ્યિકા'),
  CatalogL10n.mode: _M('MODE', 'बहुलक', 'બહુલક'),
  CatalogL10n.stockId: _M('Stock ID', 'स्टॉक आईडी', 'સ્ટોક ID'),
  CatalogL10n.report: _M('Report', 'रिपोर्ट', 'રિપોર્ટ'),
  CatalogL10n.summary: _M('Summary', 'सारांश', 'સારાંશ'),
  CatalogL10n.details: _M('Details', 'विवरण', 'વિગતો'),
  CatalogL10n.comment: _M('Comment', 'टिप्पणी', 'ટિપ્પણી'),
  CatalogL10n.overview: _M('Overview', 'अवलोकन', 'ઝાંખી'),
  CatalogL10n.specifications: _M('Specifications', 'विशेषताएँ', 'વિશિષ્ટતાઓ'),
  CatalogL10n.availability: _M('Availability', 'उपलब्धता', 'ઉપલબ્ધતા'),
  CatalogL10n.sold: _M('Sold', 'बिक चुका', 'વેચાઈ ગયું'),
  CatalogL10n.onHold: _M('On hold', 'होल्ड पर', 'હોલ્ડ પર'),
  CatalogL10n.onMemo: _M('On memo', 'मेमो पर', 'મેમો પર'),
  CatalogL10n.available: _M('Available', 'उपलब्ध', 'ઉપલબ્ધ'),
  CatalogL10n.availabilityUnknown: _M(
    'Availability not listed',
    'उपलब्धता दर्ज नहीं है',
    'ઉપલબ્ધતા દર્શાવેલી નથી',
  ),
  CatalogL10n.certified: _M(
    '{authority} certified',
    '{authority} प्रमाणित',
    '{authority} પ્રમાણિત',
  ),
  CatalogL10n.perCarat: _M('per carat', 'प्रति कैरेट', 'પ્રતિ કેરેટ'),
  CatalogL10n.perGram: _M('per gram', 'प्रति ग्राम', 'પ્રતિ ગ્રામ'),
  CatalogL10n.seller: _M('Seller', 'विक्रेता', 'વિક્રેતા'),
  CatalogL10n.phone: _M('Phone', 'फ़ोन', 'ફોન'),
  CatalogL10n.location: _M('Location', 'स्थान', 'સ્થાન'),
  CatalogL10n.type: _M('Type', 'प्रकार', 'પ્રકાર'),
  CatalogL10n.cut: _M('Cut', 'कट', 'કટ'),
  CatalogL10n.origin: _M('Origin', 'मूल', 'મૂળ'),
  CatalogL10n.treatment: _M('Treatment', 'उपचार', 'ઉપચાર'),
  CatalogL10n.purity: _M('Purity', 'शुद्धता', 'શુદ્ધતા'),
  CatalogL10n.metal: _M('Metal', 'धातु', 'ધાતુ'),
  CatalogL10n.stones: _M('Stones', 'पत्थर', 'પથ્થરો'),
  CatalogL10n.year: _M('Year', 'वर्ष', 'વર્ષ'),
  CatalogL10n.movement: _M('Movement', 'मूवमेंट', 'મૂવમેન્ટ'),
  CatalogL10n.fullSet: _M('Full set', 'पूरा सेट', 'સંપૂર્ણ સેટ'),
  CatalogL10n.caseSize: _M('Case size', 'केस आकार', 'કેસ કદ'),
  CatalogL10n.basicInfo: _M('Basic Info', 'मूल जानकारी', 'મૂળ માહિતી'),
  CatalogL10n.caliber: _M('Caliber', 'कैलिबर', 'કેલિબર'),
  CatalogL10n.watchCase: _M('Case', 'केस', 'કેસ'),
  CatalogL10n.braceletStrap: _M(
    'Bracelet/strap',
    'ब्रेसलेट/स्ट्रैप',
    'બ્રેસલેટ/સ્ટ્રેપ',
  ),
  CatalogL10n.security: _M('Security', 'सुरक्षा', 'સુરક્ષા'),
  CatalogL10n.product: _M('Product', 'उत्पाद', 'ઉત્પાદન'),
  CatalogL10n.productUnavailable: _M(
    'This product is no longer loaded',
    'यह उत्पाद अब लोड नहीं है',
    'આ ઉત્પાદન હવે લોડ થયેલું નથી',
  ),
  CatalogL10n.openFromCatalog: _M(
    'Open the product from a catalog listing to see its details.',
    'विवरण देखने के लिए उत्पाद को कैटलॉग सूची से खोलें।',
    'વિગતો જોવા ઉત્પાદનને કૅટલૉગ સૂચિમાંથી ખોલો.',
  ),
  CatalogL10n.reopenFromCatalog: _M(
    'Reopen {productId} from a catalog listing to see its details.',
    'विवरण देखने के लिए कैटलॉग सूची से {productId} फिर खोलें।',
    'વિગતો જોવા કૅટલૉગ સૂચિમાંથી {productId} ફરી ખોલો.',
  ),
  CatalogL10n.accessories: _M('Accessories', 'सहायक वस्तुएँ', 'એસેસરીઝ'),
  CatalogL10n.adjustStyleOrPrice: _M(
    'Try adjusting style or price range.',
    'शैली या कीमत सीमा बदलें।',
    'શૈલી અથવા કિંમત શ્રેણી બદલો.',
  ),
  CatalogL10n.backToListings: _M(
    'Back to listings',
    'सूची पर वापस जाएँ',
    'સૂચિ પર પાછા જાઓ',
  ),
  CatalogL10n.brand: _M('brand', 'ब्रांड', 'બ્રાન્ડ'),
  CatalogL10n.brands: _M('brands', 'ब्रांड', 'બ્રાન્ડ'),
  CatalogL10n.browseCatalog: _M('Browse catalog', 'कैटलॉग देखें', 'કૅટલૉગ જુઓ'),
  CatalogL10n.cancel: _M('Cancel', 'रद्द करें', 'રદ કરો'),
  CatalogL10n.condition: _M('Condition', 'स्थिति', 'સ્થિતિ'),
  CatalogL10n.delete: _M('Delete', 'हटाएँ', 'કાઢી નાખો'),
  CatalogL10n.dimensions: _M('Dimensions', 'आयाम', 'પરિમાણો'),
  CatalogL10n.done: _M('Done', 'हो गया', 'પૂર્ણ'),
  CatalogL10n.enhancement: _M('Enhancement', 'संवर्धन', 'સુધારણા'),
  CatalogL10n.gemstoneCutHelp: _M(
    "Filter by the quality of the gemstone's cut.",
    'रत्न की कट गुणवत्ता से फ़िल्टर करें।',
    'રત્નની કટ ગુણવત્તાથી ફિલ્ટર કરો.',
  ),
  CatalogL10n.heartsAndArrows: _M(
    'Hearts & Arrows',
    'हार्ट्स और एरोज़',
    'હાર્ટ્સ અને એરો',
  ),
  CatalogL10n.jewelry: _M('Jewelry', 'आभूषण', 'આભૂષણ'),
  CatalogL10n.loadJewelryCategoriesError: _M(
    'Could not load jewelry categories.',
    'आभूषण श्रेणियाँ लोड नहीं हो सकीं।',
    'આભૂષણ શ્રેણીઓ લોડ થઈ શકી નહીં.',
  ),
  CatalogL10n.loading: _M('Loading…', 'लोड हो रहा है…', 'લોડ થઈ રહ્યું છે…'),
  CatalogL10n.lotTypePresets: _M(
    'Lot Type Presets',
    'लॉट प्रकार प्रीसेट',
    'લોટ પ્રકાર પ્રીસેટ',
  ),
  CatalogL10n.milky: _M('Milky', 'दूधियापन', 'દૂધિયાપણું'),
  CatalogL10n.mintMark: _M('Mint Mark', 'मिंट चिह्न', 'મિન્ટ ચિહ્ન'),
  CatalogL10n.noBgmLong: _M(
    'No BGM (No Brown, Green, Milky tints)',
    'कोई भूरा, हरा या दूधिया रंग नहीं',
    'કોઈ ભૂરો, લીલો કે દૂધિયો રંગ નહીં',
  ),
  CatalogL10n.priceRange: _M('Price Range', 'कीमत सीमा', 'કિંમત શ્રેણી'),
  CatalogL10n.projectSummary: _M(
    '{count} stones · {carat} ct · {price}',
    '{count} पत्थर · {carat} कैरेट · {price}',
    '{count} પથ્થરો · {carat} કેરેટ · {price}',
  ),
  CatalogL10n.quantity: _M('Quantity', 'मात्रा', 'જથ્થો'),
  CatalogL10n.savedProjectsHelp: _M(
    'Select the current listing page and tap Save now to keep a project.',
    'प्रोजेक्ट रखने के लिए वर्तमान सूची पृष्ठ चुनें और अभी सहेजें दबाएँ।',
    'પ્રોજેક્ટ સાચવવા વર્તમાન સૂચિ પેજ પસંદ કરીને હમણાં સાચવો દબાવો.',
  ),
  CatalogL10n.searchGemstones: _M(
    'SEARCH GEMSTONES',
    'रत्न खोजें',
    'રત્ન શોધો',
  ),
  CatalogL10n.selectEnhancement: _M(
    'Select enhancement',
    'संवर्धन चुनें',
    'સુધારણા પસંદ કરો',
  ),
  CatalogL10n.selectPageHelp: _M(
    'Use Select current page on a diamond listing to analyze loaded stones.',
    'लोड किए गए पत्थरों के विश्लेषण के लिए सूची में वर्तमान पृष्ठ चुनें।',
    'લોડ થયેલા પથ્થરોનું વિશ્લેષણ કરવા સૂચિમાં વર્તમાન પેજ પસંદ કરો.',
  ),
  CatalogL10n.shareInvalidOrExpired: _M(
    'This share link is invalid or expired.',
    'यह शेयर लिंक अमान्य है या समाप्त हो चुका है।',
    'આ શેર લિંક અમાન્ય છે અથવા સમાપ્ત થઈ ગઈ છે.',
  ),
  CatalogL10n.shopByCategory: _M(
    'Shop by category',
    'श्रेणी के अनुसार खरीदें',
    'શ્રેણી પ્રમાણે ખરીદો',
  ),
  CatalogL10n.showDiamonds: _M(
    'SHOW DIAMONDS',
    'डायमंड दिखाएँ',
    'ડાયમંડ બતાવો',
  ),
  CatalogL10n.showingProducts: _M(
    'Showing {count} Products',
    '{count} उत्पाद दिख रहे हैं',
    '{count} ઉત્પાદનો બતાવી રહ્યાં છે',
  ),
  CatalogL10n.showingDiamonds: _M(
    'Showing {count} Diamonds',
    '{count} डायमंड दिख रहे हैं',
    '{count} ડાયમંડ બતાવી રહ્યાં છે',
  ),
  CatalogL10n.showingGemstones: _M(
    'Showing {count} Gemstones',
    '{count} रत्न दिख रहे हैं',
    '{count} રત્ન બતાવી રહ્યાં છે',
  ),
  CatalogL10n.sortByLabel: _M(
    'Sort by: {label}',
    'क्रमबद्ध करें: {label}',
    'સૉર્ટ કરો: {label}',
  ),
  CatalogL10n.defaultSorting: _M(
    'Default Sorting',
    'डिफ़ॉल्ट क्रम',
    'ડિફૉલ્ટ સૉર્ટ',
  ),
  CatalogL10n.sieve: _M('Sieve', 'छलनी', 'ચાળણી'),
  CatalogL10n.sieveSize: _M('Sieve Size', 'छलनी आकार', 'ચાળણી કદ'),
  CatalogL10n.somethingWentWrong: _M(
    'Something went wrong',
    'कुछ गलत हो गया',
    'કંઈક ખોટું થયું',
  ),
  CatalogL10n.weight: _M('Weight', 'वजन', 'વજન'),
  CatalogL10n.whatsAppUnavailableCopied: _M(
    'WhatsApp unavailable — share link copied',
    'WhatsApp उपलब्ध नहीं — शेयर लिंक कॉपी किया गया',
    'WhatsApp ઉપલબ્ધ નથી — શેર લિંક કૉપિ થઈ',
  ),
  CatalogL10n.enterValidEmail: _M(
    'Enter a valid email address',
    'मान्य ईमेल पता दर्ज करें',
    'માન્ય ઈમેલ સરનામું દાખલ કરો',
  ),
  CatalogL10n.shareEmailSent: _M(
    'Share email sent to {email}',
    '{email} पर शेयर ईमेल भेजा गया',
    '{email} પર શેર ઈમેલ મોકલાયું',
  ),
  CatalogL10n.shareLinkCopied: _M(
    'Share link copied',
    'शेयर लिंक कॉपी किया गया',
    'શેર લિંક કૉપિ થઈ',
  ),
  CatalogL10n.shareProduct: _M(
    'Share product',
    'उत्पाद साझा करें',
    'ઉત્પાદન શેર કરો',
  ),
  CatalogL10n.images: _M('Images', 'चित्र', 'ચિત્રો'),
  CatalogL10n.videos360: _M('Videos / 360°', 'वीडियो / 360°', 'વિડિયો / 360°'),
  CatalogL10n.shareVia: _M(
    'Share via',
    'इसके द्वारा साझा करें',
    'આ દ્વારા શેર કરો',
  ),
  CatalogL10n.emailRecipient: _M(
    'Email recipient',
    'ईमेल प्राप्तकर्ता',
    'ઈમેલ પ્રાપ્તકર્તા',
  ),
  CatalogL10n.selectFluorescenceColor: _M(
    'Select fluorescence color',
    'फ्लोरोसेंस रंग चुनें',
    'ફ્લોરોસન્સ રંગ પસંદ કરો',
  ),
  CatalogL10n.colorIntensityHelp: _M(
    'Filter by the saturation strength of the gemstone color.',
    'रत्न के रंग की संतृप्ति से फ़िल्टर करें।',
    'રત્નના રંગની સંતૃપ્તિથી ફિલ્ટર કરો.',
  ),
  CatalogL10n.clarityHelp: _M(
    'Filter by the visibility of inclusions in the gemstone.',
    'रत्न में समावेशन की दृश्यता से फ़िल्टर करें।',
    'રત્નમાં સમાવિષ્ટોની દૃશ્યતા પ્રમાણે ફિલ્ટર કરો.',
  ),
  CatalogL10n.qualityGradeHelp: _M(
    'Overall commercial quality grade of the gemstone.',
    'रत्न का समग्र व्यावसायिक गुणवत्ता ग्रेड।',
    'રત્નનો એકંદર વ્યાવસાયિક ગુણવત્તા ગ્રેડ.',
  ),
  CatalogL10n.advance: _M('Advance', 'उन्नत', 'અદ્યતન'),
  CatalogL10n.measurement: _M('Measurement', 'माप', 'માપ'),
  CatalogL10n.measurementMin: _M(
    'Measurement min',
    'न्यूनतम माप',
    'ન્યૂનતમ માપ',
  ),
  CatalogL10n.measurementMax: _M('Measurement max', 'अधिकतम माप', 'મહત્તમ માપ'),
  CatalogL10n.ratio: _M('Ratio', 'अनुपात', 'ગુણોત્તર'),
  CatalogL10n.shade: _M('Shade', 'छाया', 'છાંયો'),
  CatalogL10n.growth: _M('Growth', 'विकास', 'વિકાસ'),
  CatalogL10n.growthType: _M('Growth Type', 'विकास प्रकार', 'વિકાસ પ્રકાર'),
  CatalogL10n.totalPiecesLabel: _M('Total pieces', 'कुल नग', 'કુલ નંગ'),
  CatalogL10n.weightPerPieceLabel: _M(
    'Weight per piece',
    'प्रति नग वजन',
    'પ્રતિ નંગ વજન',
  ),
  CatalogL10n.totalWeightLabel: _M(
    'Total Weight',
    'कुल वजन',
    'કુલ વજન',
  ),
  CatalogL10n.tablePercent: _M('Table Percent', 'टेबल प्रतिशत', 'ટેબલ ટકાવારી'),
  CatalogL10n.depthPercent: _M(
    'Depth Percent',
    'गहराई प्रतिशत',
    'ઊંડાઈ ટકાવારી',
  ),
  CatalogL10n.crown: _M('Crown', 'क्राउन', 'ક્રાઉન'),
  CatalogL10n.pavilion: _M('Pavilion', 'पैविलियन', 'પેવિલિયન'),
  CatalogL10n.culetCondition: _M(
    'Culet Condition',
    'क्यूलेट स्थिति',
    'ક્યુલેટ સ્થિતિ',
  ),
  CatalogL10n.listingCode: _M('Listing code', 'लिस्टिंग कोड', 'લિસ્ટિંગ કોડ'),
  CatalogL10n.brandLabel: _M('Brand', 'ब्रांड', 'બ્રાન્ડ'),
  CatalogL10n.model: _M('Model', 'मॉडल', 'મોડેલ'),
  CatalogL10n.referenceNumber: _M(
    'Reference number',
    'संदर्भ संख्या',
    'સંદર્ભ નંબર',
  ),
  CatalogL10n.caseMaterial: _M('Case material', 'केस सामग्री', 'કેસ સામગ્રી'),
  CatalogL10n.braceletMaterial: _M(
    'Bracelet material',
    'ब्रेसलेट सामग्री',
    'બ્રેસલેટ સામગ્રી',
  ),
  CatalogL10n.yearProduction: _M(
    'Year of production',
    'निर्माण वर्ष',
    'ઉત્પાદન વર્ષ',
  ),
  CatalogL10n.scopeDelivery: _M(
    'Scope of delivery',
    'डिलीवरी सामग्री',
    'ડિલિવરી સામગ્રી',
  ),
  CatalogL10n.gender: _M('Gender', 'लिंग', 'લિંગ'),
  CatalogL10n.powerReserve: _M('Power reserve', 'पावर रिज़र्व', 'પાવર રિઝર્વ'),
  CatalogL10n.display: _M('Display', 'डिस्प्ले', 'ડિસ્પ્લે'),
  CatalogL10n.caseShape: _M('Case shape', 'केस आकार', 'કેસ આકાર'),
  CatalogL10n.glass: _M('Glass', 'काँच', 'કાચ'),
  CatalogL10n.dialColor: _M('Dial color', 'डायल रंग', 'ડાયલ રંગ'),
  CatalogL10n.waterResistance: _M(
    'Water resistance',
    'जल प्रतिरोध',
    'જળ પ્રતિરોધ',
  ),
  CatalogL10n.braceletColor: _M(
    'Bracelet color',
    'ब्रेसलेट रंग',
    'બ્રેસલેટ રંગ',
  ),
  CatalogL10n.caratWeight: _M('Carat Weight', 'कैरेट वजन', 'કેરેટ વજન'),
  CatalogL10n.certificationStatus: _M(
    'Certification Status',
    'प्रमाणन स्थिति',
    'પ્રમાણપત્ર સ્થિતિ',
  ),
  CatalogL10n.metalWeightLabel: _M('Metal weight', 'धातु वजन', 'ધાતુ વજન'),
  CatalogL10n.stoneWeightLabel: _M('Stone weight', 'पत्थर वजन', 'પથ્થર વજન'),
  CatalogL10n.watchStyle: _M('Watch Style', 'घड़ी शैली', 'ઘડિયાળ શૈલી'),
  CatalogL10n.withMedia: _M('With Media', 'मीडिया सहित', 'મીડિયા સાથે'),
  CatalogL10n.bezel: _M('Bezel', 'बेज़ल', 'બેઝલ'),
  CatalogL10n.dial: _M('Dial', 'डायल', 'ડાયલ'),
  CatalogL10n.strap: _M('Strap', 'स्ट्रैप', 'સ્ટ્રેપ'),
  CatalogL10n.clasp: _M('Clasp', 'क्लैस्प', 'ક્લાસ્પ'),
  CatalogL10n.features: _M('Features', 'विशेषताएँ', 'વિશેષતાઓ'),
  CatalogL10n.modelYear: _M('Model Year', 'मॉडल वर्ष', 'મોડેલ વર્ષ'),
  CatalogL10n.authentication: _M('Authentication', 'प्रामाणिकता', 'પ્રમાણીકરણ'),
  CatalogL10n.occasion: _M('Occasion', 'अवसर', 'પ્રસંગ'),
  CatalogL10n.stone: _M('Stone', 'पत्थर', 'પથ્થર'),
  CatalogL10n.deliveryTime: _M('Delivery Time', 'डिलीवरी समय', 'ડિલિવરી સમય'),
  CatalogL10n.braceletSize: _M('Bracelet Size', 'ब्रेसलेट आकार', 'બ્રેસલેટ કદ'),
  CatalogL10n.braceletLength: _M(
    'Bracelet Length',
    'ब्रेसलेट लंबाई',
    'બ્રેસલેટ લંબાઈ',
  ),
  CatalogL10n.chainLength: _M('Chain Length', 'चेन लंबाई', 'ચેઇન લંબાઈ'),
  CatalogL10n.necklaceLength: _M(
    'Necklace Length',
    'हार की लंबाई',
    'હારની લંબાઈ',
  ),
  CatalogL10n.ringSize: _M('Ring Size', 'अंगूठी आकार', 'વીંટી કદ'),
  CatalogL10n.sorting: _M('Sorting', 'क्रमबद्ध करना', 'ક્રમબદ્ધ કરવું'),
  CatalogL10n.selectedSortingFilters: _M(
    'Selected Sorting Filters',
    'चुने गए क्रम फ़िल्टर',
    'પસંદ કરેલા ક્રમ ફિલ્ટર',
  ),
  CatalogL10n.noSortingCriteria: _M(
    'No sorting criteria selected',
    'कोई क्रम मानदंड नहीं चुना',
    'કોઈ ક્રમ માપદંડ પસંદ નથી',
  ),
  CatalogL10n.addSortingFields: _M(
    'Add fields from below to start sorting',
    'क्रम शुरू करने के लिए नीचे से फ़ील्ड जोड़ें',
    'ક્રમ શરૂ કરવા નીચેથી ફીલ્ડ ઉમેરો',
  ),
  CatalogL10n.availableSortingFields: _M(
    'Available Sorting Fields',
    'उपलब्ध क्रम फ़ील्ड',
    'ઉપલબ્ધ ક્રમ ફીલ્ડ',
  ),
  CatalogL10n.allSortingFieldsSelected: _M(
    'All fields are already selected',
    'सभी फ़ील्ड पहले से चुने गए हैं',
    'બધી ફીલ્ડ પહેલેથી પસંદ છે',
  ),
  CatalogL10n.standard: _M('Standard', 'मानक', 'પ્રમાણભૂત'),
  CatalogL10n.fancy: _M('Fancy', 'फैंसी', 'ફેન્સી'),
  CatalogL10n.fancyColors: _M('Fancy Colors', 'फैंसी रंग', 'ફેન્સી રંગો'),
  CatalogL10n.overtone: _M('Overtone', 'अतिरिक्त रंग', 'વધારાની રંગછટા'),
  CatalogL10n.intensity: _M('Intensity', 'तीव्रता', 'તીવ્રતા'),
  CatalogL10n.eyeCleanLong: _M(
    'Eye Clean (No inclusions visible to naked eye)',
    'आई-क्लीन (नंगी आँख से कोई समावेशन नहीं)',
    'આઈ-ક્લીન (નરી આંખે કોઈ સમાવેશ દેખાતો નથી)',
  ),
  CatalogL10n.viewMoreFilters: _M(
    'View more filters',
    'और फ़िल्टर देखें',
    'વધુ ફિલ્ટર જુઓ',
  ),
  CatalogL10n.finishQuickSelect: _M(
    'Finish (Quick Select)',
    'फ़िनिश (त्वरित चयन)',
    'ફિનિશ (ઝડપી પસંદગી)',
  ),
  CatalogL10n.gemstoneSearch: _M('Gemstone Search', 'रत्न खोज', 'રત્ન શોધ'),
  CatalogL10n.viewMore: _M('View More', 'और देखें', 'વધુ જુઓ'),
  CatalogL10n.viewLess: _M('View Less', 'कम देखें', 'ઓછું જુઓ'),
  CatalogL10n.certificateHash: _M(
    'Certificate #',
    'प्रमाणपत्र #',
    'પ્રમાણપત્ર #',
  ),
  CatalogL10n.sellerInformation: _M(
    'Seller information',
    'विक्रेता की जानकारी',
    'વિક્રેતાની માહિતી',
  ),
  CatalogL10n.cutSymPol: _M(
    'Cut - Sym - Pol',
    'कट - सम - पॉल',
    'કટ - સિમ - પોલ',
  ),
  CatalogL10n.bgmLabel: _M('BGM', 'BGM', 'BGM'),
  CatalogL10n.floro: _M('Floro', 'फ्लोरो', 'ફ્લોરો'),
  CatalogL10n.selectedDiamonds: _M(
    'Selected diamonds',
    'चुने गए हीरे',
    'પસંદ કરેલા હીરા',
  ),
  CatalogL10n.projectNoData: _M('No data', 'कोई डेटा नहीं', 'કોઈ ડેટા નથી'),
  CatalogL10n.projectUnsaved: _M('Unsaved', 'सहेजा नहीं', 'સાચવેલ નથી'),
  CatalogL10n.projectStonesKpi: _M('STONES', 'पत्थर', 'પથ્થર'),
  CatalogL10n.projectTotalCaratKpi: _M('TOTAL CARAT', 'कुल कैरेट', 'કુલ કેરેટ'),
  CatalogL10n.projectAvgCaratKpi: _M('AVG CARAT', 'औसत कैरेट', 'સરેરાશ કેરેટ'),
  CatalogL10n.projectTotalPriceKpi: _M('TOTAL PRICE', 'कुल कीमत', 'કુલ કિંમત'),
  CatalogL10n.projectAvgPriceKpi: _M('AVG PRICE', 'औसत कीमत', 'સરેરાશ કિંમત'),
  CatalogL10n.projectAvgPpcKpi: _M('AVG \$/CT', 'औसत \$/CT', 'સરેરાશ \$/CT'),
  CatalogL10n.hideAnalytics: _M(
    'Hide analytics →',
    'एनालिटिक्स छिपाएँ →',
    'એનાલિટિક્સ છુપાવો →',
  ),
  CatalogL10n.showAnalytics: _M(
    'Show analytics →',
    'एनालिटिक्स दिखाएँ →',
    'એનાલિટિક્સ બતાવો →',
  ),
  CatalogL10n.caratVsPpc: _M(
    'Carat vs price per carat',
    'कैरेट VS प्रति कैरेट कीमत',
    'કેરેટ VS પ્રતિ કેરેટ કિંમત',
  ),
  CatalogL10n.priceStats: _M('Price stats', 'कीमत आँकड़े', 'કિંમત આંકડા'),
  CatalogL10n.outliers: _M('OUTLIERS', 'आउटलायर्स', 'આઉટલાયર્સ'),
  CatalogL10n.outliersSummary: _M(
    'Count: {count}  ·  IQR fences {low} - {high}',
    'संख्या: {count}  ·  IQR सीमा {low} - {high}',
    'સંખ્યા: {count}  ·  IQR સીમા {low} - {high}',
  ),
  CatalogL10n.ppcOutliers: _M(
    '{count} \$/ct outliers (IQR method)',
    '{count} \$/ct आउटलायर्स (IQR विधि)',
    '{count} \$/ct આઉટલાયર્સ (IQR પદ્ધતિ)',
  ),
  CatalogL10n.outlierHigh: _M('High', 'उच्च', 'ઉચ્ચ'),
  CatalogL10n.outlierLow: _M('Low', 'निम्न', 'નીચું'),
  CatalogL10n.diamondsSelectedSummary: _M(
    '{count} diamonds selected · {id}',
    '{count} हीरे चुने गए · {id}',
    '{count} હીરા પસંદ · {id}',
  ),
  CatalogL10n.sellerDiamondProjectsTitle: _M(
    'Diamond projects',
    'डायमंड प्रोजेक्ट',
    'ડાયમંડ પ્રોજેક્ટ',
  ),
  CatalogL10n.sellerDiamondProjectsSubtitle: _M(
    'Filter your active natural inventory (not sold / not expired / not deleted), select stones, open analytics, and share Excel.',
    'अपनी सक्रिय प्राकृतिक इन्वेंटरी (बिकी नहीं / समाप्त नहीं / हटाई नहीं) फ़िल्टर करें, पत्थर चुनें, एनालिटिक्स खोलें और Excel साझा करें।',
    'તમારી સક્રિય કુદરતી ઇન્વેન્ટરી (વેચાયેલ નહીં / સમાપ્ત નહીં / કાઢી નાખેલ નહીં) ફિલ્ટર કરો, પથ્થરો પસંદ કરો, એનાલિટિક્સ ખોલો અને Excel શેર કરો.',
  ),
  CatalogL10n.filtersToOpenDiamondProject: _M(
    'Filters to open diamond project',
    'डायमंड प्रोजेक्ट खोलने के लिए फ़िल्टर',
    'ડાયમંડ પ્રોજેક્ટ ખોલવા માટે ફિલ્ટર',
  ),
  CatalogL10n.clearFilters: _M(
    'Clear filters',
    'फ़िल्टर साफ़ करें',
    'ફિલ્ટર સાફ કરો',
  ),
  CatalogL10n.applyFilters: _M(
    'Apply filters',
    'फ़िल्टर लागू करें',
    'ફિલ્ટર લાગુ કરો',
  ),
  CatalogL10n.openProjectAllMatching: _M(
    'Open project — all active matching filters',
    'प्रोजेक्ट खोलें — सभी सक्रिय मिलान फ़िल्टर',
    'પ્રોજેક્ટ ખોલો — બધા સક્રિય મેળ ખાતા ફિલ્ટર',
  ),
  CatalogL10n.matchingStonesCount: _M(
    '{count} matching stones',
    '{count} मिलान वाले पत्थर',
    '{count} મેળ ખાતા પથ્થર',
  ),
  CatalogL10n.allShapes: _M('All', 'सभी', 'બધા'),
  CatalogL10n.allFancyColors: _M('All', 'सभी', 'બધા'),
  CatalogL10n.cutGradePoor: _M('Poor', 'खराब', 'નબળું'),
  CatalogL10n.certOther: _M('Other', 'अन्य', 'અન્ય'),
};

/// Maps adapter-owned static English labels to stable localization keys.
const catalogDisplayMessageKeys = <String, String>{
  'Stock ID': CatalogL10n.stockId,
  'Report': CatalogL10n.report,
  'Summary': CatalogL10n.summary,
  'Details': CatalogL10n.details,
  'Comment': CatalogL10n.comment,
  'Overview': CatalogL10n.overview,
  'Specifications': CatalogL10n.specifications,
  'Certification': CatalogL10n.certification,
  'Availability': CatalogL10n.availability,
  'Sold': CatalogL10n.sold,
  'On hold': CatalogL10n.onHold,
  'On memo': CatalogL10n.onMemo,
  'Available': CatalogL10n.available,
  'Availability not listed': CatalogL10n.availabilityUnknown,
  'per carat': CatalogL10n.perCarat,
  'per gram': CatalogL10n.perGram,
  'Carat': CatalogL10n.carat,
  'Color': CatalogL10n.color,
  'Clarity': CatalogL10n.clarity,
  'Shape': CatalogL10n.shape,
  'Sieve': CatalogL10n.sieve,
  'Polish': CatalogL10n.polish,
  'Girdle': CatalogL10n.girdle,
  'Total Price': CatalogL10n.totalPrice,
  'Price': CatalogL10n.price,
  'Condition': CatalogL10n.condition,
  'Seller': CatalogL10n.seller,
  'Email': CatalogL10n.email,
  'Phone': CatalogL10n.phone,
  'Location': CatalogL10n.location,
  'Type': CatalogL10n.type,
  'Cut': CatalogL10n.cut,
  'Origin': CatalogL10n.origin,
  'Treatment': CatalogL10n.treatment,
  'Purity': CatalogL10n.purity,
  'Metal': CatalogL10n.metal,
  'Weight': CatalogL10n.weight,
  'Stones': CatalogL10n.stones,
  'Year': CatalogL10n.year,
  'Movement': CatalogL10n.movement,
  'Full set': CatalogL10n.fullSet,
  'Case size': CatalogL10n.caseSize,
  'Basic Info': CatalogL10n.basicInfo,
  'Caliber': CatalogL10n.caliber,
  'Case': CatalogL10n.watchCase,
  'Bracelet/strap': CatalogL10n.braceletStrap,
  'Security': CatalogL10n.security,
  'Advance': CatalogL10n.advance,
  'Measurement': CatalogL10n.measurement,
  'Measurement min': CatalogL10n.measurementMin,
  'Measurement max': CatalogL10n.measurementMax,
  'Ratio': CatalogL10n.ratio,
  'Shade': CatalogL10n.shade,
  'Growth': CatalogL10n.growth,
  'Growth Type': CatalogL10n.growthType,
  'Rough Source': CatalogL10n.roughSource,
  'Total pieces': CatalogL10n.totalPiecesLabel,
  'Weight per piece': CatalogL10n.weightPerPieceLabel,
  'Total Weight': CatalogL10n.totalWeightLabel,
  'Table Percent': CatalogL10n.tablePercent,
  'Depth Percent': CatalogL10n.depthPercent,
  'Crown': CatalogL10n.crown,
  'Pavilion': CatalogL10n.pavilion,
  'Culet Condition': CatalogL10n.culetCondition,
  'Listing code': CatalogL10n.listingCode,
  'Brand': CatalogL10n.brandLabel,
  'Model': CatalogL10n.model,
  'Reference number': CatalogL10n.referenceNumber,
  'Case material': CatalogL10n.caseMaterial,
  'Bracelet material': CatalogL10n.braceletMaterial,
  'Year of production': CatalogL10n.yearProduction,
  'Scope of delivery': CatalogL10n.scopeDelivery,
  'Gender': CatalogL10n.gender,
  'Power reserve': CatalogL10n.powerReserve,
  'Display': CatalogL10n.display,
  'Case shape': CatalogL10n.caseShape,
  'Glass': CatalogL10n.glass,
  'Dial color': CatalogL10n.dialColor,
  'Water resistance': CatalogL10n.waterResistance,
  'Bracelet color': CatalogL10n.braceletColor,
  'Carat Weight': CatalogL10n.caratWeight,
  'Certification Status': CatalogL10n.certificationStatus,
  'Metal weight': CatalogL10n.metalWeightLabel,
  'Stone weight': CatalogL10n.stoneWeightLabel,
  'Jewelry': CatalogL10n.jewelry,
  'Gemstone': CatalogL10n.gemstoneType,
  'Watch': CatalogL10n.luxuryWatches,
  'Bullion': CatalogL10n.bullions,
  'Certificate #': CatalogL10n.certificateHash,
  'Certificate': CatalogL10n.certification,
  'Cut - Sym - Pol': CatalogL10n.cutSymPol,
  'BGM': CatalogL10n.bgmLabel,
  'Floro': CatalogL10n.floro,
};
