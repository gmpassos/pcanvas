import 'pcanvas_base.dart';
import 'pcanvas_html.dart';

PCanvas createPCanvasImpl(int width, int height, PCanvasPainter painter) =>
    PCanvasHTML(width, height, painter);
