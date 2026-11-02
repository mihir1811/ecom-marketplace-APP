import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'order_link.dart';

/// Holds the order link that is waiting to open: until the saved session is
/// read and the navigator exists (cold start), or until the person signs in.
class OrderLinks extends ChangeNotifier {
  OrderLinks._();

  static final OrderLinks instance = OrderLinks._();

  OrderLink? _pending;

  /// True once a signed-out person was sent to sign in for [pending], so
  /// later route changes don't send them again.
  bool signInRequested = false;

  OrderLink? get pending => _pending;

  /// Queues [link]; the newest tap wins. Pass [signInRequested] when the
  /// caller already sent the person to sign in.
  void receive(OrderLink link, {bool signInRequested = false}) {
    _pending = link;
    this.signInRequested = signInRequested;
    notifyListeners();
  }

  /// Hands over the pending link and clears it.
  OrderLink? take() {
    final link = _pending;
    _pending = null;
    signInRequested = false;
    return link;
  }

  /// Catches order links tapped while the app runs, before the router does,
  /// so they open on top of the current screen instead of replacing it.
  /// Register before `runApp` so this observer is asked first.
  static void attach() {
    WidgetsBinding.instance.addObserver(_OrderLinkObserver());
  }
}

class _OrderLinkObserver with WidgetsBindingObserver {
  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) {
    final link = parseOrderLink(routeInformation.uri);
    if (link == null) return SynchronousFuture(false);
    OrderLinks.instance.receive(link);
    return SynchronousFuture(true);
  }
}
