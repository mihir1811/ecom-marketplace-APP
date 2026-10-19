import 'package:flutter/foundation.dart';

import '../../diamond_education/domain/diamond_grades.dart';
import '../../diamond_education/domain/diamond_proportions.dart';
import '../../diamond_education/domain/diamond_shape.dart';
import '../../diamond_education/domain/diamond_spec.dart';
import 'jewelry_metal.dart';

/// The kinds of piece the jewelry simulator builds.
enum JewelryType { ring, earrings, necklace, bracelet }

/// How the centre stone is held: prong counts and layouts, or a collar.
enum HeadStyle {
  /// Three prongs: the "martini" stud setting, and trillions and hearts.
  prong3,
  prong4,
  prong6,

  /// Eight prongs, for large stones.
  prong8,

  /// Four prongs at north, east, south and west.
  compass,

  /// Four pairs of slim claws.
  doubleClaw,
  bezel,

  /// A collar on two sides only, open at the ends.
  halfBezel,
}

/// The shape of each prong's tip over the crown.
enum ProngTip {
  /// A rounded bead, the classic tip.
  round,

  /// A slim tip tapering to a point.
  claw,

  /// A flat, wide tab: low and snag-free on square stones.
  tab,

  /// A chevron folded over a pointed tip (pear, marquise, heart,
  /// princess) to guard it from chipping; round tips elsewhere.
  vTip,
}

/// How high the head lifts the stone above the band.
enum SettingHeight { low, medium, high }

/// The structure under the girdle that ties the prongs together.
enum GalleryStyle {
  /// Rails round the head at two heights.
  basket,

  /// Prongs that cross each other in X's, with no rails.
  trellis,

  /// Prongs alone, rising from one post (a peg head).
  open,
}

/// Rings of small accent stones around the centre stone.
enum HaloStyle { none, single, double }

/// Cross-section of a band.
enum BandProfile { comfort, flat, knifeEdge, dShape }

/// How a ring's shank runs from the bottom up to the head.
enum ShankStyle {
  straight,

  /// Narrowing toward the head, so the stone looks larger.
  tapered,

  /// Widening toward the head.
  reverseTapered,

  /// Splitting into two strands that frame the head.
  split,

  /// Two ends that pass beside the head in opposite directions.
  bypass,

  /// Two strands twisted round each other.
  twisted,
}

/// How far round a band (or hoop, or bangle) its small stones run.
enum BandAccent { plain, half, threeQuarter, eternity }

/// How the small stones on a band are held.
enum AccentSetting {
  /// Beads raised from the metal between stones.
  pave,

  /// Stones in a groove between two metal walls.
  channel,

  /// Prongs shared by neighbouring stones.
  sharedProng,

  /// A metal rim round each stone.
  bezel,
}

enum EarringStyle { stud, drop, hoop, huggie }

/// What holds a stud (or a drop's stud top) on the ear.
enum EarringBack {
  /// A friction butterfly that slides on the post.
  butterfly,

  /// A nut that screws onto a threaded post: the most secure.
  screw,

  /// A wide disc ("jumbo") back that keeps heavy studs upright.
  disc,
}

/// What a drop earring hangs from.
enum DropFitting {
  /// A small stone on a post with a loop below.
  post,

  /// An open wire hook through the ear.
  frenchHook,

  /// A wire hook closed at the back by a hinged lever.
  leverBack,
}

enum HoopShape { round, oval }

/// How a hoop or huggie opens and closes.
enum HoopClosure {
  /// A hinged section that snaps into the other end.
  hinged,

  /// A post through the ear caught by a latch.
  latch,

  /// A thin wire end that slips into a tube: no visible clasp.
  endless,
}

enum ChainStyle {
  cable,
  curb,
  box,
  rope,

  /// Curb links in a long, three short pattern.
  figaro,

  /// Long, flat, elongated cable links.
  paperclip,

  /// Smooth, close plates: a flexible tube.
  snake,

  /// Metal beads on a fine wire.
  bead,
}

/// Necklace lengths in inches, as sold.
enum ChainLength {
  in14(14),
  in16(16),
  in18(18),
  in20(20),
  in22(22),
  in24(24),
  in30(30);

  const ChainLength(this.inches);

  final int inches;

  double get mm => inches * 25.4;
}

/// How a pendant hangs on its chain.
enum BailStyle {
  /// A visible loop above the head.
  loop,

  /// A loop behind the head, out of sight from the front.
  hidden,

  /// A wide loop set with small diamonds.
  pave,

  /// The chain runs through a tube behind the head ("floating").
  slide,
}

enum BraceletStyle { tennis, bangle, chain }

/// How each stone of a tennis bracelet is held.
enum TennisSetting { prong4, prong3, bezel, channel }

enum BangleStyle {
  /// A closed hoop that slides over the hand.
  slipOn,

  /// Opens on a hinge and closes with a box clasp.
  hinged,

  /// An open cuff with a gap.
  cuff,
}

enum BangleShape { round, oval }

/// How a chain bracelet fastens.
enum ClaspStyle { lobster, springRing, toggle, box }

/// Ring sizes on the US scale and their inside diameter.
abstract final class RingSizes {
  static const min = 3.0, max = 13.0;

  /// Inside diameter in mm (ISO 8653 via the US scale).
  static double diameterMm(double us) => 11.63 + 0.8128 * us;
}

/// The head of a piece: everything that holds its centre stone.
@immutable
class HeadSpec {
  const HeadSpec({
    this.style = HeadStyle.prong6,
    this.tip = ProngTip.round,
    this.gallery = GalleryStyle.basket,
    this.halo = HaloStyle.none,
    this.hiddenHalo = false,
    this.milgrain = false,
  });

  final HeadStyle style;
  final ProngTip tip;
  final GalleryStyle gallery;
  final HaloStyle halo;
  final bool hiddenHalo, milgrain;

  bool get isBezel => style == HeadStyle.bezel || style == HeadStyle.halfBezel;

  int get haloRows => switch (halo) {
    HaloStyle.none => 0,
    HaloStyle.single => 1,
    HaloStyle.double => 2,
  };

  @override
  bool operator ==(Object other) =>
      other is HeadSpec &&
      other.style == style &&
      other.tip == tip &&
      other.gallery == gallery &&
      other.halo == halo &&
      other.hiddenHalo == hiddenHalo &&
      other.milgrain == milgrain;

  @override
  int get hashCode =>
      Object.hash(style, tip, gallery, halo, hiddenHalo, milgrain);
}

/// Everything that describes one simulated piece of jewelry: what it is,
/// its metal, the centre diamond (a full [DiamondSpec], so a stone from
/// the diamond simulator carries over unchanged) and each type's own
/// construction.
@immutable
class JewelryDesign {
  const JewelryDesign({
    required this.stone,
    this.type = JewelryType.ring,
    this.metal = JewelryMetal.yellowGold,
    this.purity = MetalPurity.k18,
    this.finish = MetalFinish.polished,
    this.headMetal,
    this.head = HeadStyle.prong6,
    this.prongTip = ProngTip.round,
    this.gallery = GalleryStyle.basket,
    this.settingHeight = SettingHeight.medium,
    this.halo = HaloStyle.none,
    this.hiddenHalo = false,
    this.milgrain = false,
    this.threeStone = false,
    this.eastWest = false,
    this.cathedral = false,
    this.shank = ShankStyle.straight,
    this.bandProfile = BandProfile.comfort,
    this.bandWidthMm = 2.2,
    this.ringSize = 6.5,
    this.bandAccent = BandAccent.plain,
    this.accentSetting = AccentSetting.pave,
    this.earringStyle = EarringStyle.stud,
    this.earringBack = EarringBack.butterfly,
    this.dropFitting = DropFitting.post,
    this.dropLinks = 2,
    this.hoopDiameterMm = 22,
    this.hoopShape = HoopShape.round,
    this.hoopWireMm = 1.8,
    this.hoopClosure = HoopClosure.hinged,
    this.chainStyle = ChainStyle.cable,
    this.chainLength = ChainLength.in18,
    this.chainWidthMm = 1.6,
    this.bail = BailStyle.loop,
    this.yDropMm = 0,
    this.stations = 0,
    this.braceletStyle = BraceletStyle.tennis,
    this.braceletLengthIn = 7.0,
    this.accentStoneMm = 2.6,
    this.tennisSetting = TennisSetting.prong4,
    this.safetyLatch = true,
    this.bangleStyle = BangleStyle.slipOn,
    this.bangleShape = BangleShape.round,
    this.bangleWidthMm = 4.5,
    this.clasp = ClaspStyle.lobster,
    this.charms = 0,
  });

  factory JewelryDesign.initial({DiamondSpec? stone, JewelryType? type}) =>
      JewelryDesign(
        stone:
            stone ??
            DiamondSpec(
              shape: SimShape.round,
              proportions: DiamondProportions.ideal(SimShape.round),
              colorGrade: ColorGrade.f,
              clarity: ClarityGrade.vs1,
            ),
        type: type ?? JewelryType.ring,
      );

  static const minBandWidth = 1.5, maxBandWidth = 4.0;
  static const minChainWidth = 1.0, maxChainWidth = 3.0;
  static const minHoop = 14.0, maxHoop = 40.0;
  static const minHuggie = 8.0, maxHuggie = 16.0;
  static const minHoopWire = 1.2, maxHoopWire = 4.0;
  static const minBracelet = 6.0, maxBracelet = 8.0;
  static const minAccent = 1.8, maxAccent = 4.0;
  static const minDropLinks = 1, maxDropLinks = 8;
  static const maxYDrop = 60.0;
  static const minBangleWidth = 2.0, maxBangleWidth = 10.0;

  /// Station counts a necklace offers, and charm counts a bracelet does.
  static const stationCounts = [0, 2, 4, 6];
  static const charmCounts = [0, 1, 3];

  final JewelryType type;
  final JewelryMetal metal;
  final MetalPurity purity;
  final MetalFinish finish;

  /// A second metal for the setting (two-tone), or null for one metal.
  final JewelryMetal? headMetal;

  /// The centre stone; earrings carry one of these on each side.
  final DiamondSpec stone;

  // The head, shared by rings, pendants, studs and drops.
  final HeadStyle head;
  final ProngTip prongTip;
  final GalleryStyle gallery;
  final SettingHeight settingHeight;
  final HaloStyle halo;
  final bool hiddenHalo;

  /// Beaded edges on the band, bezel and halo.
  final bool milgrain;

  // Ring.
  final bool threeStone, eastWest, cathedral;
  final ShankStyle shank;
  final BandProfile bandProfile;
  final double bandWidthMm;
  final double ringSize;

  /// Small stones round a ring band, a hoop or a bangle, and how they
  /// are held.
  final BandAccent bandAccent;
  final AccentSetting accentSetting;

  // Earrings.
  final EarringStyle earringStyle;
  final EarringBack earringBack;
  final DropFitting dropFitting;

  /// Jump rings (chain links) between a drop's fitting and its stone.
  final int dropLinks;

  /// A hoop's (or huggie's) outside diameter, shape, wire and closure.
  final double hoopDiameterMm;
  final HoopShape hoopShape;
  final double hoopWireMm;
  final HoopClosure hoopClosure;

  // Necklace (and a chain bracelet's links).
  final ChainStyle chainStyle;
  final ChainLength chainLength;
  final double chainWidthMm;
  final BailStyle bail;

  /// A Y (lariat) drop: chain below the V down to the pendant, mm; 0
  /// hangs the pendant right on the chain.
  final double yDropMm;

  /// Bezel-set diamond stations spaced along the chain.
  final int stations;

  // Bracelet.
  final BraceletStyle braceletStyle;
  final double braceletLengthIn;

  /// Diameter of each stone in a tennis bracelet.
  final double accentStoneMm;
  final TennisSetting tennisSetting;

  /// A figure-eight safety beside a tennis bracelet's box clasp.
  final bool safetyLatch;
  final BangleStyle bangleStyle;
  final BangleShape bangleShape;
  final double bangleWidthMm;
  final ClaspStyle clasp;

  /// Charms hanging from a chain bracelet.
  final int charms;

  /// The setting's metal: [headMetal] when two-tone, else [metal].
  JewelryMetal get settingMetal => headMetal ?? metal;

  MetalPurity get settingPurity {
    final m = headMetal;
    if (m == null) return purity;
    return m.purities.contains(purity) ? purity : m.defaultPurity;
  }

  HeadSpec get headSpec => HeadSpec(
    style: head,
    tip: prongTip,
    gallery: gallery,
    halo: halo,
    hiddenHalo: hiddenHalo,
    milgrain: milgrain,
  );

  /// Whether this piece has a traced centre stone.
  bool get hasCentreStone => switch (type) {
    JewelryType.ring || JewelryType.necklace => true,
    JewelryType.earrings =>
      earringStyle == EarringStyle.stud || earringStyle == EarringStyle.drop,
    JewelryType.bracelet => false,
  };

  /// Whether the piece has a head to set (and so a halo, a gallery...).
  bool get takesHalo => hasCentreStone;

  /// Whether the piece has a band, hoop or bangle that can carry stones.
  bool get takesBandStones => switch (type) {
    JewelryType.ring => shank != ShankStyle.twisted,
    JewelryType.earrings =>
      earringStyle == EarringStyle.hoop || earringStyle == EarringStyle.huggie,
    JewelryType.necklace => false,
    JewelryType.bracelet => braceletStyle == BraceletStyle.bangle,
  };

  /// Whether the piece shows any metal in a second tone.
  bool get takesTwoTone => hasCentreStone;

  JewelryDesign copyWith({
    JewelryType? type,
    JewelryMetal? metal,
    MetalPurity? purity,
    MetalFinish? finish,
    JewelryMetal? headMetal,
    bool clearHeadMetal = false,
    DiamondSpec? stone,
    HeadStyle? head,
    ProngTip? prongTip,
    GalleryStyle? gallery,
    SettingHeight? settingHeight,
    HaloStyle? halo,
    bool? hiddenHalo,
    bool? milgrain,
    bool? threeStone,
    bool? eastWest,
    bool? cathedral,
    ShankStyle? shank,
    BandProfile? bandProfile,
    double? bandWidthMm,
    double? ringSize,
    BandAccent? bandAccent,
    AccentSetting? accentSetting,
    EarringStyle? earringStyle,
    EarringBack? earringBack,
    DropFitting? dropFitting,
    int? dropLinks,
    double? hoopDiameterMm,
    HoopShape? hoopShape,
    double? hoopWireMm,
    HoopClosure? hoopClosure,
    ChainStyle? chainStyle,
    ChainLength? chainLength,
    double? chainWidthMm,
    BailStyle? bail,
    double? yDropMm,
    int? stations,
    BraceletStyle? braceletStyle,
    double? braceletLengthIn,
    double? accentStoneMm,
    TennisSetting? tennisSetting,
    bool? safetyLatch,
    BangleStyle? bangleStyle,
    BangleShape? bangleShape,
    double? bangleWidthMm,
    ClaspStyle? clasp,
    int? charms,
  }) {
    final m = metal ?? this.metal;
    var p = purity ?? this.purity;
    // A metal change keeps the purity only if the new metal comes in it.
    if (!m.purities.contains(p)) p = m.defaultPurity;
    var hm = clearHeadMetal ? null : headMetal ?? this.headMetal;
    // Two-tone in the band's own metal is one metal.
    if (hm == m) hm = null;
    final es = earringStyle ?? this.earringStyle;
    final huggie = es == EarringStyle.huggie;
    return JewelryDesign(
      type: type ?? this.type,
      metal: m,
      purity: p,
      finish: finish ?? this.finish,
      headMetal: hm,
      stone: stone ?? this.stone,
      head: head ?? this.head,
      prongTip: prongTip ?? this.prongTip,
      gallery: gallery ?? this.gallery,
      settingHeight: settingHeight ?? this.settingHeight,
      halo: halo ?? this.halo,
      hiddenHalo: hiddenHalo ?? this.hiddenHalo,
      milgrain: milgrain ?? this.milgrain,
      threeStone: threeStone ?? this.threeStone,
      eastWest: eastWest ?? this.eastWest,
      cathedral: cathedral ?? this.cathedral,
      shank: shank ?? this.shank,
      bandProfile: bandProfile ?? this.bandProfile,
      bandWidthMm: (bandWidthMm ?? this.bandWidthMm).clamp(
        minBandWidth,
        maxBandWidth,
      ),
      ringSize: (ringSize ?? this.ringSize).clamp(RingSizes.min, RingSizes.max),
      bandAccent: bandAccent ?? this.bandAccent,
      accentSetting: accentSetting ?? this.accentSetting,
      earringStyle: es,
      earringBack: earringBack ?? this.earringBack,
      dropFitting: dropFitting ?? this.dropFitting,
      dropLinks: (dropLinks ?? this.dropLinks).clamp(
        minDropLinks,
        maxDropLinks,
      ),
      hoopDiameterMm: (hoopDiameterMm ?? this.hoopDiameterMm).clamp(
        huggie ? minHuggie : minHoop,
        huggie ? maxHuggie : maxHoop,
      ),
      hoopShape: hoopShape ?? this.hoopShape,
      hoopWireMm: (hoopWireMm ?? this.hoopWireMm).clamp(
        minHoopWire,
        maxHoopWire,
      ),
      hoopClosure: hoopClosure ?? this.hoopClosure,
      chainStyle: chainStyle ?? this.chainStyle,
      chainLength: chainLength ?? this.chainLength,
      chainWidthMm: (chainWidthMm ?? this.chainWidthMm).clamp(
        minChainWidth,
        maxChainWidth,
      ),
      bail: bail ?? this.bail,
      yDropMm: (yDropMm ?? this.yDropMm).clamp(0.0, maxYDrop),
      stations: stations ?? this.stations,
      braceletStyle: braceletStyle ?? this.braceletStyle,
      braceletLengthIn: (braceletLengthIn ?? this.braceletLengthIn).clamp(
        minBracelet,
        maxBracelet,
      ),
      accentStoneMm: (accentStoneMm ?? this.accentStoneMm).clamp(
        minAccent,
        maxAccent,
      ),
      tennisSetting: tennisSetting ?? this.tennisSetting,
      safetyLatch: safetyLatch ?? this.safetyLatch,
      bangleStyle: bangleStyle ?? this.bangleStyle,
      bangleShape: bangleShape ?? this.bangleShape,
      bangleWidthMm: (bangleWidthMm ?? this.bangleWidthMm).clamp(
        minBangleWidth,
        maxBangleWidth,
      ),
      clasp: clasp ?? this.clasp,
      charms: charms ?? this.charms,
    );
  }

  List<Object?> get _props => [
    type,
    metal,
    purity,
    finish,
    headMetal,
    stone,
    head,
    prongTip,
    gallery,
    settingHeight,
    halo,
    hiddenHalo,
    milgrain,
    threeStone,
    eastWest,
    cathedral,
    shank,
    bandProfile,
    bandWidthMm,
    ringSize,
    bandAccent,
    accentSetting,
    earringStyle,
    earringBack,
    dropFitting,
    dropLinks,
    hoopDiameterMm,
    hoopShape,
    hoopWireMm,
    hoopClosure,
    chainStyle,
    chainLength,
    chainWidthMm,
    bail,
    yDropMm,
    stations,
    braceletStyle,
    braceletLengthIn,
    accentStoneMm,
    tennisSetting,
    safetyLatch,
    bangleStyle,
    bangleShape,
    bangleWidthMm,
    clasp,
    charms,
  ];

  @override
  bool operator ==(Object other) =>
      other is JewelryDesign && listEquals(other._props, _props);

  @override
  int get hashCode => Object.hashAll(_props);
}
