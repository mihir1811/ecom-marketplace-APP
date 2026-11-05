import 'models/diamond.dart';
import 'models/sieve_size.dart';

/// Display figures for a melee lot: pieces, total carat and unit prices.
///
/// Seller values are used as given. Missing ones are worked out from the
/// other lot values, and as a last resort from the sieve size (or mm size)
/// via the standard sieve chart. Anything that leans on the chart is flagged
/// approximate so the UI can say so.
///
/// Display only: cart and offer pricing keep using seller data.
/// Melee carat per piece: up to 3 decimals, never below 2
/// ("0.005", "0.01", "0.15").
String formatCaratPerPiece(double ct) {
  var s = ct.toStringAsFixed(3);
  while (s.endsWith('0') && s.length - s.indexOf('.') > 3) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}

class MeleeLotFigures {
  const MeleeLotFigures({
    this.totalPcs,
    this.totalCarat,
    this.caratPerPcs,
    this.pricePerPcs,
    this.pricePerCarat,
    this.totalPcsApprox = false,
    this.totalCaratApprox = false,
    this.caratPerPcsApprox = false,
    this.pricePerPcsApprox = false,
    this.pricePerCaratApprox = false,
  });

  final int? totalPcs;
  final double? totalCarat;
  final double? caratPerPcs;
  final double? pricePerPcs;
  final double? pricePerCarat;

  // Each flag: that value leans on the sieve chart.
  final bool totalPcsApprox;
  final bool totalCaratApprox;
  final bool caratPerPcsApprox;
  final bool pricePerPcsApprox;
  final bool pricePerCaratApprox;

  /// Pieces-mode figures (total pcs / price per piece) are estimates.
  bool get pcsApprox => totalPcsApprox || pricePerPcsApprox;

  /// Carat-mode figures (total carat / price per carat) are estimates.
  bool get caratApprox => totalCaratApprox || pricePerCaratApprox;

  static MeleeLotFigures of(Diamond d) {
    final price = d.price;
    final sellerPcs = (d.totalPcs ?? 0) > 0 ? d.totalPcs : null;
    // The mapper falls back to carat-per-piece for `carat`, so only trust
    // `carat` as a lot total when no per-piece value was sent.
    final sellerCt =
        _pos(d.totalCaratWeight) ??
        (d.caratPerPcs == null ? _pos(d.carat) : null);
    final sellerCpp = _pos(d.caratPerPcs);

    // Carat per piece: seller, then lot totals, then the sieve chart.
    var cpp = sellerCpp;
    var cppApprox = false;
    if (cpp == null && sellerPcs != null && sellerCt != null) {
      cpp = sellerCt / sellerPcs;
    }
    if (cpp == null) {
      cpp = sieveCaratPerPcs(d);
      cppApprox = cpp != null;
    }

    int? pcs = sellerPcs;
    var pcsApprox = false;
    if (pcs == null && sellerCt != null && cpp != null) {
      final n = (sellerCt / cpp).round();
      if (n > 0) {
        pcs = n;
        pcsApprox = cppApprox;
      }
    }

    double? ct = sellerCt;
    var ctApprox = false;
    if (ct == null && pcs != null && cpp != null) {
      ct = pcs * cpp;
      ctApprox = cppApprox;
    }

    final ppp =
        _pos(d.pricePerPcs) ?? (pcs != null && price > 0 ? price / pcs : null);
    final pppApprox = _pos(d.pricePerPcs) == null && pcsApprox;
    final ppc =
        _pos(d.pricePerCarat) ??
        (ct != null && ct > 0 && price > 0 ? price / ct : null);
    final ppcApprox = _pos(d.pricePerCarat) == null && ctApprox;

    return MeleeLotFigures(
      totalPcs: pcs,
      totalCarat: ct,
      caratPerPcs: cpp,
      pricePerPcs: ppp,
      pricePerCarat: ppc,
      totalPcsApprox: pcsApprox,
      totalCaratApprox: ctApprox,
      caratPerPcsApprox: cppApprox,
      pricePerPcsApprox: pppApprox,
      pricePerCaratApprox: ppcApprox,
    );
  }

  /// Average carat per stone from the sieve range, else the mm range.
  static double? sieveCaratPerPcs(Diamond d) {
    final fromSieve = _rangeAverage(d.sieveLabel, _sieveFor);
    if (fromSieve != null) return fromSieve;
    final mm = [
      _mmFor(d.measurementMin),
      _mmFor(d.measurementMax),
    ].whereType<double>().toList();
    if (mm.isEmpty) return null;
    return mm.reduce((a, b) => a + b) / mm.length;
  }

  static double? _rangeAverage(
    String? label,
    double? Function(String part) lookup,
  ) {
    final raw = label?.trim();
    if (raw == null || raw.isEmpty) return null;
    final whole = lookup(raw);
    if (whole != null) return whole;
    // Mapper joins min/max as "a–b".
    final parts = raw.split('–').map(lookup).whereType<double>().toList();
    if (parts.isEmpty) return null;
    return parts.reduce((a, b) => a + b) / parts.length;
  }

  static String _norm(String s) =>
      s.replaceAll('/', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Matches "+2 -2.5", "+2", "-2.5" or a bare "2" against the chart.
  static double? _sieveFor(String part) {
    final p = _norm(part);
    if (p.isEmpty) return null;
    for (final s in SieveSize.defaultSieves) {
      if (_norm(s.sieve) == p) return s.carat;
    }
    if (p.toLowerCase().contains('mm')) return _mmFor(p);
    final bare = RegExp(r'^\d+(\.\d+)?$').hasMatch(p) ? '+$p' : p;
    for (final s in SieveSize.defaultSieves) {
      final bits = _norm(s.sieve).split(' ');
      if (bare.startsWith('+') && bits.first == bare) return s.carat;
      if (bare.startsWith('-') && bits.last == bare) return s.carat;
    }
    return null;
  }

  /// Carat per stone for a diameter in mm (first number in [raw]).
  static double? _mmFor(String? raw) {
    if (raw == null) return null;
    final m = RegExp(r'\d+(\.\d+)?').firstMatch(raw);
    final mm = m == null ? null : double.tryParse(m.group(0)!);
    if (mm == null || mm <= 0) return null;
    for (final s in SieveSize.defaultSieves) {
      if (mm >= s.mmMin && mm < s.mmMax) return s.carat;
    }
    return null;
  }

  static double? _pos(num? v) => v != null && v > 0 ? v.toDouble() : null;
}
