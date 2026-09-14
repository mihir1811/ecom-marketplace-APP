import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/haptics/app_haptics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(AppHaptics.debugReset);

  tearDown(() {
    AppHaptics.debugReset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('semantic methods complete without throwing', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });

    final methods = <void Function()>[
      AppHaptics.light,
      AppHaptics.selection,
      AppHaptics.medium,
      AppHaptics.heavy,
      AppHaptics.success,
      AppHaptics.warning,
      AppHaptics.error,
    ];
    for (final method in methods) {
      AppHaptics.debugReset();
      method();
    }

    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(calls, isNotEmpty);
    expect(
      calls.every((c) => c.method.startsWith('HapticFeedback.')),
      isTrue,
    );
  });

  test('debugDisable prevents platform channel calls', () async {
    AppHaptics.debugDisable = true;
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });

    AppHaptics.medium();
    AppHaptics.error();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(calls, isEmpty);
  });

  test('platform channel errors are swallowed', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          throw PlatformException(code: 'UNAVAILABLE');
        });

    expect(AppHaptics.light, returnsNormally);
    expect(AppHaptics.error, returnsNormally);
  });
}
