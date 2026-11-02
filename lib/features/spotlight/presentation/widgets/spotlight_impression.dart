import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../application/spotlight_providers.dart';

/// Ads already counted during one visit to a screen.
///
/// A view counts once per ad per screen visit; give one visit to every
/// spotlight widget of a screen (or let each block keep its own).
class SpotlightVisit {
  final _seen = <String>{};

  /// True the first time [adId] is claimed in this visit.
  bool claim(String adId) => adId.isNotEmpty && _seen.add(adId);
}

/// Counts a view of [adId] the first time at least half of [child] is on
/// screen during [visit].
class SpotlightImpression extends ConsumerStatefulWidget {
  const SpotlightImpression({
    required this.adId,
    required this.visit,
    required this.child,
    super.key,
  });

  final String adId;
  final SpotlightVisit visit;
  final Widget child;

  @override
  ConsumerState<SpotlightImpression> createState() =>
      _SpotlightImpressionState();
}

class _SpotlightImpressionState extends ConsumerState<SpotlightImpression> {
  final _key = UniqueKey();

  void _onVisibility(VisibilityInfo info) {
    if (!mounted || info.visibleFraction < 0.5) return;
    if (!widget.visit.claim(widget.adId)) return;
    ref.read(spotlightEventsProvider).impression(widget.adId);
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: _key,
      onVisibilityChanged: _onVisibility,
      child: widget.child,
    );
  }
}
