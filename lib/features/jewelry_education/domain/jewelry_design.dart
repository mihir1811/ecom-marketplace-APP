import 'package:flutter/foundation.dart';

import '../../diamond_education/domain/diamond_grades.dart';
import '../../diamond_education/domain/diamond_proportions.dart';
import '../../diamond_education/domain/diamond_shape.dart';
import '../../diamond_education/domain/diamond_spec.dart';
import 'jewelry_metal.dart';

/// The kinds of piece the jewelry simulator builds.
enum JewelryType { ring, earrings, necklace, bracelet }

/// How the centre stone is held.
enum HeadStyle { prong4, prong6, bezel }

/// Rings of small accent stones around the centre stone.
enum HaloStyle { none, single, double }

/// Cross-section of a ring's band.
enum BandProfile { comfort, flat, knifeEdge, dShape }

/// Small stones set along a ring's band.
enum BandAccent { plain, pave, eternity }

enum EarringStyle { stud, drop, hoop }

enum ChainStyle { cable, curb, box, rope }

/// Necklace lengths in inches, as sold.
enum ChainLength {
  in16(16),
  in18(18),
  in20(20),
  in24(24);

  const ChainLength(this.inches);

  final int inches;

  double get mm => inches * 25.4;
}

enum BraceletStyle { tennis, bangle, chain }

/// Ring sizes on the US scale and their inside diameter.
abstract final class RingSizes {
  static const min = 3.0, max = 13.0;

  /// Inside diameter in mm (ISO 8653 via the US scale).
  static double diameterMm(double us) => 11.63 + 0.8128 * us;
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
    this.head = HeadStyle.prong6,
    this.halo = HaloStyle.none,
    this.threeStone = false,
    this.cathedral = false,
    this.bandProfile = BandProfile.comfort,
    this.bandWidthMm = 2.2,
    this.ringSize = 6.5,
    this.bandAccent = BandAccent.plain,
    this.earringStyle = EarringStyle.stud,
    this.hoopDiameterMm = 22,
    this.chainStyle = ChainStyle.cable,
    this.chainLength = ChainLength.in18,
    this.chainWidthMm = 1.6,
    this.braceletStyle = BraceletStyle.tennis,
    this.braceletLengthIn = 7.0,
    this.accentStoneMm = 2.6,
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
  static const minBracelet = 6.0, maxBracelet = 8.0;
  static const minAccent = 1.8, maxAccent = 4.0;

  final JewelryType type;
  final JewelryMetal metal;
  final MetalPurity purity;
  final MetalFinish finish;

  /// The centre stone; earrings carry one of these on each side.
  final DiamondSpec stone;

  final HeadStyle head;
  final HaloStyle halo;

  // Ring.
  final bool threeStone, cathedral;
  final BandProfile bandProfile;
  final double bandWidthMm;
  final double ringSize;
  final BandAccent bandAccent;

  // Earrings.
  final EarringStyle earringStyle;
  final double hoopDiameterMm;

  // Necklace.
  final ChainStyle chainStyle;
  final ChainLength chainLength;
  final double chainWidthMm;

  // Bracelet.
  final BraceletStyle braceletStyle;
  final double braceletLengthIn;

  /// Diameter of each stone in a tennis bracelet or bangle.
  final double accentStoneMm;

  /// Whether this piece has a traced centre stone.
  bool get hasCentreStone => switch (type) {
    JewelryType.ring || JewelryType.necklace => true,
    JewelryType.earrings => earringStyle != EarringStyle.hoop,
    JewelryType.bracelet => false,
  };

  /// Whether a halo can be fitted to this piece.
  bool get takesHalo => hasCentreStone;

  JewelryDesign copyWith({
    JewelryType? type,
    JewelryMetal? metal,
    MetalPurity? purity,
    MetalFinish? finish,
    DiamondSpec? stone,
    HeadStyle? head,
    HaloStyle? halo,
    bool? threeStone,
    bool? cathedral,
    BandProfile? bandProfile,
    double? bandWidthMm,
    double? ringSize,
    BandAccent? bandAccent,
    EarringStyle? earringStyle,
    double? hoopDiameterMm,
    ChainStyle? chainStyle,
    ChainLength? chainLength,
    double? chainWidthMm,
    BraceletStyle? braceletStyle,
    double? braceletLengthIn,
    double? accentStoneMm,
  }) {
    final m = metal ?? this.metal;
    var p = purity ?? this.purity;
    // A metal change keeps the purity only if the new metal comes in it.
    if (!m.purities.contains(p)) p = m.defaultPurity;
    return JewelryDesign(
      type: type ?? this.type,
      metal: m,
      purity: p,
      finish: finish ?? this.finish,
      stone: stone ?? this.stone,
      head: head ?? this.head,
      halo: halo ?? this.halo,
      threeStone: threeStone ?? this.threeStone,
      cathedral: cathedral ?? this.cathedral,
      bandProfile: bandProfile ?? this.bandProfile,
      bandWidthMm: (bandWidthMm ?? this.bandWidthMm).clamp(
        minBandWidth,
        maxBandWidth,
      ),
      ringSize: (ringSize ?? this.ringSize).clamp(RingSizes.min, RingSizes.max),
      bandAccent: bandAccent ?? this.bandAccent,
      earringStyle: earringStyle ?? this.earringStyle,
      hoopDiameterMm: (hoopDiameterMm ?? this.hoopDiameterMm).clamp(
        minHoop,
        maxHoop,
      ),
      chainStyle: chainStyle ?? this.chainStyle,
      chainLength: chainLength ?? this.chainLength,
      chainWidthMm: (chainWidthMm ?? this.chainWidthMm).clamp(
        minChainWidth,
        maxChainWidth,
      ),
      braceletStyle: braceletStyle ?? this.braceletStyle,
      braceletLengthIn: (braceletLengthIn ?? this.braceletLengthIn).clamp(
        minBracelet,
        maxBracelet,
      ),
      accentStoneMm: (accentStoneMm ?? this.accentStoneMm).clamp(
        minAccent,
        maxAccent,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is JewelryDesign &&
      other.type == type &&
      other.metal == metal &&
      other.purity == purity &&
      other.finish == finish &&
      other.stone == stone &&
      other.head == head &&
      other.halo == halo &&
      other.threeStone == threeStone &&
      other.cathedral == cathedral &&
      other.bandProfile == bandProfile &&
      other.bandWidthMm == bandWidthMm &&
      other.ringSize == ringSize &&
      other.bandAccent == bandAccent &&
      other.earringStyle == earringStyle &&
      other.hoopDiameterMm == hoopDiameterMm &&
      other.chainStyle == chainStyle &&
      other.chainLength == chainLength &&
      other.chainWidthMm == chainWidthMm &&
      other.braceletStyle == braceletStyle &&
      other.braceletLengthIn == braceletLengthIn &&
      other.accentStoneMm == accentStoneMm;

  @override
  int get hashCode => Object.hashAll([
    type,
    metal,
    purity,
    finish,
    stone,
    head,
    halo,
    threeStone,
    cathedral,
    bandProfile,
    bandWidthMm,
    ringSize,
    bandAccent,
    earringStyle,
    hoopDiameterMm,
    chainStyle,
    chainLength,
    chainWidthMm,
    braceletStyle,
    braceletLengthIn,
    accentStoneMm,
  ]);
}
