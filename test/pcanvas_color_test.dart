import 'dart:math';

import 'package:pcanvas/pcanvas.dart';
import 'package:test/test.dart';

void main() {
  group('color', () {
    test('rgb->hsv->rgb', () {
      _testColor(0, 0, 0, 0, 0, 0);
      _testColor(255, 255, 255, 0, 0, 100);

      _testColor(255, 0, 0, 0, 100, 100);
      _testColor(0, 255, 0, 120, 100, 100);
      _testColor(0, 0, 255, 240, 100, 100);

      _testColor(216, 118, 100, 9, 53, 84);
      _testColor(252, 186, 3, 44, 98, 98);
    });

    test('rgb->hsv->rgb (Random)', () {
      var random = Random(123);

      for (var i = 0; i < 100; ++i) {
        var r = random.nextInt(256);
        var g = random.nextInt(256);
        var b = random.nextInt(256);

        _testColor(r, g, b);
      }
    });
  });
}

void _testColor(int r, int g, int b, [int? h, int? s, int? v]) {
  print('----------------------------------------');
  print('_testColor> $r, $g, $b -> $h, $s, $v');

  var rgb0 = (r: r, g: g, b: b);
  print('rgb0: $rgb0');

  var hsv = rgbToHSV(rgb0.r, rgb0.g, rgb0.b);
  print('hsv: $hsv');

  if (h != null) {
    expect(
      [hsv.h.toInt(), (hsv.s * 100).toInt(), (hsv.v * 100).toInt()],
      [h, s, v],
    );
  }

  var rgb2 = hsvToRGB(hsv.h, hsv.s, hsv.v);
  print('rgb2: $rgb2');

  expect(rgb0, rgb2);
}
