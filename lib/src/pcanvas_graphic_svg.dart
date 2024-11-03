import 'package:path_parsing/path_parsing.dart';
import 'package:xml/xml.dart';

import 'pcanvas_base.dart';
import 'pcanvas_color.dart';
import 'pcanvas_graphic.dart';
import 'pcanvas_utils.dart' as utils;

/// A SVG shape.
///
/// Supports basic SVG operations (including `path` tags).
class GSVG extends GPanel {
  PColor? strokeColor;
  int? strokeSize;
  PColor? fillColor;

  num? scaleX;
  num? scaleY;

  GSVG(super.x, super.y, super.width, super.height, super.elements,
      {this.strokeColor,
      this.strokeSize,
      this.fillColor,
      this.scaleX,
      this.scaleY});

  factory GSVG.fromSVG(int x, int y, int width, int height, String svg,
      {PColor? strokeColor,
      int? strokeSize,
      PColor? fillColor,
      num? scaleX,
      num? scaleY}) {
    var returnViewBox = <_SVGViewBox?>[null];

    var elements = _parseSVG(svg,
        strokeColor: strokeColor,
        strokeSize: strokeSize,
        fillColor: fillColor,
        returnViewBox: returnViewBox);

    var viewBox = returnViewBox[0];

    viewBox = viewBox?.copyWith(svgWidth: width, svgHeight: height);

    return GSVG(
        x,
        y,
        width,
        height,
        strokeColor: strokeColor,
        strokeSize: strokeSize,
        fillColor: fillColor,
        scaleX: scaleX ?? viewBox?.scaleX,
        scaleY: scaleY ?? viewBox?.scaleY,
        elements);
  }

  @override
  GraphicContext resolveGraphicContext([GraphicContext? parentContext]) => super
      .resolveGraphicContext(parentContext)
      .copyWith(scaleX: scaleX, scaleY: scaleY);

  static List<GShape> _parseSVG(String svg,
      {PColor? strokeColor,
      int? strokeSize,
      PColor? fillColor,
      List<_SVGViewBox?>? returnViewBox}) {
    final xml = XmlDocument.parse(svg);

    returnViewBox ??= [null];

    var elements = xml.descendantElements
        .expand((e) => _resolveShapes(
            e, strokeColor, strokeSize, fillColor, returnViewBox!))
        .nonNulls
        .toList();

    return elements;
  }

  static List<GShape> _resolveShapes(XmlNode node, PColor? strokeColor,
      int? strokeSize, PColor? fillColor, List<_SVGViewBox?> returnViewBox) {
    if (node is! XmlElement) {
      return [];
    }

    var props = _SVGProperties.fromXmlElement(node,
        strokeColor: strokeColor, strokeSize: strokeSize, fillColor: fillColor);

    switch (node.localName) {
      case 'svg':
        {
          var svgWidth = int.tryParse(node.getAttribute('width') ?? '');
          var svgHeight = int.tryParse(node.getAttribute('height') ?? '');

          var viewBox = _SVGViewBox.parse(
              svgWidth, svgHeight, node.getAttribute('viewBox'));

          returnViewBox[0] = viewBox;

          return node.descendantElements
              .expand((e) => _resolveShapes(
                  e,
                  props?.strokeColor ?? strokeColor,
                  props?.strokeSize ?? strokeSize,
                  props?.fillColor ?? fillColor,
                  returnViewBox))
              .toList();
        }
      case 'path':
        {
          var paths = node.getAttribute('d');

          return [
            if (paths != null)
              GSVGPath.fromSVGPaths(paths,
                  strokeColor: props?.strokeColor,
                  strokeSize: props?.strokeSize,
                  fillColor: props?.fillColor)
          ];
        }
      case 'line':
        {
          var x1 = int.tryParse(node.getAttribute('x1') ?? '');
          var y1 = int.tryParse(node.getAttribute('y1') ?? '');

          var x2 = int.tryParse(node.getAttribute('x2') ?? '');
          var y2 = int.tryParse(node.getAttribute('y2') ?? '');

          return [
            if (x1 != null && y1 != null && x2 != null && y2 != null)
              GLine(x1, y1, x2, y2,
                  color: props?.strokeColor, size: props?.strokeSize ?? 1)
          ];
        }
      case 'rect':
        {
          var x = int.tryParse(node.getAttribute('x') ?? '');
          var y = int.tryParse(node.getAttribute('y') ?? '');

          var w = int.tryParse(node.getAttribute('width') ?? '');
          var h = int.tryParse(node.getAttribute('height') ?? '');

          return [
            if (x != null && y != null && w != null && h != null)
              GRectangle(x, y, w, h,
                  color: props?.strokeColor,
                  strokeSize: props?.strokeSize,
                  backgroundColor: props?.fillColor)
          ];
        }
      default:
        return [];
    }
  }

  @override
  String get className => 'GSVG';

  @override
  String get shapeName => 'svg';

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        if (strokeColor != null) 'strokeColor': strokeColor,
        if (strokeSize != null) 'strokeSize': strokeSize,
        if (fillColor != null) 'fillColor': fillColor,
        if (scaleX != null) 'scaleX': scaleX,
        if (scaleX != null) 'scaleY': scaleY,
      };

  factory GSVG.fromJson(Map<String, dynamic> json) {
    return GSVG(
      utils.parseInt(json["x"]),
      utils.parseInt(json["y"]),
      utils.parseInt(json["width"]),
      utils.parseInt(json["height"]),
      GShape.listFrom(json['elements'] as List<Map<String, dynamic>>),
      strokeColor: json.containsKey('strokeColor')
          ? PColor.from(json['strokeColor'])
          : null,
      strokeSize: json.containsKey('strokeSize')
          ? utils.parseInt(json['strokeSize'])
          : null,
      fillColor:
          json.containsKey('fillColor') ? PColor.from(json['fillColor']) : null,
      scaleX:
          json.containsKey('scaleX') ? utils.parseInt(json['scaleX']) : null,
      scaleY:
          json.containsKey('scaleY') ? utils.parseInt(json['scaleY']) : null,
    );
  }
}

class GSVGPath extends GShape {
  late final List<GPath> _paths;

  PColor? strokeColor;
  int? strokeSize;
  PColor? fillColor;

  GSVGPath(List<GPath> paths,
      {this.strokeColor, this.strokeSize, this.fillColor})
      : _paths = paths;

  GSVGPath.fromSVGPaths(String svgPaths,
      {this.strokeColor, this.strokeSize, this.fillColor})
      : _paths = _SVGPathOperations(svgPaths).toGPaths(
            strokeColor: strokeColor,
            strokeSize: strokeSize ?? 1,
            fillColor: fillColor);

  @override
  String get shapeName => 'svg_path';

  @override
  PRectangle get shapeBoundingBox {
    var ps = _paths
        .map((e) => e.shapeBoundingBox)
        .expand((r) => [Point(r.x, r.y), Point(r.x + r.width, r.y + r.height)])
        .toList();

    var boundingBox = ps.boundingBox ?? (throw StateError("Empty `_paths`"));
    return boundingBox;
  }

  @override
  void translate(Point p) {
    for (var path in _paths) {
      path.translate(p);
    }
  }

  @override
  GSVGPath scaled(double scale) => GSVGPath(_paths.scaled(scale),
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeSize: strokeSize?.scaled(scale));

  @override
  GraphicContext resolveGraphicContext([GraphicContext? parentContext]) => super
      .resolveGraphicContext(parentContext)
      .copyWith(color: strokeColor, backgroundColor: fillColor);

  @override
  void paint(PCanvas pCanvas, [GraphicContext? graphicContext]) {
    for (var p in _paths) {
      p.paint(pCanvas, graphicContext);
    }
  }

  @override
  String get className => 'GSVGPath';

  @override
  Map<String, dynamic> toJson() => {
        'shape': 'path',
        if (strokeColor != null) 'strokeColor': strokeColor.toString(),
        if (strokeSize != null) 'strokeSize': strokeSize,
        if (fillColor != null) 'fillColor': fillColor.toString(),
        'paths': _paths.map((e) => e.toJson()).toList(),
      };

  factory GSVGPath.fromJson(Map<String, dynamic> json) {
    return GSVGPath(
      (json['paths'] as List)
          .map((l) => GShape.from(l))
          .whereType<GPath>()
          .toList(),
      strokeColor: json.containsKey('strokeColor')
          ? PColor.from(json['strokeColor'])
          : null,
      strokeSize: json.containsKey('strokeSize')
          ? utils.parseInt(json['strokeSize'])
          : null,
      fillColor:
          json.containsKey('fillColor') ? PColor.from(json['fillColor']) : null,
    );
  }
}

class _SVGPathOperations implements PathProxy {
  final List<num> _operations = <num>[];

  _SVGPathOperations(String svgPaths) {
    writeSvgPathDataToPath(svgPaths, this);
  }

  @override
  void moveTo(double x, double y) {
    _operations.add(1);
    _operations.add(x);
    _operations.add(y);
  }

  @override
  void lineTo(double x, double y) {
    _operations.add(2);
    _operations.add(x);
    _operations.add(y);
  }

  @override
  void cubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    _operations.add(3);
    _operations.add(x1);
    _operations.add(y1);
    _operations.add(x2);
    _operations.add(y2);
    _operations.add(x3);
    _operations.add(y3);
  }

  @override
  void close() {
    _operations.add(0);
  }

  List<GPath> toGPaths(
      {PColor? strokeColor, int? strokeSize, PColor? fillColor}) {
    var gPaths = <GPath>[];

    var operations = _operations;
    final length = operations.length;

    var points = <Object>[];

    for (var i = 0; i < length; ++i) {
      var cmp = operations[i];

      switch (cmp) {
        case 0:
          {
            if (points.isNotEmpty) {
              gPaths.add(GPath(points,
                  strokeColor: strokeColor,
                  strokeSize: strokeSize,
                  fillColor: fillColor,
                  closePath: true));
              points = [];
            }
            break;
          }
        case 1:
          {
            if (points.isNotEmpty) {
              gPaths.add(GPath(points,
                  strokeColor: strokeColor,
                  strokeSize: strokeSize,
                  fillColor: fillColor));
              points = [];
            }

            var x = operations[++i];
            var y = operations[++i];

            points.add(x);
            points.add(y);
            break;
          }
        case 2:
          {
            var x = operations[++i];
            var y = operations[++i];

            points.add(x);
            points.add(y);
            break;
          }
        case 3:
          {
            var x1 = operations[++i];
            var y1 = operations[++i];
            var x2 = operations[++i];
            var y2 = operations[++i];
            var x3 = operations[++i];
            var y3 = operations[++i];

            points.add([x1, y1, x2, y2, x3, y3]);
            break;
          }
        default:
          throw StateError("Unknown cmd ID: $cmp");
      }
    }

    if (points.isNotEmpty) {
      gPaths.add(GPath(points,
          strokeColor: strokeColor,
          strokeSize: strokeSize,
          fillColor: fillColor));
    }

    return gPaths;
  }
}

class _SVGProperties {
  PColor? fillColor;
  PColor? strokeColor;
  int? strokeSize;

  _SVGProperties(this.fillColor, this.strokeColor, this.strokeSize);

  static _SVGProperties? fromXmlElement(XmlElement node,
      {PColor? strokeColor, int? strokeSize, PColor? fillColor}) {
    var style = node.getAttribute('style');

    Map<String, String> styleProps;
    if (style != null) {
      styleProps = Map.fromEntries(style.split(';').map((e) {
        var parts = e.split(':');
        var k = parts[0].trim();
        var v = parts[1].trim();
        return MapEntry(k, v);
      }));
    } else {
      styleProps = {};
    }

    var fill = node.getAttribute('fill') ?? styleProps['fill'];

    var stroke = node.getAttribute('stroke') ?? styleProps['stroke'];
    var strokeWidth =
        node.getAttribute('stroke-width') ?? styleProps['stroke-width'];

    var fillColor2 = _resolveColor(fill, fillColor);
    var strokeColor2 = _resolveColor(stroke, strokeColor);
    var strokeSize2 = num.tryParse(strokeWidth ?? '')?.toInt() ?? strokeSize;

    return fillColor2 != null || strokeColor2 != null || strokeSize2 != null
        ? _SVGProperties(fillColor2, strokeColor2, strokeSize2)
        : null;
  }

  static PColor? _resolveColor(String? value, PColor? def) {
    if (value == null) return def;
    value = value.trim();
    if (value.isEmpty) return def;

    if (value == 'none') return PColor.colorTransparent;

    if (value == 'currentcolor') return def;

    return PColor.from(value) ?? def;
  }
}

class _SVGViewBox {
  int svgWidth;
  int svgHeight;

  int x;
  int y;
  int width;
  int height;

  double scaleX;
  double scaleY;

  _SVGViewBox(
      this.svgWidth, this.svgHeight, this.x, this.y, this.width, this.height)
      : scaleX = width > 0 ? svgWidth / width : 1,
        scaleY = height > 0 ? svgHeight / height : 1;

  static _SVGViewBox? parse(int? svgWidth, int? svgHeight, String? viewBox) {
    if (viewBox == null) return null;
    viewBox = viewBox.trim();
    if (viewBox.isEmpty) return null;

    var parts = viewBox
        .split(RegExp(r'\s*,\s*|\s+'))
        .map((e) => e.trim())
        .toList(growable: false);

    if (parts.length < 4) {
      if (svgWidth == null || svgHeight == null) return null;
      return _SVGViewBox(svgWidth, svgHeight, 0, 0, svgWidth, svgHeight);
    }

    var x = int.tryParse(parts[0]);
    var y = int.tryParse(parts[1]);
    var w = int.tryParse(parts[2]);
    var h = int.tryParse(parts[3]);

    if (x == null || y == null || w == null || h == null) {
      if (svgWidth == null || svgHeight == null) return null;
      return _SVGViewBox(svgWidth, svgHeight, 0, 0, svgWidth, svgHeight);
    }

    return _SVGViewBox(svgWidth ?? w, svgHeight ?? h, x, y, w, h);
  }

  _SVGViewBox copyWith({int? svgWidth, int? svgHeight}) => _SVGViewBox(
      svgWidth ?? this.svgWidth,
      svgHeight ?? this.svgHeight,
      x,
      y,
      width,
      height);

  @override
  String toString() {
    return '_SVGViewBox{svg: $svgWidth x $svgHeight ; viewBox: $x, $y , $width x $height}';
  }
}

extension on int {
  int scaled(double scale) => (this * scale).round();
}
