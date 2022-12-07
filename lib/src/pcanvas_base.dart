import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:pcanvas/pcanvas.dart';

import 'pcanvas_element.dart';

import 'pcanvas_impl_bitmap.dart'
    if (dart.library.html) 'pcanvas_impl_html.dart';

/// A [PCanvas] event.
///
/// See [PCanvasClickEvent].
abstract class PCanvasEvent {
  /// The event type.
  final String type;

  const PCanvasEvent(this.type);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PCanvasEvent &&
          runtimeType == other.runtimeType &&
          type == other.type;

  @override
  int get hashCode => type.hashCode;
}

/// A [PCanvas] click event.
/// See [PCanvas.onClick].
class PCanvasClickEvent extends PCanvasEvent {
  /// The event X coordinate.
  final num x;

  /// The event Y coordinate.
  final num y;

  const PCanvasClickEvent(super.type, this.x, this.y) : super();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is PCanvasClickEvent &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => super.hashCode ^ x.hashCode ^ y.hashCode;

  @override
  String toString() {
    return 'PCanvasClickEvent{type: $type, x: $x, y: $y}';
  }
}

/// A [PCanvas] key event.
/// See [PCanvas.onKey].
class PCanvasKeyEvent extends PCanvasEvent {
  /// The Unicode value of the key:
  final int charCode;

  /// The code of the key (the name of the key).
  final String? code;

  /// The key value.
  final String? key;

  /// Whether the "CTRL" key was pressed.
  final bool ctrlKey;

  /// Whether the "ALT" key was pressed.
  final bool altKey;

  /// Whether the "SHIFT" key was pressed.
  final bool shiftKey;

  /// Whether the "META" key was pressed.
  final bool metaKey;

  const PCanvasKeyEvent(super.type, this.charCode, this.code, this.key,
      this.ctrlKey, this.altKey, this.shiftKey, this.metaKey)
      : super();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is PCanvasKeyEvent &&
          runtimeType == other.runtimeType &&
          charCode == other.charCode &&
          code == other.code &&
          key == other.key &&
          ctrlKey == other.ctrlKey &&
          altKey == other.altKey &&
          shiftKey == other.shiftKey &&
          metaKey == other.metaKey;

  @override
  int get hashCode =>
      super.hashCode ^
      charCode.hashCode ^
      code.hashCode ^
      key.hashCode ^
      ctrlKey.hashCode ^
      altKey.hashCode ^
      shiftKey.hashCode ^
      metaKey.hashCode;

  @override
  String toString() {
    var extra = [
      if (shiftKey) 'SHIFT',
      if (ctrlKey) 'CTRL',
      if (altKey) 'ALT',
      if (metaKey) 'META',
    ];
    return 'PCanvasKeyEvent{type: $type, key: <$key>, charCode: $charCode, code: <$code>}${extra.isNotEmpty ? '$extra' : ''}';
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

  /// Paint the [elements].
  FutureOr<bool> paintElements(
      PCanvas pCanvas, List<PCanvasElement> elements, bool posPaint) {
    for (var e in elements) {
      e.paint(pCanvas);
    }
    return true;
  }

  /// The paint operations.
  FutureOr<bool> paint(PCanvas pCanvas);

  /// Canvas `onClickDown` handler.
  void onClickDown(PCanvasClickEvent event) {}

  /// Canvas `onClickUp` handler.
  void onClickUp(PCanvasClickEvent event) {}

  /// Canvas `onClick` handler.
  void onClick(PCanvasClickEvent event) {}

  /// Canvas `onKeyDown` handler.
  void onKeyDown(PCanvasKeyEvent event) {}

  /// Canvas `onKeyUp` handler.
  void onKeyUp(PCanvasKeyEvent event) {}

  /// Canvas `onKey` handler.
  void onKey(PCanvasKeyEvent event) {}
}

typedef PaintFuntion = FutureOr<bool> Function(PCanvas pCanvas);

/// Portable Canvas.
abstract class PCanvas with WithDimension {
  /// The painter of this canvas.
  PCanvasPainter get painter;

  /// The pixels width of this canvas.
  @override
  num get width;

  /// The pixels height of this canvas.
  @override
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

  final List<PCanvasElement> _elements = <PCanvasElement>[];

  List<PCanvasElement> get elements =>
      UnmodifiableListView<PCanvasElement>(_elements);

  bool get hasElements => _elements.isNotEmpty;

  void clearElements() {
    if (_elements.isNotEmpty) {
      _elements.clear();
      requestRepaint();
    }
  }

  void addElement(PCanvasElement element) {
    _elements.add(element);
    _elements.sortByZIndex();
    requestRepaint();
  }

  bool removeElement(PCanvasElement element) {
    var rm = _elements.remove(element);
    if (rm) {
      requestRepaint();
    }
    return rm;
  }

  /// Waits the loading of the canvas and also the [painter.loadResources].
  FutureOr<bool> waitLoading();

  /// The dimension of the visual element of this canvas.
  /// - If [pixelRatio] is > 1 it will habe a different dimension than [dimension].
  PDimension get elementDimension => PDimension(elementWidth, elementHeight);

  /// The dimension of this canvas.
  @override
  PDimension get dimension => PDimension(width, height);

  /// The pixels ratio of the device of the [canvasNative].
  num get devicePixelRatio;

  /// The current pixel ration of this canvas.
  /// See [devicePixelRatio].
  num get pixelRatio;

  /// Sets the pixel ration of this canvas and refreshes it.
  set pixelRatio(num pr);

  /// [PCanvas] information.
  Map<String, Object?> get info => <String, Object?>{
        'pixelRatio': pixelRatio,
        'devicePixelRatio': devicePixelRatio,
        'width': width,
        'height': height,
        'elementWidth': elementWidth,
        'elementHeight': elementHeight,
      };

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
      final painter = this.painter;

      onPrePaint();

      painter.clear(this);

      final ret = painter.isLoadingResources
          ? _callPainterLoading()
          : _callPainterImpl();

      if (ret is Future<bool>) {
        return ret.whenComplete(() {
          _painting = false;
          onPosPaint();
        });
      } else {
        _painting = false;
        onPosPaint();
        return ret;
      }
    } catch (e) {
      _painting = false;
      onPosPaint();
      rethrow;
    }
  }

  FutureOr<bool> _callPainterLoading() {
    return painter.paintLoading(this);
  }

  FutureOr<bool> _callPainterImpl() {
    var hasElements = _elements.isNotEmpty;

    List<PCanvasElement>? elementsPrev;
    List<PCanvasElement>? elementsPos;

    if (hasElements) {
      elementsPrev = _elements.where((e) {
        var zIndex = e.zIndex;
        return zIndex != null && zIndex < 0;
      }).toList();

      elementsPos = _elements.where((e) {
        var zIndex = e.zIndex;
        return zIndex == null || zIndex >= 0;
      }).toList();
    }

    final painter = this.painter;

    FutureOr<bool> ret = true;

    if (elementsPrev != null) {
      ret = painter.paintElements(this, elementsPrev, false);
    }

    if (ret is Future<bool>) {
      ret = ret.then((_) => painter.paint(this));
    } else {
      ret = painter.paint(this);
    }

    if (elementsPos != null) {
      if (ret is Future<bool>) {
        ret = ret.then((_) => painter.paintElements(this, elementsPos!, true));
      } else {
        ret = painter.paintElements(this, elementsPos, true);
      }
    }

    return ret;
  }

  void onPrePaint() {}

  void onPosPaint() {}

  Future<bool> requestRepaint();

  /// Refreshes the canvas asynchronously.
  Future<bool> refresh() => Future.microtask(callPainter);

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

  /// Fill a rectangle ([x],[y] , [width] x [height]) with a top down linear gradient.
  /// See [fillBottomUpGradient].
  void fillTopDownGradient(
      num x, num y, num width, num height, PColor colorFrom, PColor colorTo);

  /// Fill a rectangle ([x],[y] , [width] x [height]) with a bottom up linear gradient.
  /// See [fillTopDownGradient].
  void fillBottomUpGradient(num x, num y, num width, num height,
          PColor colorFrom, PColor colorTo) =>
      fillTopDownGradient(x, y, width, height, colorTo, colorFrom);

  /// Fill a rectangle ([x],[y] , [width] x [height]) with a left right linear gradient.
  /// See [fillRightLeftGradient].
  void fillLeftRightGradient(
      num x, num y, num width, num height, PColor colorFrom, PColor colorTo);

  /// Fill a rectangle ([x],[y] , [width] x [height]) with a right left linear gradient.
  /// See [fillLeftRightGradient].
  void fillRightLeftGradient(num x, num y, num width, num height,
          PColor colorFrom, PColor colorTo) =>
      fillLeftRightGradient(x, y, width, height, colorTo, colorFrom);

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

  /// Parse [pixel] to [PColor];
  PColorRGB parseColor(int pixel);

  /// Index of a pixel ([x],[y]) at [pixels].
  int pixelIndex(int x, int y) => (width * y) + x;

  /// Returns a pixel at ([x],[y]) in the format 4-byte Uint32 integer in #AABBGGRR channel order.
  int pixel(int x, int y) => pixels[pixelIndex(x, y)];

  /// Returns a pixel at ([x],[y]) as [PColor].
  PColorRGB pixelColor(int x, int y) => parseColor(pixel(x, y));

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

  @override
  PColorRGB parseColor(int pixel) => PColorRGBA.fromARGB(pixel);

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

  @override
  PColorRGB parseColor(int pixel) => PColorRGBA.fromABGR(pixel);

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

  @override
  PColorRGB parseColor(int pixel) => PColorRGBA.fromRGBA(pixel);

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

  /// Converts this intances to a [PColorRGB].
  PColorRGB toPColorRGB();

  /// Converts this intances to a [PColorRGBA].
  PColorRGBA toPColorRGBA();

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

  @override
  bool get hasAlpha => false;

  int get a => 255;

  int maxDistance(PColorRGB other) {
    var rd = (r - other.r).abs();
    var gd = (g - other.g).abs();
    var bd = (b - other.b).abs();
    var ad = (a - other.a).abs();

    return math.max(rd, math.max(gd, math.max(bd, ad)));
  }

  @override
  PColorRGB toPColorRGB() => this;

  @override
  PColorRGBA toPColorRGBA() => PColorRGBA(r, g, b, 1);

  @override
  PColorRGB copyWith({int? r, int? g, int? b, double? alpha}) {
    if (alpha != null) {
      return PColorRGBA(r ?? this.r, g ?? this.g, b ?? this.b, alpha);
    } else {
      return PColorRGB(r ?? this.r, g ?? this.g, b ?? this.b);
    }
  }

  String? _rgb;

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
  PColorRGB copyWith({int? r, int? g, int? b, double? alpha}) =>
      PColorRGBA(r ?? this.r, g ?? this.g, b ?? this.b, alpha ?? this.alpha);

  String? _rgba;

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

abstract class WithDimension {
  /// The dimension width.
  num get width;

  /// The dimension height.
  num get height;

  /// The [PDimension] of this instance.
  PDimension get dimension;

  /// The aspect ration of this dimension ([width] / [height]).
  double get aspectRation => isZeroDimension ? 0 : width / height;

  /// The center [point] of this dimension.
  Point get center => Point(width ~/ 2, height ~/ 2);

  /// The area of this dimension.
  num get area => isZeroDimension ? 0 : width * height;

  /// Returns `true` if the area of this dimension is zero.
  bool get isZeroDimension => width <= 0 || height <= 0;
}

/// A [PCanvas] dimension.
class PDimension with WithDimension {
  @override
  final num width;

  @override
  final num height;

  const PDimension(this.width, this.height);

  @override
  PDimension get dimension => this;

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

  PRectangle.fromDimension(num x, num y, PDimension dimension)
      : this(x, y, dimension.width, dimension.height);

  PRectangle copyWith({num? x, num? y, num? width, num? height}) => PRectangle(
      x ?? this.x, y ?? this.y, width ?? this.width, height ?? this.height);

  @override
  PRectangle get dimension => this;

  /// The center [Point] of this rectangle.
  @override
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

  @override
  PTextMetric get dimension => this;

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
