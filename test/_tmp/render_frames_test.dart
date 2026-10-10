import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/router/route_names.dart';
import 'package:gemstone/core/widgets/navigation/bottom_nav/diamond_transition/diamond_cut.dart';
import 'package:gemstone/core/widgets/navigation/bottom_nav/diamond_transition/diamond_mesh.dart';
import 'package:gemstone/core/widgets/navigation/bottom_nav/diamond_transition/diamond_transition_controller.dart';

const w = 390.0, h = 700.0;

DiamondSnapshot page(Color tone, Color card) {
  final r = ui.PictureRecorder();
  final c = Canvas(r);
  c.drawRect(
    const Rect.fromLTWH(0, 0, w, h),
    Paint()..color = const Color(0xFFF6F3EE),
  );
  c.drawRect(const Rect.fromLTWH(0, 0, w, 90), Paint()..color = tone);
  for (var i = 0; i < 4; i++) {
    for (var k = 0; k < 2; k++) {
      final rect = Rect.fromLTWH(16 + k * 187, 110 + i * 150, 171, 136);
      c.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(14)),
        Paint()..color = card,
      );
      c.drawRect(
        Rect.fromLTWH(rect.left + 12, rect.bottom - 30, 100, 8),
        Paint()..color = const Color(0xFF16140F),
      );
      c.drawCircle(
        rect.center.translate(0, -14),
        30,
        Paint()..color = tone.withValues(alpha: 0.6),
      );
    }
  }
  final img = r.endRecording().toImageSync(w.toInt(), h.toInt());
  return DiamondSnapshot(img, 1, const Size(w, h));
}

void main() {
  testWidgets('render', (tester) async {
    final out = Platform.environment['OUT']!;
    final dark = Platform.environment['DARK'] == '1';
    var path = AppRouteNames.home;
    var n = 0;
    final pages = [
      page(const Color(0xFF9C7A45), const Color(0xFFFFFFFF)),
      page(const Color(0xFF2F5A7A), const Color(0xFFE8EEF4)),
    ];
    final c = DiamondTransitionController(
      vsync: const TestVSync(),
      routes: const [
        AppRouteNames.home,
        AppRouteNames.buyerWishlist,
        AppRouteNames.cart,
        AppRouteNames.buyerProfile,
      ],
      cuts: [
        DiamondCut.brilliant,
        DiamondCut.marquise,
        DiamondCut.emerald,
        DiamondCut.brilliant,
      ],
      navigate: (r) => path = r,
      currentPath: () => path,
      currentTab: () => 0,
    );
    c.capture = (_) {
      final p = pages[path == AppRouteNames.home ? 0 : 1];
      return DiamondSnapshot(p.image.clone(), 1, p.size);
    };
    final mesh = DiamondMesh();
    final style = dark
        ? const DiamondStyle(
            backdrop: Color(0xFF0A0A0C),
            sheetBack: Color(0xFF1B1B1F),
            accent: Color(0xFFD9BB84),
            isDark: true,
          )
        : const DiamondStyle(
            backdrop: Color(0xFFF6F3EE),
            sheetBack: Color(0xFFEFEAE2),
            accent: Color(0xFF9C7A45),
            isDark: false,
          );
    final cut = Platform.environment['CUT'] ?? '2';
    final every = int.parse(Platform.environment['EVERY'] ?? '4');
    c.requestTab(int.parse(cut));
    await tester.pump();
    for (var f = 0; f < 90; f++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (f % every != 0 || !c.isActive) continue;
      final r = ui.PictureRecorder();
      mesh.paint(Canvas(r), const Size(w, h), c, style);
      final img = r.endRecording().toImageSync(w.toInt(), h.toInt());
      final bytes = await tester.runAsync(
        () => img.toByteData(format: ui.ImageByteFormat.png),
      );
      File(
        '$out/f${cut}_${(n++).toString().padLeft(2, '0')}_p${c.progress.toStringAsFixed(2)}.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
    }
  });
}
