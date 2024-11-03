import 'package:collection/collection.dart';
import 'package:pcanvas/src/pcanvas_utils.dart';

import 'pcanvas_base.dart';
import 'pcanvas_color.dart';

/// A base class for [PCanvas] elements.
abstract class PCanvasElement extends WithBoundingBox with WithJson {
  static List<PCanvasElement?> fromList(List l) =>
      l.map(PCanvasElement.from).toList();

  static PCanvasElement? from(Object? o) {
    if (o == null) return null;
    if (o is PCanvasElement) return o;

    if (o is Map<String, dynamic>) {
      return PCanvasElement.fromJson(o);
    }

    return null;
  }

  factory PCanvasElement.fromJson(Map<String, dynamic> j) {
    var className = j['className'];

    switch (className) {
      default:
        return PCanvasElement2D.fromJson(j);
    }
  }

  static void resolveWithElement(Object o, PCanvasElement element) {
    if (o is WithElement) {
      o.element ??= element;
    }

    if (o is WithParentElement &&
        o.parent == null &&
        element is PCanvasElement2D) {
      var p = element.parent;
      if (p is PCanvasElement) {
        o.parent = p as PCanvasElement;
      }
    }
  }

  /// The ID of this element.
  String? id;

  /// The parent of this element.
  PCanvasElementContainer? parent;

  PCanvasElement({this.parent, this.id});

  PCanvasElement? get parentElement {
    final parent = this.parent;
    if (parent is PCanvasElement) {
      return parent as PCanvasElement;
    }
    return null;
  }

  /// Returns the root [PCanvas] if this element is attached.
  PCanvas? get pCanvas {
    final parent = this.parent;
    if (parent == null) return null;
    return parent is PCanvas ? parent : parent.pCanvas;
  }

  String get typeName;

  /// The bounding box of this element.
  @override
  PRectangle get boundingBox;

  /// The dimension this element.
  PDimension get dimension => boundingBox;

  /// The bounding box of the painted area of this element.
  PRectangle getPaintBoundingBox(PCanvas pCanvas);

  /// The Z index of this element.
  int? get zIndex;

  /// The paint operation of this element.
  void paint(PCanvas pCanvas);

  /// Canvas `onClickDown` handler.
  void onClickDown(PCanvasClickEvent event) {}

  /// Canvas `onClickMove` handler.
  void onClickMove(PCanvasClickEvent event) {}

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

  /// Processes [event] and calls [onClickDown]
  PCanvasClickEvent dispatchOnClickDown(PCanvasClickEvent event) {
    var event2 = toInnerClickEvent(event, targetElement: this);
    onClickDown(event2);
    return event2;
  }

  /// Processes [event] and calls [onClickMove]
  PCanvasClickEvent dispatchOnClickMove(PCanvasClickEvent event) {
    var event2 = toInnerClickEvent(event, targetElement: this);
    onClickMove(event2);
    return event2;
  }

  /// Processes [event] and calls [onClickUp]
  PCanvasClickEvent dispatchOnClickUp(PCanvasClickEvent event) {
    var event2 = toInnerClickEvent(event, targetElement: this);
    onClickUp(event2);
    return event2;
  }

  /// Processes [event] and calls [onClick]
  PCanvasClickEvent dispatchOnClick(PCanvasClickEvent event) {
    var event2 = toInnerClickEvent(event, targetElement: this);
    onClick(event2);
    return event2;
  }

  /// Processes [event] and calls [onKeyDown]
  void dispatchOnKeyDown(PCanvasKeyEvent event) {
    onKeyDown(event);
  }

  /// Processes [event] and calls [onKeyUp]
  void dispatchOnKeyUp(PCanvasKeyEvent event) {
    onKeyUp(event);
  }

  /// Processes [event] and calls [onKey]
  void dispatchOnKey(PCanvasKeyEvent event) {
    onKey(event);
  }

  @override
  String toString() {
    var id = this.id;
    return '$typeName${id != null ? '#$id' : ''}';
  }
}

extension IterablePCanvasElementExtension on Iterable<PCanvasElement> {
  void dispatchOnClickDown(PCanvasClickEvent event) {
    for (var e in this) {
      e.dispatchOnClickDown(event);
    }
  }

  void dispatchOnClickMove(PCanvasClickEvent event) {
    for (var e in this) {
      e.dispatchOnClickMove(event);
    }
  }

  void dispatchOnClickUp(PCanvasClickEvent event) {
    for (var e in this) {
      e.dispatchOnClickUp(event);
    }
  }

  void dispatchOnClick(PCanvasClickEvent event) {
    for (var e in this) {
      e.dispatchOnClick(event);
    }
  }

  void dispatchOnKeyDown(PCanvasKeyEvent event) {
    for (var e in this) {
      e.dispatchOnKeyDown(event);
    }
  }

  void dispatchOnKeyUp(PCanvasKeyEvent event) {
    for (var e in this) {
      e.dispatchOnKeyUp(event);
    }
  }

  void dispatchOnKey(PCanvasKeyEvent event) {
    for (var e in this) {
      e.dispatchOnKey(event);
    }
  }
}

/// Interface for classes with [element].
abstract class WithElement {
  PCanvasElement? get element;

  set element(PCanvasElement? element);
}

/// Interface for classes with a [parent] [PCanvasElement].
abstract class WithParentElement {
  PCanvasElement? get parent;

  set parent(PCanvasElement? parent);
}

/// Interface for classes with a [boundingBox].
abstract class WithBoundingBox {
  /// The bounding box of this element.
  PRectangle get boundingBox;

  /// Returns an [event] translated to the internal coordinates of this element.
  PCanvasClickEvent toInnerClickEvent(PCanvasClickEvent event,
      {PCanvasElement? targetElement, PCanvas? pCanvas}) {
    final boundingBox = this.boundingBox.resolve();
    return event.translate(-boundingBox.x, -boundingBox.y,
        targetElement: targetElement, pCanvas: pCanvas);
  }
}

/// Mixin for a class that is a container for [PCanvasElement].
mixin PCanvasElementContainer<E extends PCanvasElement>
    implements WithBoundingBox {
  /// The bounding box of this element container.
  @override
  PRectangle get boundingBox;

  /// Returns this instance casted to [PCanvasElement] if it's possible.
  PCanvasElement? get asPCanvasElement;

  /// Returns this instance casted to [PCanvas] if it's possible.
  PCanvas? get asPCanvas;

  /// Returns the root [PCanvas].
  PCanvas? get pCanvas;

  /// All the [PCanvasElement]s of this instance.
  UnmodifiableListView<E> get elements;

  /// Returns the element at [elements] [index].
  E getElement(int index);

  /// Returns [elements] length.
  int get elementsLength;

  /// Returns `true` if this instances has [elements].
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

  /// Returns a list of [PCanvasElement] of type [T] filtered by [selector].
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

  List<T> selectElementAtPoint<T extends PCanvasElement>(Point point,
      {bool recursive = false}) {
    var elements = this.elements;

    var sel = elements
        .whereType<T>()
        .where((e) => e.boundingBox.containsPoint(point))
        .toList();

    if (!recursive || sel.isEmpty) {
      return sel;
    }

    var subList = sel.whereType<PCanvasElementContainer>().expand((e) {
      var b = e.boundingBox;
      var p = Point(point.x - b.x, point.y - b.y);
      return e.selectElementAtPoint<T>(p, recursive: true);
    }).toList();

    return [...sel, ...subList];
  }

  PCanvasClickEvent _resolveInnerClickEvent(PCanvasClickEvent event) =>
      toInnerClickEvent(event,
          targetElement: asPCanvasElement, pCanvas: asPCanvas);

  /// Processes [event] and calls [onClickDown] on clicked [elements].
  PCanvasClickEvent dispatchOnClickDown(PCanvasClickEvent event) {
    var event2 = _resolveInnerClickEvent(event);
    var elements = selectElementAtPoint(event2.point);
    elements.dispatchOnClickDown(event2);
    return event2;
  }

  /// Processes [event] and calls [onClickMove] on clicked [elements].
  PCanvasClickEvent dispatchOnClickMove(PCanvasClickEvent event) {
    var event2 = _resolveInnerClickEvent(event);
    var elements = selectElementAtPoint(event2.point);
    elements.dispatchOnClickMove(event2);
    return event2;
  }

  /// Processes [event] and calls [onClickUp] on clicked [elements].
  PCanvasClickEvent dispatchOnClickUp(PCanvasClickEvent event) {
    var event2 = _resolveInnerClickEvent(event);
    var elements = selectElementAtPoint(event2.point);
    elements.dispatchOnClickUp(event2);
    return event2;
  }

  /// Processes [event] and calls [onClick] on clicked [elements].
  PCanvasClickEvent dispatchOnClick(PCanvasClickEvent event) {
    var event2 = _resolveInnerClickEvent(event);
    var elements = selectElementAtPoint(event2.point);
    elements.dispatchOnClick(event2);
    return event2;
  }

  PCanvasKeyEvent _resolveInnerKeyEvent(PCanvasKeyEvent event) =>
      event.copyWith(
          parentEvent: event,
          targetElement: asPCanvasElement,
          pCanvas: asPCanvas);

  /// Processes [event] and calls [onKeyDown] on [elements].
  PCanvasKeyEvent dispatchOnKeyDown(PCanvasKeyEvent event) {
    var event2 = _resolveInnerKeyEvent(event);
    elements.dispatchOnKeyDown(event2);
    return event2;
  }

  /// Processes [event] and calls [onKeyUp] on [elements].
  PCanvasKeyEvent dispatchOnKeyUp(PCanvasKeyEvent event) {
    var event2 = _resolveInnerKeyEvent(event);
    elements.dispatchOnKeyUp(event);
    return event2;
  }

  /// Processes [event] and calls [onKey] on [elements].
  PCanvasKeyEvent dispatchOnKey(PCanvasKeyEvent event) {
    var event2 = _resolveInnerKeyEvent(event);
    elements.dispatchOnKey(event);
    return event2;
  }
}

abstract class PCanvasElement2D extends PCanvasElement {
  static List<PCanvasElement2D?> fromList(List l) =>
      l.map(PCanvasElement2D.from).toList();

  static PCanvasElement2D? from(Object? o) {
    if (o == null) return null;
    if (o is PCanvasElement2D) return o;

    if (o is PCanvasElement) {
      throw StateError("Type `${o.className}` is NOT a `PCanvasElement2D`: $o");
    }

    if (o is Map<String, dynamic>) {
      return PCanvasElement2D.fromJson(o);
    }

    return null;
  }

  factory PCanvasElement2D.fromJson(Map<String, dynamic> j) {
    var className = j['className'];

    switch (className) {
      case 'PCanvasPanel2D':
        return PCanvasPanel2D.fromJson(j);
      case 'PCanvasGridPanel2D':
        return PCanvasGridPanel2D.fromJson(j);
      default:
        throw StateError("Can't handle JSON with `className`: $className");
    }
  }

  PCanvasElement2D({super.parent, super.id}) : super();

  /// The resolved X coordinate of this 2D element.
  num get x;

  set x(num x);

  /// The resolved Y coordinate of this 2D element.
  num get y;

  set y(num y);

  /// gets [x] and [y].
  Point getXY();

  /// Sets the [x] and [y].
  setXY(num x, num y);

  /// The resolved width of this 2D element.
  num get width;

  set width(num width);

  /// The resolved height of this 2D element.
  num get height;

  set height(num height);
}

abstract class PCanvasElement2DBase extends PCanvasElement2D {
  /// The position of this element.
  late Position position;

  /// The dimension of this element.
  @override
  late PDimension dimension;

  @override
  int? zIndex;

  PCanvasElement2DBase({
    super.parent,
    this.zIndex,
    Position? pos,
    PDimension? dimension,
    super.id,
  }) : super() {
    position = _resolvePosition(pos);
    this.dimension = _resolveDimension(dimension);
  }

  Position _resolvePosition(Position? pos) =>
      Position.resolvePosition(pos, null, null, element: this);

  PDimension _resolveDimension(PDimension? dimension) =>
      PDimension.resolveDimension(dimension, null, null);

  @override
  num get x => position.x;

  @override
  set x(num x) => position = position.setX(x);

  @override
  num get y => position.y;

  @override
  set y(num y) => position = position.setY(y);

  @override
  Point getXY() => position.toPoint();

  @override
  setXY(num x, num y) => position = position.setXY(x, y);

  @override
  num get width => dimension.width;

  @override
  set width(num width) => dimension = dimension.setWidth(width);

  @override
  num get height => dimension.height;

  @override
  set height(num height) => dimension = dimension.setHeight(height);

  @override
  PRectangle get boundingBox {
    var position = this.position.resolve();
    var dimension = this.dimension.resolve();
    return PRectangle(
        position.x, position.y, dimension.width, dimension.height);
  }

  @override
  PRectangle getPaintBoundingBox(PCanvas pCanvas) {
    var position = this.position.resolve();
    var dimension = this.dimension.resolve();
    return PRectangle(pCanvas.canvasX(position.x), pCanvas.canvasX(position.y),
        pCanvas.canvasX(dimension.width), pCanvas.canvasX(dimension.height));
  }

  @override
  Map<String, dynamic> toJson() => {
        'className': className,
        'position': position.toJson(),
        'dimension': dimension.toJson(),
        if (zIndex != null) 'zIndex': zIndex,
      };
}

class PCanvasPanel2D extends PCanvasElement2DBase
    with PCanvasElementContainer<PCanvasElement2D> {
  PStyle? style;

  PCanvasPanel2D({
    this.style,
    super.parent,
    super.zIndex,
    super.pos,
    super.dimension,
    Iterable<PCanvasElement2D>? elements,
    super.id,
  }) : super() {
    if (elements != null) {
      addAllElements(elements);
    }
  }

  @override
  String get typeName => 'PCanvasPanel2D';

  @override
  PCanvasElement? get asPCanvasElement => this;

  @override
  PCanvas? get asPCanvas => null;

  final List<PCanvasElement2D> _elements = <PCanvasElement2D>[];

  @override
  UnmodifiableListView<PCanvasElement2D> get elements =>
      UnmodifiableListView<PCanvasElement2D>(_elements);

  @override
  PCanvasElement2D getElement(int index) => _elements[index];

  void sortElements(
      int Function(PCanvasElement2D a, PCanvasElement2D b) comparator) {
    _elements.sort(comparator);
  }

  @override
  int get elementsLength => _elements.length;

  @override
  bool get hasElements => _elements.isNotEmpty;

  @override
  void clearElements() {
    if (_elements.isNotEmpty) {
      for (var e in _elements) {
        e.parent = null;
      }
      _elements.clear();
    }
  }

  @override
  void addElement(PCanvasElement2D element) {
    _elements.add(element);
    element.parent = this;
  }

  @override
  bool removeElement(PCanvasElement2D element) {
    var rm = _elements.remove(element);
    if (rm) {
      element.parent = null;
    }
    return rm;
  }

  @override
  void paint(PCanvas pCanvas) {
    var prevState = pCanvas.saveState();

    final prevT = pCanvas.transform;

    final boundingBox = this.boundingBox;
    final boundingBoxTransformed = boundingBox.transform(prevT);

    final t =
        PcanvasTransform(translateX: boundingBox.x, translateY: boundingBox.y);

    try {
      pCanvas.subTransform = t;
      pCanvas.subClip = boundingBoxTransformed;

      paintBackground(pCanvas);

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

  void paintBackground(PCanvas pCanvas) {
    var style = this.style;
    if (style != null) {
      pCanvas.fillRect(0, 0, width, height, style);
    }
  }

  @override
  PCanvasClickEvent dispatchOnClickDown(PCanvasClickEvent event) {
    final event2 = super.dispatchOnClickDown(event);
    onClickDown(event2);
    return event2;
  }

  @override
  PCanvasClickEvent dispatchOnClickMove(PCanvasClickEvent event) {
    final event2 = super.dispatchOnClickMove(event);
    onClickMove(event2);
    return event2;
  }

  @override
  PCanvasClickEvent dispatchOnClickUp(PCanvasClickEvent event) {
    var event2 = super.dispatchOnClickUp(event);
    onClickUp(event2);
    return event2;
  }

  @override
  PCanvasClickEvent dispatchOnClick(PCanvasClickEvent event) {
    var event2 = super.dispatchOnClick(event);
    onClick(event2);
    return event2;
  }

  @override
  PCanvasKeyEvent dispatchOnKeyDown(PCanvasKeyEvent event) {
    var event2 = super.dispatchOnKeyDown(event);
    onKeyDown(event2);
    return event2;
  }

  @override
  PCanvasKeyEvent dispatchOnKeyUp(PCanvasKeyEvent event) {
    var event2 = super.dispatchOnKeyUp(event);
    onKeyUp(event2);
    return event2;
  }

  @override
  PCanvasKeyEvent dispatchOnKey(PCanvasKeyEvent event) {
    var event2 = super.dispatchOnKey(event);
    onKey(event2);
    return event2;
  }

  @override
  String get className => 'PCanvasPanel2D';

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        if (style != null) 'style': style?.toJson(),
        'elements': elements.map((e) => e.toJson()).toList(),
      };

  factory PCanvasPanel2D.fromJson(Map<String, dynamic> j,
          {PCanvasElementContainer? parent}) =>
      PCanvasPanel2D(
        parent: parent,
        style: PStyle.fromJson(j['style']),
        zIndex: j.containsKey('zIndex') ? parseInt(j['zIndex']) : null,
        pos: Position.fromJson(j['pos']),
        dimension: PDimension.fromJson(j['dimension']),
        id: j['id'],
        elements: PCanvasElement2D.fromList(j['elements']).nonNulls.toList(),
      );
}

extension PCanvasElementExtension on List<PCanvasElement> {
  /// Sorts the list by [PCanvasElement.zIndex].
  void sortByZIndex() => sort((a, b) {
        var z1 = a.zIndex ?? 0;
        var z2 = b.zIndex ?? 0;
        return z1.compareTo(z2);
      });
}

class PCanvasGridPanel2D extends PCanvasPanel2D {
  final int spacing;

  PCanvasGridPanel2D({
    this.spacing = 0,
    super.style,
    super.parent,
    super.zIndex,
    super.id,
    super.pos,
    super.dimension,
    super.elements,
  });

  @override
  void addElement(PCanvasElement2D element) {
    setNextElementPosition(element);
    super.addElement(element);
  }

  void setNextElementPosition(PCanvasElement2D element) {
    if (!hasElements) {
      element.setXY(spacing, spacing);
    } else {
      var lastIdx = elementsLength - 1;
      var last = getElement(lastIdx);

      var p = last.getXY();

      var p2 = p.setX(p.x + last.width + spacing);

      if (p2.x + element.width > width) {
        var lastLine = <PCanvasElement2D>[];
        for (var i = lastIdx; i >= 0; --i) {
          var e = getElement(i);

          if (e.y == last.y) {
            lastLine.add(e);
          } else {
            break;
          }
        }

        assert(lastLine.isNotEmpty);

        var lineHeight = lastLine.map((e) => e.height).max;

        p2 = p.setXY(spacing, p2.y + lineHeight + spacing);
      }

      element.setXY(p2.x, p2.y);
    }
  }

  @override
  String get className => 'PCanvasGridPanel2D';

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'spacing': spacing,
      };

  factory PCanvasGridPanel2D.fromJson(Map<String, dynamic> j,
          {PCanvasElementContainer? parent}) =>
      PCanvasGridPanel2D(
        parent: parent,
        style: PStyle.fromJson(j['style']),
        zIndex: j.containsKey('zIndex') ? parseInt(j['zIndex']) : null,
        pos: Position.fromJson(j['pos']),
        dimension: PDimension.fromJson(j['dimension']),
        spacing: parseInt(j['spacing']),
        id: j['id'],
        elements:
            PCanvasElement2D.fromList(j['elements'] as List).nonNulls.toList(),
      );
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
    super.dimension,
  });

  @override
  String get typeName => 'PRectangleElement';

  @override
  void paint(PCanvas pCanvas) {
    var style = this.style;
    if (style != null) {
      pCanvas.fillRect(x, y, width, height, style);
    }
  }

  @override
  String get className => 'PRectangleElement';

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        if (style != null) 'style': style?.toJson(),
      };

  factory PRectangleElement.fromJson(Map<String, dynamic> j) =>
      PRectangleElement(
        style: PStyle.fromJson(j['style']),
        pos: Position.fromJson(j['position']),
        dimension: PDimension.fromJson(j['dimension']),
        zIndex: j.containsKey('zIndex') ? parseInt(j['zIndex']) : null,
      );
}

/// A simple gradient background.
class PCanvasBackgroundGradient extends PCanvasElement2DBase {
  final PColor colorFrom;
  final PColor colorTo;

  static const int defaultZIndex = -999999999;

  PCanvasBackgroundGradient(this.colorFrom, this.colorTo,
      {super.parent,
      super.pos,
      super.dimension,
      int zIndex = defaultZIndex,
      super.id})
      : super(zIndex: zIndex);

  @override
  Position _resolvePosition(Position? pos) {
    if (pos == null) {
      return Point(0, 0);
    }
    return super._resolvePosition(pos);
  }

  @override
  PDimension _resolveDimension(PDimension? dimension) {
    if (dimension == null) {
      var parent = this.parent;
      if (parent is PCanvasElement) {
        PCanvasElement p = parent as PCanvasElement;
        return DynamicDimension((_) => p.dimension);
      }
    }
    return super._resolveDimension(dimension);
  }

  @override
  String get typeName => 'PCanvasBackgroundGradient';

  @override
  int? get zIndex => super.zIndex!;

  @override
  PRectangle get boundingBox =>
      _lastPaintBoundingBox ?? PRectangle(x, y, width, height);

  @override
  PRectangle getPaintBoundingBox(PCanvas pCanvas) =>
      PRectangle.fromDimension(0, 0, pCanvas.dimension);

  PRectangle? _lastPaintBoundingBox;

  @override
  void paint(PCanvas pCanvas) {
    _lastPaintBoundingBox = PRectangle.fromDimension(0, 0, pCanvas.dimension);

    if (pCanvas.isZeroDimension) return;

    pCanvas.fillBottomUpGradient(
        0, 0, pCanvas.width, pCanvas.height, colorFrom, colorTo);
  }

  @override
  String get className => 'PCanvasBackgroundGradient';

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'colorFrom': colorFrom.toJson(),
        'colorTo': colorTo.toJson(),
      };

  factory PCanvasBackgroundGradient.fromJson(Map<String, dynamic> j) =>
      PCanvasBackgroundGradient(
        PColor.fromJson(j['colorFrom']),
        PColor.fromJson(j['colorTo']),
        pos: Position.fromJson(j['position']),
        dimension: PDimension.fromJson(j['dimension']),
        zIndex: j.containsKey('zIndex') ? parseInt(j['zIndex']) : defaultZIndex,
      );
}
