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

  PCanvasBitmap(this.width, this.height, this.painter,
      {PCanvasPixels? initialPixels})
      : super.impl() {
    _bitmap = img.Image(
        width: width,
        height: height,
        format: img.Format.uint8,
        numChannels: 4,
        withPalette: false);

    if (initialPixels != null) {
      setPixels(initialPixels);
    }

    painter.callLoadResources(this);
  }

  @override
  void setPixels(PCanvasPixels pixels,
      {int x = 0, int y = 0, int? width, int? height}) {
    var w = width ?? this.width;
    if (x + w > this.width) w = this.width - x;

    var h = height ?? this.height;
    if (y + h > this.height) h = this.height - y;

    if (w <= 0 || h <= 0) return;

    for (var y1 = 0; y1 < h; ++y1) {
      for (var x1 = 0; x1 < w; ++x1) {
        var p = pixels.getImageColor(x, y);
        _bitmap.setPixel(x + x1, y + y1, p);
      }
    }
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
  PCanvasStateExtra? get stateExtra => null;

  PRectangle? _clip;

  @override
  PRectangle? get clip => _clip;

  @override
  set clip(PRectangle? clip) {
    _clip = clip;
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
          var data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
          return img.decodeImage(data)!;
        });

        return _PCanvasImageMemoryAsync('img_$id', imageFuture, '$uri');
      }
    }

    throw ArgumentError("Can't handle image source: $source");
  }

  @override
  void clearRect(num x, num y, num width, num height, {PStyle? style}) {
    x = transform.x(x);
    y = transform.y(y);

    var clip = _clip;

    if (clip != null) {
      var r = clip.intersection(PRectangle(x, y, width, height));

      if (r.isZeroDimension) {
        return;
      }

      x = r.x;
      y = r.y;
      width = r.width;
      height = r.height;
    }

    var color = style?.color ?? PColor.colorWhite;
    fillRect(x, y, width, height, PStyle(color: color));
  }

  @override
  void drawImage(PCanvasImage image, num x, num y) {
    checkImageLoaded(image);

    x = transform.x(x);
    y = transform.y(y);

    var clip = _clip;
    if (clip != null) {
      var imgW = image.width;
      var imgH = image.height;

      var box = PRectangle(x, y, imgW, imgH);
      var r = clip.intersection(box);
      if (r.isZeroDimension) return;

      if (r.width != imgW || r.height != imgH) {
        drawImageArea(image, 0, 0, imgW, imgH, x, y, imgW, imgH);
        return;
      }
    }

    if (image is PCanvasImageMemory) {
      var srcImg = image.image;

      img.compositeImage(
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

    x = transform.x(x);
    y = transform.y(y);

    var clip = _clip;
    if (clip != null) {
      var box = PRectangle(x, y, width, height);
      var r = clip.intersection(box);
      if (r.isZeroDimension) return;

      if (r.width != width || r.height != height) {
        drawImageArea(
            image, 0, 0, image.width, image.height, x, y, width, height);
        return;
      }
    }

    if (image is PCanvasImageMemory) {
      var srcImg = image.image;
      img.compositeImage(
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

    dstX = transform.x(dstX);
    dstY = transform.y(dstY);

    var clip = _clip;
    if (clip != null) {
      var box = PRectangle(dstX, dstY, dstWidth, dstHeight);
      var r = clip.intersection(box);
      if (r.isZeroDimension) return;

      if (r.width != dstWidth || r.height != dstHeight) {
        var imgW = image.width;
        var imgH = image.height;

        var rW = (imgW / dstWidth);
        var rH = (imgH / dstHeight);

        srcX = ((r.x - dstX) * rW).toInt();
        srcY = ((r.y - dstY) * rH).toInt();
        srcWidth = (r.width * rW).toInt();
        srcHeight = (r.height * rH).toInt();

        dstX = r.x.toInt();
        dstY = r.y.toInt();
        dstWidth = r.width.toInt();
        dstHeight = r.height.toInt();
      }
    }

    if (image is PCanvasImageMemory) {
      var srcImg = image.image;
      img.compositeImage(
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
    x = transform.x(x);
    y = transform.y(y);

    var clip = _clip;
    if (clip != null) {
      var box = PRectangle(x, y, width, height);
      var r = clip.intersection(box);
      if (r.isZeroDimension) return;

      x = r.x;
      y = r.y;
      width = r.width;
      height = r.height;
    }

    if (width <= 0 || height <= 0) return;

    var color = style.color ?? PColor.colorGrey;
    var size = style.size ?? 1;

    var x1 = x.toInt();
    var y1 = y.toInt();

    var x2 = x1 + width.toInt();
    var y2 = y1 + height.toInt();

    _strokeRect(_bitmap, x1, y1, x2, y2, color.imageColor, thickness: size);
  }

  @override
  void fillRect(num x, num y, num width, num height, PStyle style) {
    x = transform.x(x);
    y = transform.y(y);

    var clip = _clip;
    if (clip != null) {
      var box = PRectangle(x, y, width, height);
      var r = clip.intersection(box);
      if (r.isZeroDimension) return;

      x = r.x;
      y = r.y;
      width = r.width;
      height = r.height;
    }

    if (width <= 0 || height <= 0) return;

    var x2 = (x + width).toInt() - 1;
    var y2 = (y + height).toInt() - 1;

    var color = style.color ?? PColor.colorGrey;

    img.fillRect(_bitmap,
        x1: x.toInt(), y1: y.toInt(), x2: x2, y2: y2, color: color.imageColor);
  }

  @override
  void strokeCircle(num x, num y, num radius, PStyle style,
      {num startAngle = 0, num endAngle = 360}) {
    x = transform.x(x);
    y = transform.y(y);

    var clip = _clip;
    if (clip != null) {
      var w = radius * 2;

      var box = PRectangle(x, y, w, w);
      var r = clip.intersection(box);
      if (r.isZeroDimension) return;

      _callClipped(clip, box,
          () => _strokeCircleImpl(x, y, radius, style, startAngle, endAngle));
    } else {
      _strokeCircleImpl(x, y, radius, style, startAngle, endAngle);
    }
  }

  void _strokeCircleImpl(
      num x, num y, num radius, PStyle style, num startAngle, num endAngle) {
    x = canvasX(x);
    y = canvasY(y);
    radius = canvasX(radius);
    var color = style.color ?? PColor.colorGrey;

    if ((startAngle == 0 && endAngle == 360) ||
        (startAngle == 360 && endAngle == 0)) {
      img.drawCircle(_bitmap,
          x: x.toInt(),
          y: y.toInt(),
          radius: radius.toInt(),
          color: color.imageColor);
    } else {
      throw UnsupportedError(
          "Only `startAngle = 0` and `endAngle = 360` are suported.");
    }
  }

  @override
  void fillCircle(num x, num y, num radius, PStyle style,
      {num startAngle = 0, num endAngle = 360}) {
    x = transform.x(x);
    y = transform.y(y);

    var clip = _clip;
    if (clip != null) {
      var w = radius * 2;

      var box = PRectangle(x, y, w, w);
      var r = clip.intersection(box);
      if (r.isZeroDimension) return;

      _callClipped(clip, box,
          () => _fillCircleImpl(x, y, radius, style, startAngle, endAngle));
    } else {
      _fillCircleImpl(x, y, radius, style, startAngle, endAngle);
    }
  }

  void _fillCircleImpl(
      num x, num y, num radius, PStyle style, num startAngle, num endAngle) {
    x = canvasX(x);
    y = canvasY(y);
    radius = canvasX(radius);
    var color = style.color ?? PColor.colorGrey;

    if ((startAngle == 0 && endAngle == 360) ||
        (startAngle == 360 && endAngle == 0)) {
      img.fillCircle(_bitmap,
          x: x.toInt(),
          y: y.toInt(),
          radius: radius.toInt(),
          color: color.imageColor);
    } else {
      throw UnsupportedError(
          "Only `startAngle = 0` and `endAngle = 360` are suported.");
    }
  }

  @override
  void fillTopDownGradient(
      num x, num y, num width, num height, PColor colorFrom, PColor colorTo) {
    x = transform.x(x);
    y = transform.y(y);

    var clip = _clip;
    if (clip != null) {
      var box = PRectangle(x, y, width, height);
      var r = clip.intersection(box);
      if (r.isZeroDimension) return;

      x = r.x;
      y = r.y;
      width = r.width;
      height = r.height;
    }

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
    x = transform.x(x);
    y = transform.y(y);

    var clip = _clip;
    if (clip != null) {
      var box = PRectangle(x, y, width, height);
      var r = clip.intersection(box);
      if (r.isZeroDimension) return;

      x = r.x;
      y = r.y;
      width = r.width;
      height = r.height;
    }

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

    var h = _findStringHeight(bitmapFont, text);

    return PTextMetric(w, h);
  }

  int _characterXAdvance(img.BitmapFont bitmapFont, String ch) {
    if (ch.isEmpty) return 0;

    final c = ch.codeUnits[0];
    var bitmapCharacter = bitmapFont.characters[c];

    if (bitmapCharacter == null) {
      return bitmapFont.base ~/ 2;
    } else {
      return bitmapCharacter.xAdvance;
    }
  }

  @override
  void drawText(String text, num x, num y, PFont font, PStyle style) {
    x = transform.x(x);
    y = transform.y(y);

    var clip = _clip;
    if (clip != null) {
      var m = measureText(text, font);

      var box = PRectangle(x, y, m.actualWidth, m.actualHeight);
      var r = clip.intersection(box);
      if (r.isZeroDimension) return;

      _callClipped(clip, box, () => _drawTextImpl(style, font, x, y, text));
    } else {
      _drawTextImpl(style, font, x, y, text);
    }
  }

  void _drawTextImpl(PStyle style, PFont font, num x, num y, String text) {
    var color = style.color ?? PColor.colorGrey;
    var bitmapFont = font.toBitmapFont();
    img.drawString(_bitmap, text,
        font: bitmapFont, x: x.toInt(), y: y.toInt(), color: color.imageColor);
  }

  @override
  void fillPath(List path, PStyle style, {bool closePath = false}) {
    var points = _toPoints(path, closePath);
    if (points.length < 2) return;

    throw UnimplementedError();
  }

  @override
  void strokePath(List path, PStyle style, {bool closePath = false}) {
    var points = _toPoints(path, closePath);
    if (points.length < 2) return;

    var clip = _clip;
    if (clip != null) {
      var box = points.boundingBox;

      if (box == null || !clip.containsRectangle(box)) return;

      _callClipped(clip, box, () => _strokePathImpl(points, style));
    } else {
      _strokePathImpl(points, style);
    }
  }

  void _strokePathImpl(List<Point> points, PStyle style) {
    var color = style.color ?? PColor.colorBlack;
    var c = color.imageColor;

    for (var i = 1; i < points.length; ++i) {
      var p1 = points[i - 1];
      var p2 = points[i];

      var x1 = p1.x.toInt();
      var y1 = p1.y.toInt();

      var x2 = p2.x.toInt();
      var y2 = p2.y.toInt();

      img.drawLine(_bitmap, x1: x1, y1: y1, x2: x2, y2: y2, color: c);
    }
  }

  /// Performs a paint in the [paintRect] applying a [clip] rectangle.
  /// - The paint operations performed by the [call] [Function] must not exceed the clip rectangle.
  R? _callClipped<R>(PRectangle clip, PRectangle paintRect, R Function() call) {
    var imgRect = PRectangle(0, 0, width, height);

    clip = imgRect.intersection(clip);
    if (clip.isZeroDimension) return null;

    paintRect = imgRect.intersection(paintRect);
    if (paintRect.isZeroDimension) return null;

    var paintRectClipped = clip.intersection(paintRect);
    if (paintRectClipped.isZeroDimension) return null;

    var pixels =
        PCanvasPixelsRGBA.fromBytes(width, height, _bitmap.dataAsUint8List);

    var cp1 = pixels.copyRectangle(paintRect)!;

    var ret = call();

    var cp2 = pixels.copyRectangle(paintRectClipped)!;

    pixels.putPixels(cp1, paintRect.x, paintRect.y);
    pixels.putPixels(cp2, paintRectClipped.x, paintRectClipped.y);

    return ret;
  }

  List<Point> _toPoints(List<dynamic> path, bool closePath) {
    var points = <Point>[];

    for (var i = 0; i < path.length; ++i) {
      var e = path[i];

      if (e is num) {
        var x = e;
        var y = path[++i];
        x = transform.x(x);
        y = transform.y(y);
        points.add(Point(x, y));
      } else if (e is Point) {
        e = transform.point(e);
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
  PCanvasPixels get pixels =>
      PCanvasPixelsABGR.fromBytes(width, height, _bitmap.dataAsUint8List);

  @override
  FutureOr<Uint8List> toPNG() => img.encodePng(_bitmap);

  @override
  String toString() {
    return 'PCanvasBitmap[${width}x$height]$info';
  }
}

extension _PColorExtension on PColor {
  img.Color get imageColor {
    var c = this;

    if (c is PColorRGBA && c.hasAlpha) {
      return img.ColorUint8.rgba(c.r, c.g, c.b, c.a);
    } else if (c is PColorRGB) {
      return img.ColorUint8.rgb(c.r, c.g, c.b);
    } else {
      throw StateError("Can't handle color type `${c.runtimeType}`: $c");
    }
  }
}

void _strokeRect(img.Image dst, int x1, int y1, int x2, int y2, img.Color color,
    {bool antialias = true, num thickness = 1}) {
  var thicknessHalf = thickness ~/ 2;
  var fix = thickness % 2 == 0 ? 0 : 1;

  final x0 = math.min(x1, x2);
  final y0 = math.min(y1, y2);
  x1 = math.max(x1, x2);
  y1 = math.max(y1, y2);

  img.drawLine(dst,
      x1: x0 - thicknessHalf,
      y1: y0,
      x2: x1 + thicknessHalf - 1,
      y2: y0,
      color: color,
      antialias: antialias,
      thickness: thickness);

  img.drawLine(dst,
      x1: x0 - thicknessHalf,
      y1: y1 - fix,
      x2: x1 + thicknessHalf - 1,
      y2: y1 - fix,
      color: color,
      antialias: antialias,
      thickness: thickness);

  img.drawLine(dst,
      x1: x0,
      y1: y0 + thicknessHalf,
      x2: x0,
      y2: y1 - thicknessHalf - fix,
      color: color,
      antialias: antialias,
      thickness: thickness);

  img.drawLine(dst,
      x1: x1 - fix,
      y1: y0 + thicknessHalf,
      x2: x1 - fix,
      y2: y1 - thicknessHalf - fix,
      color: color,
      antialias: antialias,
      thickness: thickness);
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
      return img.arial48;
    } else if (size >= 19) {
      return img.arial24;
    } else {
      return img.arial14;
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

extension _PCanvasPixelsExtension on PCanvasPixels {
  img.Color getImageColor(int x, int y) {
    var pixels = this;

    var p = pixels.pixel(x, y);

    int r, g, b, a;

    if (pixels is PCanvasPixelsRGBA) {
      r = (p >> 24) & 0xff;
      g = (p >> 16) & 0xff;
      b = (p >> 8) & 0xff;
      a = ((p) & 0xff);
    } else if (pixels is PCanvasPixelsARGB) {
      r = (p >> 16) & 0xff;
      g = (p >> 8) & 0xff;
      b = (p) & 0xff;
      a = ((p >> 24) & 0xff);
    } else if (pixels is PCanvasPixelsABGR) {
      r = (p) & 0xff;
      g = (p >> 8) & 0xff;
      b = (p >> 16) & 0xff;
      a = ((p >> 24) & 0xff);
    } else {
      throw StateError("Can't pixels type: ${pixels.runtimeType} > $pixels");
    }

    return img.ColorUint32.rgba(r, g, b, a);
  }
}

extension _ImageExtension on img.Image {
  Uint8List get dataAsUint8List {
    var imageData = data as img.ImageDataUint8;
    var dataUint8 = imageData.data;
    return dataUint8;
  }
}

// From package `image 3.3.0`.
int _findStringHeight(img.BitmapFont font, String string) {
  var stringHeight = 0;
  final chars = string.codeUnits;

  for (var c in chars) {
    if (!font.characters.containsKey(c)) {
      continue;
    }
    final ch = font.characters[c]!;

    if (ch.height + ch.yOffset > stringHeight) {
      stringHeight = ch.height + ch.yOffset;
    }
  }

  return (stringHeight * 1.05).round();
}
