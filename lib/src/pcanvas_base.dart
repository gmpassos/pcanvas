import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'pcanvas_impl_bitmap.dart'
    if (dart.library.html) 'pcanvas_impl_html.dart';

/// A [PCanvas] event.
/// See [PCanvas.onClick].
class PCanvasEvent {
  /// The event type.
  final String type;

  /// The event X coordinate.
  final num x;

  /// The event Y coordinate.
  final num y;

  const PCanvasEvent(this.type, this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PCanvasEvent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => type.hashCode ^ x.hashCode ^ y.hashCode;

  @override
  String toString() {
    return 'PCanvasEvent{type: $type, x: $x, y: $y}';
  }
}

/// [PCanvas] painter base class.
abstract class PCanvasPainter {
  PCanvas? _pCanvas;

  /// The [PCanvas] of this painter.
  PCanvas? get pCanvas => _pCanvas;

  void setup(PCanvas pCanvas) {
    _pCanvas = pCanvas;
  }

  FutureOr<bool>? _loadingFuture;

  /// Waits the [loadResources].
  FutureOr<bool> waitLoading() {
    var loadingFuture = _loadingFuture;
    if (loadingFuture != null) {
      return loadingFuture;
    } else {
      return false;
    }
  }

  bool _loadingResources = false;

  /// Returns `true` if this painter is loading resources.
  /// See [loadResources]
  bool get isLoadingResources => _loadingResources;

  /// Calls [loadResources].
  FutureOr<bool> callLoadResources(PCanvas pCanvas) {
    if (_loadingResources) return false;
    _loadingResources = true;

    try {
      var ret = loadResources(pCanvas);

      if (ret is Future<bool>) {
        return _loadingFuture = ret.whenComplete(() {
          _loadingResources = false;
        });
      } else {
        _loadingResources = false;
        _loadingFuture = true;
        return ret;
      }
    } catch (e) {
      _loadingResources = false;
      _loadingFuture = false;
      rethrow;
    }
  }

  /// The load resource implementation.
  FutureOr<bool> loadResources(PCanvas pCanvas) => true;

  /// Refreshes the canvas of this painter.
  void refresh() => _pCanvas?.refresh();

  /// Clears the canvas.
  void clear(PCanvas pCanvas) {
    pCanvas.clear();
  }

  /// The loading text of the default [paintLoading] implementation.
  String loadingText = 'Loading...';

  /// The loading font of the default [paintLoading] implementation.
  PFont loadingFont = PFont('Arial', 20, familyFallback: 'san-serif');

  /// The loading style of the default [paintLoading] implementation.
  PStyle loadingStyle = PStyle(color: PColor.colorBlack);

  /// The paint operations while the canvas is loading.
  /// See [isLoadingResources].
  FutureOr<bool> paintLoading(PCanvas pCanvas) {
    var w = pCanvas.width;
    var h = pCanvas.height;

    var font = loadingFont;
    var style = loadingStyle;
    var text = loadingText;

    var m = pCanvas.measureText(text, font);

    var x = (w ~/ 2) - (m.actualWidth ~/ 2);
    var y = (h ~/ 2) - (m.actualHeight ~/ 2);

    pCanvas.drawText(text, x, y, font, style);

    return true;
  }

  /// The paint operations.
  FutureOr<bool> paint(PCanvas pCanvas);

  /// Canvas `onClickDown` handler.
  void onClickDown(PCanvasEvent event) {}

  /// Canvas `onClickUp` handler.
  void onClickUp(PCanvasEvent event) {}

  /// Canvas `onClick` handler.
  void onClick(PCanvasEvent event) {}
}

/// Portable Canvas.
abstract class PCanvas {
  PCanvasPainter get painter;

  /// The pixels width of this canvas.
  num get width;

  /// The pixels height of this canvas.
  num get height;

  /// The width of the visual element.
  /// See [elementDimension].
  num get elementWidth;

  /// The height of the visual element.
  /// See [elementDimension].
  num get elementHeight;

  PCanvas.impl();

  factory PCanvas(int width, int height, PCanvasPainter painter) {
    return createPCanvasImpl(width, height, painter);
  }

  /// Waits the loading of the canvas and also the [painter.loadResources].
  FutureOr<bool> waitLoading();

  /// The dimension of the visual element of this canvas.
  /// - If [pixelRatio] is > 1 it will habe a different dimension than [dimension].
  PDimension get elementDimension => PDimension(elementWidth, elementHeight);

  /// The dimension of this canvas.
  PDimension get dimension => PDimension(width, height);

  /// The pixels ratio of the device of the [canvasNative].
  num get devicePixelRatio;

  /// The current pixel ration of this canvas.
  /// See [devicePixelRatio].
  num get pixelRatio;

  /// Sets the pixel ration of this canvas and refreshes it.
  set pixelRatio(num pr);

  /// Logs a debugging message.
  void log(Object? o);

  /// Checks if the canvas dimension has changed.
  void checkDimension();

  bool _painting = false;

  /// Calls the [painter], forcing a render operation.
  FutureOr<bool> callPainter() {
    if (_painting) return false;
    _painting = true;

    checkDimension();

    try {
      painter.clear(this);

      FutureOr<bool> ret;
      if (painter.isLoadingResources) {
        ret = painter.paintLoading(this);
      } else {
        ret = painter.paint(this);
      }

      if (ret is Future<bool>) {
        return ret.whenComplete(() {
          _painting = false;
        });
      } else {
        _painting = false;
        return ret;
      }
    } catch (e) {
      _painting = false;
      rethrow;
    }
  }

  /// Refreshes the canvas asynchronously.
  Future<bool> refresh() => Future.microtask(() => callPainter());

  /// The native canvas of this instance implementation.
  dynamic get canvasNative;

  /// Creates a [PCanvasImage] instance compatible to this canvas and its [painter].
  PCanvasImage createCanvasImage(Object source, {int? width, int? height});

  num canvasX(num x) => x;

  num canvasY(num y) => y;

  double canvasXD(num x) => canvasX(x).toDouble();

  double canvasYD(num y) => canvasY(y).toDouble();

  Point canvasPoint(Point p) => Point(p.x, p.y);

  /// Clears the canvas.
  /// - Applies [style] if provided.
  void clear({PStyle? style}) => clearRect(0, 0, width, height, style: style);

  /// Clears a part of the canvas.
  /// - Applies [style] if provided.
  void clearRect(num x, num y, num width, num height, {PStyle? style});

  /// Draw an [image] at ([x],[y]) using the original dimension of the [image].
  void drawImage(PCanvasImage image, num x, num y);

  /// Draw an [image] at ([x],[y]) scaling it to the dimension [width] x [height].
  void drawImageScaled(PCanvasImage image, num x, num y, num width, num height);

  /// Draw an [image] part ([srcX],[srcY] , [srcWidth] x [srcHeight]) to a
  /// destiny area ([dstX],[dstY] , [dstWidth] x [dstHeight]).
  void drawImageArea(PCanvasImage image, int srcX, int srcY, int srcWidth,
      int srcHeight, num dstX, num dstY, num dstWidth, num dstHeight);

  /// Draw an [image] fitting a destiny area ([dstX],[dstY] , [dstWidth] x [dstHeight]).
  void drawImageFitted(
      PCanvasImage image, num dstX, num dstY, num dstWidth, num dstHeight) {
    checkImageLoaded(image);

    if (dstWidth == 0 || dstHeight == 0) return;

    final imgR = image.aspectRatio;
    final r = dstWidth / dstHeight;

    final imageW = image.width;
    final imageH = image.height;

    var srcX = 0;
    var srcY = 0;
    var srcW = imageW;
    var srcH = imageH;

    if (imgR < r) {
      srcW = imageW;
      srcH = (srcW * (1 / r)).toInt();
      srcY = (imageH - srcH) ~/ 2;
    } else if (imgR > r) {
      srcH = imageH;
      srcW = (srcH * r).toInt();
      srcX = (imageW - srcW) ~/ 2;
    }

    drawImageArea(
        image, srcX, srcY, srcW, srcH, dstX, dstY, dstWidth, dstHeight);
  }

  /// Checks if [image] is already loaded.
  /// - If the [image] is not loaded it will throw a [StateError].
  void checkImageLoaded(PCanvasImage image) {
    if (!image.isLoaded) {
      throw StateError("Can't draw NOT loaded image: $image");
    }
  }

  /// Stroke a rectangle ([x],[y] , [width] x [height]).
  void strokeRect(num x, num y, num width, num height, PStyle style);

  /// Fill a rectangle ([x],[y] , [width] x [height]).
  void fillRect(num x, num y, num width, num height, PStyle style);

  /// Measure the [text] dimension.
  PTextMetric measureText(String text, PFont font);

  /// Draw a text at position ([x],[y]).
  void drawText(String text, num x, num y, PFont font, PStyle style);

  /// Stroke a [path] of points.
  void strokePath(List path, PStyle style, {bool closePath = false});

  /// Fill a [path] of points.
  void fillPath(List path, PStyle style, {bool closePath = false});

  /// A helper funtion to center draw operations.
  void centered(
      void Function(PCanvas pCanvas, Point point, PDimension size) paint,
      {num? x,
      num? y,
      Point? point,
      PDimension? area,
      num? width,
      num? height,
      PDimension? dimension,
      PDimension Function()? sizer,
      double? scale}) {
    if (x == null || y == null) {
      if (point == null) {
        if (area == null) {
          throw ArgumentError("Parameters `point` and `area` not provided!");
        }
        point = area.center;
      }

      x ??= point.x;
      y ??= point.y;
    }

    if (width == null || height == null) {
      if (dimension == null) {
        if (sizer == null) {
          throw ArgumentError(
              "Parameters `dimension` and `sizer` not provided!");
        }
        dimension = sizer();
      }

      if (dimension is PTextMetric) {
        width ??= dimension.actualWidth.toInt();
        height ??= dimension.actualHeight.toInt();
      } else {
        width ??= dimension.width.toInt();
        height ??= dimension.height.toInt();
      }
    }

    if (scale != null) {
      width = (width * scale).toInt();
      height = (height * scale).toInt();
    }

    var x2 = x - (width ~/ 2);
    var y2 = y - (height ~/ 2);

    paint(this, Point(x2, y2), PDimension(width, height));
  }

  /// Returns the pixels of this canvas.
  /// See [PCanvasPixels].
  FutureOr<PCanvasPixels> get pixels;

  /// Returns the pixels of this as a PNG data.
  FutureOr<Uint8List> toPNG();

  /// Returns a data URI containing the canvas data in PNG format.
  /// See [toPNG].
  FutureOr<String> toDataUrl() async {
    var pngData = await toPNG();
    var dataBase64 = base64.encode(pngData);

    var url = StringBuffer();
    url.write('data:image/png;base64,');
    url.write(dataBase64);

    return url.toString();
  }
}

/// Pixels of a [PCanvas].
/// See [PCanvas.pixels].
abstract class PCanvasPixels {
  /// Width of the [pixels] image.
  final int width;

  /// Height of the [pixels] image.
  final int height;

  /// Pixels are encoded into 4-byte Uint32 integers.
  /// See [format].
  final Uint32List pixels;

  PCanvasPixels(this.width, this.height, this.pixels);

  /// Length of [pixels].
  int get length => pixels.length;

  /// Length of [pixels] in bytes.
  int get lengthInBytes => pixels.length * 4;

  /// The pixel format.
  String get format;

  /// Formats [color] to this instance [format].
  int formatColor(PColor color);

  /// Index of a pixel ([x],[y]) at [pixels].
  int pixelIndex(int x, int y) => (width * y) + x;

  /// Returns a pixel at ([x],[y]) in the format 4-byte Uint32 integer in #AABBGGRR channel order.
  int pixel(int x, int y) => pixels[pixelIndex(x, y)];

  /// Returns the Red channel of [pixel] at ([x],[y]).
  int pixelR(int x, int y);

  /// Returns the Green channel of [pixel] at ([x],[y]).
  int pixelG(int x, int y);

  /// Returns the Blue channel of [pixel] at ([x],[y]).
  int pixelB(int x, int y);

  /// Returns the Alpha channel of [pixel] at ([x],[y]).
  int pixelA(int x, int y);

  PCanvasPixelsARGB toPCanvasPixelsARGB();

  PCanvasPixelsABGR toPCanvasPixelsABGR();

  PCanvasPixelsRGBA toPCanvasPixelsRGBA();

  @override
  String toString() {
    return 'PCanvasPixels{width: $width, height: $height, format: $format, bytes: $lengthInBytes}';
  }
}

/// [PCanvasPixels] in `ARGB` format.
class PCanvasPixelsARGB extends PCanvasPixels {
  PCanvasPixelsARGB(super.width, super.height, super.pixels) : super();

  @override
  String get format => 'ARGB';

  @override
  int formatColor(PColor color) => color.argb;

  /// Returns the Alpha channel of [pixel] at ([x],[y]).
  @override
  int pixelA(int x, int y) => ((pixel(x, y) >> 24) & 0xff);

  /// Returns the Red channel of [pixel] at ([x],[y]).
  @override
  int pixelR(int x, int y) => ((pixel(x, y) >> 16) & 0xff);

  /// Returns the Green channel of [pixel] at ([x],[y]).
  @override
  int pixelG(int x, int y) => ((pixel(x, y) >> 8) & 0xff);

  /// Returns the Blue channel of [pixel] at ([x],[y]).
  @override
  int pixelB(int x, int y) => (pixel(x, y) & 0xff);

  @override
  PCanvasPixelsARGB toPCanvasPixelsARGB() => this;

  @override
  PCanvasPixelsABGR toPCanvasPixelsABGR() => PCanvasPixelsABGR(
      width,
      height,
      Uint32List.fromList(pixels.map((p) {
        var a = (p >> 24) & 0xff;
        var r = (p >> 16) & 0xff;
        var g = (p >> 8) & 0xff;
        var b = (p) & 0xff;

        return (a << 24) | (b << 16) | (g << 8) | (r);
      }).toList(growable: false)));

  @override
  PCanvasPixelsRGBA toPCanvasPixelsRGBA() => PCanvasPixelsRGBA(
      width,
      height,
      Uint32List.fromList(pixels.map((p) {
        var a = (p >> 24) & 0xff;
        var r = (p >> 16) & 0xff;
        var g = (p >> 8) & 0xff;
        var b = (p) & 0xff;

        return (r << 24) | (g << 16) | (b << 8) | (a);
      }).toList(growable: false)));
}

/// [PCanvasPixels] in `ABGR` format.
class PCanvasPixelsABGR extends PCanvasPixels {
  PCanvasPixelsABGR(super.width, super.height, super.pixels) : super();

  @override
  String get format => 'ABGR';

  @override
  int formatColor(PColor color) => color.abgr;

  /// Returns the Alpha channel of [pixel] at ([x],[y]).
  @override
  int pixelA(int x, int y) => ((pixel(x, y) >> 24) & 0xff);

  /// Returns the Blue channel of [pixel] at ([x],[y]).
  @override
  int pixelB(int x, int y) => ((pixel(x, y) >> 16) & 0xff);

  /// Returns the Green channel of [pixel] at ([x],[y]).
  @override
  int pixelG(int x, int y) => ((pixel(x, y) >> 8) & 0xff);

  /// Returns the Red channel of [pixel] at ([x],[y]).
  @override
  int pixelR(int x, int y) => (pixel(x, y) & 0xff);

  @override
  PCanvasPixelsARGB toPCanvasPixelsARGB() => PCanvasPixelsARGB(
      width,
      height,
      Uint32List.fromList(pixels.map((p) {
        var a = (p >> 24) & 0xff;
        var b = (p >> 16) & 0xff;
        var g = (p >> 8) & 0xff;
        var r = (p) & 0xff;

        return (a << 24) | (r << 16) | (g << 8) | (b);
      }).toList(growable: false)));

  @override
  PCanvasPixelsABGR toPCanvasPixelsABGR() => this;

  @override
  PCanvasPixelsRGBA toPCanvasPixelsRGBA() => PCanvasPixelsRGBA(
      width,
      height,
      Uint32List.fromList(pixels.map((p) {
        var a = (p >> 24) & 0xff;
        var b = (p >> 16) & 0xff;
        var g = (p >> 8) & 0xff;
        var r = (p) & 0xff;

        return (r << 24) | (g << 16) | (b << 8) | (a);
      }).toList(growable: false)));
}

/// [PCanvasPixels] in `RGBA` format.
class PCanvasPixelsRGBA extends PCanvasPixels {
  PCanvasPixelsRGBA(super.width, super.height, super.pixels) : super();

  @override
  String get format => 'RGBA';

  @override
  int formatColor(PColor color) => color.rgba;

  /// Returns the Red channel of [pixel] at ([x],[y]).
  @override
  int pixelR(int x, int y) => ((pixel(x, y) >> 24) & 0xff);

  /// Returns the Green channel of [pixel] at ([x],[y]).
  @override
  int pixelG(int x, int y) => ((pixel(x, y) >> 16) & 0xff);

  /// Returns the Blue channel of [pixel] at ([x],[y]).
  @override
  int pixelB(int x, int y) => ((pixel(x, y) >> 8) & 0xff);

  /// Returns the Alpha channel of [pixel] at ([x],[y]).
  @override
  int pixelA(int x, int y) => (pixel(x, y) & 0xff);

  @override
  PCanvasPixelsARGB toPCanvasPixelsARGB() => PCanvasPixelsARGB(
      width,
      height,
      Uint32List.fromList(pixels.map((p) {
        var r = (p >> 24) & 0xff;
        var g = (p >> 16) & 0xff;
        var b = (p >> 8) & 0xff;
        var a = (p) & 0xff;

        return (a << 24) | (r << 16) | (g << 8) | (b);
      }).toList(growable: false)));

  @override
  PCanvasPixelsABGR toPCanvasPixelsABGR() => PCanvasPixelsABGR(
      width,
      height,
      Uint32List.fromList(pixels.map((p) {
        var r = (p >> 24) & 0xff;
        var g = (p >> 16) & 0xff;
        var b = (p >> 8) & 0xff;
        var a = (p) & 0xff;

        return (a << 24) | (b << 16) | (g << 8) | (r);
      }).toList(growable: false)));

  @override
  PCanvasPixelsRGBA toPCanvasPixelsRGBA() => this;
}

/// Base class for [PCanvas] compatible images.
/// See [PCanvas.createCanvasImage].
abstract class PCanvasImage {
  /// The implementation type.
  String get type;

  /// The ID of the image int the [PCanvas] instance.
  Object get id;

  /// The width of the image. See [isLoaded].
  int get width;

  /// The height of the image. See [isLoaded].
  int get height;

  /// The source of the image.
  String get src;

  /// The dimension of the image ([width] x [height]).
  PDimension get dimension => PDimension(width, height);

  /// Returns `true` if this image is loaded.
  bool get isLoaded;

  /// Loads the image.
  FutureOr<bool> load();

  /// The aspect ratio of the image ([width] / [height]).
  double get aspectRatio {
    var h = height;
    return h == 0 ? 0 : width / h;
  }

  /// Information of the image.
  Map<String, Object?> get info => <String, Object?>{
        'id': id,
        'loaded': isLoaded,
        if (isLoaded) 'width': width,
        if (isLoaded) 'height': height,
        if (isLoaded) 'aspectRatio': aspectRatio,
        'src': src,
      };

  @override
  String toString() {
    return 'PCanvasImage[$type]$info';
  }
}

/// A [PCanvas] color.
abstract class PColor {
  static final PColorRGB colorRed = PColorRGB(255, 0, 0);
  static final PColorRGB colorGreen = PColorRGB(0, 255, 0);
  static final PColorRGB colorBlue = PColorRGB(0, 0, 255);

  static final PColorRGB colorYellow = PColorRGB(255, 255, 0);
  static final PColorRGB colorPink = PColorRGB(255, 0, 255);

  static final PColorRGB colorWhite = PColorRGB(255, 255, 255);
  static final PColorRGB colorGrey = PColorRGB(128, 128, 128);
  static final PColorRGB colorBlack = PColorRGB(0, 0, 0);

  static final PColorRGB colorTransparent = PColorRGBA(0, 0, 0, 0.0);

  /// Returns `true` if this color has alpha.
  bool get hasAlpha;

  PColorRGB copyWith({int? r, int? g, int? b, double? alpha});

  /// Converts to the `RGB` format.
  String toRGB();

  /// Converts to the `RGBA` format.
  String toRGBA();

  /// This color in `ARGB` format.
  int get argb;

  /// This color in `ABGR` format.
  int get abgr;

  /// This color in `RGBA` format.
  int get rgba;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PColor && toString() == other.toString();

  @override
  int get hashCode => toString().hashCode;
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

  @override
  bool get hasAlpha => false;

  String? _rgb;

  @override
  PColorRGB copyWith({int? r, int? g, int? b, double? alpha}) {
    if (alpha != null) {
      return PColorRGBA(r ?? this.r, g ?? this.g, b ?? this.b, alpha);
    } else {
      return PColorRGB(r ?? this.r, g ?? this.g, b ?? this.b);
    }
  }

  @override
  String toRGB() => _rgb ??= 'rgb($r,$g,$b)';

  @override
  String toRGBA() => toRGB();

  @override
  int get argb =>
      ((255 & 0xff) << 24) |
      ((r & 0xff) << 16) |
      ((g & 0xff) << 8) |
      (b & 0xff);

  @override
  int get abgr =>
      ((255 & 0xff) << 24) |
      ((b & 0xff) << 16) |
      ((g & 0xff) << 8) |
      (r & 0xff);

  @override
  int get rgba =>
      ((r & 0xff) << 24) | ((g & 0xff) << 16) | ((b & 0xff) << 8) | (255);

  @override
  String toString() => toRGB();
}

class PColorRGBA extends PColorRGB {
  /// The alpha value.
  final double alpha;

  PColorRGBA(super.r, super.g, super.b, double a)
      : alpha = ((a.clamp(0, 1) * 10000).toInt() / 10000);

  @override
  bool get hasAlpha => alpha != 1.0;

  int? _a;

  int get a => _a ??= (alpha * 255).toInt();

  String? _rgba;

  @override
  PColorRGB copyWith({int? r, int? g, int? b, double? alpha}) =>
      PColorRGBA(r ?? this.r, g ?? this.g, b ?? this.b, alpha ?? this.alpha);

  @override
  String toRGBA() => _rgba ??= 'rgba($r,$g,$b,$alpha)';

  @override
  int get argb =>
      ((a & 0xff) << 24) | ((r & 0xff) << 16) | ((g & 0xff) << 8) | (b & 0xff);

  @override
  int get abgr =>
      ((a & 0xff) << 24) | ((b & 0xff) << 16) | ((g & 0xff) << 8) | (r & 0xff);

  @override
  int get rgba =>
      ((r & 0xff) << 24) | ((g & 0xff) << 16) | ((b & 0xff) << 8) | (a & 0xff);

  @override
  String toString() => hasAlpha ? toRGBA() : toRGB();
}

class PStyle {
  final PColor? color;
  final int? size;

  const PStyle({this.color, this.size});

  bool equals(PStyle other) =>
      identical(this, other) ||
      runtimeType == other.runtimeType &&
          color == other.color &&
          size == other.size;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PStyle &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          size == other.size;

  @override
  int get hashCode => color.hashCode ^ size.hashCode;
}

/// A [PCanvas] dimension.
class PDimension {
  /// The dimension width.
  final num width;

  /// The dimension height.
  final num height;

  const PDimension(this.width, this.height);

  /// The aspect ration of this dimension ([width] / [height]).
  double get aspectRation => width / height;

  /// The center [point] of this dimension.
  Point get center => Point(width ~/ 2, height ~/ 2);

  @override
  String toString() {
    return 'PDimension{width: $width, height: $height}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PDimension && width == other.width && height == other.height;

  @override
  int get hashCode => width.hashCode ^ height.hashCode;
}

/// A [PCanvas] rectangle.
class PRectangle extends PDimension {
  /// The X coordinate.
  final num x;

  /// The Y coordinate.
  final num y;

  PRectangle(this.x, this.y, super.width, super.height);

  @override

  /// The center [Point] of this rectangle.
  Point get center => Point(x + width ~/ 2, y + height ~/ 2);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other && other is PRectangle && x == other.x && y == other.y;

  @override
  int get hashCode => super.hashCode ^ x.hashCode ^ y.hashCode;

  @override
  String toString() {
    return 'PRectangle{x: $x, y: $y, width: $width, height: $height}';
  }
}

/// A [PCanvas] text metric.
class PTextMetric extends PDimension {
  /// The actual width of the text.
  final num actualWidth;

  /// The actual height of the text.
  final num actualHeight;

  const PTextMetric(super.width, super.height,
      [num? actualWidth, num? actualHeight, num? y])
      : actualWidth = actualWidth ?? width,
        actualHeight = actualHeight ?? height,
        super();

  /// Returns `true` if [actualWidth] == [width] AND [actualHeight] == [height].
  bool get inCompliance => actualWidth == width && actualHeight == height;

  @override
  String toString() {
    return inCompliance
        ? 'TextMetric{width: $width, height: $height}'
        : 'TextMetric{width: $width, height: $height, actualWidth: $actualWidth, actualHeight: $actualHeight}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is PTextMetric &&
          runtimeType == other.runtimeType &&
          actualWidth == other.actualWidth &&
          actualHeight == other.actualHeight;

  @override
  int get hashCode =>
      super.hashCode ^ actualWidth.hashCode ^ actualHeight.hashCode;
}

/// A [PCanvas] font.
class PFont {
  /// The family of the font.
  final String family;

  /// The size of the font.
  final num size;

  /// The family fallback.
  final String? familyFallback;

  /// If `true` the font is bold.
  final bool bold;

  /// If `true` the font is italic.
  final bool italic;

  PFont(this.family, this.size,
      {this.bold = false, this.italic = false, this.familyFallback});

  String? _css;

  /// Returns this font properties in CSS.
  String toCSS({num pixelRatio = 1}) =>
      _css ??= '${size / pixelRatio}px $family';

  @override
  String toString() => toCSS();

  bool equals(PFont other) =>
      identical(this, other) || family == other.family && size == other.size;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PFont && family == other.family && size == other.size;

  @override
  int get hashCode => family.hashCode ^ size.hashCode;
}

/// A [PCanvas] point.
class Point {
  /// The X coordinate.
  final num x;

  /// The Y coordinate.
  final num y;

  const Point(this.x, this.y);

  @override
  String toString() {
    return '($x,$y)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Point && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

extension ListPCanvasImageExtension on List<PCanvasImage> {
  /// Loads all the images of this list.
  Future<List<bool>> loadAll() {
    var list = map((e) => e.load())
        .map((e) => e is Future<bool> ? e : Future.value(e))
        .toList();

    return Future.wait(list);
  }
}
