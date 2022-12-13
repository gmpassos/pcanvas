import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;

import 'pcanvas_base.dart';

/// An in-memory [PCanvas] implementation.
class PCanvasBitmap extends PCanvas {
  @override
  final PCanvasPainter painter;

  @override
  final int width;

  @override
  final int height;

  late final img.Image _bitmap;

  PCanvasBitmap(this.width, this.height, this.painter) : super.impl() {
    _bitmap = img.Image(width, height);
    painter.callLoadResources(this);
  }

  @override
  FutureOr<bool> waitLoading() => painter.waitLoading();

  @override
  num get elementWidth => width;

  @override
  num get elementHeight => height;

  @override
  double get devicePixelRatio => 1;

  @override
  num get pixelRatio => 1;

  @override
  set pixelRatio(num pr) {}

  @override
  void checkDimension() {}

  @override
  void log(Object? o) {
    print(o);
  }

  Future<bool>? _requestedPaint;

  @override
  Future<bool> requestRepaint() {
    var requestedPaint = _requestedPaint;
    if (requestedPaint != null) return requestedPaint;

    return _requestedPaint = refresh();
  }

  @override
  void onPosPaint() {
    _requestedPaint = null;
  }

  @override
  Object get canvasNative => _bitmap;

  int _imageIdCount = 0;

  @override
  PCanvasImage createCanvasImage(Object source, {int? width, int? height}) {
    var id = ++_imageIdCount;

    if (source is Uint8List) {
      var image = img.decodeImage(source);
      return _PCanvasImageMemorySync('img_$id', image!, '[bytes]');
    } else if (source is String) {
      if (source.startsWith('http://') || source.startsWith('https://')) {
        var uri = Uri.parse(source);

        var imageFuture = Dio()
            .getUri(uri, options: Options(responseType: ResponseType.bytes))
            .then((response) {
          var bytes = response.data as List<int>;
          return img.decodeImage(bytes)!;
        });

        return _PCanvasImageMemoryAsync('img_$id', imageFuture, '$uri');
      }
    }

    throw ArgumentError("Can't handle image source: $source");
  }

  @override
  void clearRect(num x, num y, num width, num height, {PStyle? style}) {
    var color = style?.color ?? PColor.colorWhite;
    fillRect(x, y, width, height, PStyle(color: color));
  }

  @override
  void drawImage(PCanvasImage image, num x, num y) {
    checkImageLoaded(image);

    if (image is PCanvasImageMemory) {
      var srcImg = image.image;
      img.drawImage(
        _bitmap,
        srcImg,
        srcX: 0,
        srcY: 0,
        srcW: srcImg.width,
        srcH: srcImg.height,
        dstX: x.toInt(),
        dstY: y.toInt(),
        dstW: srcImg.width,
        dstH: srcImg.height,
      );
    } else {
      throw ArgumentError("Can't handle image type: $image");
    }
  }

  @override
  void drawImageScaled(
      PCanvasImage image, num x, num y, num width, num height) {
    checkImageLoaded(image);

    if (image is PCanvasImageMemory) {
      var srcImg = image.image;
      img.drawImage(
        _bitmap,
        srcImg,
        srcX: 0,
        srcY: 0,
        srcW: srcImg.width,
        srcH: srcImg.height,
        dstX: x.toInt(),
        dstY: y.toInt(),
        dstW: width.toInt(),
        dstH: height.toInt(),
      );
    } else {
      throw ArgumentError("Can't handle image type: $image");
    }
  }

  @override
  void drawImageArea(PCanvasImage image, int srcX, int srcY, int srcWidth,
      int srcHeight, num dstX, num dstY, num dstWidth, num dstHeight) {
    checkImageLoaded(image);

    if (image is PCanvasImageMemory) {
      var srcImg = image.image;
      img.drawImage(
        _bitmap,
        srcImg,
        srcX: srcX.toInt(),
        srcY: srcY.toInt(),
        srcW: srcWidth.toInt(),
        srcH: srcHeight.toInt(),
        dstX: dstX.toInt(),
        dstY: dstY.toInt(),
        dstW: dstWidth.toInt(),
        dstH: dstHeight.toInt(),
      );
    } else {
      throw ArgumentError("Can't handle image type: $image");
    }
  }

  @override
  void strokeRect(num x, num y, num width, num height, PStyle style) {
    var color = style.color ?? PColor.colorGrey;
    var size = style.size ?? 1;

    _strokeRect(_bitmap, x.toInt(), y.toInt(), (x + width).toInt(),
        (y + height).toInt(), color.rgba32,
        thickness: size);
  }

  @override
  void fillRect(num x, num y, num width, num height, PStyle style) {
    var color = style.color ?? PColor.colorGrey;

    img.fillRect(_bitmap, x.toInt(), y.toInt(), (x + width).toInt(),
        (y + height).toInt(), color.rgba32);
  }

  @override
  void strokeCircle(num x, num y, num radius, PStyle style,
      {num startAngle = 0, num endAngle = 360}) {
    x = canvasX(x);
    y = canvasY(y);
    radius = canvasX(radius);
    var color = style.color ?? PColor.colorGrey;

    if ((startAngle == 0 && endAngle == 360) ||
        (startAngle == 360 && endAngle == 0)) {
      img.drawCircle(
          _bitmap, x.toInt(), y.toInt(), radius.toInt(), color.rgba32);
    } else {
      throw UnsupportedError(
          "Only `startAngle = 0` and `endAngle = 360` are suported.");
    }
  }

  @override
  void fillCircle(num x, num y, num radius, PStyle style,
      {num startAngle = 0, num endAngle = 360}) {
    x = canvasX(x);
    y = canvasY(y);
    radius = canvasX(radius);
    var color = style.color ?? PColor.colorGrey;

    if ((startAngle == 0 && endAngle == 360) ||
        (startAngle == 360 && endAngle == 0)) {
      img.fillCircle(
          _bitmap, x.toInt(), y.toInt(), radius.toInt(), color.rgba32);
    } else {
      throw UnsupportedError(
          "Only `startAngle = 0` and `endAngle = 360` are suported.");
    }
  }

  @override
  void fillTopDownGradient(
      num x, num y, num width, num height, PColor colorFrom, PColor colorTo) {
    var cFrom = colorFrom.toPColorRGBA();
    var cTo = colorTo.toPColorRGBA();

    var r1 = cFrom.r;
    var g1 = cFrom.g;
    var b1 = cFrom.b;
    var a1 = cFrom.alpha;

    var r2 = cTo.r;
    var g2 = cTo.g;
    var b2 = cTo.b;
    var a2 = cTo.alpha;

    var rd = r2 - r1;
    var gd = g2 - g1;
    var bd = b2 - b1;
    var ad = a2 - a1;

    var w = width;
    var h = height;

    var steps = 256;

    var s = h ~/ steps;
    while (s == 0 && steps > 1) {
      --steps;
      s = h ~/ steps;
    }

    var end = (h ~/ s) - 1;

    if (a1 == 1 && a1 == a2) {
      for (var y = 0; y < h; y += s) {
        var ratio = y / end;

        var r = (r1 + rd * ratio).toInt();
        var g = (g1 + gd * ratio).toInt();
        var b = (b1 + bd * ratio).toInt();

        var c = PColorRGB(r, g, b);
        fillRect(0, y, w, s, PStyle(color: c));
      }
    } else {
      for (var y = 0; y < h; y += s) {
        var ratio = y / end;

        var r = (r1 + rd * ratio).toInt();
        var g = (g1 + gd * ratio).toInt();
        var b = (b1 + bd * ratio).toInt();
        var a = (a1 + ad * ratio);

        var c = PColorRGBA(r, g, b, a);
        fillRect(x, y, w, s, PStyle(color: c));
      }
    }
  }

  @override
  void fillLeftRightGradient(
      num x, num y, num width, num height, PColor colorFrom, PColor colorTo) {
    var cFrom = colorFrom.toPColorRGBA();
    var cTo = colorTo.toPColorRGBA();

    var r1 = cFrom.r;
    var g1 = cFrom.g;
    var b1 = cFrom.b;
    var a1 = cFrom.alpha;

    var r2 = cTo.r;
    var g2 = cTo.g;
    var b2 = cTo.b;
    var a2 = cTo.alpha;

    var rd = r2 - r1;
    var gd = g2 - g1;
    var bd = b2 - b1;
    var ad = a2 - a1;

    var w = width;
    var h = height;

    var steps = 256;

    var s = w ~/ steps;
    while (s == 0 && steps > 1) {
      --steps;
      s = w ~/ steps;
    }

    var end = (w ~/ s) - 1;

    if (a1 == 1 && a1 == a2) {
      for (var x = 0; x < w; x += s) {
        var ratio = x / end;

        var r = (r1 + rd * ratio).toInt();
        var g = (g1 + gd * ratio).toInt();
        var b = (b1 + bd * ratio).toInt();

        var c = PColorRGB(r, g, b);
        fillRect(x, y, s, h, PStyle(color: c));
      }
    } else {
      for (var x = 0; x < w; x += s) {
        var ratio = x / end;

        var r = (r1 + rd * ratio).toInt();
        var g = (g1 + gd * ratio).toInt();
        var b = (b1 + bd * ratio).toInt();
        var a = (a1 + ad * ratio);

        var c = PColorRGBA(r, g, b, a);
        fillRect(x, y, s, h, PStyle(color: c));
      }
    }
  }

  @override
  PTextMetric measureText(String text, PFont font) {
    var bitmapFont = font.toBitmapFont();

    var w = 0;

    var lng = text.length;
    for (var i = 0; i < lng; ++i) {
      var c = text[i];
      var x = _characterXAdvance(bitmapFont, c);
      w += x;
    }

    var h = img.findStringHeight(bitmapFont, text);

    return PTextMetric(w, h);
  }

  int _characterXAdvance(img.BitmapFont bitmapFont, String ch) {
    if (ch.isEmpty) return 0;

    final c = ch.codeUnits[0];
    var bitmapCharacter = bitmapFont.characters[c];

    if (bitmapCharacter == null) {
      return bitmapFont.base ~/ 2;
    } else {
      return bitmapCharacter.xadvance;
    }
  }

  @override
  void drawText(String text, num x, num y, PFont font, PStyle style) {
    var color = style.color ?? PColor.colorGrey;
    var bitmapFont = font.toBitmapFont();
    img.drawString(_bitmap, bitmapFont, x.toInt(), y.toInt(), text,
        color: color.rgba32);
  }

  @override
  void fillPath(List path, PStyle style, {bool closePath = false}) {
    throw UnimplementedError();
  }

  @override
  void strokePath(List path, PStyle style, {bool closePath = false}) {
    var points = _toPoints(path, closePath);
    if (points.length < 2) return;

    var color = style.color ?? PColor.colorBlack;
    var c = color.rgba32;

    for (var i = 1; i < points.length; ++i) {
      var p1 = points[i - 1];
      var p2 = points[i];

      var x1 = p1.x.toInt();
      var y1 = p1.y.toInt();

      var x2 = p2.x.toInt();
      var y2 = p2.y.toInt();

      img.drawLine(_bitmap, x1, y1, x2, y2, c);
    }
  }

  List<Point> _toPoints(List<dynamic> path, bool closePath) {
    var points = <Point>[];

    for (var i = 0; i < path.length; ++i) {
      var e = path[i];

      if (e is num) {
        var x = e;
        var y = path[++i];
        points.add(Point(x, y));
      } else if (e is Point) {
        points.add(e);
      }
    }

    if (closePath && points.length > 2) {
      var p1 = points.first;
      var p2 = points.last;

      if (p1 != p2) {
        points.add(p1);
      }
    }

    return points;
  }

  @override
  PCanvasPixels get pixels {
    return PCanvasPixelsABGR(width, height, Uint32List.fromList(_bitmap.data));
  }

  @override
  FutureOr<Uint8List> toPNG() {
    var bytes = img.encodePng(_bitmap);
    return bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  }

  @override
  String toString() {
    return 'PCanvasBitmap[${width}x$height]$info';
  }
}

extension _PColorExtension on PColor {
  int get rgba32 {
    var c = this;

    if (c is PColorRGBA && c.hasAlpha) {
      return img.getColor(c.r, c.g, c.b, c.a);
    } else if (c is PColorRGB) {
      return img.getColor(c.r, c.g, c.b);
    } else {
      throw StateError("Can't handle color type `${c.runtimeType}`: $c");
    }
  }
}

void _strokeRect(img.Image dst, int x1, int y1, int x2, int y2, int color,
    {bool antialias = true, num thickness = 1}) {
  final x0 = math.min(x1, x2);
  final y0 = math.min(y1, y2);
  x1 = math.max(x1, x2);
  y1 = math.max(y1, y2);

  img.drawLine(dst, x0, y0, x1, y0, color,
      antialias: antialias, thickness: thickness);
  img.drawLine(dst, x1, y0, x1, y1, color,
      antialias: antialias, thickness: thickness);
  img.drawLine(dst, x0, y1, x1, y1, color,
      antialias: antialias, thickness: thickness);
  img.drawLine(dst, x0, y0, x0, y1, color,
      antialias: antialias, thickness: thickness);
}

abstract class PCanvasImageMemory extends PCanvasImage {
  img.Image get image;
}

class _PCanvasImageMemorySync extends PCanvasImageMemory {
  @override
  final String id;

  @override
  final img.Image image;

  @override
  final String src;

  _PCanvasImageMemorySync(this.id, this.image, this.src);

  @override
  String get type => 'bitmap:sync';

  @override
  int get width => image.width;

  @override
  int get height => image.height;

  @override
  bool get isLoaded => true;

  @override
  FutureOr<bool> load() => true;
}

class _PCanvasImageMemoryAsync extends PCanvasImageMemory {
  @override
  final String id;

  Future<img.Image>? _imageFuture;

  img.Image? _image;

  @override
  final String src;

  _PCanvasImageMemoryAsync(this.id, this._imageFuture, this.src) {
    _imageFuture!.then((img) {
      _image = img;
      _imageFuture = null;
    });
  }

  @override
  String get type => 'bitmap:async';

  @override
  img.Image get image => _image!;

  @override
  int get width => _image?.width ?? 0;

  @override
  int get height => _image?.height ?? 0;

  @override
  bool get isLoaded => _image != null;

  Future<bool>? _loading;

  @override
  FutureOr<bool> load() {
    if (_image != null) return true;

    var imageFuture = _imageFuture;
    if (imageFuture == null) return true;

    return _loading ??= imageFuture.then((_) {
      _loading = null;
      return true;
    });
  }
}

extension _PFontExtension on PFont {
  img.BitmapFont toBitmapFontFamily() {
    if (size >= 36) {
      return img.arial_48;
    } else if (size >= 19) {
      return img.arial_24;
    } else {
      return img.arial_14;
    }
  }

  img.BitmapFont toBitmapFont() {
    var f = toBitmapFontFamily();
    if (bold) f.bold = true;
    if (italic) f.italic = true;
    f.antialias = true;
    return f;
  }
}
