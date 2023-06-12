import 'dart:math' as math;

import 'pcanvas_base.dart';
import 'pcanvas_utils.dart';

/// A [PCanvas] color.
abstract class PColor implements WithJson {
  static final PColorRGB colorRed = PColorRGB(255, 0, 0);
  static final PColorRGB colorGreen = PColorRGB(0, 255, 0);
  static final PColorRGB colorBlue = PColorRGB(0, 0, 255);

  static final PColorRGB colorYellow = PColorRGB(255, 255, 0);
  static final PColorRGB colorPink = PColorRGB(255, 0, 255);

  static final PColorRGB colorWhite = PColorRGB(255, 255, 255);
  static final PColorRGB colorBlack = PColorRGB(0, 0, 0);

  static final PColorRGB colorGreyLight2 = PColorRGB(224, 224, 224);
  static final PColorRGB colorGreyLight1 = PColorRGB(192, 192, 192);
  static final PColorRGB colorGrey = PColorRGB(128, 128, 128);
  static final PColorRGB colorGreyDark1 = PColorRGB(64, 64, 64);
  static final PColorRGB colorGreyDark2 = PColorRGB(32, 32, 32);

  static final PColorRGB colorBlackAlpha50 = PColorRGBA(0, 0, 0, 0.50);
  static final PColorRGB colorGreyAlpha50 = PColorRGBA(128, 128, 128, 0.50);

  static final PColorRGB colorTransparent = PColorRGBA(0, 0, 0, 0.0);

  static PColor? from(Object? o) {
    if (o == null) return null;

    if (o is PColor) return o;

    var s = o.toString().trim();

    if (s.startsWith('#')) {
      var hex = s.substring(1);

      var hexLng = hex.length;
      if (hexLng >= 6) {
        var r = int.tryParse(hex.substring(0, 2), radix: 16);
        var g = int.tryParse(hex.substring(2, 4), radix: 16);
        var b = int.tryParse(hex.substring(4, 6), radix: 16);

        if (r != null && g != null && b != null) {
          if (hexLng == 9) {
            var a = int.tryParse(hex.substring(6, 9), radix: 16);

            if (a != null) {
              return PColorRGBA(r, g, b, a / 255);
            }
          }

          return PColorRGB(r, g, b);
        }
      } else if (hexLng == 3) {
        var r =
            int.tryParse(hex.substring(0, 1) + hex.substring(0, 1), radix: 16);
        var g =
            int.tryParse(hex.substring(1, 2) + hex.substring(1, 2), radix: 16);
        var b =
            int.tryParse(hex.substring(2, 3) + hex.substring(2, 3), radix: 16);

        if (r != null && g != null && b != null) {
          return PColorRGB(r, g, b);
        }
      }
    }

    var m = RegExp(
            r'^(?:rgba?\(|\(?)?\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*(\d+(?:\.\d+)?)\s*)?\)?$')
        .firstMatch(s);

    if (m != null) {
      var r = int.tryParse(m.group(1) ?? '');
      var g = int.tryParse(m.group(2) ?? '');
      var b = int.tryParse(m.group(3) ?? '');

      var aStr = m.group(4) ?? '';

      double? a;
      if (aStr.contains('.')) {
        a = double.tryParse(aStr);
      } else {
        var aN = int.tryParse(aStr);
        a = aN != null ? aN / 255 : null;
      }

      if (r != null && g != null && b != null) {
        if (a != null) {
          return PColorRGBA(r, g, b, a);
        }
        return PColorRGB(r, g, b);
      }
    }

    return null;
  }

  PColor();

  /// Returns `true` if this color has alpha.
  bool get hasAlpha;

  /// The alpha of this color.
  double get alpha;

  /// Returns `true` if this color alpha is `0.0`.
  bool get isFullyTransparent;

  /// Converts this instances to a [PColorRGB].
  PColorRGB toPColorRGB();

  /// Converts this instances to a [PColorRGBA].
  PColorRGBA toPColorRGBA();

  PColorRGB copyWith({int? r, int? g, int? b, double? alpha});

  PColorRGB withAlpha(double alpha) => copyWith(alpha: alpha);

  /// Converts to the `RGB` format.
  String toRGB();

  /// Converts to the `RGBA` format.
  String toRGBA();

  /// This color in `ARGB` format.
  int get argbInt;

  /// This color in `ABGR` format.
  int get abgrInt;

  /// This color in `RGBA` format.
  int get rgbaInt;

  /// Returns a RGB record.
  ({int r, int g, int b}) get rgb;

  /// Returns a RGBA record.
  ({int r, int g, int b, double a}) get rgba;

  /// Returns a HSV record.
  ({double h, double s, double v}) get hsv;

  /// Returns a HSVA record.
  ({double h, double s, double v, double a}) get hsva;

  /// Returns a lighter color.
  PColor lighter(double ratio) {
    final hsv = this.hsv;
    var v2 = (hsv.v * ratio).clamp(0.0, 1.0);
    var color2 = PColorRGB.fromHSV(hsv.h, hsv.s, v2, alpha: alpha);
    return color2;
  }

  /// Returns a darker color.
  PColor darker(double ratio) => lighter(1 / ratio);

  /// Returns a [PStyle] using `this` as `color` and optional parameter [size].
  PStyle toStyle({int? size});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PColor && toString() == other.toString();

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString();

  @override
  Map<String, dynamic> toJson();

  factory PColor.fromJson(Map<String, dynamic> j) =>
      j.containsKey('a') ? PColorRGBA.fromJson(j) : PColorRGB.fromJson(j);
}

class PColorRGB extends PColor {
  /// The read value.
  final int r;

  /// The green value.
  final int g;

  /// The blue value.
  final int b;

  PColorRGB(int r, int g, int b)
      : r = r.clamp(0, 255),
        g = g.clamp(0, 255),
        b = b.clamp(0, 255);

  PColorRGB.fromRGB(int p)
      : this(
          (p >> 16) & 0xff,
          (p >> 8) & 0xff,
          (p) & 0xff,
        );

  PColorRGB.fromRGBA(int p)
      : this(
          (p >> 24) & 0xff,
          (p >> 16) & 0xff,
          (p >> 8) & 0xff,
        );

  PColorRGB.fromBGR(int p)
      : this(
          (p) & 0xff,
          (p >> 8) & 0xff,
          (p >> 16) & 0xff,
        );

  factory PColorRGB.fromHSV(double h, double s, double v, {double? alpha}) {
    var rgb = hsvToRGB(h, s, v);
    if (alpha != null && alpha != 1.0) {
      return PColorRGBA(rgb.r, rgb.g, rgb.b, alpha);
    } else {
      return PColorRGB(rgb.r, rgb.g, rgb.b);
    }
  }

  @override
  bool get hasAlpha => false;

  @override
  double get alpha => 1.0;

  @override
  bool get isFullyTransparent => false;

  int get a => 255;

  int maxDistance(PColorRGB other) {
    var rd = (r - other.r).abs();
    var gd = (g - other.g).abs();
    var bd = (b - other.b).abs();
    var ad = (a - other.a).abs();

    return math.max(rd, math.max(gd, math.max(bd, ad)));
  }

  int distanceR(PColorRGB other) => (r - other.r).abs();

  int distanceG(PColorRGB other) => (g - other.g).abs();

  int distanceB(PColorRGB other) => (b - other.b).abs();

  int distanceA(PColorRGB other) => (a - other.a).abs();

  @override
  PColorRGB toPColorRGB() => this;

  @override
  PColorRGBA toPColorRGBA() => PColorRGBA(r, g, b, 1);

  @override
  PColorRGB copyWith({int? r, int? g, int? b, double? alpha}) {
    if (alpha == null || alpha == 1.0) {
      return PColorRGB(r ?? this.r, g ?? this.g, b ?? this.b);
    } else {
      return PColorRGBA(r ?? this.r, g ?? this.g, b ?? this.b, alpha);
    }
  }

  String? _rgb;

  @override
  String toRGB() => _rgb ??= 'rgb($r,$g,$b)';

  @override
  String toRGBA() => toRGB();

  @override
  int get argbInt =>
      ((255 & 0xff) << 24) |
      ((r & 0xff) << 16) |
      ((g & 0xff) << 8) |
      (b & 0xff);

  @override
  int get abgrInt =>
      ((255 & 0xff) << 24) |
      ((b & 0xff) << 16) |
      ((g & 0xff) << 8) |
      (r & 0xff);

  @override
  int get rgbaInt =>
      ((r & 0xff) << 24) | ((g & 0xff) << 16) | ((b & 0xff) << 8) | (255);

  @override
  ({int r, int g, int b}) get rgb => (r: r, g: g, b: b);

  @override
  ({int r, int g, int b, double a}) get rgba => (r: r, g: g, b: b, a: 1.0);

  @override
  ({double h, double s, double v}) get hsv => rgbToHSV(r, g, b);

  @override
  ({double h, double s, double v, double a}) get hsva {
    final hsv = this.hsv;
    return (h: hsv.h, s: hsv.s, v: hsv.v, a: 1.0);
  }

  @override
  PStyle toStyle({int? size}) => PStyle(color: this, size: size);

  @override
  String toString() => toRGB();

  @override
  String get className => 'PColorRGB';

  @override
  Map<String, dynamic> toJson() => {
        'className': 'className',
        'r': r,
        'g': g,
        'b': b,
      };

  factory PColorRGB.fromJson(Map<String, dynamic> j) =>
      PColorRGB(parseInt(j['r']), parseInt(j['g']), parseInt(j['b']));
}

class PColorRGBA extends PColorRGB {
  /// The alpha value.
  @override
  final double alpha;

  PColorRGBA(super.r, super.g, super.b, double a)
      : alpha = ((a.clamp(0, 1) * 10000).toInt() / 10000);

  PColorRGBA.fromARGB(int p)
      : this(
          (p >> 16) & 0xff,
          (p >> 8) & 0xff,
          (p) & 0xff,
          ((p >> 24) & 0xff) / 255,
        );

  PColorRGBA.fromABGR(int p)
      : this(
          (p) & 0xff,
          (p >> 8) & 0xff,
          (p >> 16) & 0xff,
          ((p >> 24) & 0xff) / 255,
        );

  PColorRGBA.fromRGBA(int p)
      : this(
          (p >> 24) & 0xff,
          (p >> 16) & 0xff,
          (p >> 8) & 0xff,
          ((p) & 0xff) / 255,
        );

  @override
  bool get hasAlpha => alpha != 1.0;

  int? _a;

  @override
  int get a => _a ??= (alpha * 255).toInt();

  @override
  PColorRGB toPColorRGB() => PColorRGB(r, g, b);

  @override
  PColorRGBA toPColorRGBA() => this;

  @override
  PColorRGB copyWith({int? r, int? g, int? b, double? alpha}) {
    if (alpha == 1.0) {
      return PColorRGB(r ?? this.r, g ?? this.g, b ?? this.b);
    } else {
      return PColorRGBA(
          r ?? this.r, g ?? this.g, b ?? this.b, alpha ?? this.alpha);
    }
  }

  String? _rgba;

  @override
  String toRGBA() => _rgba ??= 'rgba($r,$g,$b,$alpha)';

  @override
  int get argbInt =>
      ((a & 0xff) << 24) | ((r & 0xff) << 16) | ((g & 0xff) << 8) | (b & 0xff);

  @override
  int get abgrInt =>
      ((a & 0xff) << 24) | ((b & 0xff) << 16) | ((g & 0xff) << 8) | (r & 0xff);

  @override
  int get rgbaInt =>
      ((r & 0xff) << 24) | ((g & 0xff) << 16) | ((b & 0xff) << 8) | (a & 0xff);

  @override
  ({int r, int g, int b, double a}) get rgba => (r: r, g: g, b: b, a: alpha);

  @override
  ({double h, double s, double v, double a}) get hsva {
    final hsv = this.hsv;
    return (h: hsv.h, s: hsv.s, v: hsv.v, a: alpha);
  }

  @override
  bool get isFullyTransparent => alpha == 0.0;

  @override
  String toString() => hasAlpha ? toRGBA() : toRGB();

  @override
  String get className => 'PColorRGBA';

  @override
  Map<String, dynamic> toJson() => {
        'className': className,
        'r': r,
        'g': g,
        'b': b,
        if (hasAlpha) 'a': alpha,
      };

  factory PColorRGBA.fromJson(Map<String, dynamic> j) => PColorRGBA(
      parseInt(j['r']),
      parseInt(j['g']),
      parseInt(j['b']),
      tryParseDouble(j['a']) ?? 1.0);
}

@override
({double h, double s, double v}) rgbToHSV(int r, int g, int b) {
  final red = r / 255;
  final green = g / 255;
  final blue = b / 255;

  final max = max3(red, green, blue);
  final min = min3(red, green, blue);
  final delta = max - min;

  final value = max;
  final saturation = max == 0 ? 0.0 : (delta / max);

  var hue = 0.0;
  {
    if (delta != 0) {
      if (max == red) {
        hue = ((green - blue) / delta) % 6;
      } else if (max == green) {
        hue = ((blue - red) / delta) + 2;
      } else {
        hue = ((red - green) / delta) + 4;
      }
    }

    hue *= 60;

    if (hue < 0) {
      hue += 360;
    }
  }

  return (h: hue, s: saturation, v: value);
}

({int r, int g, int b}) hsvToRGB(double h, double s, double v) {
  final chroma = v * s;
  final huePrime = h / 60.0;
  final x = chroma * (1 - (huePrime % 2 - 1).abs());
  final m = v - chroma;

  double r, g, b;

  if (huePrime >= 0 && huePrime < 1) {
    r = chroma;
    g = x;
    b = 0;
  } else if (huePrime >= 1 && huePrime < 2) {
    r = x;
    g = chroma;
    b = 0;
  } else if (huePrime >= 2 && huePrime < 3) {
    r = 0;
    g = chroma;
    b = x;
  } else if (huePrime >= 3 && huePrime < 4) {
    r = 0;
    g = x;
    b = chroma;
  } else if (huePrime >= 4 && huePrime < 5) {
    r = x;
    g = 0;
    b = chroma;
  } else {
    r = chroma;
    g = 0;
    b = x;
  }

  final red = ((r + m) * 255).round();
  final green = ((g + m) * 255).round();
  final blue = ((b + m) * 255).round();

  return (r: red, g: green, b: blue);
}
