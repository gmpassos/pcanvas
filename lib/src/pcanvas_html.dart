import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import 'pcanvas_base.dart';

extension CanvasElementExtension on CanvasElement {
  PCanvasHTML? get pCanvas => PCanvasHTML.getPCanvasFromCanvasElement(this);
}

class PCanvasHTML extends PCanvas {
  static final ResizeObserver _resizeObserver =
      ResizeObserver((entries, observer) {
    var canvas = entries
        .map((e) => e is ResizeObserverEntry ? e.target : e)
        .whereType<CanvasElement>();

    for (var c in canvas) {
      var pCanvas = c.pCanvas;
      pCanvas?.callPainter();
    }
  });

  static final Expando<PCanvasHTML> _canvasRelations =
      Expando<PCanvasHTML>('PCanvasHTML');

  static PCanvasHTML? getPCanvasFromCanvasElement(CanvasElement canvas) =>
      _canvasRelations[canvas];

  @override
  final PCanvasPainter painter;
  late final CanvasElement _canvas;
  late final CanvasRenderingContext2D _ctx;

  @override
  num get width => (_canvas.width ?? 0);

  @override
  num get height => (_canvas.height ?? 0);

  late final PCanvasHTMLStateExtra _initialStateExtra;

  PCanvasHTML(int width, int height, this.painter,
      {PCanvasPixels? initialPixels})
      : super.impl() {
    _canvas = CanvasElement(width: width, height: height);

    _ctx = (_canvas.getContext('2d', {'willReadFrequently': true})
            as CanvasRenderingContext2D?) ??
        _canvas.context2D;

    // Saves the initial drawing state to allow `_resetCtx`.
    _ctx.save();
    _initialStateExtra = PCanvasHTMLStateExtra._(_ctx);

    _setFont(PFont('Arial', 14));
    _setStrokeStyle(PStyle(color: PColor.colorBlack, size: 1));
    _setFillStyle(PStyle(color: PColor.colorWhite));

    _canvas.onMouseDown.listen(_onMouseDown);
    _canvas.onMouseUp.listen(_onMouseUp);
    _canvas.onClick.listen(_onClick);

    window.onKeyDown.listen(_onKeyDown);
    window.onKeyUp.listen(_onKeyUp);
    window.onKeyPress.listen(_onKey);

    _canvasRelations[_canvas] = this;
    _resizeObserver.observe(_canvas);

    _setup();
    _initialize(initialPixels);
  }

  @override
  void setPixels(PCanvasPixels pixels,
      {int x = 0, int y = 0, int? width, int? height}) {
    pixels = pixels.toPCanvasPixelsABGR();

    var pixelsData = pixels.pixels;
    var pixelsDataBuffer = pixelsData.buffer;

    var bytes = pixelsDataBuffer.asUint8ClampedList(
        pixelsData.offsetInBytes, pixelsData.lengthInBytes);

    var imageData = ImageData(bytes, pixels.width, pixels.height);

    _ctx.putImageData(imageData, x, y, 0, 0, pixels.width, pixels.height);
  }

  @override
  num get elementWidth => _canvas.client.width;

  @override
  num get elementHeight => _canvas.client.height;

  @override
  num get devicePixelRatio => window.devicePixelRatio;

  num _pixelRatio = 1;

  @override
  num get pixelRatio => _pixelRatio;

  @override
  set pixelRatio(num pr) {
    if (_pixelRatio != pr) {
      _pixelRatio = pr;
      checkDimension();
      refresh();
    }
  }

  bool _checkingDimension = false;

  @override
  void checkDimension() {
    if (_checkingDimension) return;
    _checkingDimension = true;

    final canvas = _canvas;

    var cW = canvas.clientWidth;
    var cH = canvas.clientHeight;

    if (cW != 0 && cH != 0) {
      var w = canvas.width ?? 0;
      var h = canvas.height ?? 0;

      var cWpr = (cW * _pixelRatio).toInt();
      var cHpr = (cH * _pixelRatio).toInt();

      if (w != cWpr || h != cHpr) {
        canvas.width = cWpr;
        canvas.height = cHpr;
        _clearSetStates();
      }
    }

    _checkingDimension = false;
  }

  @override
  void log(Object? o) {
    window.console.log(o);
  }

  void _setup() {
    painter.setup(this);
    pixelRatio = devicePixelRatio;
  }

  @override
  FutureOr<bool> waitLoading() => painter.waitLoading();

  void _initialize(PCanvasPixels? initialPixels) {
    if (initialPixels != null) {
      setPixels(initialPixels);
    }

    var ret = painter.callLoadResources(this);

    if (ret is Future<bool>) {
      ret.then((_) => callPainter());
    } else {
      callPainter();
    }
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

  void _onMouseDown(MouseEvent mEvent) =>
      painter.onClickDown(mEvent.toEvent('onMouseDown'));

  void _onMouseUp(MouseEvent mEvent) =>
      painter.onClickDown(mEvent.toEvent('onMouseUp'));

  void _onClick(MouseEvent mEvent) =>
      painter.onClick(mEvent.toEvent('onClick'));

  void _onKeyDown(KeyboardEvent kEvent) =>
      painter.onKeyDown(kEvent.toEvent('onKeyDown'));

  void _onKeyUp(KeyboardEvent kEvent) =>
      painter.onKeyUp(kEvent.toEvent('onKeyUp'));

  void _onKey(KeyboardEvent kEvent) => painter.onKey(kEvent.toEvent('onKey'));

  @override
  CanvasElement get canvasNative => _canvas;

  int _imageIdCount = 0;

  @override
  PCanvasImage createCanvasImage(Object source, {int? width, int? height}) {
    var id = ++_imageIdCount;

    if (source is String) {
      var imageElement = ImageElement(src: source, width: width, height: height)
        ..crossOrigin = 'anonymous';
      return _PCanvasImageElement('img_$id', imageElement);
    } else {
      throw ArgumentError("Can't handle image source: $source");
    }
  }

  @override
  PCanvasStateExtra get stateExtra => PCanvasHTMLStateExtra._(_ctx);

  @override
  PCanvasState? restoreState({PCanvasState? expectedState}) {
    _ctx.resetTransform();

    final s = super.restoreState(expectedState: expectedState);

    var stateExtra = s?.stateExtra as PCanvasHTMLStateExtra?;
    stateExtra?.setContext(_ctx);

    return s;
  }

  PRectangle? _clip;

  @override
  PRectangle? get clip => _clip;

  void _setClipGlobal(Path2D clipPath) {
    var stateExtra = PCanvasHTMLStateExtra._(_ctx);

    _resetCtx();

    _ctx.clip(clipPath);
    stateExtra.setContext(_ctx);
  }

  @override
  set clip(PRectangle? clip) {
    if (clip == null) {
      if (_clip != null) {
        var rect = Path2D()..rect(0, 0, width, height);
        _setClipGlobal(rect);
        _clip = null;
      }
    } else {
      if (_clip != clip) {
        var clipPath = clip.asPath2D;
        _setClipGlobal(clipPath);
        _clip = clip;
      }
    }
  }

  @override
  set subClip(PRectangle? clip2) {
    if (clip2 == null) return;

    var prevClip = clip;
    if (prevClip == null) {
      var clipPath = clip2.asPath2D;
      _ctx.clip(clipPath);
      _clip = clip2;
    } else {
      var subClip = prevClip.intersection(clip2);
      var clipPath = subClip.asPath2D;
      _ctx.clip(clipPath);
      _clip = subClip;
    }
  }

  /// Resets the [Canvas] [CanvasRenderingContext2D].
  ///
  /// - Note that [CanvasRenderingContext2D.save] and [CanvasRenderingContext2D.restore]
  ///   are only used in this method, to ensure that it can `reset` to the original
  ///   state (including clip), saved at construction.
  void _resetCtx() {
    _ctx.restore();
    _ctx.resetTransform();
    _initialStateExtra.setContext(_ctx);
    _ctx.save();

    _clearSetStates();
  }

  @override
  void clear({PStyle? style}) {
    _resetCtx();
    super.clear(style: style);
  }

  @override
  void clearRect(num x, num y, num width, num height, {PStyle? style}) {
    x = transform.x(x);
    y = transform.y(y);

    x = canvasX(x);
    y = canvasY(y);
    width = canvasX(width);
    height = canvasY(height);

    _ctx.clearRect(x, y, width, height);

    if (style != null) {
      fillRect(x, y, width, height, style);
    }
  }

  @override
  void drawImage(PCanvasImage image, num x, num y) {
    checkImageLoaded(image);

    x = transform.x(x);
    y = transform.y(y);

    x = canvasX(x);
    y = canvasY(y);

    final imageWidth = image.width;
    final imageHeight = image.height;

    var width = canvasX(imageWidth);
    var height = canvasY(imageHeight);

    if (image is _PCanvasImageElement) {
      if (width == imageWidth && height == imageHeight) {
        _ctx.drawImage(image.imageElement, x, y);
      } else {
        _ctx.drawImageScaled(image.imageElement, x, y, width, height);
      }
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

    x = canvasX(x);
    y = canvasY(y);
    width = canvasX(width);
    height = canvasY(height);

    final imageWidth = image.width;
    final imageHeight = image.height;

    if (image is _PCanvasImageElement) {
      if (width == imageWidth && height == imageHeight) {
        _ctx.drawImage(image.imageElement, x, y);
      } else {
        _ctx.drawImageScaled(image.imageElement, x, y, width, height);
      }
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

    dstX = canvasX(dstX);
    dstY = canvasY(dstY);
    dstWidth = canvasX(dstWidth);
    dstHeight = canvasY(dstHeight);

    if (image is _PCanvasImageElement) {
      _ctx.drawImageScaledFromSource(image.imageElement, srcX, srcY, srcWidth,
          srcHeight, dstX, dstY, dstWidth, dstHeight);
    } else {
      throw ArgumentError("Can't handle image type: $image");
    }
  }

  @override
  void strokeRect(num x, num y, num width, num height, PStyle style) {
    if (width == 1 || height == 1) {
      fillRect(x, y, width, height, style);
      return;
    }

    x = transform.x(x);
    y = transform.y(y);

    x = canvasX(x);
    y = canvasY(y);
    width = canvasX(width);
    height = canvasY(height);

    if (width <= 0 || height <= 0) return;

    final size = _setStrokeStyle(style);

    if (size % 2 != 0) {
      x += 0.5;
      y += 0.5;
      --width;
      --height;
    }

    //_ctx.strokeRect(x + 0.5, y + 0.5, width - 1, height - 1);

    _ctx.strokeRect(x, y, width, height);
  }

  @override
  void fillRect(num x, num y, num width, num height, PStyle style) {
    x = transform.x(x);
    y = transform.y(y);

    x = canvasX(x);
    y = canvasY(y);
    width = canvasX(width);
    height = canvasY(height);

    if (width <= 0 || height <= 0) return;

    _setFillStyle(style);

    _ctx.fillRect(x, y, width, height);
  }

  @override
  void strokeCircle(num x, num y, num radius, PStyle style,
      {num startAngle = 0, num endAngle = 360}) {
    x = transform.x(x);
    y = transform.y(y);

    x = canvasX(x);
    y = canvasY(y);
    radius = canvasX(radius);

    startAngle = angleToRadians(startAngle);
    endAngle = angleToRadians(endAngle);

    _setFillStyle(style);

    _ctx.beginPath();
    _ctx.arc(x, y, radius, startAngle, endAngle);
    _ctx.stroke();
  }

  @override
  void fillCircle(num x, num y, num radius, PStyle style,
      {num startAngle = 0, num endAngle = 360}) {
    x = transform.x(x);
    y = transform.y(y);

    x = canvasX(x);
    y = canvasY(y);
    radius = canvasX(radius);

    startAngle = angleToRadians(startAngle);
    endAngle = angleToRadians(endAngle);

    _setFillStyle(style);

    _ctx.beginPath();
    _ctx.arc(x, y, radius, startAngle, endAngle);
    _ctx.fill();
  }

  @override
  void fillTopDownGradient(
      num x, num y, num width, num height, PColor colorFrom, PColor colorTo) {
    x = transform.x(x);
    y = transform.y(y);

    var grd = _ctx.createLinearGradient(x, y, x, y + height);
    grd.addColorStop(0, colorFrom.toString());
    grd.addColorStop(1, colorTo.toString());

    _setFillStyleGradient(grd);
    _ctx.fillRect(x, y, x + width, y + height);
  }

  @override
  void fillLeftRightGradient(
      num x, num y, num width, num height, PColor colorFrom, PColor colorTo) {
    x = transform.x(x);
    y = transform.y(y);

    var grd = _ctx.createLinearGradient(x, y, x + width, y);
    grd.addColorStop(0, colorFrom.toString());
    grd.addColorStop(1, colorTo.toString());

    _setFillStyleGradient(grd);
    _ctx.fillRect(x, y, x + width, y + height);
  }

  @override
  PTextMetric measureText(String text, PFont font, {num? pixelRatio}) {
    var m = _measureTextImpl(text, font);
    return m;
  }

  PTextMetric _measureTextImpl(String text, PFont font) {
    _setFont(font);

    var m = _ctx.measureText(text);

    var width = m.width ?? 0;

    var height =
        (m.fontBoundingBoxAscent ?? 0) + (m.fontBoundingBoxDescent ?? 0);

    var actualWidth =
        (m.actualBoundingBoxLeft ?? 0) + (m.actualBoundingBoxRight ?? 0);

    var actualHeight =
        (m.actualBoundingBoxAscent ?? 0) + (m.actualBoundingBoxDescent ?? 0);

    return PTextMetric(width, height, actualWidth, actualHeight);
  }

  @override
  void drawText(String text, num x, num y, PFont font, PStyle style) {
    x = transform.x(x);
    y = transform.y(y);

    x = canvasX(x);
    y = canvasY(y);

    _setFont(font);
    _setFillStyle(style);

    _ctx.textBaseline = 'top';
    _ctx.fillText(text, x, y);
  }

  @override
  void strokePath(List path, PStyle style, {bool closePath = false}) {
    if (path.isEmpty) return;

    _setStrokeStyle(style);
    _drawPath(path, closePath);

    _ctx.stroke();
  }

  @override
  void fillPath(List path, PStyle style, {bool closePath = false}) {
    if (path.isEmpty) return;

    _setStrokeStyle(style);
    _drawPath(path, closePath);

    _ctx.fill();
  }

  void _drawPath(List path, bool closePath) {
    _ctx.beginPath();

    if (path is List<num>) {
      for (var i = 0; i < path.length; i += 2) {
        var x = path[i];
        var y = path[i + 1];

        x = transform.x(x);
        y = transform.y(y);

        x = canvasX(x);
        y = canvasY(y);
        _ctx.lineTo(x, y);
      }
    } else if (path is List<Point>) {
      for (var p in path) {
        p = transform.point(p);

        p = canvasPoint(p);
        _ctx.lineTo(p.x, p.y);
      }
    } else {
      for (var i = 0; i < path.length; i++) {
        var e = path[i];
        if (e is num) {
          var x = e;
          var y = path[++i];

          x = transform.x(x);
          y = transform.y(y);

          x = canvasX(x);
          y = canvasY(y);
          _ctx.lineTo(x, y);
        } else if (e is Point) {
          e = transform.point(e);
          e = canvasPoint(e);
          _ctx.lineTo(e.x, e.y);
        } else {
          throw ArgumentError(
              "Can't stroke path point of type: ${e.runtimeType}");
        }
      }
    }

    if (closePath) {
      _ctx.closePath();
    }
  }

  PFont _lastFont = PFont.dummy;
  num _lastFontPixelRatio = 0;

  void _setFont(PFont font) {
    final pr = _pixelRatio;
    if (font.equals(_lastFont) && _lastFontPixelRatio == pr) return;

    var fontCSS = font.toCSS(pixelRatio: pr / devicePixelRatio);

    _ctx.font = fontCSS;
    _lastFont = font;
    _lastFontPixelRatio = pr;
  }

  PStyle _lastStrokeStyle = PStyle.none;

  int _setStrokeStyle(PStyle style) {
    var size = style.size ?? 1;

    if (style.equals(_lastStrokeStyle)) {
      return size;
    }

    _ctx.lineWidth = size;
    _ctx.strokeStyle = style.color.toString();

    _lastStrokeStyle = style;

    return size;
  }

  PStyle _lastFillStyle = PStyle.none;

  void _setFillStyle(PStyle style) {
    if (style.equals(_lastFillStyle)) return;

    var color = style.color ?? PColor.colorGrey;

    _ctx.fillStyle = color.toString();
    _lastFillStyle = style;
  }

  void _setFillStyleGradient(CanvasGradient grd) {
    _ctx.fillStyle = grd;
    _lastFillStyle = PStyle.none;
  }

  void _clearSetStates() {
    _lastFont = PFont.dummy;
    _lastFontPixelRatio = 0;
    _lastFillStyle = _lastStrokeStyle = PStyle.none;
  }

  @override
  PCanvasPixels get pixels {
    var w = _canvas.width ?? 0;
    var h = _canvas.height ?? 0;

    var imageData = _ctx.getImageData(0, 0, w, h);

    var data = imageData.data.buffer.asUint32List(
        imageData.data.offsetInBytes, (imageData.width * imageData.height));

    return PCanvasPixelsABGR.fromPixels(
        imageData.width, imageData.height, data);
  }

  @override
  Future<Uint8List> toPNG() async {
    var blob = await _canvas.toBlob('image/png');

    var reader = FileReader();

    var completer = Completer<Uint8List>();

    reader.onLoadEnd.listen((_) {
      var result = reader.result as List<int>;
      var bytes = result is Uint8List ? result : Uint8List.fromList(result);
      completer.complete(bytes);
    });

    reader.readAsArrayBuffer(blob);

    return completer.future;
  }

  @override
  String toDataUrl() {
    var url = _canvas.toDataUrl('image/png');
    return url;
  }

  @override
  String toString() {
    return 'PCanvasHTML[${width}x$height]$info';
  }
}

class PCanvasHTMLStateExtra extends PCanvasStateExtra {
  final Object? strokeStyle;
  final Object? fillStyle;

  final num globalAlpha;

  final num lineWidth;

  final String lineCap;

  final String lineJoin;

  final num miterLimit;

  //final num lineDashOffset;

  final num shadowOffsetX;

  final num shadowOffsetY;

  final num shadowBlur;

  final String shadowColor;

  final String globalCompositeOperation;

  final String font;

  final String textAlign;

  final String textBaseline;

  final String? direction;

  final bool? imageSmoothingEnabled;

  PCanvasHTMLStateExtra._(CanvasRenderingContext2D ctx)
      : strokeStyle = ctx.strokeStyle,
        fillStyle = ctx.fillStyle,
        globalAlpha = ctx.globalAlpha,
        lineWidth = ctx.lineWidth,
        lineCap = ctx.lineCap,
        lineJoin = ctx.lineJoin,
        miterLimit = ctx.miterLimit,
        //lineDashOffset = ctx.lineDashOffset,
        shadowOffsetX = ctx.shadowOffsetX,
        shadowOffsetY = ctx.shadowOffsetY,
        shadowBlur = ctx.shadowBlur,
        shadowColor = ctx.shadowColor,
        globalCompositeOperation = ctx.globalCompositeOperation,
        font = ctx.font,
        textAlign = ctx.textAlign,
        textBaseline = ctx.textBaseline,
        direction = ctx.direction,
        imageSmoothingEnabled = ctx.imageSmoothingEnabled;

  void setContext(CanvasRenderingContext2D ctx) {
    ctx.strokeStyle = strokeStyle;
    ctx.fillStyle = fillStyle;
    ctx.globalAlpha = globalAlpha;
    ctx.lineWidth = lineWidth;
    ctx.lineCap = lineCap;
    ctx.lineJoin = lineJoin;
    ctx.miterLimit = miterLimit;
    //ctx.lineDashOffset = lineDashOffset;
    ctx.shadowOffsetX = shadowOffsetX;
    ctx.shadowOffsetY = shadowOffsetY;
    ctx.shadowBlur = shadowBlur;
    ctx.shadowColor = shadowColor;
    ctx.globalCompositeOperation = globalCompositeOperation;
    ctx.font = font;
    ctx.textAlign = textAlign;
    ctx.textBaseline = textBaseline;
    ctx.direction = direction;
    ctx.imageSmoothingEnabled = imageSmoothingEnabled;
  }

  Map<String, Object?> get properties => <String, Object?>{
        'strokeStyle': strokeStyle,
        'fillStyle': fillStyle,
        'globalAlpha': globalAlpha,
        'lineWidth': lineWidth,
        'lineCap': lineCap,
        'lineJoin': lineJoin,
        'miterLimit': miterLimit,
        //'lineDashOffset': lineDashOffset,
        'shadowOffsetX': shadowOffsetX,
        'shadowOffsetY': shadowOffsetY,
        'shadowBlur': shadowBlur,
        'shadowColor': shadowColor,
        'globalCompositeOperation': globalCompositeOperation,
        'font': font,
        'textAlign': textAlign,
        'textBaseline': textBaseline,
        'direction': direction,
        'imageSmoothingEnabled': imageSmoothingEnabled,
      };

  @override
  String toString() => 'PCanvasHTMLStateExtra$properties';
}

class _PCanvasImageElement extends PCanvasImage {
  @override
  final String id;

  final ImageElement imageElement;

  _PCanvasImageElement(this.id, this.imageElement) {
    imageElement.id = id;
    load();
  }

  @override
  String get type => 'html:ImageElement';

  @override
  String get src => imageElement.src!;

  @override
  int get width => imageElement.width ?? 0;

  @override
  int get height => imageElement.height ?? 0;

  bool _loaded = false;

  @override
  bool get isLoaded => _loaded;

  Future<bool>? _loading;

  @override
  FutureOr<bool> load() {
    if (_loaded) return true;

    if (imageElement.complete ?? false) {
      _loaded = true;
      return true;
    }

    return _loading ??= imageElement.onLoad.first.then((_) {
      _loaded = true;
      _loading = null;
      return true;
    });
  }
}

extension _MouseEventExtension on MouseEvent {
  PCanvasClickEvent toEvent(String type) {
    var point = offset;
    return PCanvasClickEvent(type, point.x, point.y);
  }
}

extension _KeyboardEventExtension on KeyboardEvent {
  PCanvasKeyEvent toEvent(String type) {
    return PCanvasKeyEvent(
        type, charCode, code, key, ctrlKey, altKey, shiftKey, metaKey);
  }
}

extension PRectangleHTMLExtension on PRectangle {
  Path2D get asPath2D {
    var p = Path2D();
    p.rect(x, y, width, height);
    return p;
  }
}
