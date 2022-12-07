import 'pcanvas_base.dart';

/// A base class for [PCanvas] elements.
abstract class PCanvasElement {
  /// The bounding box of this element.
  PRectangle getBoundingBox(PCanvas pCanvas);

  /// The Z index of this element.
  int? get zIndex;

  /// The paint operation of this element.
  void paint(PCanvas pCanvas);
}

extension PCanvasElementExtension on List<PCanvasElement> {
  /// Sorts the list by [PCanvasElement.zIndex].
  void sortByZIndex() => sort((a, b) {
        var z1 = a.zIndex ?? 0;
        var z2 = b.zIndex ?? 0;
        return z1.compareTo(z2);
      });
}
