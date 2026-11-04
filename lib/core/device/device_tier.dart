import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Whether this phone should skip the costliest per-frame effects
/// (backdrop blurs over scrolling content).
///
/// True on phones with about 3 GB of RAM or less, and while battery saver is
/// on. Asked from the native `gemworld/device_perf` channel
/// (DevicePerfChannel.kt) at startup and whenever the app resumes, since
/// battery saver can change at any time. False until known, and on non-Android
/// platforms.
abstract final class DeviceTier {
  static final reduceEffects = ValueNotifier<bool>(false);

  /// Phones sold as "3 GB" report roughly 2.7–3.0 GB total; "4 GB" phones
  /// report about 3.6 GB and up.
  static const _lowRamBytes = 3.3e9;

  static const _channel = MethodChannel('gemworld/device_perf');
  static AppLifecycleListener? _lifecycle;

  /// Call once after `WidgetsFlutterBinding.ensureInitialized()`.
  static void init() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _lifecycle ??= AppLifecycleListener(onResume: refresh);
    refresh();
  }

  static Future<void> refresh() async {
    try {
      final snapshot = await _channel.invokeMapMethod<String, Object?>(
        'snapshot',
      );
      if (snapshot == null) return;
      final total = (snapshot['totalBytes'] as num?)?.toDouble() ?? 0;
      final powerSaving = snapshot['powerSaving'] == true;
      reduceEffects.value = (total > 0 && total <= _lowRamBytes) || powerSaving;
    } catch (_) {
      // Channel unavailable (tests, other embedders): keep full effects.
    }
  }
}
