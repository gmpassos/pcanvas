import 'dart:convert' as dart_convert;
import 'dart:math' as math;

import 'pcanvas_base.dart';
import 'pcanvas_color.dart';
import 'pcanvas_element.dart';
import 'pcanvas_graphic_svg.dart';
import 'pcanvas_utils.dart' as utils;

/// A [PCanvasElement] that paints a [Graphic].
class PGraphic extends PCanvasElement2DBase {
  Graphic graphic;

  bool clip;

  PColor? backgroundColor;

  PColor? borderColor;
  int borderSize;

  PGraphic(this.graphic,
      {super.zIndex,
      super.pos,
      this.clip = true,
      this.backgroundColor,
      this.borderColor,
      this.borderSize = 1})
      : super(dimension: PDimension(graphic.width, graphic.height));

  @override
  String get typeName => 'PGraphic';

  @override
  PRectangle get boundingBox {
    final position = this.position.resolve();
    return PRectangle(position.x, position.y, graphic.width, graphic.height);
  }

  @override
  PRectangle getPaintBoundingBox(PCanvas pCanvas) =>
      PRectangle(position.x, position.y, graphic.width, graphic.height);

  @override
  void paint(PCanvas pCanvas) {
    var prevState = pCanvas.saveState();

    final prevT = pCanvas.transform;

    final boundingBox = this.boundingBox;
    final boundingBoxTransformed = boundingBox.transform(prevT);

    var t =
        PcanvasTransform(translateX: boundingBox.x, translateY: boundingBox.y);

    try {
      pCanvas.subTransform = t;
      PRectangle? prevClip;
      if (clip) {
        prevClip = pCanvas.clip;
        pCanvas.subClip = boundingBoxTransformed;
      }

      final backgroundColor = this.backgroundColor;
      if (backgroundColor != null && !backgroundColor.isFullyTransparent) {
        // `pCanvas` already translated by `t`.
        pCanvas.fillRect(0, 0, boundingBox.width, boundingBox.height,
            PStyle(color: backgroundColor));
      }

      graphic.paint(pCanvas, GraphicContext.defaultContext);

      if (clip) {
        pCanvas.clip = prevClip;
      }

      final borderColor = this.borderColor;
      if (borderColor != null && borderSize > 0) {
        // `pCanvas` already translated by `t`.
        pCanvas.strokeRect(0, 0, boundingBox.width, boundingBox.height,
            PStyle(color: borderColor, size: borderSize));
      }
    } finally {
      pCanvas.restoreState(expectedState: prevState);
    }
  }

  @override
  String get className => 'PGraphic';

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'clip': clip,
        if (backgroundColor != null)
          'backgroundColor': backgroundColor?.toJson(),
        if (borderColor != null) 'borderColor': borderColor?.toJson(),
        'borderSize': borderSize,
        'graphic': graphic.toJson(),
      };

  factory PGraphic.fromJson(Map<String, dynamic> j) => PGraphic(
        Graphic.fromJson(j['graphic']),
        zIndex: j.containsKey('zIndex') ? utils.parseInt(j['zIndex']) : null,
        pos: Position.fromJson(j['position']),
        clip: bool.parse(j['clip']),
        backgroundColor: PColor.fromJson(j['backgroundColor']),
        borderColor: PColor.fromJson(j['borderColor']),
        borderSize: utils.parseInt(j['borderSize']),
      );
}

abstract class GShape implements WithJson {
  static List<GShape> listFrom(List<Map<String, dynamic>>? jsonList) {
    if (jsonList == null || jsonList.isEmpty) return [];
    var list = jsonList.map(GShape.from).nonNulls.toList();
    return list;
  }

  static GShape? from(Map<String, dynamic>? json) {
    if (json == null) return null;

    var shape = json['shape'];

    switch (shape) {
      case 'panel':
        return GPanel.fromJson(json);
      case 'rectangle':
        return GRectangle.fromJson(json);
      case 'line':
        return GLine.fromJson(json);
      case 'svg':
        return GSVG.fromJson(json);
      case 'svg_path':
        return GSVGPath.fromJson(json);
      default:
        return null;
    }
  }

  String get shapeName;

  PRectangle get shapeBoundingBox;

  bool containsPoint(Point p) => shapeBoundingBox.containsPoint(p);

  void translate(Point p);

  /// Scaled version of this [GShape].
  GShape scaled(double scale);

  List<GShape> selectShapesAtPoint(Point p, {bool recursive = false}) {
    if (shapeBoundingBox.containsPoint(p)) {
      return [this];
    } else {
      return [];
    }
  }

  GraphicContext resolveGraphicContext([GraphicContext? parentContext]) =>
      parentContext ?? GraphicContext.defaultContext;

  void paint(PCanvas pCanvas, [GraphicContext? graphicContext]);

  @override
  Map<String, dynamic> toJson();

  String toJsonEncoded({bool pretty = false}) {
    var json = toJson();
    if (pretty) {
      return dart_convert.JsonEncoder.withIndent('  ').convert(json);
    } else {
      return dart_convert.json.encode(json);
    }
  }
}

class GraphicContext {
  static final GraphicContext defaultContext = GraphicContext();

  final Position position;

  final PColor color;
  final PColor backgroundColor;

  final num scaleX;

  final num scaleY;

  GraphicContext(
      {Position? position,
      PColor? color,
      PColor? backgroundColor,
      num? scaleX,
      num? scaleY})
      : position = position ?? Point.pZero,
        color = color ?? PColor.colorBlack,
        backgroundColor = backgroundColor ?? PColor.colorBlack,
        scaleX = scaleX ?? 1,
        scaleY = scaleY ?? 1;

  GraphicContext copyWith(
          {Position? position,
          PColor? color,
          PColor? backgroundColor,
          num? scaleX,
          num? scaleY}) =>
      GraphicContext(
          position: position ?? this.position,
          color: color ?? this.color,
          backgroundColor: backgroundColor ?? this.backgroundColor,
          scaleX: scaleX ?? this.scaleX,
          scaleY: scaleY ?? this.scaleY);
}

/// A graphic built by simple shapes ([GShape]).
class Graphic extends GShape {
  int width;
  int height;

  List<GShape> shapes;

  Graphic(this.width, this.height, this.shapes);

  @override
  String get shapeName => 'graphic';

  @override
  PRectangle get shapeBoundingBox => PRectangle(0, 0, width, height);

  @override
  void translate(Point p) {}

  @override
  List<GShape> selectShapesAtPoint(Point p, {bool recursive = false}) {
    final shapeBoundingBox = this.shapeBoundingBox;
    if (shapeBoundingBox.containsPoint(p)) {
      if (recursive) {
        final p2 = p.decrement(shapeBoundingBox);
        var subShapes =
            shapes.selectShapesAtPoint(p2, recursive: true, growable: false);
        return [this, ...subShapes];
      } else {
        return [this];
      }
    } else {
      return [];
    }
  }

  @override
  Graphic scaled(double scale) =>
      Graphic(width.scaled(scale), height.scaled(scale), shapes.scaled(scale));

  @override
  void paint(PCanvas pCanvas, [GraphicContext? graphicContext]) {
    graphicContext = resolveGraphicContext(graphicContext);

    for (var e in shapes) {
      e.paint(pCanvas, graphicContext);
    }
  }

  @override
  String get className => 'Graphic';

  @override
  Map<String, dynamic> toJson() => {
        "shape": shapeName,
        "width": width,
        "height": height,
        "shapes": shapes.toJson(),
      };

  factory Graphic.fromJson(Map<String, dynamic> json) {
    return Graphic(
      utils.parseInt(json["width"]),
      utils.parseInt(json["height"]),
      GShape.listFrom(json["shapes"] ??
          GShape.listFrom(json["elements"]) ??
          json["content"]),
    );
  }
}

extension ListGShapeExtension<G extends GShape> on List<G> {
  List<G> scaled(double scale) => map((e) => e.scaled(scale) as G).toList();

  List<GShape> selectShapesAtPoint(Point p,
          {bool recursive = false, bool growable = true}) =>
      expand((e) => e.selectShapesAtPoint(p, recursive: recursive))
          .toList(growable: growable);

  List<Map<String, dynamic>> toJson() => map((e) => e.toJson()).toList();
}

/// A panel shape that can have sub-shapes ([elements]).
class GPanel extends GShape {
  int x;
  int y;

  int width;
  int height;

  List<GShape> elements;

  PColor? backgroundColor;

  GPanel(this.x, this.y, this.width, this.height, this.elements,
      {this.backgroundColor});

  @override
  String get shapeName => 'panel';

  @override
  PRectangle get shapeBoundingBox => PRectangle(x, y, width, height);

  @override
  void translate(Point p) {
    x += p.x.toInt();
    y += p.y.toInt();
  }

  @override
  GPanel scaled(double scale) => GPanel(x.scaled(scale), y.scaled(scale),
      width.scaled(scale), height.scaled(scale), elements.scaled(scale),
      backgroundColor: backgroundColor);

  @override
  List<GShape> selectShapesAtPoint(Point p, {bool recursive = false}) {
    final shapeBoundingBox = this.shapeBoundingBox;
    if (shapeBoundingBox.containsPoint(p)) {
      if (recursive) {
        final p2 = p.decrement(shapeBoundingBox);
        var subShapes =
            elements.selectShapesAtPoint(p2, recursive: true, growable: false);
        return [this, ...subShapes];
      } else {
        return [this];
      }
    } else {
      return [];
    }
  }

  @override
  GraphicContext resolveGraphicContext([GraphicContext? parentContext]) {
    var graphicContext = super.resolveGraphicContext(parentContext);
    return graphicContext.copyWith(
      position: graphicContext.position.incrementXY(x, y),
      backgroundColor: backgroundColor,
    );
  }

  @override
  void paint(PCanvas pCanvas, [GraphicContext? graphicContext]) {
    graphicContext = resolveGraphicContext(graphicContext);

    var x = graphicContext.position.x;
    var y = graphicContext.position.y;

    if (backgroundColor != null) {
      pCanvas.fillRect(
          x, y, width, height, PStyle(color: graphicContext.backgroundColor));
    }

    for (var e in elements) {
      e.paint(pCanvas, graphicContext);
    }
  }

  factory GPanel.fromJson(Map<String, dynamic> json) {
    return GPanel(
      utils.parseInt(json["x"]),
      utils.parseInt(json["y"]),
      utils.parseInt(json["width"]),
      utils.parseInt(json["height"]),
      GShape.listFrom(json["elements"] ?? json["shapes"] ?? json["content"]),
      backgroundColor: PColor.from(json["backgroundColor"]),
    );
  }

  @override
  String get className => 'GPanel';

  @override
  Map<String, dynamic> toJson() {
    return {
      "shape": shapeName,
      "x": x,
      "y": y,
      "width": width,
      "height": height,
      "elements": elements.toJson(),
      if (backgroundColor != null)
        "backgroundColor": backgroundColor.toString(),
    };
  }
}

/// A simple rectangle shape.
class GRectangle extends GShape {
  int x;
  int y;

  int width;
  int height;

  PColor? color;
  int? strokeSize;

  PColor? backgroundColor;

  GRectangle(this.x, this.y, this.width, this.height,
      {this.strokeSize, this.color, this.backgroundColor});

  @override
  String get shapeName => 'rectangle';

  @override
  PRectangle get shapeBoundingBox => PRectangle(x, y, width, height);

  @override
  void translate(Point p) {
    x += p.x.toInt();
    y += p.y.toInt();
  }

  @override
  GRectangle scaled(double scale) => GRectangle(x.scaled(scale),
      y.scaled(scale), width.scaled(scale), height.scaled(scale),
      strokeSize: strokeSize?.scaled(scale),
      color: color,
      backgroundColor: backgroundColor);

  @override
  GraphicContext resolveGraphicContext([GraphicContext? parentContext]) => super
      .resolveGraphicContext(parentContext)
      .copyWith(color: color, backgroundColor: backgroundColor);

  @override
  void paint(PCanvas pCanvas, [GraphicContext? graphicContext]) {
    graphicContext = resolveGraphicContext(graphicContext);

    var x = graphicContext.position.x + this.x;
    var y = graphicContext.position.y + this.y;

    pCanvas.fillRect(
        x, y, width, height, PStyle(color: graphicContext.backgroundColor));

    var strokeSize = this.strokeSize;
    if (strokeSize != null) {
      pCanvas.strokeRect(
          x, y, width, height, PStyle(color: graphicContext.color));
    }
  }

  factory GRectangle.fromJson(Map<String, dynamic> json) => GRectangle(
        utils.parseInt(json["x"]),
        utils.parseInt(json["y"]),
        utils.parseInt(json["width"]),
        utils.parseInt(json["height"]),
        color: PColor.from(json["color"]),
        strokeSize: utils.tryParseInt(json["strokeSize"]),
        backgroundColor: PColor.from(json["backgroundColor"]),
      );

  @override
  String get className => 'GRectangle';

  @override
  Map<String, dynamic> toJson() => {
        "shape": shapeName,
        "x": x,
        "y": y,
        "width": width,
        "height": height,
        if (color != null) "color": color.toString(),
        if (strokeSize != null) 'strokeSize': strokeSize,
        if (backgroundColor != null)
          "backgroundColor": backgroundColor.toString(),
      };
}

class GLine extends GShape {
  int x1;
  int y1;

  int x2;
  int y2;

  int size;

  PColor? color;

  GLine(this.x1, this.y1, this.x2, this.y2, {this.size = 1, this.color});

  @override
  String get shapeName => 'line';

  @override
  PRectangle get shapeBoundingBox {
    var x1 = math.min(this.x1, this.x2);
    var x2 = math.max(this.x1, this.x2);

    var y1 = math.min(this.y1, this.y2);
    var y2 = math.max(this.y1, this.y2);

    var w = x2 - x1;
    var h = y2 - y1;

    return PRectangle(x1, y1, w, h);
  }

  @override
  void translate(Point p) {
    var x1 = math.min(this.x1, this.x2);
    var x2 = math.max(this.x1, this.x2);

    var y1 = math.min(this.y1, this.y2);
    var y2 = math.max(this.y1, this.y2);

    var x = p.x.toInt();
    var y = p.y.toInt();

    x1 += x;
    x2 += x;

    y1 += y;
    y2 += y;

    this.x1 = x1;
    this.x2 = x2;

    this.y1 = y1;
    this.y2 = y2;
  }

  @override
  GLine scaled(double scale) => GLine(
      x1.scaled(scale), y1.scaled(scale), x2.scaled(scale), y2.scaled(scale),
      size: size.scaled(scale), color: color);

  @override
  GraphicContext resolveGraphicContext([GraphicContext? parentContext]) =>
      super.resolveGraphicContext(parentContext).copyWith(color: color);

  @override
  void paint(PCanvas pCanvas, [GraphicContext? graphicContext]) {
    graphicContext = resolveGraphicContext(graphicContext);

    var x1 = graphicContext.position.x + this.x1;
    var y1 = graphicContext.position.y + this.y1;

    var x2 = graphicContext.position.x + this.x2;
    var y2 = graphicContext.position.y + this.y2;

    pCanvas.strokePath(
        <num>[x1, y1, x2, y2], PStyle(color: graphicContext.color, size: size),
        closePath: false);
  }

  factory GLine.fromJson(Map<String, dynamic> json) => GLine(
        utils.parseInt(json["x1"]),
        utils.parseInt(json["y1"]),
        utils.parseInt(json["x2"]),
        utils.parseInt(json["y2"]),
        size: utils.parseInt(json["size"]),
        color: PColor.from(json["color"]),
      );

  @override
  String get className => 'GLine';

  @override
  Map<String, dynamic> toJson() => {
        "shape": shapeName,
        "x1": x1,
        "y1": y1,
        "x2": x2,
        "y2": y2,
        "size": size,
        if (color != null) "color": color.toString(),
      };
}

/// A path shape.
class GPath extends GShape {
  List<Object> pathPoints;

  PColor? strokeColor;
  int? strokeSize;
  PColor? fillColor;

  bool closePath;

  GPath(this.pathPoints,
      {this.strokeColor,
      this.strokeSize,
      this.fillColor,
      this.closePath = true});

  @override
  String get shapeName => 'path';

  @override
  PRectangle get shapeBoundingBox {
    List<Point> ps = [];

    var pathPoints2 = pathPoints;
    final length = pathPoints2.length;

    for (var i = 0; i < length; ++i) {
      var e = pathPoints2[i];

      if (e is num) {
        var x1 = e;
        var y1 = pathPoints2[++i] as num;

        ps.add(Point(x1, y1));
      } else if (e is Point) {
        ps.add(e);
      } else if (e is List<num>) {
        var cubic = e.toList(growable: false);
        assert(cubic.length == 6);

        ps.add(Point(cubic[0], cubic[1]));
        ps.add(Point(cubic[2], cubic[3]));
        ps.add(Point(cubic[4], cubic[5]));
      }
    }

    var boundingBox =
        ps.boundingBox ?? (throw StateError("Empty `pathPoints`"));
    return boundingBox;
  }

  @override
  void translate(Point p) {
    var x = p.x.toInt();
    var y = p.y.toInt();

    var pathPoints2 = pathPoints;
    final length = pathPoints2.length;

    for (var i = 0; i < length; ++i) {
      var e = pathPoints2[i];

      if (e is num) {
        var x1 = e;
        var y1 = pathPoints2[i + 1] as num;

        pathPoints2[i] = x1 + x;
        pathPoints2[++i] = y1 + y;
      } else if (e is Point) {
        pathPoints2[i] = e.incrementXY(x, y);
      } else if (e is List<num>) {
        var cubic = e.toList(growable: false);
        assert(cubic.length == 6);

        var x1 = cubic[0];
        var y1 = cubic[1];

        var x2 = cubic[2];
        var y2 = cubic[3];

        var x3 = cubic[4];
        var y3 = cubic[5];

        cubic[0] = x1 + x;
        cubic[1] = y1 + y;

        cubic[2] = x2 + x;
        cubic[3] = y2 + y;

        cubic[4] = x3 + x;
        cubic[5] = y3 + y;

        pathPoints2[i] = cubic;
      }
    }
  }

  @override
  GPath scaled(double scale) {
    var pathPoints2 = pathPoints.toList();
    final length = pathPoints2.length;

    for (var i = 0; i < length; ++i) {
      var e = pathPoints2[i];

      if (e is num) {
        var x1 = e;
        var y1 = pathPoints2[i + 1] as num;

        pathPoints2[i] = x1 * scale;
        pathPoints2[++i] = y1 * scale;
      } else if (e is Point) {
        pathPoints2[i] = e.scale(scale, scale);
      } else if (e is List<num>) {
        var cubic = e.toList(growable: false);
        assert(cubic.length == 6);

        var x1 = cubic[0];
        var y1 = cubic[1];

        var x2 = cubic[2];
        var y2 = cubic[3];

        var x3 = cubic[4];
        var y3 = cubic[5];

        cubic[0] = x1 * scale;
        cubic[1] = y1 * scale;

        cubic[2] = x2 * scale;
        cubic[3] = y2 * scale;

        cubic[4] = x3 * scale;
        cubic[5] = y3 * scale;

        pathPoints2[i] = cubic;
      }
    }

    return GPath(pathPoints2,
        strokeSize: strokeSize?.scaled(scale),
        strokeColor: strokeColor,
        fillColor: fillColor,
        closePath: closePath);
  }

  @override
  GraphicContext resolveGraphicContext([GraphicContext? parentContext]) => super
      .resolveGraphicContext(parentContext)
      .copyWith(color: strokeColor, backgroundColor: fillColor);

  @override
  void paint(PCanvas pCanvas, [GraphicContext? graphicContext]) {
    graphicContext = resolveGraphicContext(graphicContext);

    var position = graphicContext.position;
    var x = position.x;
    var y = position.y;

    var scaleX = graphicContext.scaleX;
    var scaleY = graphicContext.scaleY;

    var pathPoints2 = pathPoints.toList(growable: false);
    final length = pathPoints2.length;

    for (var i = 0; i < length; ++i) {
      var e = pathPoints2[i];

      if (e is num) {
        var x1 = e;
        pathPoints2[i] = x + (x1 * scaleX);

        var y1 = pathPoints2[++i] as num;
        pathPoints2[i] = y + (y1 * scaleY);
      } else if (e is Point) {
        pathPoints2[i] = e.scale(scaleX, scaleY).incrementXY(x, y);
      } else if (e is List<num>) {
        var cubic = e.toList(growable: false);
        assert(cubic.length == 6);

        cubic[0] *= scaleX;
        cubic[1] *= scaleY;

        cubic[2] *= scaleX;
        cubic[3] *= scaleY;

        cubic[4] *= scaleX;
        cubic[5] *= scaleY;

        cubic[0] += x;
        cubic[1] += y;

        cubic[2] += x;
        cubic[3] += y;

        cubic[4] += x;
        cubic[5] += y;

        pathPoints2[i] = cubic;
      }
    }

    var backgroundColor = graphicContext.backgroundColor;
    if (!backgroundColor.isFullyTransparent) {
      pCanvas.fillPath(pathPoints2, PStyle(color: backgroundColor),
          closePath: closePath);
    }

    var color = graphicContext.color;
    if (!color.isFullyTransparent) {
      pCanvas.strokePath(pathPoints2, PStyle(color: color),
          closePath: closePath);
    }
  }

  @override
  String get className => 'GPath';

  @override
  Map<String, dynamic> toJson() => {
        'shape': 'path',
        'points': pathPoints.toList(),
        if (strokeColor != null) 'strokeColor': strokeColor.toString(),
        if (strokeSize != null) 'strokeSize': strokeSize.toString(),
        if (fillColor != null) 'fillColor': fillColor.toString(),
        'closed': closePath,
      };
}

extension on int {
  int scaled(double scale) => (this * scale).round();
}
