import 'dart:collection';

import 'pcanvas_base.dart';

/// A base class for [PCanvas] elements.
abstract class PCanvasElement {
  /// The ID of this element.
  String? id;

  PCanvasElement({this.id});

  /// The bounding box of this element.
  PRectangle get boundingBox;

  /// The dimension this element.
  PDimension get dimension => boundingBox;

  /// The bounding box of the painted area of this element.
  PRectangle getPaintBoundingBox(PCanvas pCanvas);

  /// The Z index of this element.
  int? get zIndex;

  /// The paint operation of this element.
  void paint(PCanvas pCanvas);
}

/// Mixin for a class that is a container for [PCanvasElement].
mixin PCanvasElementContainer<E extends PCanvasElement> {
  /// All the [PCanvasElement]s of this instance.
  UnmodifiableListView<E> get elements;

  /// Returns `true` if this isntances has [elements].
  bool get hasElements;

  /// Clears the [elements] of this instance.
  void clearElements();

  /// Adds an [element] to this instances.
  void addElement(E element);

  /// Removes [element] from this instance.
  bool removeElement(E element);

  /// Adds all the entries in [elements] to this instances.
  void addAllElements(Iterable<E> elements) {
    for (var e in elements) {
      addElement(e);
    }
  }

  /// Removes all entries in [elements] from this instances.
  void removeAllElements(Iterable<E> elements) {
    for (var e in elements) {
      removeElement(e);
    }
  }

  /// Returns a list of [PCanvasElement] of type [T] with a matching [id].
  List<T> selectElementByID<T extends PCanvasElement>(String? id,
      {bool recursive = false}) {
    var elements = this.elements;

    var sel = elements.whereType<T>().where((e) => e.id == id).toList();

    if (!recursive) {
      return sel;
    }

    var subList = elements
        .whereType<PCanvasElementContainer>()
        .expand((e) => e.selectElementByID<T>(id, recursive: true))
        .toList();

    return [...sel, ...subList];
  }

  /// Returns a list of [PCanvasElement] of type [T].
  List<T> selectElementByType<T extends PCanvasElement>(
      {bool recursive = false}) {
    var elements = this.elements;

    var sel = elements.whereType<T>().toList();

    if (!recursive) {
      return sel;
    }

    var subList = elements
        .whereType<PCanvasElementContainer>()
        .expand((e) => e.selectElementByType<T>(recursive: true))
        .toList();

    return [...sel, ...subList];
  }

  /// Returns a list of [PCanvasElement] of type [T] filteted by [selector].
  List<T> selectElementWhere<T extends PCanvasElement>(
      bool Function(T elem) selector,
      {bool recursive = false}) {
    var elements = this.elements;

    var sel = elements.whereType<T>().where(selector).toList();

    if (!recursive) {
      return sel;
    }

    var subList = elements
        .whereType<PCanvasElementContainer>()
        .expand((e) => e.selectElementWhere<T>(selector, recursive: true))
        .toList();

    return [...sel, ...subList];
  }
}

abstract class PCanvasElement2D extends PCanvasElement {
  /// The parent of this 2D element.
  PCanvasElementContainer? get parent;

  PCanvasElement2D({super.id}) : super();

  /// The resolved X coordinate of this 2D element.
  num get x;

  /// The resolved Y coordinate of this 2D element.
  num get y;

  /// The resolved width of this 2D element.
  num get width;

  /// The resolved height of this 2D element.
  num get height;
}

abstract class PCanvasElement2DBase extends PCanvasElement2D {
  @override
  PCanvasElementContainer? parent;

  /// The position of this element.
  Position position;

  /// The dimension of this element.
  @override
  PDimension dimension;

  @override
  int? zIndex;

  PCanvasElement2DBase({
    this.parent,
    this.zIndex,
    super.id,
    Position? pos,
    num? x,
    num? y,
    PDimension? dimension,
    num? width,
    num? height,
  })  : position = _resolvePosition(pos, x, y),
        dimension = _resolveDimension(dimension, width, height),
        super();

  static Position _resolvePosition(Position? pos, num? x, num? y) {
    if (pos != null) return pos;

    if (x == null || y == null) {
      throw ArgumentError("Invalid position coordinate> x: $x ; y: $y");
    }

    return Point(x, y);
  }

  static PDimension _resolveDimension(PDimension? dimension, num? w, num? h) {
    if (dimension != null) return dimension;

    if (w == null || h == null) {
      throw ArgumentError("Invalid dimension> width: $w ; height: $h");
    }

    return PDimension(w, h);
  }

  @override
  num get x => position.x;

  void set(num x) => position = position;

  @override
  num get y => position.y;

  @override
  num get width => dimension.width;

  @override
  num get height => dimension.height;

  @override
  PRectangle get boundingBox => PRectangle(x, y, width, height);

  @override
  PRectangle getPaintBoundingBox(PCanvas pCanvas) => PRectangle(
      pCanvas.canvasX(x),
      pCanvas.canvasX(y),
      pCanvas.canvasX(width),
      pCanvas.canvasX(height));
}

class PCanvasPanel2D extends PCanvasElement2DBase
    with PCanvasElementContainer<PCanvasElement2D> {
  PStyle? style;

  PCanvasPanel2D({
    this.style,
    super.parent,
    super.zIndex,
    super.id,
    super.pos,
    super.x,
    super.y,
    super.dimension,
    super.width,
    super.height,
  }) : super();

  final List<PCanvasElement2D> _elements = <PCanvasElement2D>[];

  @override
  UnmodifiableListView<PCanvasElement2D> get elements =>
      UnmodifiableListView<PCanvasElement2D>(_elements);

  @override
  bool get hasElements => _elements.isNotEmpty;

  @override
  void clearElements() => _elements.clear();

  @override
  void addElement(PCanvasElement2D element) => _elements.add(element);

  @override
  bool removeElement(PCanvasElement2D element) => _elements.remove(element);

  @override
  void paint(PCanvas pCanvas) {
    var prevState = pCanvas.saveState();

    var panelT = PcanvasTransform(translateX: x, translateY: y);
    var prevT = pCanvas.transform;

    var boundingBox = this.boundingBox.transform(prevT);

    pCanvas.subTransform = panelT;

    try {
      pCanvas.subClip = boundingBox;

      var style = this.style;
      if (style != null) {
        pCanvas.fillRect(0, 0, width, height, style);
      }

      var paintRect = dimension.toPRectangle();

      for (var e in elements) {
        var eBox = e.boundingBox;

        if (!paintRect.intersectsRectangle(eBox)) {
          continue;
        }

        e.paint(pCanvas);
      }
    } finally {
      pCanvas.restoreState(expectedState: prevState);
    }
  }
}

extension PCanvasElementExtension on List<PCanvasElement> {
  /// Sorts the list by [PCanvasElement.zIndex].
  void sortByZIndex() => sort((a, b) {
        var z1 = a.zIndex ?? 0;
        var z2 = b.zIndex ?? 0;
        return z1.compareTo(z2);
      });
}

/// A rectangle [PCanvasElement2D].
class PRectangleElement extends PCanvasElement2DBase {
  PStyle? style;

  PRectangleElement({
    this.style,
    super.parent,
    super.zIndex,
    super.id,
    super.pos,
    super.x,
    super.y,
    super.dimension,
    super.width,
    super.height,
  });

  @override
  void paint(PCanvas pCanvas) {
    var style = this.style;
    if (style != null) {
      pCanvas.fillRect(x, y, width, height, style);
    }
  }
}
