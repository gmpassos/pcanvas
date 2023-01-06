import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:pcanvas/pcanvas_bitmap.dart';

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

/// A dummy [PCanvasPainter] implementation that won't perform any operation.
class PCanvasPainterDummy extends PCanvasPainter {
  @override
  void clear(PCanvas pCanvas) {}

  @override
  FutureOr<bool> paintLoading(PCanvas pCanvas) => true;

  @override
  FutureOr<bool> paint(PCanvas pCanvas) => true;
}

typedef PaintFuntion = FutureOr<bool> Function(PCanvas pCanvas);

/// Portable Canvas.
abstract class PCanvas
    with PCanvasElementContainer<PCanvasElement>, WithDimension {
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

  factory PCanvas(int width, int height, PCanvasPainter painter,
      {PCanvasPixels? initialPixels}) {
    return createPCanvasImpl(width, height, painter,
        initialPixels: initialPixels);
  }

  /// Sets the canvas pixels.
  void setPixels(PCanvasPixels pixels,
      {int x = 0, int y = 0, int? width, int? height});

  /// The current transformation of the canvas operation.
  PcanvasTransform transform = PcanvasTransform.none;

  /// Sets [transform] to a sub-transformation, merging the current [transform]
  /// with [transform2].
  set subTransform(PcanvasTransform transform2) {
    if (transform2.isZeroTransformation) return;

    var prevT = transform;
    if (prevT.isZeroTransformation) {
      transform = transform2;
    } else {
      var subT = transform + transform2;
      transform = subT;
    }
  }

  /// The current drawing state.
  PCanvasState get state =>
      PCanvasState(transform: transform, clip: clip, stateExtra: stateExtra);

  /// The platform specific extra states.
  PCanvasStateExtra? get stateExtra;

  final QueueList<PCanvasState> _stateStack = QueueList<PCanvasState>();

  /// Saves the drawing state ([PCanvasState]).
  PCanvasState saveState() {
    var s = state;
    _stateStack.addLast(s);

    return s;
  }

  /// Restores the drawing [state].
  PCanvasState? restoreState({PCanvasState? expectedState}) {
    if (_stateStack.isEmpty) {
      throw StateError(
          "State stack error: `saveState`/`restoreState` not properly called.");
    }

    var s = _stateStack.removeLast();

    transform = s.transform;
    clip = s.clip;

    if (expectedState != null && !identical(s, expectedState)) {
      throw StateError(
          "State stack error: `expectedState` not matching the last instance in stack.");
    }

    return s;
  }

  /// Executes [call] preserving the internal drawing [state].
  ///
  /// See [saveState] and [restoreState].
  R callWithGuardedState<R>(R Function() call) {
    saveState();

    var restored = false;

    try {
      var ret = call();

      if (ret is Future) {
        return ret.whenComplete(() {
          restored = true;
          restoreState();
        }) as R;
      } else {
        restored = true;
        restoreState();
        return ret;
      }
    } finally {
      if (!restored) {
        restoreState();
      }
    }
  }

  /// Executes [call] preserving the internal drawing state, accepting [Future]
  /// as return value.
  ///
  /// See [saveState] and [restoreState].
  FutureOr<R> callWithGuardedStateAsync<R>(FutureOr<R> Function() call) {
    saveState();

    var restored = false;

    try {
      var ret = call();

      if (ret is Future<R>) {
        return ret.whenComplete(() {
          restored = true;
          restoreState();
        });
      } else {
        restored = true;
        restoreState();
        return ret;
      }
    } finally {
      if (!restored) {
        restoreState();
      }
    }
  }

  final List<PCanvasElement> _elements = <PCanvasElement>[];

  @override
  UnmodifiableListView<PCanvasElement> get elements =>
      UnmodifiableListView<PCanvasElement>(_elements);

  @override
  bool get hasElements => _elements.isNotEmpty;

  @override
  void clearElements() {
    if (_elements.isNotEmpty) {
      _elements.clear();
      requestRepaint();
    }
  }

  @override
  void addElement(PCanvasElement element) {
    _elements.add(element);
    _elements.sortByZIndex();
    requestRepaint();
  }

  @override
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
  void clear({PStyle? style}) {
    saveState();

    transform = PcanvasTransform.none;
    clearRect(0, 0, width, height, style: style);

    restoreState();
  }

  /// Clears a part of the canvas.
  /// - Applies [style] if provided.
  void clearRect(num x, num y, num width, num height, {PStyle? style});

  /// Sets the drawing clip.
  /// - Same as `this.clip = rect`.
  /// - See [clip].
  void setClip(num x, num y, num width, num height) =>
      clip = PRectangle(x, y, width, height);

  /// Sets [clip] merging the passed coordinates with the previous clip.
  /// - See [subClip].
  void setSubClip(num x, num y, num width, num height) =>
      subClip = PRectangle(x, y, width, height);

  /// Returns the current drawing clip.
  PRectangle? get clip;

  /// Sets the drawing clip.
  /// - Note that the [clip] won't be merged with the previouse clip
  ///   (the clip coordinates are always global).
  /// - See [subClip].
  set clip(PRectangle? clip);

  /// Sets [clip] merging the coordinates of [clip2] with the previous clip.
  set subClip(PRectangle? clip2) {
    if (clip2 == null) return;

    var clip = this.clip;
    if (clip == null) {
      this.clip = clip2;
    } else {
      var subClip = clip.intersection(clip2);
      this.clip = subClip;
    }
  }

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

  /// Converts [angle] in degrees to arcs.
  double angleToRadians(num angle) => (math.pi / 180) * angle;

  /// Stroke a circle at ([x],[y]) with [radius].
  void strokeCircle(num x, num y, num radius, PStyle style,
      {num startAngle = 0, num endAngle = 360});

  /// Fill a circle at ([x],[y]) with [radius].
  void fillCircle(num x, num y, num radius, PStyle style,
      {num startAngle = 0, num endAngle = 360});

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
  FutureOr<String> toDataUrl() {
    var pngData = toPNG();
    if (pngData is Future<Uint8List>) {
      return pngData.then(_toDataUrlImpl);
    } else {
      return _toDataUrlImpl(pngData);
    }
  }

  String _toDataUrlImpl(Uint8List pngData) {
    var dataBase64 = base64.encode(pngData);

    var url = StringBuffer();
    url.write('data:image/png;base64,');
    url.write(dataBase64);

    return url.toString();
  }
}

class PCanvasState {
  final PcanvasTransform transform;
  final PRectangle? clip;
  final PCanvasStateExtra? stateExtra;

  const PCanvasState(
      {this.transform = PcanvasTransform.none, this.clip, this.stateExtra});

  @override
  String toString() {
    return 'PCanvasState{transform: $transform, clip: $clip, stateExtra: $stateExtra}';
  }
}

abstract class PCanvasStateExtra {}

/// [PCanvas] transformation.
class PcanvasTransform {
  static const PcanvasTransform none = PcanvasTransform();

  final num translateX;

  final num translateY;

  const PcanvasTransform({this.translateX = 0, this.translateY = 0});

  bool get isZeroTranslation => translateX == 0 && translateY == 0;

  bool get isZeroTransformation => isZeroTranslation;

  Point get translate => Point(translateX, translateY);

  num x(num x) => translateX + x;

  num y(num y) => translateY + y;

  double xD(num x) => this.x(x).toDouble();

  double yD(num y) => this.y(y).toDouble();

  Point point(Point p) => Point(x(p.x), y(p.y));

  PcanvasTransform operator +(PcanvasTransform other) => PcanvasTransform(
      translateX: translateX + other.translateX,
      translateY: translateY + other.translateY);

  @override
  String toString() {
    return 'PcanvasTransform{translate: ($translateX, $translateY)}';
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

  PCanvasPixels.blank(this.width, this.height)
      : pixels = Uint32List(width * height);

  /// Construct a [PCanvasPixels] from [bytes].
  /// - If [bytes] is a [TypedData] it will be converted to an [Uint32List]
  ///   through its internal [ByteBuffer].
  /// - If [bytes] is not a [TypedData] it will be converted to a [Uint8ClampedList.fromList]
  ///   and after that to an [Uint32List].
  /// - Note that in most systems the [Endian.host] is 'little-endian'.
  /// - Modern CPU architectures are `little-endian`, like `x86` and `ARMv8`.
  PCanvasPixels.fromBytes(int width, int height, List<int> bytes)
      : this.fromPixels(width, height, _bytesToUint32List(bytes));

  static Uint32List _bytesToUint32List(List<int> bytes) {
    if (bytes is TypedData) {
      var td = bytes as TypedData;
      return td.buffer.asUint32List(td.offsetInBytes, td.lengthInBytes ~/ 4);
    } else {
      var bs = Uint8ClampedList.fromList(bytes);
      return bs.buffer.asUint32List(bs.offsetInBytes, bs.lengthInBytes ~/ 4);
    }
  }

  /// Construct a [PCanvasPixels] from [pixels].
  /// - [pixels] is expected to be an [Uint32List] in the same [format] of this class implementation.
  PCanvasPixels.fromPixels(this.width, this.height, this.pixels);

  /// Creates a blank [PCanvasPixels] instance with the same [format] of this one.
  PCanvasPixels createBlank(int width, int height);

  /// Length of [pixels].
  int get length => pixels.length;

  /// Length of [pixels] in bytes.
  int get lengthInBytes => pixels.length * 4;

  /// The pixel format.
  String get format;

  bool isSameFormat(PCanvasPixels other);

  /// Formats [color] to this instance [format].
  int formatColor(PColor color);

  /// Parse [pixel] to [PColor];
  PColorRGB parseColor(int pixel);

  /// Index of a pixel ([x],[y]) at [pixels].
  int pixelIndex(int x, int y) => (width * y) + x;

  /// Returns a pixel at ([x],[y]) in the format 4-byte Uint32 integer in [format].
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

  /// Sets a pixels at ([x],[y]) with value [p].
  /// - [p] is expected to be in the same [format] of this instances [pixels].
  void setPixel(int x, int y, int p) => pixels[pixelIndex(x, y)] = p;

  void _checkSameFormat(PCanvasPixels src) {
    if (!isSameFormat(src)) {
      throw StateError(
          "Parameter `src` not of same format> src: ${src.format} ; this: $format");
    }
  }

  /// Sets a pixels at ([dstX],[dstY]) with value from [src] at ([srcX],[srcY]).
  void setPixelFrom(PCanvasPixels src, int srcX, int srcY, int dstX, int dstY) {
    _checkSameFormat(src);
    _setPixelFromImpl(src, srcX, srcY, dstX, dstY);
  }

  void _setPixelFromImpl(
      PCanvasPixels src, int srcX, int srcY, int dstX, int dstY) {
    pixels[pixelIndex(dstX, dstY)] = src.pixel(srcX, srcY);
  }

  void setPixelsLineFrom(
      PCanvasPixels src, int srcX, int srcY, int dstX, int dstY, int width) {
    _checkSameFormat(src);

    for (var i = 0; i < width; ++i) {
      _setPixelFromImpl(src, srcX + i, srcY, dstX + i, dstY);
    }
  }

  void setPixelsColumnFrom(
      PCanvasPixels src, int srcX, int srcY, int dstX, int dstY, int height) {
    _checkSameFormat(src);

    for (var i = 0; i < height; ++i) {
      _setPixelFromImpl(src, srcX, srcY + i, dstX, dstY + i);
    }
  }

  void setPixelsRectFrom(PCanvasPixels src, int srcX, int srcY, int dstX,
      int dstY, int width, int height) {
    _checkSameFormat(src);

    final srcPixels = src.pixels;

    for (var y = 0; y < height; ++y) {
      var srcIndex = src.pixelIndex(srcX, srcY + y);
      var dstIndex = pixelIndex(dstX, dstY + y);

      for (var x = 0; x < width; ++x) {
        pixels[dstIndex + x] = srcPixels[srcIndex + x];
      }
    }
  }

  void putPixels(PCanvasPixels src, num dstX, num dstY) => setPixelsRectFrom(
      src, 0, 0, dstX.toInt(), dstY.toInt(), src.width, src.height);

  PCanvasPixels? copyRectangle(PRectangle r) =>
      copyRect(r.x.toInt(), r.y.toInt(), r.width.toInt(), r.height.toInt());

  PCanvasPixels? copyRect(int x, int y, int width, int height) {
    if (width <= 0 || height <= 0) return null;

    var rect = createBlank(width, height);
    rect.setPixelsRectFrom(this, x, y, 0, 0, width, height);
    return rect;
  }

  PCanvasPixelsARGB toPCanvasPixelsARGB();

  PCanvasPixelsABGR toPCanvasPixelsABGR();

  PCanvasPixelsRGBA toPCanvasPixelsRGBA();

  PCanvas toPCanvas({PCanvasPainter? painter}) {
    var pCanvas = PCanvas(width, height, painter ?? PCanvasPainterDummy(),
        initialPixels: this);
    return pCanvas;
  }

  FutureOr<Uint8List> toPNG() {
    var pCanvas = toPCanvas();
    return pCanvas.toPNG();
  }

  FutureOr<String> toDataUrl() {
    var pCanvas = toPCanvas();
    return pCanvas.toDataUrl();
  }

  @override
  String toString() {
    return 'PCanvasPixels{width: $width, height: $height, format: $format, bytes: $lengthInBytes}';
  }
}

/// [PCanvasPixels] in `ARGB` format.
class PCanvasPixelsARGB extends PCanvasPixels {
  PCanvasPixelsARGB.blank(super.width, super.height) : super.blank();

  PCanvasPixelsARGB.fromBytes(super.width, super.height, super.bytes)
      : super.fromBytes();

  PCanvasPixelsARGB.fromPixels(super.width, super.height, super.pixels)
      : super.fromPixels();

  @override
  String get format => 'ARGB';

  @override
  bool isSameFormat(PCanvasPixels other) => other is PCanvasPixelsARGB;

  @override
  PCanvasPixelsARGB createBlank(int width, int height) =>
      PCanvasPixelsARGB.blank(width, height);

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
  PCanvasPixelsABGR toPCanvasPixelsABGR() => PCanvasPixelsABGR.fromPixels(
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
  PCanvasPixelsRGBA toPCanvasPixelsRGBA() => PCanvasPixelsRGBA.fromPixels(
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
  PCanvasPixelsABGR.blank(super.width, super.height) : super.blank();

  PCanvasPixelsABGR.fromBytes(super.width, super.height, super.bytes)
      : super.fromBytes();

  PCanvasPixelsABGR.fromPixels(super.width, super.height, super.pixels)
      : super.fromPixels();

  @override
  String get format => 'ABGR';

  @override
  bool isSameFormat(PCanvasPixels other) => other is PCanvasPixelsABGR;

  @override
  PCanvasPixelsABGR createBlank(int width, int height) =>
      PCanvasPixelsABGR.blank(width, height);

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
  PCanvasPixelsARGB toPCanvasPixelsARGB() => PCanvasPixelsARGB.fromPixels(
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
  PCanvasPixelsRGBA toPCanvasPixelsRGBA() => PCanvasPixelsRGBA.fromPixels(
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
  PCanvasPixelsRGBA.blank(super.width, super.height) : super.blank();

  PCanvasPixelsRGBA.fromBytes(super.width, super.height, super.bytes)
      : super.fromBytes();

  PCanvasPixelsRGBA.fromPixels(super.width, super.height, super.pixels)
      : super.fromPixels();

  @override
  String get format => 'RGBA';

  @override
  bool isSameFormat(PCanvasPixels other) => other is PCanvasPixelsRGBA;

  @override
  PCanvasPixelsRGBA createBlank(int width, int height) =>
      PCanvasPixelsRGBA.blank(width, height);

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
  PCanvasPixelsARGB toPCanvasPixelsARGB() => PCanvasPixelsARGB.fromPixels(
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
  PCanvasPixelsABGR toPCanvasPixelsABGR() => PCanvasPixelsABGR.fromPixels(
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

  PStyle toStyle({int? size}) => PStyle(color: this, size: size);
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
  static const PStyle none = PStyle();

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

  @override
  String toString() => 'PStyle{color: $color, size: $size}';
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

  PRectangle toPRectangle({num x = 0, num y = 0}) =>
      PRectangle(x, y, width, height);
}

/// A [PCanvas] rectangle.
class PRectangle extends PDimension {
  /// The X coordinate.
  final num x;

  /// The Y coordinate.
  final num y;

  const PRectangle(this.x, this.y, super.width, super.height);

  PRectangle.fromDimension(num x, num y, PDimension dimension)
      : this(x, y, dimension.width, dimension.height);

  factory PRectangle.fromPoints(Point p1, Point p2) =>
      PRectangle.fromCoordinates(p1.x, p1.y, p2.x, p2.y);

  factory PRectangle.fromCoordinates(num x1, num y1, num x2, num y2) {
    if (x2 < x1) {
      var tmp = x1;
      x1 = x2;
      x2 = tmp;
    }

    if (y2 < y1) {
      var tmp = y1;
      y1 = y2;
      y2 = tmp;
    }

    return PRectangle(x1, y1, x2 - x1, y2 - y1);
  }

  PRectangle copyWith({num? x, num? y, num? width, num? height}) => PRectangle(
      x ?? this.x, y ?? this.y, width ?? this.width, height ?? this.height);

  /// Increments [x] by [n].
  PRectangle incrementX(num n) => PRectangle(x + n, y, width, height);

  /// Increments [y] by [n].
  PRectangle incrementY(num n) => PRectangle(x, y + n, width, height);

  /// Increments [x],[y] by [nX],[nY],
  PRectangle incrementXY(num nX, num nY) =>
      PRectangle(x + nX, y + nY, width, height);

  /// Translate this rectangle.
  ///
  /// - Alias for [incrementXY].
  PRectangle translate(num x, num y) => incrementXY(x, y);

  /// Increments [width] by [n].
  PRectangle incrementWidth(num n) => PRectangle(x, y, width + n, height);

  /// Increments [height] by [n].
  PRectangle incrementHeight(num n) => PRectangle(x, y, width, height + n);

  /// Increments [width],[height] by [nW],[nH].
  PRectangle incrementWH(num nW, num nH) =>
      PRectangle(x, y, width + nW, height + nH);

  @override
  PRectangle get dimension => this;

  /// The center [Point] of this rectangle.
  @override
  Point get center => Point(x + width ~/ 2, y + height ~/ 2);

  /// Returns: `x + width`
  num get maxX => x + width;

  /// Returns: `y + height`
  num get maxY => y + height;

  /// Returns `true` if [r] intersects this rectangle.
  bool intersectsRectangle(PRectangle r) =>
      intersects(r.x, r.y, r.width, r.height);

  /// Returns `true` this rectangle intersects with [x],[y] , [width],[height].
  bool intersects(num x, num y, num width, num height) {
    final mx = this.x;
    final my = this.y;
    final mw = this.width;
    final mh = this.height;
    return width > 0 &&
        height > 0 &&
        mw > 0 &&
        mh > 0 &&
        x < mx + mw &&
        x + width > mx &&
        y < my + mh &&
        y + height > my;
  }

  /// Returns the intersection between this rectangle and [r].
  PRectangle intersection(PRectangle r) {
    final src1 = this;
    final src2 = r;

    final x = math.max(src1.x, src2.x);
    final y = math.max(src1.y, src2.y);

    final maxx = math.min(src1.maxX, src2.maxX);
    final maxy = math.min(src1.maxY, src2.maxY);

    return PRectangle(x, y, maxx - x, maxy - y);
  }

  /// Returns `true` if this rectangle contains the rectangle [r].
  bool containsRectangle(PRectangle r) => contains(r.x, r.y, r.width, r.height);

  /// Returns `true` if this rectangle contains the rectangle [x],[y] , [width],[height].
  bool contains(num x, num y, num width, num height) {
    final mx = this.x;
    final my = this.y;
    final mw = this.width;
    final mh = this.height;

    return width > 0 &&
        height > 0 &&
        mw > 0 &&
        mh > 0 &&
        x >= mx &&
        (x + width) <= (mx + mw) &&
        y >= my &&
        (y + height) <= (my + mh);
  }

  /// Returns `true` if this rectangle contains the point [p].
  bool containsPoint(Point p) => containsXY(p.x, p.y);

  /// Returns `true` if this rectangle contains the coordinates [x],[y].
  bool containsXY(num x, num y) {
    final mx = this.x;
    final my = this.y;
    var w = width;
    var h = height;
    return w > 0 && h > 0 && x >= mx && x < (mx + w) && y >= my && y < (my + h);
  }

  PRectangle transform(PcanvasTransform t) {
    return PRectangle(x + t.translateX, y + t.translateY, width, height);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is PRectangle &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode =>
      super.hashCode ^
      x.hashCode ^
      y.hashCode ^
      width.hashCode ^
      height.hashCode;

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
  /// This `dummy` instance shoudn't be used in paint operations.
  static final PFont dummy = PFont('', 0);

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

abstract class Position {
  /// The resolved X coordinate.
  num get x;

  /// The resolved Y coordinate.
  num get y;

  /// Sets the X coordinate.
  Position setX(num x);

  /// Sets the Y coordinate.
  Position setY(num y);

  /// Increments the X coordinate by [n]
  Position incrementX(num n);

  /// Increments the Y coordinate by [n]
  Position incrementY(num n);

  /// Increments the X,Y coordinates by [nX] and [nY].
  Position incrementXY(num nX, num nY);
}

/// A [PCanvas] point.
class Point implements Position {
  /// The X coordinate.
  @override
  final num x;

  /// The Y coordinate.
  @override
  final num y;

  const Point(this.x, this.y);

  bool get isZero => x == 0 && y == 0;

  @override
  String toString() {
    return '($x,$y)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Point && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  Position setX(num x) => Point(x, y);

  @override
  Position setY(num y) => Point(x, y);

  @override
  Point incrementX(num n) => Point(x + n, y);

  @override
  Point incrementY(num n) => Point(x, y + n);

  @override
  Point incrementXY(num nX, num nY) => Point(x + nX, y + nY);
}

extension ListPointExtension on List<Point> {
  PRectangle? get boundingBox {
    var length = this.length;
    if (length == 0) return null;

    var p0 = this[0];

    num minX, minY, maxX, maxY;

    minX = maxX = p0.x;
    minY = maxY = p0.y;

    for (var i = 1; i < length; ++i) {
      var p = this[i];

      var x = p.x;
      var y = p.y;

      if (x < minX) minX = x;
      if (y < minY) minY = y;

      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }

    return PRectangle.fromCoordinates(minX, minY, maxX, maxY);
  }
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
