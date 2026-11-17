import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Mutes the tickers below [child] (shimmers, pulses, looping controllers,
/// anything listening to [TickerMode]) while it is scrolled fully out of view
/// of the nearest vertical [Scrollable].
///
/// Sections of a long page built with `SliverToBoxAdapter` stay mounted when
/// scrolled away, so their loops would keep the page producing frames even
/// when nothing visible moves. Nothing changes while the child is on screen:
/// tickers resume [margin] pixels before it scrolls back in.
class PauseWhenOffscreen extends StatefulWidget {
  const PauseWhenOffscreen({required this.child, this.margin = 120, super.key});

  final Widget child;

  /// How far outside the viewport the child still counts as visible.
  final double margin;

  @override
  State<PauseWhenOffscreen> createState() => _PauseWhenOffscreenState();
}

class _PauseWhenOffscreenState extends State<PauseWhenOffscreen> {
  ScrollPosition? _position;
  bool _visible = true;
  bool _checkScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var scrollable = Scrollable.maybeOf(context);
    while (scrollable != null &&
        axisDirectionToAxis(scrollable.axisDirection) != Axis.vertical) {
      scrollable = Scrollable.maybeOf(scrollable.context);
    }
    final next = scrollable?.position;
    if (next != _position) {
      _position?.removeListener(_scheduleCheck);
      _position = next;
      _position?.addListener(_scheduleCheck);
    }
    _scheduleCheck();
  }

  /// Measures after layout so the box reflects the latest scroll offset.
  void _scheduleCheck() {
    if (_checkScheduled) return;
    _checkScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      _check();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  void _check() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final bottom = top + box.size.height;
    final viewport = MediaQuery.sizeOf(context).height;
    final visible = bottom > -widget.margin && top < viewport + widget.margin;
    if (visible != _visible) setState(() => _visible = visible);
  }

  @override
  void dispose() {
    _position?.removeListener(_scheduleCheck);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      TickerMode(enabled: _visible, child: widget.child);
}
