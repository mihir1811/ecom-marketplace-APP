import '../../seller/presentation/atelier/atelier_studio.dart';

/// `1,250`.
String rewardPointsCount(num points) =>
    atelierMoney(points.round(), symbol: '');

/// `1,250 pts` / `1 pt`.
String rewardPointsLabel(num points) {
  final n = points.round();
  return '${rewardPointsCount(n)} ${n.abs() == 1 ? 'pt' : 'pts'}';
}

/// `20%` / `12.5%`.
String rewardPercentLabel(double percent) => percent == percent.roundToDouble()
    ? '${percent.toStringAsFixed(0)}%'
    : '${percent.toStringAsFixed(1)}%';
