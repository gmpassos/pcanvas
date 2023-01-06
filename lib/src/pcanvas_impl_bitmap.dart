import 'pcanvas_base.dart';
import 'pcanvas_bitmap.dart';

PCanvas createPCanvasImpl(int width, int height, PCanvasPainter painter,
        {PCanvasPixels? initialPixels}) =>
    PCanvasBitmap(width, height, painter, initialPixels: initialPixels);
