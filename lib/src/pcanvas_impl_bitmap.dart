import 'pcanvas_base.dart';
import 'pcanvas_bitmap.dart';

PCanvas createPCanvasImpl(int width, int height, PCanvasPainter painter) =>
    PCanvasBitmap(width, height, painter);
