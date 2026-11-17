import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/core/widgets/fit_resize_image.dart';

void main() {
  final provider = MemoryImage(Uint8List(4));

  FitResizeImage box(int w, int h, BoxFit fit) =>
      FitResizeImage(provider, width: w, height: h, fit: fit);

  test('cover keeps the side that is drawn larger at box size', () {
    // Wide 4000x1000 photo in a 1170x660 banner: cover scales by height.
    final t = box(1170, 660, BoxFit.cover).targetSize(4000, 1000);
    expect(t.height, 660);
    expect(t.width, 2640); // drawn 2640 wide, cropped to 1170: still sharp
  });

  test('cover with a tall photo scales by width', () {
    final t = box(540, 540, BoxFit.cover).targetSize(3000, 4000);
    expect(t.width, 540);
    expect(t.height, 720);
  });

  test('contain fits inside the box', () {
    final t = box(900, 600, BoxFit.contain).targetSize(3000, 3000);
    expect(t.width, 600);
    expect(t.height, 600);
  });

  test('never upscales a smaller image', () {
    final t = box(1170, 660, BoxFit.cover).targetSize(800, 400);
    expect(t.width, 800);
    expect(t.height, 400);
  });

  test('keys differ by target size so caches do not mix', () async {
    final a = await box(
      100,
      100,
      BoxFit.cover,
    ).obtainKey(ImageConfiguration.empty);
    final b = await box(
      200,
      100,
      BoxFit.cover,
    ).obtainKey(ImageConfiguration.empty);
    final a2 = await box(
      100,
      100,
      BoxFit.cover,
    ).obtainKey(ImageConfiguration.empty);
    expect(a, isNot(b));
    expect(a, a2);
  });
}
