import 'dart:io';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Native side: MainActivity's LiveDeviceChannel and AppDelegate's
/// LiveDevice. battery_plus is not used: its Linux dbus pin clashes with
/// wakelock_plus.
const _channel = MethodChannel('gemworld/live_device');

const _installIdKey = 'live_install_id';

/// This install's id: made once, kept until the app is removed. Ties a
/// guest's visits together; never the advertising id.
Future<String> liveInstallId() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_installIdKey);
  if (saved != null && saved.isNotEmpty) return saved;
  final id = _uuidV4();
  await prefs.setString(_installIdKey, id);
  return id;
}

String _uuidV4() {
  final random = math.Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

bool get _isPhone =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Battery level 0–100 and whether it charges; nulls when the OS won't say.
Future<({int? level, bool? charging})> liveBattery() async {
  if (!_isPhone) return (level: null, charging: null);
  try {
    final map = await _channel.invokeMapMethod<String, Object?>('battery');
    final level = (map?['level'] as num?)?.round();
    return (
      level: level != null && level >= 0 && level <= 100 ? level : null,
      charging: map?['charging'] as bool?,
    );
  } catch (_) {
    return (level: null, charging: null);
  }
}

/// The SIM operator's name on Android ("Jio"); null elsewhere or with no
/// SIM. iOS stopped giving it in iOS 16.
Future<String?> _simOperatorName() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
  try {
    final name = await _channel.invokeMethod<String>('simOperatorName');
    return name == null || name.trim().isEmpty ? null : name.trim();
  } catch (_) {
    return null;
  }
}

/// Join body for `POST /live/shows/{id}/join`: what only the app can see.
/// Never the IP, city, state or network provider — the server reads those.
/// Each field is best-effort; a failing source just leaves its field out.
Future<Map<String, Object>> liveJoinDetails({
  Map<String, String> campaign = const {},
}) async {
  final out = <String, Object>{};

  Future<void> add(Future<void> Function() read) async {
    try {
      await read();
    } catch (_) {}
  }

  final view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
  if (view != null && view.devicePixelRatio > 0) {
    final screen = view.physicalSize / view.devicePixelRatio;
    out['screenWidth'] = screen.width.round();
    out['screenHeight'] = screen.height.round();
    out['pixelRatio'] = view.devicePixelRatio;
  }
  out['language'] = WidgetsBinding.instance.platformDispatcher.locale
      .toLanguageTag();

  await Future.wait([
    add(() async => out['deviceId'] = await liveInstallId()),
    add(
      () async => out['timezone'] =
          (await FlutterTimezone.getLocalTimezone()).identifier,
    ),
    add(() async {
      final network = await Connectivity().checkConnectivity();
      out['connectionType'] = switch (network) {
        _ when network.contains(ConnectivityResult.wifi) => 'wifi',
        _ when network.contains(ConnectivityResult.mobile) => 'cellular',
        _ when network.contains(ConnectivityResult.ethernet) => 'ethernet',
        _ when network.contains(ConnectivityResult.vpn) => 'vpn',
        _ when network.contains(ConnectivityResult.none) => 'none',
        _ => 'other',
      };
    }),
  ]);

  if (!_isPhone) return out..addAll(_campaign(campaign));

  out['platform'] = defaultTargetPlatform == TargetPlatform.iOS
      ? 'IOS'
      : 'ANDROID';
  out['cpuCores'] = Platform.numberOfProcessors;

  await Future.wait([
    add(
      () async =>
          out['appVersion'] = (await PackageInfo.fromPlatform()).version,
    ),
    add(() async {
      final battery = await liveBattery();
      if (battery.level != null) out['batteryLevel'] = battery.level!;
      if (battery.charging != null) out['batteryCharging'] = battery.charging!;
    }),
    add(() async {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = await DeviceInfoPlugin().iosInfo;
        out['deviceBrand'] = 'Apple';
        out['deviceModel'] = ios.modelName;
        out['osVersion'] = ios.systemVersion;
        _addMemory(out, ios.physicalRamSize);
      } else {
        final android = await DeviceInfoPlugin().androidInfo;
        out['deviceBrand'] = android.manufacturer;
        out['deviceModel'] = android.model;
        out['osVersion'] = android.version.release;
        _addMemory(out, android.physicalRamSize);
      }
    }),
    add(() async {
      final carrier = await _simOperatorName();
      if (carrier != null) out['carrier'] = carrier;
    }),
  ]);

  return out..addAll(_campaign(campaign));
}

void _addMemory(Map<String, Object> out, int megabytes) {
  if (megabytes <= 0) return;
  out['deviceMemoryGb'] = (megabytes / 1024 * 10).round() / 10;
}

/// `utm_*` of the link that opened the show, as the join body names them.
Map<String, String> _campaign(Map<String, String> query) {
  const names = {
    'utm_source': 'utmSource',
    'utm_medium': 'utmMedium',
    'utm_campaign': 'utmCampaign',
  };
  return {
    for (final MapEntry(:key, :value) in names.entries)
      if (query[key]?.trim() case final v? when v.isNotEmpty) value: v,
  };
}
