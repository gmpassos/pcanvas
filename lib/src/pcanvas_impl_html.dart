import 'pcanvas_base.dart';
import 'pcanvas_html.dart';

PCanvas createPCanvasImpl(int width, int height, PCanvasPainter painter,
        {PCanvasPixels? initialPixels}) =>
    PCanvasHTML(width, height, painter, initialPixels: initialPixels);
