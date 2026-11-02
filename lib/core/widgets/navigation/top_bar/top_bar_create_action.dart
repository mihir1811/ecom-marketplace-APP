import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../router/app_navigation.dart';
import '../../../theme/app_fonts.dart';
import '../../../theme/atelier_palette.dart';

/// A screen's main "create" shortcut (new question, new inquiry, create
/// auction…) shown in the top bar as a gold plus pill with a short label,
/// so the page does not spend a row on it.
@immutable
class TopBarCreate {
  const TopBarCreate({
    required this.label,
    required this.tooltip,
    required this.onPressed,
    this.icon = Icons.add_rounded,
  });

  /// One short word shown next to the icon ("Ask", "Inquiry").
  final String label;

  /// Full name for tooltip / screen readers ("New question").
  final String tooltip;
  final IconData icon;

  /// Null greys the pill out (e.g. while a save is running).
  final VoidCallback? onPressed;
}

/// A registered shortcut and the screen that owns it.
class TopBarCreateEntry {
  const TopBarCreateEntry(this.owner, this.create);
  final Object owner;
  final TopBarCreate create;
}

class TopBarCreateRegistry
    extends StateNotifier<Map<String, TopBarCreateEntry>> {
  TopBarCreateRegistry() : super(const {});

  void put(String path, Object owner, TopBarCreate create) {
    state = {...state, path: TopBarCreateEntry(owner, create)};
  }

  void remove(String path, Object owner) {
    if (state[path]?.owner != owner) return;
    state = {...state}..remove(path);
  }
}

/// Create shortcuts keyed by canonical route path.
final topBarCreateRegistryProvider =
    StateNotifierProvider<TopBarCreateRegistry, Map<String, TopBarCreateEntry>>(
      (_) => TopBarCreateRegistry(),
    );

/// The create shortcut registered for [location], if any.
TopBarCreate? topBarCreateFor(WidgetRef ref, String location) {
  final path = AppNavigation.canonicalPath(location);
  return ref.watch(topBarCreateRegistryProvider.select((m) => m[path]?.create));
}

/// Wrap a screen's body to put [create] in the top bar while the screen is
/// on its route. The bar is owned by the shell, so the screen hands the
/// action up instead of drawing a button of its own.
class TopBarCreateAction extends ConsumerStatefulWidget {
  const TopBarCreateAction({
    super.key,
    required this.create,
    required this.child,
  });

  /// Null hides the shortcut (e.g. while the page has nothing to create).
  final TopBarCreate? create;
  final Widget child;

  @override
  ConsumerState<TopBarCreateAction> createState() => _TopBarCreateActionState();
}

class _TopBarCreateActionState extends ConsumerState<TopBarCreateAction> {
  final Object _owner = Object();
  String? _path;
  TopBarCreateRegistry? _registry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pinned to the route the screen was built for: a page pushed on top
    // must not inherit this shortcut.
    if (_path == null && _registry == null) {
      _registry = ref.read(topBarCreateRegistryProvider.notifier);
      try {
        _path = AppNavigation.canonicalPath(GoRouterState.of(context).uri.path);
      } on GoError {
        return; // Not on a route (tests, dialogs): nothing to register.
      }
      _sync();
    }
  }

  @override
  void didUpdateWidget(TopBarCreateAction old) {
    super.didUpdateWidget(old);
    _sync();
  }

  // The registry rebuilds the bar, which cannot happen mid-build: defer.
  void _sync() {
    final path = _path;
    final registry = _registry;
    if (path == null || registry == null) return;
    final create = widget.create;
    scheduleMicrotask(() {
      if (!mounted) return;
      if (create == null) {
        registry.remove(path, _owner);
      } else {
        registry.put(path, _owner, create);
      }
    });
  }

  @override
  void dispose() {
    final path = _path;
    final registry = _registry;
    if (path != null && registry != null) {
      scheduleMicrotask(() => registry.remove(path, _owner));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The gold plus pill the bar draws for a [TopBarCreate].
class TopBarCreateButton extends StatelessWidget {
  const TopBarCreateButton({super.key, required this.create});

  final TopBarCreate create;

  @override
  Widget build(BuildContext context) {
    final p = AtelierPalette.of(context);
    final enabled = create.onPressed != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: create.tooltip,
        child: Semantics(
          button: true,
          enabled: enabled,
          label: create.tooltip,
          excludeSemantics: true,
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: p.goldGradient,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Material(
                type: MaterialType.transparency,
                shape: const StadiumBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: create.onPressed,
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.only(left: 9, right: 13),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(create.icon, size: 18, color: p.onGold),
                        const SizedBox(width: 5),
                        Text(
                          create.label,
                          maxLines: 1,
                          style: AppFonts.secondary(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                            color: p.onGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
